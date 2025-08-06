# Secure VPS with Cloudflare Tunnel + OTP SSH

> **Note:**  
> You will also need to **install `cloudflared` on your computer** (the one you will use to connect to SSH) in order to use the secure SSH tunnel created by this setup.  
> Installation instructions for your local machine are included in the **"Connecting to SSH"** section below.

---

## 📌 Overview

This project provides **two ways** to fully secure a VPS by hiding it behind a **Cloudflare Tunnel**:

1. **Manual Mode** — Tunnel + firewall lockdown + manual Cloudflare Access setup in the dashboard.
2. **Automated Mode** — Tunnel + firewall lockdown + automatic creation of the Cloudflare Access SSH OTP policy via the Cloudflare API.

In both modes:
- All inbound ports are **closed** (even SSH).
- Services are **only accessible through Cloudflare Tunnel**.
- SSH access is **restricted to approved users** via **Cloudflare Access One-Time PIN**.
- VPS IP is completely **hidden from the public internet**.

---

## 🔒 Security Benefits

- **Zero Attack Surface** — No exposed IP or open ports.
- **DDoS Protection** — All traffic flows through Cloudflare.
- **Access Control** — Only approved users can connect to SSH.
- **OTP Verification** — Each login requires a one-time code sent via email.
- **App Isolation** — Multiple services can run behind the same secure tunnel.
- **Easy Revocation** — Remove an email from Cloudflare Access to instantly block that user.

---

## 📦 Installation

### 1. Clone the Repository
```bash
git clone https://github.com/AvishayRapp/secure-vps-cloudflared.git
cd secure-vps-cloudflared
````

---

## ⚙️ Option 1 — Manual Mode

**Script:** `setup_cloudflared_vps.sh`
This mode sets up the tunnel and firewall, but you will create the Cloudflare Access SSH OTP policy manually.

### Steps:

1. Edit the script:

   ```bash
   nano setup_cloudflared_vps.sh
   ```

   Set:

   ```bash
   APP_HOSTNAME="app.example.com"
   SSH_HOSTNAME="ssh.example.com"
   ```

2. Run:

   ```bash
   chmod +x setup_cloudflared_vps.sh
   ./setup_cloudflared_vps.sh
   ```

3. Follow the **"Manual Cloudflare Access Setup"** section below.

---

## ⚙️ Option 2 — Automated Mode (Recommended)

**Script:** `setup_cloudflared_vps_auto.sh`
This mode sets up **everything**, including the Cloudflare Access SSH OTP policy, via the Cloudflare API.

### Before You Begin:

You’ll need:

* **Cloudflare API Token** with:

  * Zone: Read & Edit
  * Access: Applications: Edit
  * Access: Policies: Edit
* **Zone ID** (found in your domain’s Overview page in Cloudflare).
* **Account ID** (also in Overview page).

**Create an API Token:**

1. Go to [Cloudflare API Tokens](https://dash.cloudflare.com/profile/api-tokens).
2. Click **Create Token** → Use the **Edit Cloudflare Access** template.
3. Give it:

   * Zone: Read & Edit
   * Access: Applications: Edit
   * Access: Policies: Edit
4. Save the token securely.

### Run Automated Setup:

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

3. Done — no manual dashboard setup required.

---

## 🛡 Manual Cloudflare Access Setup (Only for Manual Mode)

If you ran **Manual Mode**, set up SSH OTP in Cloudflare:

1. Log in to **Cloudflare Dashboard**.
2. Go to **Access → Applications → Add an Application**.
3. Choose **Self-Hosted**.
4. **Application name:** `SSH Access`.
5. **Application domain:** Your SSH hostname (e.g., `ssh.example.com`).
6. **Session duration:** e.g., `1h` or `24h`.
7. Click **Next → Add a Policy**:

   * **Policy name:** `Allow Approved SSH Users`.
   * **Action:** Allow.
   * **Include → Emails:** Add approved user emails.
8. Save the policy.
9. Go to **Access → Authentication**:

   * Enable **One-Time PIN**.
   * Disable other login methods if you want OTP-only.

---

## 🖥️ Connecting to SSH

### Install `cloudflared` on Your Local Machine

**macOS:**

```bash
brew install cloudflared
```

**Windows (PowerShell):**

```powershell
winget install --id Cloudflare.cloudflared
```

**Debian/Ubuntu:**

```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb
```

---

### Connect:

```bash
cloudflared access ssh --hostname ssh.example.com
```

1. Enter your approved email.
2. Receive a **one-time PIN** in your inbox.
3. Enter it to authenticate.
4. Enjoy secure SSH access.

---

## 📌 Firewall Lockdown

Both scripts automatically:

* Deny all **incoming** connections.
* Allow all **outgoing** connections.
* Close SSH port 22 to the public.

Your VPS is invisible without the Cloudflare Tunnel.

---

## 🛠️ Adding More Services

Edit:

```bash
sudo nano /etc/cloudflared/config.yml
```

Example:

```yaml
ingress:
  - hostname: app.example.com
    service: http://localhost:8080
  - hostname: blog.example.com
    service: http://localhost:2368
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

MIT License — feel free to use, modify, and share.

---

## 💡 Contributing

Pull requests are welcome! If you improve this setup or add features, please contribute so others can benefit.
