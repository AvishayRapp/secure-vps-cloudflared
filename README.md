# Secure VPS with Cloudflare Tunnel + OTP SSH

> **Note:** You will also need to **install `cloudflared` on your computer** (the one you will use to connect to SSH) in order to use the secure SSH tunnel created by this setup. Installation instructions for your local machine are included in the **"Connecting to SSH"** section below.

---

## 📌 Overview

This project secures your VPS by hiding it behind a **Cloudflare Tunnel** and enforcing **One-Time PIN (OTP)** authentication via Cloudflare Access.

You can run the script in:

1. **Manual Mode** — Tunnel + firewall lockdown, you configure Cloudflare Access manually.
2. **Automated Mode** — Tunnel + firewall lockdown + automatic Cloudflare Access SSH OTP setup via the Cloudflare API.

In both modes:

* All inbound ports are closed (including SSH).
* Services are only accessible through the Cloudflare Tunnel.
* SSH access is limited to approved users via OTP.
* VPS IP is hidden from the public internet.

---

## 🔒 Security Benefits

* **Zero Attack Surface** — No open ports.
* **DDoS Protection** — All traffic via Cloudflare.
* **Access Control** — Approved users only.
* **OTP Verification** — Login requires a one-time PIN sent via email.
* **Easy Revocation** — Remove an email in Cloudflare Access to block instantly.

---

## 📦 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/AvishayRapp/secure-vps-cloudflared.git
cd secure-vps-cloudflared
```

---

## ⚙️ Running the Script with CLI Arguments (Recommended)

You can now provide all required configuration via CLI arguments instead of editing the script manually.

**Syntax:**

```bash
./setup_cloudflared_vps_auto.sh \
  --zoneid=YOUR_ZONE_ID \
  --accountid=YOUR_ACCOUNT_ID \
  --apitoken=YOUR_API_TOKEN \
  --apphost=app.example.com \
  --sshhost=ssh.example.com \
  --emails=user1@example.com,user2@example.com
```

**Example:**

```bash
./setup_cloudflared_vps_auto.sh \
  --zoneid=1234567890abcdef \
  --accountid=abcdef1234567890 \
  --apitoken=sk_live_your_token_here \
  --apphost=app.mydomain.com \
  --sshhost=ssh.mydomain.com \
  --emails=me@example.com,friend@example.com
```

---

## ⚙️ Manual Mode (Without CLI Arguments)

If you prefer manual setup:

1. Edit the script:

```bash
nano setup_cloudflared_vps_auto.sh
```

Set:

```bash
APP_HOSTNAME="app.example.com"
SSH_HOSTNAME="ssh.example.com"
ZONE_ID="YOUR_ZONE_ID"
ACCOUNT_ID="YOUR_ACCOUNT_ID"
API_TOKEN="YOUR_API_TOKEN"
APPROVED_EMAILS=("you@example.com" "friend@example.com")
```

2. Run:

```bash
chmod +x setup_cloudflared_vps_auto.sh
./setup_cloudflared_vps_auto.sh
```

3. Follow **Manual Cloudflare Access Setup** steps if not using API automation.

---

## 🖥️ Connecting to SSH

**Install `cloudflared` locally:**

* **macOS:**

```bash
brew install cloudflared
```

* **Windows:**

```powershell
winget install --id Cloudflare.cloudflared
```

* **Debian/Ubuntu:**

```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb
```

* **Arch Linux:**

```bash
sudo pacman -Syu --noconfirm cloudflared
```

* **Fedora/RHEL/CentOS:**

```bash
sudo dnf install -y cloudflared
```

* **openSUSE:**

```bash
sudo zypper install -y cloudflared
```

**Connect via SSH:**

```bash
cloudflared access ssh --hostname ssh.example.com
```

1. Enter your approved email.
2. Enter the OTP from your inbox.
3. You’re in.

---

## 📌 Firewall Lockdown

The script:

* Denies all incoming connections.
* Allows all outgoing connections.
* Closes port 22 to the public.

---

## 🛠 Adding More Services

Edit:

```bash
sudo nano /etc/cloudflared/config.yml
```

Example:

```yaml
ingress:
  - hostname: app.example.com
    service: http://localhost:8080
  - hostname: ssh.example.com
    service: ssh://localhost:22
  - service: http_status:404
```

Restart:

```bash
sudo systemctl restart cloudflared
```

---

## 📜 License

MIT License — free to use, modify, and share.

---

## 💡 Contributing

Pull requests welcome!
