#!/bin/bash
# ============================================================================
# Cloudflared Secure VPS Setup Script (Fully Automated Cloudflare Access OTP)
# Author: Avishay Rapp
# Description:
#   - Installs Cloudflare Tunnel (cloudflared)
#   - Hides VPS behind Cloudflare (no open ports)
#   - Creates Cloudflare Access SSH policy with One-Time PIN
#   - Adds approved SSH users automatically
# ============================================================================
set -e

# === USER CONFIGURATION (EDIT THESE) ========================================
TUNNEL_NAME="main-tunnel"                         # Tunnel name in Cloudflare
APP_HOSTNAME="app.example.com"                    # Web app hostname
SSH_HOSTNAME="ssh.example.com"                    # SSH hostname
ZONE_ID="YOUR_ZONE_ID"                             # Cloudflare Zone ID
ACCOUNT_ID="YOUR_ACCOUNT_ID"                       # Cloudflare Account ID
API_TOKEN="YOUR_CLOUDFLARE_API_TOKEN"              # Cloudflare API Token
APPROVED_EMAILS=("you@example.com" "friend@example.com")  # Approved SSH emails

# === 1. Update system =======================================================
echo "[+] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# === 2. Install dependencies ================================================
echo "[+] Installing cloudflared and dependencies..."
sudo apt install curl jq -y
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb
rm cloudflared.deb

# === 3. Authenticate cloudflared ============================================
echo "[+] Please log in to Cloudflare to authorize this VPS..."
cloudflared tunnel login

# === 4. Create tunnel =======================================================
echo "[+] Creating tunnel: $TUNNEL_NAME..."
cloudflared tunnel create "$TUNNEL_NAME"

# === 5. Create tunnel config ================================================
echo "[+] Creating Cloudflare Tunnel configuration..."
CONFIG_PATH="/etc/cloudflared/config.yml"
sudo mkdir -p /etc/cloudflared
CRED_FILE=$(ls ~/.cloudflared/*.json | head -n 1)

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

# === 6. Create DNS routes in Cloudflare =====================================
echo "[+] Creating DNS records in Cloudflare..."
cloudflared tunnel route dns "$TUNNEL_NAME" "$APP_HOSTNAME"
cloudflared tunnel route dns "$TUNNEL_NAME" "$SSH_HOSTNAME"

# === 7. Enable cloudflared as a service =====================================
echo "[+] Enabling cloudflared service..."
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared

# === 8. Firewall lockdown ===================================================
echo "[+] Locking down firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw disable
sudo ufw enable
sudo ufw status

# === 9. Create Cloudflare Access SSH App ====================================
echo "[+] Creating Cloudflare Access application for SSH..."

# Build JSON array of approved emails
EMAIL_JSON=$(printf '"%s",' "${APPROVED_EMAILS[@]}")
EMAIL_JSON="[${EMAIL_JSON%,}]"

ACCESS_APP=$(curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/access/apps" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{
        \"name\": \"SSH Access\",
        \"domain\": \"$SSH_HOSTNAME\",
        \"type\": \"self_hosted\",
        \"session_duration\": \"1h\"
    }")

APP_ID=$(echo "$ACCESS_APP" | jq -r '.result.id')

if [[ "$APP_ID" == "null" ]]; then
    echo "[!] Failed to create Access application. API response:"
    echo "$ACCESS_APP"
    exit 1
fi

# === 10. Create Access policy ===============================================
echo "[+] Creating Access policy with One-Time PIN requirement..."

curl -s -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/access/apps/$APP_ID/policies" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" \
    --data "{
        \"name\": \"Allow Approved SSH Users\",
        \"decision\": \"allow\",
        \"include\": [{ \"email\": $EMAIL_JSON }],
        \"require\": [{ \"otp\": {} }]
    }" > /dev/null

# === 11. Done ===============================================================
echo ""
echo "====================================================================="
echo "  Cloudflared VPS setup complete!"
echo ""
echo "Web App Hostname: $APP_HOSTNAME"
echo "SSH Hostname:     $SSH_HOSTNAME"
echo "Approved Emails:  ${APPROVED_EMAILS[*]}"
echo ""
echo "To connect via SSH from your local machine:"
echo "  cloudflared access ssh --hostname $SSH_HOSTNAME"
echo ""
echo "IMPORTANT:"
echo "- Install cloudflared locally on your machine"
echo "- Each SSH login will require OTP from Cloudflare Access"
echo "- VPS IP is now hidden and all inbound ports are closed"
echo "====================================================================="
