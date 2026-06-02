Latest: AAL v2.0 (June 2026)
Full specification now covers 100% of industrial automation use cases including 
State Machines, Calculated Sensors, Recipe Management, Modbus RS485/TCP, 
and Analog Output. See SPECIFICATION_v2.md

# AKILI Automation Language (AAL) v1.0

**A natural language domain-specific language for industrial automation**

[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](LICENSE)
[![Version](https://img.shields.io/badge/Version-1.0.0-blue.svg)](SPECIFICATION.md)
[![Status](https://img.shields.io/badge/Status-Production--Ready-green.svg)]()
[![Author](https://img.shields.io/badge/Author-Eric%20Fanane-orange.svg)](https://linkedin.com/in/ericfanane)

---

## What is AAL?

AAL (AKILI Automation Language) is a domain-specific language (DSL) designed for industrial automation control. It allows operators, technicians, and engineers to write automation rules in **plain English** — no PLC programming background required.

Instead of complex ladder logic or structured text, an AAL rule looks like this:

```
IF  cold_storage_1  >  8.0  FOR  2min
AND door_sensor  =  0
THEN  RELAY 2 ON
AND   SMS "Cold chain excursion detected"
RESET WHEN  cold_storage_1  <  6.0
```

A nurse in Lagos can read that. A farmer in Burkina Faso can write that.

---

## Why AAL?

Traditional PLC programming languages (IEC 61131-3: Ladder Diagram, Structured Text, Function Block Diagram) were designed in the 1960s-1980s for trained engineers. They require expensive hardware, expensive training, and expensive integrators.

**AAL is different:**

| | Traditional PLC | AAL |
|---|---|---|
| Hardware | €5,000–50,000 | €200 (Raspberry Pi) |
| Programming | Engineer required | Technician or operator |
| Language | Ladder Diagram / ST | Natural language |
| AI integration | None | Built-in (Claude) |
| Target market | Europe / North America | Global, including Africa |

---

## Key Features

- **Natural language syntax** — IF/THEN/RESET rules readable by non-programmers
- **Sequential Function Charts (SFC)** — multi-step process sequences
- **Safety interlocks** — FORCE OFF/ON, BLOCK, SAFE STATE, E-STOP
- **Math expressions** — full expression evaluation in conditions and actions
- **PID override** — rules can override PID control loops
- **Timer support** — TON, TOF, TP, retentive timers
- **Counter support** — CTU, CTD, CTUD counters
- **AI-powered** — natural language rule creation, auto-tuning, anomaly explanation
- **9 languages** — English, French, Arabic, Swahili, Portuguese, Hausa, Wolof, Dioula, Swedish

---

## Example Rules

### Generator Auto-Start
```
IF    mains_power  =  0  FOR  5s
THEN  RELAY 4 ON
AND   SMS "Mains power failed — generator started"
RESET WHEN  mains_power  =  1
ON RESET    RELAY 4 OFF
MIN_ON    30s
COOLDOWN  5min
```

### Vaccine Cold Chain Alarm
```
IF      cold_storage_1  >  8.0
AND NOT door_sensor     =  1
FOR     2min
THEN  RELAY 2 ON
AND   SMS "CRITICAL: Vaccine storage at risk"
AND   EMAIL "Temperature excursion detected"
RESET WHEN  cold_storage_1  <  6.0
PRIORITY  CRITICAL
```

### Night Greenhouse Heating
```
IF   TIME  BETWEEN  20:00  AND  06:00
AND  EXPR  "(gh_temp1 + gh_temp2) / 2"  <  18.0
THEN  RELAY 1 ON
RESET WHEN  EXPR  "(gh_temp1 + gh_temp2) / 2"  >  22.0
MIN_ON  10min
```

### Irrigation Sequence
```
SEQUENCE  "Morning Irrigation"
  MODE  CYCLIC
  START WHEN  TIME  AFTER  06:00

  STEP 1  "Irrigate Zone A"
    TIMEOUT     20min
    ON ENTER    RELAY 1 ON
    ON EXIT     RELAY 1 OFF
    ADVANCE WHEN  soil_moisture_a  >=  75.0

  STEP 2  "Irrigate Zone B"
    TIMEOUT     20min
    ON ENTER    RELAY 2 ON
    ON EXIT     RELAY 2 OFF
```

---

## Target Industries

AAL is designed for:

- 🏥 **Healthcare** — vaccine cold chain, pharmaceutical storage (WHO GDP)
- 🌱 **Agriculture** — greenhouse, irrigation, soil quality, livestock
- ❄️ **Cold chain** — refrigerated transport, cold storage
- 💊 **Pharmacy** — drug storage, compliance reporting
- 🐟 **Aquaculture** — water quality, feeding, temperature
- ⚡ **Energy** — solar/battery management, generator control
- 🏭 **Industry** — process control, building automation

---

## Platform: AKILI IoT

AAL is the automation language of the **AKILI IoT Platform** — an open industrial IoT platform running on Raspberry Pi that replaces €10,000 PLCs with a €200 device.

**AKILI features:**
- 16 industry modules
- AI Advisor (Claude) — hourly PID analysis and recommendations
- AI Rule Creator — describe a rule in plain language, AI builds it
- AI Auto-Tuner — autonomous PID parameter adjustment
- Anomaly Explainability — root cause analysis when alerts fire
- Predictive Failure Detection — 7-day trend analysis
- WHO/HACCP compliance reports
- 9 languages
- Runs on Raspberry Pi 4 (1GB RAM)

---

## Specification

The complete formal specification of AAL v1.0 is available in [SPECIFICATION.md](SPECIFICATION.md).

It covers:
- Complete syntax definition
- All condition types (20+)
- All action types (13+)
- Sequence specification (SFC)
- Reserved keywords
- Standard math library
- Runtime behaviour
- Execution model

---

## IP Notice

**AAL (AKILI Automation Language) is the intellectual property of CrossTech Path.**

© 2026 CrossTech Path — Eric Fanane. All rights reserved.

- Creation date established: May 30, 2026
- INPI Enveloppe Soleau filed: May 2026
- SHA256 fingerprint published: `930351C2C267E26E396BEAFC28A2AF2DD09CDA09DFEB9B7D59D5BE8604647391`

The AAL specification is published here for public review and reference. Third parties wishing to implement an AAL-compatible runtime must contact CrossTech Path for licensing.

---

## Author

**Eric Fanane**
Founder, CrossTech Path
Sundsvall, Sweden 🇸🇪 | Registered in France 🇫🇷

- LinkedIn: [linkedin.com/in/ericfanane](https://linkedin.com/in/ericfanane)
- Website: [crosstechpath.com](https://crosstechpath.com)
- Email: eric.fanane@hotmail.com

---

## Contact

Interested in deploying AKILI at your farm, clinic, or cold chain facility?

📧 eric.fanane@hotmail.com
🌐 crosstechpath.com

---

*"Automation for everyone — not just engineers."*
