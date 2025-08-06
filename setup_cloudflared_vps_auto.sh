#!/bin/bash
# ============================================================================
# Cloudflared Secure VPS Setup Script (Fully Automated Cloudflare Access OTP)
# Author: Avishay Rapp
# Description:
#   - Accepts CLI args for Zone ID, Account ID, API Token, Hostnames, Approved Emails
#   - Detects Linux distribution & version
#   - Installs Cloudflare Tunnel (cloudflared)
#   - Hides VPS behind Cloudflare (no open ports)
#   - Creates Cloudflare Access SSH policy with One-Time PIN
# ============================================================================
set -e

# === Default Configuration ==================================================
TUNNEL_NAME="main-tunnel"
APP_HOSTNAME="app.example.com"
SSH_HOSTNAME="ssh.example.com"
ZONE_ID=""
ACCOUNT_ID=""
API_TOKEN=""
APPROVED_EMAILS=()

# === Parse CLI Arguments ====================================================
for arg in "$@"; do
  case $arg in
    --zoneid=*)
      ZONE_ID="${arg#*=}"
      ;;
    --accountid=*)
      ACCOUNT_ID="${arg#*=}"
      ;;
    --apitoken=*)
      API_TOKEN="${arg#*=}"
      ;;
    --apphost=*)
      APP_HOSTNAME="${arg#*=}"
      ;;
    --sshhost=*)
      SSH_HOSTNAME="${arg#*=}"
      ;;
    --emails=*)
      IFS=',' read -r -a APPROVED_EMAILS <<< "${arg#*=}"
      ;;
    *)
      echo "[!] Unknown option: $arg"
      exit 1
      ;;
  esac
done

# === Validate Required Args =================================================
if [[ -z "$ZONE_ID" || -z "$ACCOUNT_ID" || -z "$API_TOKEN" || ${#APPROVED_EMAILS[@]} -eq 0 ]]; then
  echo "Usage: $0 --zoneid=ZONE --accountid=ACCOUNT --apitoken=TOKEN --apphost=HOST --sshhost=HOST --emails=email1,email2"
  exit 1
fi

# === Detect Linux Distribution ==============================================
if [ -f /etc/os-release ]; then
  . /etc/os-release
  DISTRO_NAME=$NAME
  DISTRO_VERSION=$VERSION_ID
else
  echo "[!] Cannot detect Linux distribution. Aborting."
  exit 1
fi

echo "[+] Installer detected: $DISTRO_NAME $DISTRO_VERSION"

# === Package Manager Commands ===============================================
if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
  UPDATE_CMD="sudo apt update && sudo apt upgrade -y"
  INSTALL_CMD="sudo apt install -y"
elif [[ "$ID" == "rhel" || "$ID" == "rocky" || "$ID" == "almalinux" ]]; then
  UPDATE_CMD="sudo dnf update -y"
  INSTALL_CMD="sudo dnf install -y"
elif [[ "$ID" == "fedora" ]]; then
  UPDATE_CMD="sudo dnf upgrade --refresh -y"
  INSTALL_CMD="sudo dnf install -y"
elif [[ "$ID" == "centos" ]]; then
  UPDATE_CMD="sudo yum update -y"
  INSTALL_CMD="sudo yum install -y"
elif [[ "$ID" == "arch" ]]; then
  UPDATE_CMD="sudo pacman -Syu --noconfirm"
  INSTALL_CMD="sudo pacman -S --noconfirm"
elif [[ "$ID" == opensuse* || "$ID_LIKE" == *"suse"* ]]; then
  UPDATE_CMD="sudo zypper refresh && sudo zypper update -y"
  INSTALL_CMD="sudo zypper install -y"
else
  echo "[!] Unsupported distribution: $DISTRO_NAME"
  exit 1
fi

# === Update & Install Dependencies ==========================================
echo "[+] Updating packages..."
eval "$UPDATE_CMD"
echo "[+] Installing dependencies..."
eval "$INSTALL_CMD" curl jq

# === Install cloudflared ====================================================
echo "[+] Installing cloudflared..."
if [[ "$ID" == "ubuntu" || "$ID" == "debian" ]]; then
  curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
  sudo dpkg -i cloudflared.deb || sudo apt -f install -y
  rm cloudflared.deb
elif [[ "$ID" == "arch" ]]; then
  $INSTALL_CMD cloudflared || true
else
  CLOUDFLARED_RPM_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-x86_64.rpm"
  curl -L "$CLOUDFLARED_RPM_URL" -o cloudflared.rpm
  sudo rpm -i cloudflared.rpm || eval "$INSTALL_CMD" ./cloudflared.rpm
  rm cloudflared.rpm
fi

# === Authenticate & Create Tunnel ===========================================
echo "[+] Logging in to Cloudflare..."
cloudflared tunnel login
echo "[+] Creating tunnel: $TUNNEL_NAME"
cloudflared tunnel create "$TUNNEL_NAME"

CONFIG_PATH="/etc/cloudflared/config.yml"
CRED_FILE=$(ls ~/.cloudflared/*.json | head -n 1)
sudo mkdir -p /etc/cloudflared
sudo tee $CONFIG_PATH > /dev/null <<EOF
tunnel: $TUNNEL_NAME
credentials-file: $CRED_FILE

ingress:
  - hostname: $APP_HOSTNAME
    service: http://localhost:8080
  - hostname: $SSH_HOSTNAME
    service: ssh://localhost:22
  - service: http_status:404
EOF

cloudflared tunnel route dns "$TUNNEL_NAME" "$APP_HOSTNAME"
cloudflared tunnel route dns "$TUNNEL_NAME" "$SSH_HOSTNAME"

sudo cloudflared service install
sudo systemctl enable cloudflared --now

# === Firewall Lockdown ======================================================
echo "[+] Locking down firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw disable
sudo ufw enable

# === Create Cloudflare Access App & Policy ==================================
echo "[+] Creating Cloudflare Access SSH application..."
EMAIL_JSON=$(printf '"%s",' "${APPROVED_EMAILS[@]}")
EMAIL_JSON="[${EMAIL_JSON%,}]"

ACCESS_APP=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/access/apps" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"name\":\"SSH Access\",\"domain\":\"$SSH_HOSTNAME\",\"type\":\"self_hosted\",\"session_duration\":\"1h\"}")

APP_ID=$(echo "$ACCESS_APP" | jq -r '.result.id')

if [[ "$APP_ID" == "null" ]]; then
  echo "[!] Failed to create Access application."
  echo "$ACCESS_APP"
  exit 1
fi

echo "[+] Creating Access policy with OTP requirement..."
curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/access/apps/$APP_ID/policies" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" \
  --data "{\"name\":\"Allow Approved SSH Users\",\"decision\":\"allow\",\"include\":[{\"email\":$EMAIL_JSON}],\"require\":[{\"otp\":{}}]}" > /dev/null

# === Done ===================================================================
echo ""
echo "====================================================================="
echo "  Cloudflared VPS setup complete!"
echo "  Distribution: $DISTRO_NAME $DISTRO_VERSION"
echo ""
echo "Web App Hostname: $APP_HOSTNAME"
echo "SSH Hostname:     $SSH_HOSTNAME"
echo "Approved Emails:  ${APPROVED_EMAILS[*]}"
echo ""
echo "To connect via SSH:"
echo "  cloudflared access ssh --hostname $SSH_HOSTNAME"
echo "====================================================================="
