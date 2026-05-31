# AKILI Automation Language (AAL) — Formal Specification v1.0

**Document:** AAL-SPEC-001  
**Version:** 1.0.0  
**Status:** Published  
**Author:** Eric Fanane, CrossTech Path  
**Date:** May 2026  
**Copyright:** © 2026 CrossTech Path. All rights reserved.

---

## Table of Contents

1. [Abstract](#1-abstract)
2. [Design Philosophy](#2-design-philosophy)
3. [Language Overview](#3-language-overview)
4. [Rule Syntax](#4-rule-syntax)
5. [Condition Types](#5-condition-types)
6. [Action Types](#6-action-types)
7. [Sequence Specification](#7-sequence-specification)
8. [Complete Examples](#8-complete-examples)
9. [Reserved Keywords](#9-reserved-keywords)
10. [Standard Math Library](#10-standard-math-library)
11. [Runtime Behaviour](#11-runtime-behaviour)
12. [IP Notice](#12-ip-notice)

---

## 1. Abstract

The AKILI Automation Language (AAL) is a domain-specific language (DSL) designed for industrial automation control in resource-constrained environments. AAL enables operators, technicians, and engineers to define automation logic using structured natural language constructs without requiring knowledge of traditional PLC programming languages.

AAL is optimized for deployment on embedded Linux systems (Raspberry Pi class hardware) running the AKILI IoT Platform. It targets industrial and agricultural automation use cases in Africa and developing regions where access to trained PLC engineers is limited.

---

## 2. Design Philosophy

AAL is founded on four core principles:

1. **Human Readability** — Rules must be understandable by a trained technician without a programming background
2. **Determinism** — Given the same inputs, an AAL rule always produces the same output
3. **Safety by Default** — When uncertain, the system defaults to safe state (all outputs OFF)
4. **Minimalism** — The minimum constructs necessary to cover 95% of industrial automation

---

## 3. Language Overview

### Paradigm

AAL is an **event-driven, declarative language**. Programs are expressed as a collection of independent rules and sequences.

### Execution Model

The AAL runtime evaluates all active rules every poll cycle (default: 30 seconds). Evaluation order follows rule priority:

| Priority | Level | Behaviour |
|---|---|---|
| CRITICAL | Highest | Overrides everything including PID |
| HIGH | High | Overrides PID setpoints |
| NORMAL | Standard | Default priority |
| LOW | Background | Logging and monitoring |

> **Safe State Guarantee:** If the runtime terminates unexpectedly, all relay outputs are set to OFF before exit.

---

## 4. Rule Syntax

```
RULE  <name>
  PRIORITY  <CRITICAL | HIGH | NORMAL | LOW>
  ENABLED   <TRUE | FALSE>

  IF    <condition>
  [AND  <condition>]
  [OR   <condition>]
  [AND NOT <condition>]

  FOR       <duration>     -- Debounce: condition must hold this long
  MIN_ON    <duration>     -- Relay stays ON at least this long
  MAX_ON    <duration>     -- Safety: auto-reset after this duration
  COOLDOWN  <duration>     -- Wait after reset before re-triggering

  THEN  <action>
  [AND  <action>]

  RESET WHEN  <condition>
  ON RESET    <action>

  NOTES  "<text>"
END RULE
```

### Duration Format

| Unit | Symbol | Example |
|---|---|---|
| Seconds | s or sec | 30s, 5sec |
| Minutes | m or min | 5m, 10min |
| Hours | h or hr | 2h, 1hr |

---

## 5. Condition Types

### 5.1 Sensor Comparison
```
IF  <sensor_id>  >   <value>    -- sensor_gt
IF  <sensor_id>  <   <value>    -- sensor_lt
IF  <sensor_id>  >=  <value>    -- sensor_gte
IF  <sensor_id>  <=  <value>    -- sensor_lte
IF  <sensor_id>  =   <value>    -- sensor_eq
IF  <sensor_id>  !=  <value>    -- sensor_ne
```

**Examples:**
```
IF  cargo_temp_front  >  8.0
IF  mains_power       =  0
IF  soil_moisture     <  40.0
```

### 5.2 Rate of Change
```
IF  <sensor_id>  RISING  >  <value_per_minute>
IF  <sensor_id>  FALLING >  <value_per_minute>
```

### 5.3 Sensor Loss
```
IF  <sensor_id>  NO_DATA  >  <duration>
```

### 5.4 Relay State
```
IF  RELAY  <channel>  IS  ON
IF  RELAY  <channel>  IS  OFF
```

### 5.5 Time Conditions
```
IF  TIME  BETWEEN  <HH:MM>  AND  <HH:MM>
IF  TIME  AFTER    <HH:MM>
IF  TIME  BEFORE   <HH:MM>
IF  DAY   IN       <Mon | Tue | Wed | Thu | Fri | Sat | Sun>
```

### 5.6 Variable Conditions
```
IF  VARIABLE  <name>  =  <value>
```

### 5.7 Counter Conditions
```
IF  COUNTER  <name>  >=  <count>  IN  <duration>
```

### 5.8 Math Expression
```
IF  EXPR  "<expression>"  <operator>  <value>
```

**Examples:**
```
IF  EXPR  "(temp_zone1 + temp_zone2) / 2"  >  28.0
IF  EXPR  "abs(cold_1 - cold_2)"           >  2.0
```

### 5.9 TON Timer
```
IF  SENSOR  <sensor_id>  <op>  <threshold>  FOR_TIMER  <duration>
```

### 5.10 Unconditional
```
IF  ALWAYS
```

### Logical Operators

| Operator | Behaviour |
|---|---|
| AND | Both conditions must be true |
| OR | Either condition must be true |
| AND NOT | First true AND second false |
| OR NOT | First true OR second false |

---

## 6. Action Types

### 6.1 Relay Actions

| Syntax | Description |
|---|---|
| `RELAY <ch> ON` | Energize relay channel ch (1-8) |
| `RELAY <ch> OFF` | De-energize relay channel ch |
| `RELAY <ch> PULSE <duration>` | Energize for duration then off |
| `RELAY <ch> TOGGLE` | Invert current relay state |

### 6.2 PID Override

| Syntax | Description |
|---|---|
| `PID <sensor_id> SETPOINT <value>` | Override PID setpoint |
| `PID <sensor_id> RELEASE` | Release PID override |

### 6.3 Notifications

| Syntax | Description |
|---|---|
| `SMS "<message>"` | Send SMS to configured phone |
| `EMAIL "<message>"` | Send email to configured address |
| `LOG "<message>"` | Write to audit log |

### 6.4 Variables

| Syntax | Description |
|---|---|
| `SET <name> = <value>` | Set virtual variable |
| `SET <name> = EXPR "<expression>"` | Calculate and store |
| `INCREMENT COUNTER <name>` | Increment event counter |

### 6.5 Control Flow

| Syntax | Description |
|---|---|
| `TRIGGER RULE <rule_id>` | Force evaluation of another rule |
| `START SEQUENCE <sequence_id>` | Start a named sequence |
| `STOP SEQUENCE <sequence_id>` | Stop a running sequence |

---

## 7. Sequence Specification

Sequences implement the SFC (Sequential Function Chart) concept from IEC 61131-3.

```
SEQUENCE  <name>
  MODE  <SINGLE | CYCLIC | HOLD>
  ENABLED  <TRUE | FALSE>

  START WHEN  <condition>

  STEP 1  "<name>"
    TIMEOUT     <duration>
    ON ENTER    <action>
    WHILE ACTIVE <action>
    ON EXIT     <action>
    ADVANCE WHEN  <condition>  GOTO  STEP  <n>
  END STEP

END SEQUENCE
```

### Sequence Modes

| Mode | Behaviour |
|---|---|
| SINGLE | Run once then stop |
| CYCLIC | Restart automatically after last step |
| HOLD | Pause at each step until manually advanced |

---

## 8. Complete Examples

### Generator Auto-Start
```
RULE  "Generator Auto-Start"
  PRIORITY  CRITICAL
  IF    mains_power  =  0
  FOR   5s
  THEN  RELAY 4 ON
  AND   SMS "Mains power failed — generator started"
  RESET WHEN  mains_power  =  1
  ON RESET    RELAY 4 OFF
  MIN_ON    30s
  COOLDOWN  5min
END RULE
```

### Vaccine Cold Chain Alarm
```
RULE  "Vaccine Cold Chain Alarm"
  PRIORITY  CRITICAL
  IF      cold_storage_1  >  8.0
  AND NOT door_sensor     =  1
  FOR     2min
  THEN  RELAY 2 ON
  AND   SMS "CRITICAL: Vaccine storage at risk — temp above 8°C"
  AND   EMAIL "Temperature excursion detected in cold storage"
  RESET WHEN  cold_storage_1  <  6.0
  MAX_ON  2hr
END RULE
```

### Night Greenhouse Heating
```
RULE  "Night Greenhouse Heating"
  PRIORITY  NORMAL
  IF   TIME  BETWEEN  20:00  AND  06:00
  AND  EXPR  "(gh_temp1 + gh_temp2) / 2"  <  18.0
  THEN  RELAY 1 ON
  RESET WHEN  EXPR  "(gh_temp1 + gh_temp2) / 2"  >  22.0
  MIN_ON  10min
END RULE
```

### Morning Irrigation Sequence
```
SEQUENCE  "Morning Irrigation"
  MODE     CYCLIC
  START WHEN  TIME  AFTER  06:00

  STEP 1  "Irrigate Zone A"
    TIMEOUT     20min
    ON ENTER    RELAY 1 ON
    ON EXIT     RELAY 1 OFF
    ADVANCE WHEN  soil_moisture_a  >=  75.0
  END STEP

  STEP 2  "Irrigate Zone B"
    TIMEOUT     20min
    ON ENTER    RELAY 2 ON
    ON EXIT     RELAY 2 OFF
    ADVANCE WHEN  soil_moisture_b  >=  75.0
  END STEP

END SEQUENCE
```

---

## 9. Reserved Keywords

```
RULE      SEQUENCE  STEP      IF        AND
OR        NOT       FOR       THEN      RESET
WHEN      ON        ENTER     EXIT      WHILE
ACTIVE    ADVANCE   GOTO      TIMEOUT   MODE
SINGLE    CYCLIC    HOLD      PRIORITY  ENABLED
CRITICAL  HIGH      NORMAL    LOW       RELAY
PID       SMS       EMAIL     LOG       SET
EXPR      COUNTER   VARIABLE  TRIGGER   START
STOP      ALWAYS    RISING    FALLING   NO_DATA
TIME      BETWEEN   AFTER     BEFORE    DAY
IN        IS        TRUE      FALSE     END
```

---

## 10. Standard Math Library

| Function | Signature | Description |
|---|---|---|
| abs | abs(x) | Absolute value |
| round | round(x, n) | Round to n decimal places |
| min | min(a, b, ...) | Minimum of arguments |
| max | max(a, b, ...) | Maximum of arguments |
| sqrt | sqrt(x) | Square root |
| floor | floor(x) | Round down |
| ceil | ceil(x) | Round up |
| pow | pow(x, y) | x raised to power y |
| log | log(x) | Natural logarithm |
| sin | sin(x) | Sine (radians) |
| cos | cos(x) | Cosine (radians) |
| pi | pi | Constant π |
| e | e | Constant e |

---

## 11. Runtime Behaviour

### Conflict Resolution

When multiple rules target the same relay:
1. CRITICAL priority takes absolute control
2. HIGH priority overrides PID
3. PID controller maintains control when no HIGH/CRITICAL rule active
4. NORMAL and LOW rules control relays not claimed by higher priority

### State Persistence

Survives system restart:
- Sequence current step and run count
- Virtual variable values
- Event counter values
- Rule trigger history (cooldown enforcement)

### Error Handling

If a rule evaluation encounters an error:
1. Error is logged with timestamp and rule name
2. Current evaluation cycle is skipped for that rule
3. No relay state is modified
4. All other rules continue evaluating

---

## 12. IP Notice

**AAL (AKILI Automation Language) is the intellectual property of CrossTech Path.**

© 2026 CrossTech Path — Eric Fanane. All rights reserved.

**Intellectual property claimed:**
- The AKILI Automation Language syntax as defined in this document
- The natural-language-style rule structure combining IF/AND/OR/THEN/RESET WHEN constructs
- The integration of SFC-style sequences with event-driven rules in a single DSL
- The combination of PID control override through a natural language rule system
- The AKILI Rule Engine runtime architecture

**Prior art establishment:**
- Creation date: May 2026
- INPI Enveloppe Soleau filed: May 2026
- SHA256: `930351C2C267E26E396BEAFC28A2AF2DD09CDA09DFEB9B7D59D5BE8604647391`
- LinkedIn publication: May 30, 2026

Third parties wishing to implement an AAL-compatible runtime must contact CrossTech Path for licensing.

---

*CrossTech Path | crosstechpath.com | Registered in France*
