# Secure VPS with Cloudflare Tunnel + OTP SSH

> **Note:** You will also need to **install `cloudflared` on your computer** (the one you will use to connect to SSH) in order to use the secure SSH tunnel created by this setup. Installation instructions for your local machine are included in the **"Connecting to SSH"** section below.

---

## 📌 Overview

This project provides **two modes** to secure your VPS using a **Cloudflare Tunnel** and **One-Time PIN (OTP)** authentication via Cloudflare Access.

1. **Manual Mode** — Creates tunnel + firewall lockdown, then you configure Cloudflare Access SSH OTP in the dashboard manually.
2. **Automated Mode** — Creates tunnel + firewall lockdown + automatically sets up Cloudflare Access SSH OTP via the Cloudflare API.

In both modes:

* All inbound ports are closed (including SSH).
* Services are accessible only through the Cloudflare Tunnel.
* SSH access is restricted to approved users via OTP.
* VPS IP is hidden from the public internet.

---

## 🔒 Security Benefits

* **Zero Attack Surface** — No exposed IP or open ports.
* **DDoS Protection** — All traffic flows through Cloudflare.
* **Access Control** — Only approved users can connect to SSH.
* **OTP Verification** — Login requires a one-time code sent via email.
* **Easy Revocation** — Remove an email in Cloudflare Access to instantly block that user.

---

## 📦 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/AvishayRapp/secure-vps-cloudflared.git
cd secure-vps-cloudflared
```

---

## ⚙️ Manual Mode

**Script:** `setup_cloudflared_vps_auto.sh`

1. Edit the script:

```bash
nano setup_cloudflared_vps_auto.sh
```

Set:

```bash
APP_HOSTNAME="app.example.com"
SSH_HOSTNAME="ssh.example.com"
```

2. Run:

```bash
chmod +x setup_cloudflared_vps_auto.sh
./setup_cloudflared_vps_auto.sh
```

3. Follow the **Manual Cloudflare Access Setup** section below.

---

## ⚙️ Automated Mode (Recommended)

**Script:** `setup_cloudflared_vps_auto.sh`

Before you start, you’ll need:

* **Cloudflare API Token** with permissions:

  * Zone: Read & Edit
  * Access: Applications: Edit
  * Access: Policies: Edit
* **Zone ID** and **Account ID** from Cloudflare dashboard.

Edit the script:

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

Run:

```bash
chmod +x setup_cloudflared_vps_auto.sh
./setup_cloudflared_vps_auto.sh
```

---

## 🛡 Manual Cloudflare Access Setup

If you used Manual Mode:

1. Log in to Cloudflare Dashboard → **Access → Applications → Add an Application**.
2. Select **Self-Hosted**.
3. Application domain: `ssh.example.com`.
4. Add policy → Allow → Include → Emails: Add approved users.
5. Enable **One-Time PIN** under Authentication.

---

## 🖥️ Connecting to SSH

### Install `cloudflared` Locally

**macOS:**

```bash
brew install cloudflared
```

**Windows:**

```powershell
winget install --id Cloudflare.cloudflared
```

**Debian/Ubuntu:**

```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb
```

**Arch Linux:**

```bash
sudo pacman -Syu --noconfirm cloudflared
```

**Fedora/RHEL/CentOS:**

```bash
sudo dnf install -y cloudflared
```

**openSUSE:**

```bash
sudo zypper install -y cloudflared
```

### Connect via SSH

```bash
cloudflared access ssh --hostname ssh.example.com
```

1. Enter your approved email.
2. Enter the OTP from your inbox.
3. You’re in.

---

## 📌 Firewall Lockdown

The script:

* Denies all **incoming** connections.
* Allows all **outgoing** connections.
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

MIT License — free to use, modify, share.

---

## 💡 Contributing

Pull requests welcome.
