# AKILI IoT Platform — Installation Guide
**Version:** 1.0.0 | **Updated:** 2026-06-01 | **Author:** CrossTech Path

---

## What You Need

| Item | Spec | Cost |
|---|---|---|
| Raspberry Pi 4 | 2GB RAM minimum | €50 |
| MicroSD card | 32GB Class 10 | €10 |
| Power supply | USB-C 5V 3A | €10 |
| 8-channel relay board | 5V trigger | €15 |
| DS18B20 temperature sensors | Waterproof version | €5 each |
| ADS1115 ADC board | 16-bit I2C | €5 |
| SIM7600E 4G module | With SIM card | €40 |
| 4.7kΩ resistor | For DS18B20 | €0.10 |

---

## Step 1 — Flash Raspberry Pi OS

1. Download **Raspberry Pi Imager** from raspberrypi.com
2. Flash **Raspberry Pi OS Lite 64-bit** (no desktop needed)
3. In Imager settings (gear icon) configure:
   - Hostname: `raspberrypi-plc`
   - Username: `pi`
   - Password: choose a strong password
   - WiFi: your network name and password
   - Enable SSH: Yes
4. Flash the SD card, insert into Pi, power on
5. Wait 2 minutes, then SSH in:
```bash
ssh pi@raspberrypi-plc.local
```

---

## Step 2 — Copy AKILI Files

Copy your latest backup ZIP to the Pi:
```bash
scp akili_vX_YYYYMMDD_BACKUP.zip pi@raspberrypi-plc.local:/home/pi/
```

---

## Step 3 — Run Installer

```bash
ssh pi@raspberrypi-plc.local
chmod +x install.sh
./install.sh --restore /home/pi/akili_vX_YYYYMMDD_BACKUP.zip
```

The installer does everything automatically:
- Updates the system
- Installs all Python libraries
- Enables I2C, 1-Wire, Serial interfaces
- Creates systemd services
- Restores your backup
- Starts AKILI

---

## Step 4 — Reboot

```bash
sudo reboot
```

After reboot AKILI starts automatically. Access at:
```
http://raspberrypi-plc.local:8080
```

---

## Step 5 — Wire the Hardware

### Relay Board (8 channels)
```
Relay board VCC  → Pi 5V  (Pin 2)
Relay board GND  → Pi GND (Pin 6)
Relay board IN1  → Pi GPIO 27 (Pin 13)
Relay board IN2  → Pi GPIO 22 (Pin 15)
Relay board IN3  → Pi GPIO 23 (Pin 16)
Relay board IN4  → Pi GPIO 24 (Pin 18)
Relay board IN5  → Pi GPIO 25 (Pin 22)
Relay board IN6  → Pi GPIO 8  (Pin 24)
Relay board IN7  → Pi GPIO 7  (Pin 26)
Relay board IN8  → Pi GPIO 16 (Pin 36)
```

### DS18B20 Temperature Sensor (1-Wire)
```
DS18B20 RED    → Pi 3.3V (Pin 1)
DS18B20 BLACK  → Pi GND  (Pin 9)
DS18B20 YELLOW → Pi GPIO 4 (Pin 7)
4.7kΩ resistor between RED and YELLOW
```
Multiple DS18B20 sensors can share the same 3 wires (bus).

### ADS1115 Analog ADC (I2C)
```
ADS1115 VDD  → Pi 3.3V (Pin 1)
ADS1115 GND  → Pi GND  (Pin 6)
ADS1115 SDA  → Pi GPIO 2 / SDA (Pin 3)
ADS1115 SCL  → Pi GPIO 3 / SCL (Pin 5)
ADS1115 ADDR → Pi GND  (address 0x48)
```
Analog channels A0-A3 connect to your sensors (pH probe, soil moisture, 4-20mA via 250Ω resistor).

### SIM7600E 4G Module (Serial)
```
SIM7600E TX  → Pi GPIO 15 / RXD (Pin 10)
SIM7600E RX  → Pi GPIO 14 / TXD (Pin 8)
SIM7600E GND → Pi GND (Pin 6)
SIM7600E VCC → External 5V supply (needs 2A)
```
Insert SIM card with SMS capability. Port: `/dev/ttyUSB2`

---

## Step 6 — Configure AKILI

1. Open `http://raspberrypi-plc.local:8080`
2. Run the setup wizard (5 steps)
3. Go to **Settings** and enter:
   - Installation name and location
   - Anthropic API key (from console.anthropic.com)
   - Alert phone number (for SMS)
   - Email settings (for email alerts)
4. Go to **System** page and verify hardware is detected

---

## Step 7 — Test Hardware

Run the hardware test:
```bash
python3 /home/pi/africabox/test_hardware.py
```

This verifies:
- All relay channels switch correctly
- DS18B20 sensors are reading
- ADS1115 channels are responding
- SIM7600E can send a test SMS

---

## Useful Commands

```bash
# Check status
sudo systemctl status africabox
sudo systemctl status akili-ai

# Restart
sudo systemctl restart africabox
sudo systemctl restart akili-ai

# View logs
sudo journalctl -u africabox -f
sudo journalctl -u africabox -n 50

# Backup
sudo mount /dev/sda /media/pi/sda
sudo python3 /home/pi/africabox/backup_akili.py

# Run tests
python3 /home/pi/africabox/test_severe.py

# Check database
sqlite3 /home/pi/africabox/africabox.db ".tables"
```

---

## Troubleshooting

**AKILI not starting:**
```bash
sudo journalctl -u africabox -n 30 --no-pager
```

**No temperature sensors detected:**
```bash
ls /sys/bus/w1/devices/
# Should show 28-xxxxxxxxxxxx entries
# If empty: check wiring and 4.7kΩ resistor
```

**I2C not working:**
```bash
sudo i2cdetect -y 1
# Should show 0x48 for ADS1115
# If empty: check SDA/SCL wiring
```

**SMS not sending:**
```bash
python3 -c "
import serial, time
s = serial.Serial('/dev/ttyUSB2', 115200, timeout=1)
s.write(b'AT\r\n')
time.sleep(0.5)
print(s.read(100))
"
# Should return b'AT\r\n\r\nOK\r\n'
```

**Relay not switching:**
```bash
python3 -c "
from gpiozero import OutputDevice
r = OutputDevice(27, active_high=False)
r.on(); import time; time.sleep(2); r.off()
print('Relay 1 test OK')
"
```

---

## GPIO Pin Reference

```
Pin 1  → 3.3V          Pin 2  → 5V
Pin 3  → SDA (I2C)     Pin 4  → 5V
Pin 5  → SCL (I2C)     Pin 6  → GND
Pin 7  → GPIO 4 (1W)   Pin 8  → TXD
Pin 9  → GND           Pin 10 → RXD
Pin 13 → GPIO 27 R1    Pin 15 → GPIO 22 R2
Pin 16 → GPIO 23 R3    Pin 18 → GPIO 24 R4
Pin 22 → GPIO 25 R5    Pin 24 → GPIO 8  R6
Pin 26 → GPIO 7  R7    Pin 36 → GPIO 16 R8
```

---

## File Structure

```
/home/pi/africabox/
├── africabox.py          Main server (3300+ lines)
├── pid_control.py        PID control engine
├── rule_engine.py        Automation rule engine
├── sequence_engine.py    Sequence (SFC) engine
├── interlock_engine.py   Safety interlock engine
├── hardware.py           Hardware drivers
├── auto_advisor.py       AI Advisor
├── ai_tuner.py           AI Auto-Tuner
├── anomaly_explainer.py  Anomaly explainability
├── predictive_failure.py Predictive failure detection
├── scheduler.py          Background task scheduler
├── email_alerts.py       Email/SMS/WhatsApp alerts
├── report_generator.py   HACCP/WHO report generator
├── modules.py            Industry module definitions
├── auth.py               Authentication
├── settings.json         Configuration file
├── africabox.db          SQLite database
├── backup_akili.py       Backup script
├── test_severe.py        Test suite (87 tests)
├── ai_proxy/
│   └── server.py         Claude AI proxy
├── static/
│   ├── akili_nav.js      Navigation component
│   └── akili_ai.js       AI chat widget
└── *.html                Page templates
```

---

## Version History

| Version | Date | Changes |
|---|---|---|
| 1.0.0 | 2026-06-01 | Initial release — Phase 2 First Light |

---

*CrossTech Path | akilijuma.org | eric.fanane@hotmail.com*
