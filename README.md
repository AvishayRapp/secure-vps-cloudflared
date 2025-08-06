# Secure VPS with Cloudflare Tunnel + OTP SSH

This project sets up a **zero-port VPS** where:
- All inbound ports are **closed** (even SSH).
- Services are **exposed only through Cloudflare Tunnel**.
- SSH access is **restricted to approved users** via **Cloudflare Access One-Time PIN**.
- VPS IP is completely **hidden from the public internet**.

---

## 🔒 Security Benefits
- **Zero Attack Surface** — No exposed IP or open ports.
- **DDoS Protection** — All traffic flows through Cloudflare.
- **Access Control** — Only approved users can connect to SSH.
- **OTP Verification** — Each login requires a one-time code sent via email.
- **App Isolation** — Multiple services can run behind the same secure tunnel.

---

## 📦 Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/AvishayRapp/secure-vps-cloudflared.git
   cd secure-vps-cloudflared
