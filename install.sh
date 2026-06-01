#!/bin/bash
# ============================================================
# AKILI IoT Platform — Complete Installer
# CrossTech Path 2026
# Version: 1.0.0
# Updated: 2026-06-01
#
# Usage:
#   Fresh Pi OS install:
#     curl -sSL https://raw.githubusercontent.com/ericfanane/akili-automation-language/main/install.sh | bash
#
#   Or copy this file to the Pi and run:
#     chmod +x install.sh && ./install.sh
#
#   Restore from backup:
#     ./install.sh --restore /path/to/backup.zip
# ============================================================

set -e
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠  $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; exit 1; }
info() { echo -e "${BLUE}ℹ  $1${NC}"; }

echo ""
echo "============================================================"
echo "  AKILI IoT Platform — Installer v1.0.0"
echo "  CrossTech Path 2026"
echo "============================================================"
echo ""

# ── Check we are on a Raspberry Pi ──────────────────────────
if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
    warn "Not detected as Raspberry Pi — continuing anyway"
fi

# ── Check running as pi user ────────────────────────────────
if [ "$USER" != "pi" ]; then
    warn "Not running as pi user (current: $USER)"
fi

BASE="/home/pi/africabox"
BACKUP_FILE=""

# ── Parse arguments ─────────────────────────────────────────
if [ "$1" = "--restore" ] && [ -n "$2" ]; then
    BACKUP_FILE="$2"
    info "Restore mode: $BACKUP_FILE"
fi

# ============================================================
# STEP 1 — System update
# ============================================================
echo ""
info "Step 1/8 — System update"
sudo apt-get update -q
sudo apt-get upgrade -y -q
ok "System updated"

# ============================================================
# STEP 2 — System packages
# ============================================================
echo ""
info "Step 2/8 — Installing system packages"
sudo apt-get install -y -q \
    python3 python3-pip python3-venv \
    git zip unzip curl wget \
    i2c-tools python3-smbus \
    libatlas-base-dev \
    minicom screen \
    network-manager \
    sqlite3
ok "System packages installed"

# ============================================================
# STEP 3 — Python libraries
# ============================================================
echo ""
info "Step 3/8 — Installing Python libraries"
pip3 install --break-system-packages \
    w1thermsensor \
    adafruit-circuitpython-ads1x15 \
    gpiozero \
    RPi.GPIO \
    requests \
    pyserial \
    flask 2>/dev/null || true

# Verify critical ones
python3 -c "import w1thermsensor" 2>/dev/null && ok "w1thermsensor" || warn "w1thermsensor not installed"
python3 -c "import adafruit_ads1x15" 2>/dev/null && ok "adafruit_ads1x15" || warn "adafruit_ads1x15 not installed"
python3 -c "import gpiozero" 2>/dev/null && ok "gpiozero" || warn "gpiozero not installed"
python3 -c "import serial" 2>/dev/null && ok "pyserial" || warn "pyserial not installed"

# ============================================================
# STEP 4 — Enable hardware interfaces
# ============================================================
echo ""
info "Step 4/8 — Enabling hardware interfaces"

# Enable I2C
sudo raspi-config nonint do_i2c 0 2>/dev/null || warn "Could not enable I2C via raspi-config"

# Enable 1-Wire
sudo raspi-config nonint do_onewire 0 2>/dev/null || warn "Could not enable 1-Wire via raspi-config"

# Add 1-Wire overlay to config if not already there
if ! grep -q "dtoverlay=w1-gpio" /boot/firmware/config.txt 2>/dev/null; then
    echo "dtoverlay=w1-gpio,gpiopin=4" | sudo tee -a /boot/firmware/config.txt
    ok "1-Wire overlay added (GPIO4)"
else
    ok "1-Wire overlay already configured"
fi

# Enable serial for SIM7600E (disable console on serial)
if ! grep -q "enable_uart=1" /boot/firmware/config.txt 2>/dev/null; then
    echo "enable_uart=1" | sudo tee -a /boot/firmware/config.txt
fi
sudo raspi-config nonint do_serial_hw 0 2>/dev/null || true
sudo raspi-config nonint do_serial_cons 1 2>/dev/null || true
ok "Hardware interfaces enabled"

# ============================================================
# STEP 5 — Create directories
# ============================================================
echo ""
info "Step 5/8 — Creating directories"
mkdir -p $BASE
mkdir -p $BASE/ai_proxy
mkdir -p $BASE/static
mkdir -p $BASE/reports
mkdir -p /media/pi/sda
ok "Directories created"

# ============================================================
# STEP 6 — Restore from backup OR create fresh settings
# ============================================================
echo ""
info "Step 6/8 — Installing AKILI files"

if [ -n "$BACKUP_FILE" ] && [ -f "$BACKUP_FILE" ]; then
    info "Restoring from backup: $BACKUP_FILE"
    cd /home/pi
    unzip -o "$BACKUP_FILE" -d /home/pi/
    ok "Backup restored"
else
    warn "No backup file specified"
    info "Please copy your africabox files to $BASE manually"
    info "Or run: ./install.sh --restore /path/to/backup.zip"
fi

# ============================================================
# STEP 7 — Create systemd services
# ============================================================
echo ""
info "Step 7/8 — Creating systemd services"

# Main AKILI service
sudo tee /etc/systemd/system/africabox.service > /dev/null << 'EOF'
[Unit]
Description=AKILI IoT Platform — CrossTech Path
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/africabox
ExecStart=/usr/bin/python3 /home/pi/africabox/africabox.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# AI Proxy service
sudo tee /etc/systemd/system/akili-ai.service > /dev/null << 'EOF'
[Unit]
Description=AKILI AI Proxy — CrossTech Path
After=network.target africabox.service

[Service]
Type=simple
User=pi
WorkingDirectory=/home/pi/africabox/ai_proxy
ExecStart=/usr/bin/python3 /home/pi/africabox/ai_proxy/server.py
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable africabox
sudo systemctl enable akili-ai
ok "Systemd services created and enabled"

# ============================================================
# STEP 8 — Start services
# ============================================================
echo ""
info "Step 8/8 — Starting AKILI"

if [ -f "$BASE/africabox.py" ]; then
    sudo systemctl start africabox
    sleep 3
    if sudo systemctl is-active --quiet africabox; then
        ok "AKILI is running"
    else
        warn "AKILI failed to start — check: sudo journalctl -u africabox -n 20"
    fi

    sudo systemctl start akili-ai
    sleep 2
    if sudo systemctl is-active --quiet akili-ai; then
        ok "AI Proxy is running"
    else
        warn "AI Proxy failed to start"
    fi
else
    warn "africabox.py not found — services not started"
    info "Copy your files to $BASE then run: sudo systemctl start africabox"
fi

# ============================================================
# SUMMARY
# ============================================================
echo ""
echo "============================================================"
echo -e "${GREEN}  AKILI Installation Complete${NC}"
echo "============================================================"
echo ""

# Get Pi IP
IP=$(hostname -I | awk '{print $1}')
echo "  Platform:  http://$IP:8080"
echo "  AI Proxy:  http://$IP:9090/health"
echo ""
echo "  Useful commands:"
echo "  sudo systemctl status africabox"
echo "  sudo systemctl restart africabox"
echo "  sudo journalctl -u africabox -f"
echo ""
echo "  Hardware GPIO map:"
echo "  Relay 1 → GPIO 27    Relay 5 → GPIO 25"
echo "  Relay 2 → GPIO 22    Relay 6 → GPIO 8"
echo "  Relay 3 → GPIO 23    Relay 7 → GPIO 7"
echo "  Relay 4 → GPIO 24    Relay 8 → GPIO 16"
echo "  DS18B20 → GPIO 4 (1-Wire)"
echo "  ADS1115 → I2C (SDA=GPIO2, SCL=GPIO3)"
echo "  SIM7600E → /dev/ttyUSB2"
echo ""
echo "  ⚠  Reboot required for hardware interfaces:"
echo "  sudo reboot"
echo ""
echo "  Backup:"
echo "  sudo python3 /home/pi/africabox/backup_akili.py"
echo "============================================================"
