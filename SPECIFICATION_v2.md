# AKILI Automation Language (AAL) — Formal Specification v2.0

**Document:** AAL-SPEC-002  
**Version:** 2.0.0  
**Status:** Published  
**Author:** Eric Fanane, CrossTech Path  
**Date:** June 2026  
**Supersedes:** AAL-SPEC-001 v1.0  
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
8. [State Machine Specification](#8-state-machine-specification)
9. [Interlock Specification](#9-interlock-specification)
10. [PID Control Specification](#10-pid-control-specification)
11. [Calculated Sensors](#11-calculated-sensors)
12. [Recipe Management](#12-recipe-management)
13. [Analog Output](#13-analog-output)
14. [Modbus Communication](#14-modbus-communication)
15. [Event and Alarm Management](#15-event-and-alarm-management)
16. [Program Structure and Modules](#16-program-structure-and-modules)
17. [Complete Examples](#17-complete-examples)
18. [Reserved Keywords](#18-reserved-keywords)
19. [Standard Math Library](#19-standard-math-library)
20. [Runtime Behaviour](#20-runtime-behaviour)
21. [IEC 61131-3 Compatibility](#21-iec-61131-3-compatibility)
22. [Change Log](#22-change-log)
23. [IP Notice](#23-ip-notice)

---

## 1. Abstract

The AKILI Automation Language (AAL) v2.0 is a formally specified domain-specific language (DSL) for industrial automation control. AAL enables operators, technicians, and engineers to define complete automation logic using structured natural language constructs, without requiring knowledge of traditional PLC programming languages.

AAL v2.0 achieves 100% coverage of industrial automation use cases as defined by the IEC 61131-3 standard, while maintaining the natural language readability that distinguishes it from existing PLC languages. It targets deployment on embedded Linux systems (Raspberry Pi class hardware) running the AKILI IoT Platform, with specific optimization for African and developing-region industrial environments.

**v2.0 adds over v1.0:**
- State Machine construct (complete FSM support)
- Calculated Sensors (virtual sensor expressions)
- Recipe Management (parameter set switching)
- Analog Output (0-10V, 4-20mA, PWM)
- Modbus RS485/TCP communication
- Enhanced Event and Alarm Management
- Program modules and includes
- Ramp and profile functions
- Enhanced condition logic (nested groups)
- IEC 61131-3 compatibility mapping

---

## 2. Design Philosophy

AAL v2.0 is founded on five core principles:

1. **Human Readability** — Any rule must be understandable by a trained technician without a programming background, when read aloud
2. **Determinism** — Given the same inputs and state, an AAL program always produces the same output
3. **Safety by Default** — When uncertain or on failure, the system defaults to safe state (all outputs OFF)
4. **Completeness** — AAL v2.0 covers 100% of industrial automation use cases
5. **Portability** — AAL programs are hardware-independent and can run on any AKILI-compatible runtime

---

## 3. Language Overview

### 3.1 Paradigm

AAL is a **multi-paradigm automation language** combining:
- **Event-driven rules** (reactive: IF condition THEN action)
- **Sequential programs** (procedural: step-by-step processes)
- **State machines** (behavioral: named states with transitions)
- **Continuous control** (PID loops with override capability)
- **Data transformation** (calculated sensors, recipes)

### 3.2 Execution Model

The AAL runtime operates on a **priority-ordered scan cycle**:

```
Every poll cycle (default 30s):
  1. Read all sensor inputs
  2. Update calculated sensors
  3. Evaluate interlocks (CRITICAL safety)
  4. Evaluate CRITICAL rules
  5. Evaluate HIGH rules
  6. Update PID controllers
  7. Evaluate state machines
  8. Evaluate sequences
  9. Evaluate NORMAL rules
  10. Evaluate LOW rules
  11. Apply recipe overrides
  12. Write all relay outputs
  13. Log all state changes
```

### 3.3 Data Types

| Type | Examples | Range |
|---|---|---|
| REAL | 4.0, -20.5, 3.14159 | IEEE 754 double |
| INT | 0, 42, -5 | 64-bit signed |
| BOOL | TRUE, FALSE, 0, 1 | Boolean |
| STRING | "Hello World" | UTF-8, max 512 chars |
| DURATION | 30s, 5min, 2hr | Non-negative |
| TIME | 06:00, 23:59 | HH:MM |
| DATE | 2026-06-01 | ISO 8601 |

### 3.4 Identifiers

Sensor IDs, variable names, and rule names follow these rules:
- Composed of letters, digits, and underscores
- Must start with a letter or underscore
- Maximum 64 characters
- Case-insensitive (converted to lowercase internally)
- Must not match a reserved keyword

### 3.5 Comments

```
-- This is a single-line comment
/* This is a
   multi-line comment */
```

---

## 4. Rule Syntax

### 4.1 Complete Rule Grammar

```
RULE  <name>
  [PRIORITY   <CRITICAL | HIGH | NORMAL | LOW>]
  [ENABLED    <TRUE | FALSE>]
  [RETENTIVE  <TRUE | FALSE>]     -- Survives restart

  IF    <condition_group>
  [FOR  <duration>]               -- Debounce: hold this long before triggering

  THEN  <action>
  [AND  <action>]
  ...

  [RESET WHEN  <condition_group>]
  [ON RESET    <action>]
  [AND         <action>]

  [MIN_ON    <duration>]          -- Output stays ON at least this long
  [MAX_ON    <duration>]          -- Safety: auto-reset after this duration
  [COOLDOWN  <duration>]          -- Wait after reset before re-triggering
  [MAX_DAILY <count>]             -- Maximum triggers per day

  [NOTES  "<text>"]
END RULE
```

### 4.2 Condition Groups

AAL v2.0 supports nested condition groups with parentheses:

```
IF  (<cond_a>  AND  <cond_b>)
OR  (<cond_c>  AND  <cond_d>)
```

```
IF  <cond_a>
AND NOT  (<cond_b>  OR  <cond_c>)
```

### 4.3 Duration Format

| Unit | Symbol | Example |
|---|---|---|
| Seconds | s, sec | 30s, 5sec |
| Minutes | m, min | 5m, 10min |
| Hours | h, hr | 2h, 1hr |
| Days | d, day | 1d, 7day |

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

-- Within range
IF  <sensor_id>  BETWEEN  <min>  AND  <max>

-- Outside range
IF  <sensor_id>  OUTSIDE  <min>  AND  <max>
```

### 5.2 Rate of Change

```
IF  <sensor_id>  RISING   >  <value_per_minute>
IF  <sensor_id>  FALLING  >  <value_per_minute>
IF  <sensor_id>  RISING   >  <value>  OVER  <duration>
IF  <sensor_id>  FALLING  >  <value>  OVER  <duration>
```

### 5.3 Sensor Health

```
IF  <sensor_id>  NO_DATA   >  <duration>     -- Sensor not updating
IF  <sensor_id>  FROZEN    >  <duration>     -- Value not changing
IF  <sensor_id>  SPIKE     >  <percentage>   -- Sudden jump
```

### 5.4 Relay State

```
IF  RELAY  <channel>  IS  ON
IF  RELAY  <channel>  IS  OFF
IF  RELAY  <channel>  ON_FOR   >  <duration>
IF  RELAY  <channel>  OFF_FOR  >  <duration>
```

### 5.5 Time Conditions

```
IF  TIME  BETWEEN  <HH:MM>  AND  <HH:MM>
IF  TIME  AFTER    <HH:MM>
IF  TIME  BEFORE   <HH:MM>
IF  DAY   IN       <Mon | Tue | Wed | Thu | Fri | Sat | Sun>
IF  DAY   NOT IN   <Mon | Tue | Wed | Thu | Fri | Sat | Sun>
IF  DATE  AFTER    <YYYY-MM-DD>
IF  DATE  BEFORE   <YYYY-MM-DD>
IF  WEEKDAY                           -- Monday to Friday
IF  WEEKEND                           -- Saturday or Sunday
```

### 5.6 Variable and Counter Conditions

```
IF  VARIABLE  <name>  =   <value>
IF  VARIABLE  <name>  >   <value>
IF  VARIABLE  <name>  <   <value>
IF  VARIABLE  <name>  !=  <value>

IF  COUNTER  <name>  >=  <count>
IF  COUNTER  <name>  >=  <count>  IN  <duration>   -- N events in window
```

### 5.7 Math Expression

```
IF  EXPR  "<expression>"  <operator>  <value>
```

**Examples:**
```
IF  EXPR  "(temp_zone1 + temp_zone2) / 2"  >  28.0
IF  EXPR  "abs(cold_1 - cold_2)"           >  2.0
IF  EXPR  "solar_v * solar_a"              >  50.0
IF  EXPR  "batt_pct < 20 and mains = 0"   =  1.0
```

### 5.8 State Machine Conditions

```
IF  STATE  <machine_name>  IS  <state_name>
IF  STATE  <machine_name>  IS NOT  <state_name>
IF  STATE  <machine_name>  ENTERED  <state_name>   -- Just transitioned
IF  STATE  <machine_name>  IN_FOR   >  <duration>
```

### 5.9 Sequence Conditions

```
IF  SEQUENCE  <name>  IS  RUNNING
IF  SEQUENCE  <name>  IS  STOPPED
IF  SEQUENCE  <name>  IS  PAUSED
IF  SEQUENCE  <name>  AT  STEP  <n>
IF  SEQUENCE  <name>  COMPLETED
```

### 5.10 Recipe Conditions

```
IF  RECIPE  IS  "<recipe_name>"
IF  RECIPE  IS NOT  "<recipe_name>"
```

### 5.11 Analog Input Conditions

```
IF  ANALOG_IN  <channel>  >  <voltage>     -- Raw voltage comparison
IF  ANALOG_IN  <channel>  IN_RANGE  <min>  <max>
```

### 5.12 Modbus Conditions

```
IF  MODBUS  <device_name>  REGISTER  <address>  >  <value>
IF  MODBUS  <device_name>  COIL      <address>  IS  ON
IF  MODBUS  <device_name>  ONLINE
IF  MODBUS  <device_name>  OFFLINE
```

### 5.13 Timer Conditions

```
IF  TIMER  <name>  EXPIRED
IF  TIMER  <name>  REMAINING  <  <duration>
IF  TIMER  <name>  ELAPSED    >  <duration>
```

### 5.14 Unconditional

```
IF  ALWAYS
```

---

## 6. Action Types

### 6.1 Relay Actions

```
RELAY  <channel>  ON
RELAY  <channel>  OFF
RELAY  <channel>  PULSE  <duration>
RELAY  <channel>  TOGGLE
RELAY  <channel>  ON   FOR  <duration>   -- ON then auto-OFF
RELAY  ALL  OFF                          -- All 8 channels OFF
RELAY  ALL  ON                           -- All 8 channels ON
```

### 6.2 Analog Output Actions

```
ANALOG_OUT  <channel>  =  <value>             -- 0.0 to 100.0 percent
ANALOG_OUT  <channel>  =  EXPR  "<expr>"      -- Calculated value
ANALOG_OUT  <channel>  =  PID  <loop_id>      -- Follow PID output
ANALOG_OUT  <channel>  RAMP  TO  <value>  OVER  <duration>
ANALOG_OUT  <channel>  OFF                    -- Set to 0
```

### 6.3 PID Control Actions

```
PID  <sensor_id>  SETPOINT  <value>           -- Override setpoint
PID  <sensor_id>  SETPOINT  RECIPE.<param>    -- From active recipe
PID  <sensor_id>  RELEASE                     -- Release override
PID  <sensor_id>  ENABLE
PID  <sensor_id>  DISABLE
PID  <sensor_id>  RESET                       -- Reset integral term
PID  <sensor_id>  MODE  AUTO
PID  <sensor_id>  MODE  MANUAL  OUTPUT  <pct>
```

### 6.4 Ramp Actions

```
RAMP  <sensor_id>  FROM  <start>  TO  <target>  OVER  <duration>
RAMP  <sensor_id>  TO  <target>  RATE  <value_per_minute>
RAMP  <sensor_id>  TO  <target>  RATE  <value_per_minute>  LIMIT  <max_change>
RAMP  CANCEL  <sensor_id>
```

### 6.5 Timer Actions

```
TIMER  <name>  START  <duration>
TIMER  <name>  RESET
TIMER  <name>  STOP
TIMER  <name>  PAUSE
TIMER  <name>  RESUME
```

### 6.6 Notification Actions

```
SMS      "<message>"
SMS      "<message>"  TO  "<phone_number>"      -- Override recipient
EMAIL    "<message>"
EMAIL    "<message>"  SUBJECT  "<subject>"
WHATSAPP "<message>"
LOG      "<message>"
LOG      HACCP  "<message>"                     -- HACCP audit trail
LOG      AUDIT  "<message>"                     -- Operator audit trail
LOG      EVENT  "<message>"  LEVEL  <level>
NOTIFY   ALL    "<message>"                     -- All channels
```

Message interpolation with sensor values:
```
SMS  "Cold storage: {cold_1}°C — Setpoint: {sp_cold1}"
SMS  "Alert at {TIMESTAMP}: {sensor_id} = {VALUE}"
```

### 6.7 Variable Actions

```
SET  <name>  =  <value>
SET  <name>  =  EXPR  "<expression>"
SET  <name>  =  <sensor_id>
INCREMENT  COUNTER  <name>
INCREMENT  COUNTER  <name>  BY  <value>
RESET      COUNTER  <name>
SET        RECIPE   "<recipe_name>"
```

### 6.8 Sequence Actions

```
START  SEQUENCE  <name>
STOP   SEQUENCE  <name>
PAUSE  SEQUENCE  <name>
RESUME SEQUENCE  <name>
GOTO   SEQUENCE  <name>  STEP  <n>
```

### 6.9 State Machine Actions

```
GOTO  STATE  <machine_name>  <state_name>
```

### 6.10 Modbus Actions

```
MODBUS  WRITE  <device_name>  REGISTER  <address>  VALUE  <value>
MODBUS  WRITE  <device_name>  REGISTER  <address>  VALUE  EXPR  "<expr>"
MODBUS  WRITE  <device_name>  COIL      <address>  <ON | OFF>
```

### 6.11 Alarm Actions

```
RAISE  ALARM  "<name>"  LEVEL  <CRITICAL | HIGH | MEDIUM | LOW>
CLEAR  ALARM  "<name>"
ACK    ALARM  "<name>"
SILENCE ALARMS  <duration>
```

---

## 7. Sequence Specification

### 7.1 Complete Sequence Grammar

```
SEQUENCE  <name>
  [MODE     <SINGLE | CYCLIC | HOLD | MANUAL>]
  [ENABLED  <TRUE | FALSE>]
  [PRIORITY <CRITICAL | HIGH | NORMAL | LOW>]

  [START WHEN  <condition>]
  [STOP  WHEN  <condition>]
  [PAUSE WHEN  <condition>]

  STEP <n>  "<name>"
    [TIMEOUT     <duration>]
    [ON ENTER    <action>]
    [AND         <action>]
    [WHILE ACTIVE <action>]
    [ON EXIT     <action>]
    [AND         <action>]
    [ON TIMEOUT  <action>]
    ADVANCE WHEN  <condition>  [GOTO STEP <n>]
  END STEP

  [ON COMPLETE  <action>]
  [ON ABORT     <action>]

  [NOTES  "<text>"]
END SEQUENCE
```

### 7.2 Sequence Modes

| Mode | Behaviour |
|---|---|
| SINGLE | Execute once then stop |
| CYCLIC | Restart automatically after last step |
| HOLD | Pause at each step — manual advance required |
| MANUAL | No automatic start — only started by rule or operator |

### 7.3 Step Branching

Steps can branch to any other step:

```
STEP 3  "Check quality"
  ON ENTER  RELAY 3 ON
  ADVANCE WHEN  quality_ok  =  1  GOTO STEP 4
  ADVANCE WHEN  quality_ok  =  0  GOTO STEP 7   -- Rework branch
  TIMEOUT  5min
  ON TIMEOUT  GOTO STEP 8                         -- Fault branch
END STEP
```

---

## 8. State Machine Specification

State machines implement Mealy/Moore finite state machine behavior.

### 8.1 Complete State Machine Grammar

```
STATE MACHINE  <name>
  [ENABLED  <TRUE | FALSE>]
  [INITIAL  STATE  <state_name>]
  [RETENTIVE <TRUE | FALSE>]     -- Remember state across restarts

  STATE  <name>
    [ON ENTER    <action>]
    [AND         <action>]
    [WHILE ACTIVE <action>]      -- Runs every poll cycle in this state
    [ON EXIT     <action>]
    [AND         <action>]

    [TRANSITION TO  <state_name>
      WHEN  <condition>
      [AFTER  <duration>]        -- Must hold for this duration
      [DO     <action>]          -- Action on transition
    ]

    [TIMEOUT  <duration>  GOTO  <state_name>]
    [ON TIMEOUT  <action>]
  END STATE

  [ON ANY TRANSITION  <action>]  -- Called on every state change

  [NOTES  "<text>"]
END STATE MACHINE
```

### 8.2 State Machine Example — Pasteurizer

```
STATE MACHINE  "Pasteurizer"
  ENABLED  TRUE
  INITIAL  STATE  idle
  RETENTIVE  FALSE

  STATE  idle
    ON ENTER  RELAY 1 OFF
    ON ENTER  RELAY 2 OFF
    ON ENTER  LOG "Pasteurizer idle"
    TRANSITION TO  heating
      WHEN  start_button  =  1
      DO    LOG "Pasteurization cycle started"
  END STATE

  STATE  heating
    ON ENTER  PID ph_proc1 SETPOINT 72.0
    ON ENTER  RELAY 1 ON
    WHILE ACTIVE  LOG "Heating: {ph_proc1}°C → 72°C"
    TRANSITION TO  hold
      WHEN  ph_proc1  >=  72.0
      AFTER  10s
      DO    LOG "Target temperature reached"
    TIMEOUT  30min  GOTO  fault
    ON TIMEOUT  SMS "Pasteurizer failed to reach temperature"
  END STATE

  STATE  hold
    ON ENTER  LOG "Holding at 72°C"
    WHILE ACTIVE  PID ph_proc1 SETPOINT 72.0
    TIMEOUT  15min
    TRANSITION TO  cooling  ON TIMEOUT
  END STATE

  STATE  cooling
    ON ENTER  PID ph_proc1 SETPOINT 10.0
    WHILE ACTIVE  LOG "Cooling: {ph_proc1}°C → 10°C"
    TRANSITION TO  idle
      WHEN  ph_proc1  <=  12.0
    TIMEOUT  45min  GOTO  fault
  END STATE

  STATE  fault
    ON ENTER  RELAY ALL OFF
    ON ENTER  RELAY 3 ON           -- Fault indicator light
    ON ENTER  SMS "Pasteurizer FAULT — manual intervention required"
    ON ENTER  LOG AUDIT "Pasteurizer fault — cycle aborted"
    TRANSITION TO  idle
      WHEN  reset_button  =  1
      DO    LOG "Fault cleared by operator"
  END STATE

  ON ANY TRANSITION  LOG AUDIT "Pasteurizer: state change"
END STATE MACHINE
```

---

## 9. Interlock Specification

Interlocks are hardware-level safety overrides that execute before all other logic.

### 9.1 Complete Interlock Grammar

```
INTERLOCK  <name>
  [PRIORITY  <1..99>]            -- Lower number = higher priority
  [ENABLED   <TRUE | FALSE>]

  TYPE  <FORCE_OFF | FORCE_ON | BLOCK | SAFE_STATE | ESTOP>

  CHANNELS  <ch1> [, <ch2> ...]  -- Affected relay channels

  [ACTIVE WHEN  <condition>]     -- Dynamic interlock
  [ALWAYS ACTIVE]                -- Permanent interlock

  [ON ACTIVATE    <action>]
  [ON DEACTIVATE  <action>]

  [LATCH  <TRUE | FALSE>]        -- Requires manual reset
  [RESET BY  OPERATOR]           -- Manual reset required
  [RESET BY  CONDITION  <condition>]

  [NOTES  "<text>"]
END INTERLOCK
```

### 9.2 Interlock Types

| Type | Behaviour |
|---|---|
| FORCE_OFF | Forces specified channels to OFF regardless of any rule |
| FORCE_ON | Forces specified channels to ON |
| BLOCK | Prevents specified channels from being activated |
| SAFE_STATE | Sets a complex combination of channel states |
| ESTOP | Emergency stop — forces ALL channels OFF immediately |

### 9.3 Interlock Examples

```
-- High temperature shutdown
INTERLOCK  "High Temp Shutdown"
  PRIORITY  1
  TYPE  FORCE_OFF
  CHANNELS  1, 2, 3
  ACTIVE WHEN  cabinet_temp  >  85.0
  ON ACTIVATE  SMS "CRITICAL: Cabinet overtemperature — all outputs OFF"
  LATCH  TRUE
  RESET BY  CONDITION  cabinet_temp  <  60.0
END INTERLOCK

-- Door safety
INTERLOCK  "Conveyor Door Safety"
  PRIORITY  2
  TYPE  FORCE_OFF
  CHANNELS  4, 5
  ACTIVE WHEN  safety_door  =  0
  ON ACTIVATE  LOG "Safety door open — conveyor stopped"
  ON DEACTIVATE  LOG "Safety door closed — conveyor released"
END INTERLOCK

-- Emergency stop button
INTERLOCK  "E-STOP"
  PRIORITY  0
  TYPE  ESTOP
  ACTIVE WHEN  estop_button  =  1
  LATCH  TRUE
  RESET BY  OPERATOR
  ON ACTIVATE  SMS "EMERGENCY STOP activated"
  ON ACTIVATE  LOG AUDIT "E-STOP pressed"
END INTERLOCK
```

---

## 10. PID Control Specification

### 10.1 PID Loop Definition

```
PID LOOP  <name>
  SENSOR    <sensor_id>         -- Process variable input
  OUTPUT    <RELAY | ANALOG_OUT>  <channel>
  MODE      <COOLING | HEATING>
  SETPOINT  <value>

  Kp  <value>                   -- Proportional gain
  Ki  <value>                   -- Integral gain
  Kd  <value>                   -- Derivative gain

  [WINDOW    <duration>]        -- PWM window for relay output
  [MIN_OFF   <duration>]        -- Compressor protection
  [OUTPUT_MIN <0..100>]         -- Minimum output %
  [OUTPUT_MAX <0..100>]         -- Maximum output %

  [ANTI_WINDUP  <TRUE | FALSE>] -- Integral anti-windup
  [DERIVATIVE_FILTER  <0..1>]   -- Derivative filter coefficient

  [SETPOINT_RAMP  <value_per_minute>]  -- Setpoint ramping

  [AI_AUTOTUNE
    Kp_MIN  <value>  Kp_MAX  <value>
    Ki_MIN  <value>  Ki_MAX  <value>
    Kd_MIN  <value>  Kd_MAX  <value>
    MAX_CHANGE_PCT  <percentage>
  ]

  [NOTES  "<text>"]
END PID LOOP
```

### 10.2 Cascade PID

```
PID LOOP  "Outer Temperature"
  SENSOR   zone_temp
  OUTPUT   VARIABLE  inner_setpoint
  SETPOINT 72.0
  Kp 1.0  Ki 0.05  Kd 0.1
END PID LOOP

PID LOOP  "Inner Flow"
  SENSOR   flow_rate
  OUTPUT   ANALOG_OUT  1
  SETPOINT VARIABLE  inner_setpoint   -- Follows outer loop
  Kp 2.0  Ki 0.2  Kd 0.0
END PID LOOP
```

---

## 11. Calculated Sensors

Calculated sensors create virtual sensor values derived from physical sensors or expressions.

### 11.1 Calculated Sensor Grammar

```
CALCULATED SENSOR  <name>
  EXPR   "<expression>"
  UNIT   "<unit_string>"
  [UPDATE  EVERY  <duration>]     -- Default: every poll cycle
  [FILTER  <0..1>]                -- Low-pass filter coefficient
  [CLAMP   MIN  <value>  MAX  <value>]
  [NOTES   "<text>"]
END CALCULATED SENSOR
```

### 11.2 Examples

```
-- Average of three zone temperatures
CALCULATED SENSOR  avg_zone_temp
  EXPR  "(zone1_temp + zone2_temp + zone3_temp) / 3"
  UNIT  "°C"
END CALCULATED SENSOR

-- Differential pressure
CALCULATED SENSOR  diff_pressure
  EXPR  "abs(pressure_in - pressure_out)"
  UNIT  "bar"
  CLAMP  MIN  0.0  MAX  10.0
END CALCULATED SENSOR

-- Power consumption
CALCULATED SENSOR  power_kw
  EXPR  "(voltage * current) / 1000"
  UNIT  "kW"
  FILTER  0.1    -- Heavy filtering for noisy signal
END CALCULATED SENSOR

-- Degree-hours cooling load
CALCULATED SENSOR  cooling_load
  EXPR  "max(0, ambient_temp - 18.0)"
  UNIT  "°C-above-18"
END CALCULATED SENSOR

-- 4-20mA to engineering units conversion
CALCULATED SENSOR  tank_level_pct
  EXPR  "(analog_in_1 - 4.0) / 16.0 * 100.0"
  UNIT  "%"
  CLAMP  MIN  0.0  MAX  100.0
END CALCULATED SENSOR
```

---

## 12. Recipe Management

Recipes define named parameter sets that can be switched at runtime.

### 12.1 Recipe Grammar

```
RECIPE  "<name>"
  [DESCRIPTION  "<text>"]

  <parameter_name>  =  <value>
  ...

  [ACTIVE WHEN  <condition>]     -- Auto-activate condition
  [NOTES  "<text>"]
END RECIPE

-- Set active recipe
SET  RECIPE  "<name>"
```

### 12.2 Recipe Parameters

Recipe parameters are referenced in rules and PID loops:

```
PID  <loop_id>  SETPOINT  RECIPE.<parameter>
IF   VARIABLE  RECIPE.mode  =  "summer"
SET  <variable>  =  RECIPE.<parameter>
```

### 12.3 Recipe Example

```
RECIPE  "Summer Cold Chain"
  DESCRIPTION  "Warmer months — reduced cooling setpoints"
  setpoint_cold1   = 4.0
  setpoint_cold2   = 3.5
  alert_high_temp  = 8.0
  alert_low_temp   = 1.0
  poll_interval    = 10
  ACTIVE WHEN  EXPR "avg_zone_temp > 28.0"  =  1
END RECIPE

RECIPE  "Winter Cold Chain"
  DESCRIPTION  "Cooler months — adjusted setpoints"
  setpoint_cold1   = 5.0
  setpoint_cold2   = 4.5
  alert_high_temp  = 9.0
  alert_low_temp   = 0.0
  poll_interval    = 30
END RECIPE

-- Use in PID
PID LOOP  "Cold Storage 1"
  SENSOR    cold_storage_1
  SETPOINT  RECIPE.setpoint_cold1    -- Follows active recipe
  ...
END PID LOOP

-- Use in rule
RULE  "Cold Storage High Alarm"
  IF   cold_storage_1  >  RECIPE.alert_high_temp
  THEN SMS "Cold storage above recipe threshold"
END RULE
```

---

## 13. Analog Output

Analog output provides variable (non-on/off) control signals.

### 13.1 Analog Output Configuration

```
ANALOG OUTPUT  <channel>
  TYPE    <VOLTAGE_0_10V | CURRENT_4_20MA | CURRENT_0_20MA | PWM>
  [MIN_VALUE  <value>]    -- Engineering unit at minimum output
  [MAX_VALUE  <value>]    -- Engineering unit at maximum output
  [UNIT       "<string>"]
  [SAFE_VALUE <value>]    -- Value on fault/safe state
  [NOTES  "<text>"]
END ANALOG OUTPUT
```

### 13.2 Analog Output Actions

```
-- Set by percentage (0-100%)
ANALOG_OUT  <channel>  =  <percentage>

-- Set by engineering value (auto-scaled)
ANALOG_OUT  <channel>  VALUE  <engineering_value>

-- Follow PID output
ANALOG_OUT  <channel>  =  PID  <loop_id>

-- Follow expression
ANALOG_OUT  <channel>  =  EXPR  "<expression>"

-- Ramp to value
ANALOG_OUT  <channel>  RAMP  TO  <value>  OVER  <duration>
ANALOG_OUT  <channel>  RAMP  TO  <value>  RATE  <value_per_minute>

-- Safe off
ANALOG_OUT  <channel>  OFF
```

---

## 14. Modbus Communication

Modbus RS485 and Modbus TCP support for industrial device integration.

### 14.1 Modbus Device Definition

```
MODBUS DEVICE  <name>
  TYPE     <RTU | TCP>

  -- For RTU (RS485):
  PORT     <device_path>         -- e.g. /dev/ttyUSB0
  ADDRESS  <1..247>
  BAUD     <1200|2400|4800|9600|19200|38400|57600|115200>
  [PARITY  <NONE | EVEN | ODD>]
  [STOP    <1 | 2>]

  -- For TCP:
  HOST     <ip_address>
  PORT     <1..65535>

  [TIMEOUT       <duration>]     -- Read timeout
  [RETRY         <count>]        -- Retry on failure
  [POLL_INTERVAL <duration>]     -- How often to poll

  [NOTES  "<text>"]
END MODBUS DEVICE
```

### 14.2 Modbus Register Mapping

```
MODBUS READ  <device_name>  AS  <sensor_id>
  REGISTER   <address>
  TYPE       <HOLDING | INPUT | COIL | DISCRETE>
  [DATATYPE  <INT16 | UINT16 | INT32 | UINT32 | FLOAT32 | BOOL>]
  [SCALE     <multiplier>]
  [OFFSET    <value>]
  [UNIT      "<string>"]
END MODBUS READ
```

### 14.3 Modbus Write Actions

```
MODBUS  WRITE  <device_name>  HOLDING  <address>  VALUE  <value>
MODBUS  WRITE  <device_name>  COIL     <address>  <ON | OFF>
MODBUS  WRITE  <device_name>  REGISTER <address>  VALUE  EXPR  "<expression>"
```

### 14.4 Modbus Example — VFD Speed Control

```
MODBUS DEVICE  "pump_vfd"
  TYPE     RTU
  PORT     /dev/ttyUSB0
  ADDRESS  1
  BAUD     9600
END MODBUS DEVICE

MODBUS READ  pump_vfd  AS  pump_speed_rpm
  REGISTER   2001
  TYPE       HOLDING
  DATATYPE   UINT16
  UNIT       "RPM"
END MODBUS READ

RULE  "VFD Speed Control"
  IF   flow_rate  <  RECIPE.target_flow
  THEN MODBUS WRITE pump_vfd HOLDING 2000 VALUE EXPR "RECIPE.target_flow * 100"
END RULE
```

---

## 15. Event and Alarm Management

### 15.1 Alarm Definition

```
ALARM  <name>
  LEVEL      <CRITICAL | HIGH | MEDIUM | LOW | INFO>
  [SENSOR    <sensor_id>]
  [MESSAGE   "<template>"]
  [NOTIFY    <SMS | EMAIL | WHATSAPP | ALL>]
  [LATCH     <TRUE | FALSE>]
  [DEADBAND  <value>]            -- Hysteresis to prevent chatter
  [DELAY     <duration>]         -- Delay before alarming
  [SUPPRESS  <duration>]         -- Suppress after acknowledgment
  [NOTES     "<text>"]
END ALARM
```

### 15.2 Alarm Actions

```
RAISE  ALARM  "<alarm_name>"
CLEAR  ALARM  "<alarm_name>"
ACK    ALARM  "<alarm_name>"
SILENCE  ALL  ALARMS  <duration>
SUPPRESS  ALARM  "<alarm_name>"  FOR  <duration>
```

### 15.3 Event Logging

```
LOG  EVENT   "<message>"  [LEVEL  <level>]
LOG  HACCP   "<message>"            -- WHO/HACCP audit trail
LOG  AUDIT   "<message>"            -- Operator audit trail
LOG  CHANGE  "<parameter>"  FROM  <old>  TO  <new>
```

### 15.4 On-Acknowledge Action

```
RULE  "Acknowledge Cold Storage Alarm"
  IF   ALARM  "cold_storage_high"  ACKNOWLEDGED
  THEN LOG AUDIT "Cold storage alarm acknowledged by operator"
  AND  START  TIMER  ack_reminder  15min
END RULE
```

---

## 16. Program Structure and Modules

### 16.1 Program Header

```
PROGRAM  "<name>"
  VERSION     "<version>"
  AUTHOR      "<name>"
  DATE        <YYYY-MM-DD>
  DESCRIPTION "<text>"
  MODULES     <module1> [, <module2> ...]
  PLATFORM    AKILI_v2
END PROGRAM
```

### 16.2 Include

```
INCLUDE  "<filename>"
```

### 16.3 Constants

```
CONSTANT  <name>  =  <value>  [UNIT  "<string>"]
```

**Examples:**
```
CONSTANT  VACCINE_MAX_TEMP  =  8.0   UNIT  "°C"
CONSTANT  VACCINE_MIN_TEMP  =  2.0   UNIT  "°C"
CONSTANT  ALERT_PHONE       =  "+46729394171"
```

### 16.4 Variable Declaration

```
VARIABLE  <name>  TYPE  <REAL | INT | BOOL | STRING>
  [INITIAL  <value>]
  [RETENTIVE <TRUE | FALSE>]
  [UNIT  "<string>"]
END VARIABLE
```

---

## 17. Complete Examples

### 17.1 Vaccine Cold Chain — Full Program

```
PROGRAM  "WHO Cold Chain Monitor"
  VERSION  "2.0"
  AUTHOR   "CrossTech Path"
  MODULES  healthcare, pharmacy
END PROGRAM

CONSTANT  VAX_HIGH   =  8.0   UNIT "°C"
CONSTANT  VAX_LOW    =  2.0   UNIT "°C"
CONSTANT  VAX_TARGET =  4.0   UNIT "°C"

CALCULATED SENSOR  avg_vaccine_temp
  EXPR  "(hc_vax1 + hc_vax2) / 2"
  UNIT  "°C"
END CALCULATED SENSOR

PID LOOP  "Vaccine Fridge 1"
  SENSOR    hc_vax1
  OUTPUT    RELAY  1
  MODE      COOLING
  SETPOINT  VAX_TARGET
  Kp 2.5  Ki 0.12  Kd 0.6
  WINDOW    30s
  MIN_OFF   3min
  AI_AUTOTUNE
    Kp_MIN 0.5  Kp_MAX 5.0
    Ki_MIN 0.0  Ki_MAX 1.0
    MAX_CHANGE_PCT 8
  END
END PID LOOP

INTERLOCK  "Vaccine Critical High"
  PRIORITY  1
  TYPE  FORCE_ON
  CHANNELS  1, 2
  ACTIVE WHEN  avg_vaccine_temp  >  10.0
  ON ACTIVATE  SMS "CRITICAL: Vaccine temp above 10°C — compressors forced ON"
  ON ACTIVATE  LOG HACCP "Critical temperature excursion detected"
  LATCH  FALSE
END INTERLOCK

RULE  "Vaccine High Temperature Alarm"
  PRIORITY  CRITICAL
  IF   avg_vaccine_temp  >  VAX_HIGH
  FOR  2min
  THEN SMS "WARNING: Vaccine storage at {avg_vaccine_temp}°C — above {VAX_HIGH}°C"
  AND  EMAIL "Temperature excursion in vaccine storage"
  AND  LOG HACCP "Temperature excursion: {avg_vaccine_temp}°C at {TIMESTAMP}"
  RESET WHEN  avg_vaccine_temp  <  EXPR "VAX_HIGH - 1.0"
  COOLDOWN  30min
END RULE

RULE  "Vaccine Low Temperature Alarm"
  PRIORITY  HIGH
  IF   avg_vaccine_temp  <  VAX_LOW
  FOR  5min
  THEN SMS "WARNING: Vaccine storage too cold: {avg_vaccine_temp}°C"
  AND  LOG HACCP "Low temperature event: {avg_vaccine_temp}°C"
  RESET WHEN  avg_vaccine_temp  >  EXPR "VAX_LOW + 0.5"
END RULE

RULE  "Power Failure Alert"
  PRIORITY  CRITICAL
  IF   hc_power  =  0
  FOR  30s
  THEN SMS "CRITICAL: Power failure at vaccine storage"
  AND  RELAY 3 ON    -- Backup generator
  AND  LOG AUDIT "Power failure — generator started"
  RESET WHEN  hc_power  =  1
  ON RESET  SMS "Power restored"
  ON RESET  RELAY 3 OFF
END RULE
```

### 17.2 Irrigation State Machine

```
STATE MACHINE  "Drip Irrigation"
  ENABLED  TRUE
  INITIAL  STATE  idle

  STATE  idle
    ON ENTER  RELAY ALL OFF
    TRANSITION TO  morning_check
      WHEN  TIME  AFTER  05:50
  END STATE

  STATE  morning_check
    ON ENTER  LOG "Checking soil moisture"
    TRANSITION TO  irrigating
      WHEN  EXPR "(soil_1 + soil_2 + soil_3) / 3"  <  50.0
    TRANSITION TO  idle
      WHEN  EXPR "(soil_1 + soil_2 + soil_3) / 3"  >=  50.0
      DO    LOG "Soil moisture adequate — skipping irrigation"
    TIMEOUT  5min  GOTO  idle
  END STATE

  STATE  irrigating
    ON ENTER  RELAY 1 ON
    ON ENTER  LOG EVENT "Irrigation started"
    WHILE ACTIVE  LOG "Irrigating — soil: {avg_soil}%"
    TRANSITION TO  flushing
      WHEN  EXPR "(soil_1 + soil_2 + soil_3) / 3"  >=  RECIPE.target_moisture
    TIMEOUT  RECIPE.max_irrigation_time  GOTO  flushing
  END STATE

  STATE  flushing
    ON ENTER  RELAY 1 OFF
    ON ENTER  RELAY 2 ON    -- Flush valve
    TIMEOUT  2min
    TRANSITION TO  idle  ON TIMEOUT
    ON EXIT  RELAY 2 OFF
    ON EXIT  LOG EVENT "Irrigation complete"
  END STATE

  ON ANY TRANSITION  LOG AUDIT "Irrigation state: {STATE}"
END STATE MACHINE
```

### 17.3 Modbus VFD with Recipe

```
RECIPE  "High Production"
  target_flow    =  150.0
  max_pump_speed =  1450
  min_pressure   =  3.5
END RECIPE

RECIPE  "Economy Mode"
  target_flow    =  80.0
  max_pump_speed =  900
  min_pressure   =  2.0
END RECIPE

MODBUS DEVICE  "pump_vfd"
  TYPE  RTU
  PORT  /dev/ttyUSB0
  ADDRESS  1
  BAUD  9600
END MODBUS DEVICE

MODBUS READ  pump_vfd  AS  vfd_speed
  REGISTER  2001
  TYPE  HOLDING
  DATATYPE  UINT16
  UNIT  "RPM"
END MODBUS READ

RULE  "Pump Speed Control"
  PRIORITY  NORMAL
  IF   flow_rate  <  RECIPE.target_flow
  AND  vfd_speed  <  RECIPE.max_pump_speed
  THEN MODBUS WRITE pump_vfd HOLDING 2000
       VALUE EXPR "min(RECIPE.max_pump_speed, vfd_speed + 50)"
  COOLDOWN  10s
END RULE

RULE  "Low Pressure Alarm"
  PRIORITY  HIGH
  IF   line_pressure  <  RECIPE.min_pressure
  FOR  30s
  THEN SMS "Low pressure: {line_pressure} bar"
  AND  LOG EVENT "Low pressure alarm"
END RULE
```

---

## 18. Reserved Keywords

```
PROGRAM     VERSION     AUTHOR      DATE        DESCRIPTION
MODULES     INCLUDE     CONSTANT    VARIABLE    INITIAL
RETENTIVE   UNIT        TYPE        REAL        INT
BOOL        STRING      DURATION    PLATFORM

RULE        END         PRIORITY    ENABLED     NOTES
IF          AND         OR          NOT         FOR
THEN        RESET       WHEN        ON          MIN_ON
MAX_ON      COOLDOWN    MAX_DAILY   LATCH

SEQUENCE    STEP        MODE        SINGLE      CYCLIC
HOLD        MANUAL      START       STOP        PAUSE
RESUME      ADVANCE     GOTO        TIMEOUT     COMPLETE
ABORT       RUNNING     STOPPED     PAUSED      AT

STATE       MACHINE     TRANSITION  TO          ENTERED
IN_FOR      INITIAL     ANY

INTERLOCK   FORCE_OFF   FORCE_ON    BLOCK       SAFE_STATE
ESTOP       ALWAYS      ACTIVE      CHANNELS    ACTIVATE
DEACTIVATE  RESET       OPERATOR    CONDITION

PID         LOOP        SENSOR      OUTPUT      SETPOINT
Kp          Ki          Kd          WINDOW      MIN_OFF
OUTPUT_MIN  OUTPUT_MAX  ANTI_WINDUP DERIVATIVE  FILTER
AUTOTUNE    CASCADE     AUTO        RELEASE     ENABLE
DISABLE

CALCULATED  RAMP        FROM        RATE        CLAMP
OFFSET      SCALE       FILTER

RECIPE      SET         PARAMETER

ANALOG_OUT  ANALOG_IN   VOLTAGE     CURRENT     PWM
IN_RANGE    VALUE

MODBUS      DEVICE      RTU         TCP         HOST
PORT        ADDRESS     BAUD        PARITY      RETRY
HOLDING     INPUT       COIL        DISCRETE    DATATYPE
INT16       UINT16      INT32       UINT32      FLOAT32

ALARM       RAISE       CLEAR       ACK         SILENCE
SUPPRESS    DEADBAND    DELAY       NOTIFY      LEVEL
CRITICAL    HIGH        NORMAL      LOW         INFO
MEDIUM

TIMER       EXPIRED     REMAINING   ELAPSED

RELAY       SMS         EMAIL       WHATSAPP    LOG
HACCP       AUDIT       EVENT       CHANGE      NOTIFY
INCREMENT   COUNTER     TRIGGER     BY

TIME        BETWEEN     AFTER       BEFORE      DAY
DATE        IN          IS          TRUE        FALSE
ALWAYS      RISING      FALLING     NO_DATA     FROZEN
SPIKE       WEEKDAY     WEEKEND     ONLINE      OFFLINE

RECIPE      VARIABLE    SEQUENCE    STATE
TIMESTAMP   VALUE       SENSOR_ID
```

---

## 19. Standard Math Library

### 19.1 Basic Functions

| Function | Signature | Description |
|---|---|---|
| abs | abs(x) | Absolute value |
| round | round(x, n) | Round to n decimal places |
| min | min(a, b, ...) | Minimum of arguments |
| max | max(a, b, ...) | Maximum of arguments |
| sqrt | sqrt(x) | Square root |
| floor | floor(x) | Round down to integer |
| ceil | ceil(x) | Round up to integer |
| pow | pow(x, y) | x raised to power y |
| clamp | clamp(x, lo, hi) | Clamp x between lo and hi |
| sign | sign(x) | -1, 0, or 1 |
| lerp | lerp(a, b, t) | Linear interpolation |

### 19.2 Logarithmic and Trigonometric

| Function | Signature | Description |
|---|---|---|
| log | log(x) | Natural logarithm |
| log10 | log10(x) | Base-10 logarithm |
| exp | exp(x) | e^x |
| sin | sin(x) | Sine (radians) |
| cos | cos(x) | Cosine (radians) |
| tan | tan(x) | Tangent (radians) |
| asin | asin(x) | Arc sine |
| acos | acos(x) | Arc cosine |
| atan | atan(x) | Arc tangent |
| atan2 | atan2(y, x) | 2-argument arc tangent |

### 19.3 Statistical Functions

| Function | Signature | Description |
|---|---|---|
| avg | avg(sensor_id, n) | Average of last n readings |
| stddev | stddev(sensor_id, n) | Standard deviation |
| trend | trend(sensor_id, n) | Linear trend slope per minute |
| peak | peak(sensor_id, n) | Maximum in last n readings |
| valley | valley(sensor_id, n) | Minimum in last n readings |
| rate | rate(sensor_id) | Rate of change per minute |

### 19.4 Constants

| Constant | Value |
|---|---|
| pi | 3.14159265358979 |
| e | 2.71828182845905 |
| inf | Positive infinity |
| nan | Not a number |

### 19.5 Unit Conversion Functions

| Function | Description |
|---|---|
| C_to_F(x) | Celsius to Fahrenheit |
| F_to_C(x) | Fahrenheit to Celsius |
| bar_to_psi(x) | Bar to PSI |
| psi_to_bar(x) | PSI to Bar |
| mA_to_pct(mA) | 4-20mA to 0-100% |
| pct_to_mA(pct) | 0-100% to 4-20mA |
| V_to_pct(V) | 0-10V to 0-100% |

---

## 20. Runtime Behaviour

### 20.1 Execution Priority

```
Priority 0:  E-STOP interlocks (immediate hardware override)
Priority 1:  FORCE interlocks (CRITICAL safety)
Priority 2:  CRITICAL rules
Priority 3:  HIGH rules
Priority 4:  PID controllers
Priority 5:  State machines
Priority 6:  Sequences
Priority 7:  NORMAL rules
Priority 8:  LOW rules
Priority 9:  Calculated sensors update
Priority 10: Recipe parameter application
```

### 20.2 Conflict Resolution

When multiple rules target the same output:
1. E-STOP overrides everything — no exceptions
2. FORCE interlocks override all rules and PID
3. CRITICAL rules override HIGH, PID, NORMAL, LOW
4. HIGH rules override PID, NORMAL, LOW
5. PID controllers maintain control when no override active
6. NORMAL and LOW rules apply when no higher priority is active

Last-write wins within the same priority level.

### 20.3 State Persistence

The following state survives restart (RETENTIVE = TRUE):
- Sequence current step and run counts
- State machine current state
- Virtual variable values
- Counter values
- Rule trigger history (cooldown enforcement)
- Active recipe name
- Timer remaining time

### 20.4 Error Handling

| Error Type | Behaviour |
|---|---|
| Sensor unavailable | Rule skips that condition; others continue |
| Expression error | Rule evaluation skipped; error logged |
| Modbus timeout | Device marked OFFLINE; rules using it skip |
| PID sensor fault | PID output set to safe value |
| Interlock error | Safe state applied; error logged |
| Rule syntax error | Rule disabled; error logged at startup |

### 20.5 Safe State Guarantee

On any unexpected termination:
1. All relay outputs set to OFF
2. All analog outputs set to SAFE_VALUE (default 0)
3. All PID loops paused
4. State machine transitions suspended
5. Active sequences halted at current step

---

## 21. IEC 61131-3 Compatibility

AAL v2.0 maps to IEC 61131-3 constructs as follows:

| IEC 61131-3 | AAL v2.0 Equivalent |
|---|---|
| Ladder Diagram (LD) | RULE with IF/THEN/RELAY |
| Function Block Diagram (FBD) | CALCULATED SENSOR + PID LOOP |
| Structured Text (ST) | EXPR expressions |
| Sequential Function Chart (SFC) | SEQUENCE or STATE MACHINE |
| Instruction List (IL) | Not supported (deprecated in IEC) |

### 21.1 Standard Function Blocks

| IEC FB | AAL Equivalent |
|---|---|
| TON (Timer ON Delay) | RULE with FOR clause |
| TOF (Timer OFF Delay) | RULE with MIN_ON clause |
| TP (Timer Pulse) | RELAY PULSE action |
| CTU (Count Up) | INCREMENT COUNTER |
| CTD (Count Down) | Not directly supported |
| CTUD (Count Up/Down) | COUNTER with EXPR |
| SR (Set/Reset) | RULE with RESET WHEN |
| RS (Reset/Set) | RULE with RETENTIVE |
| PID | PID LOOP |

---

## 22. Change Log

### v2.0.0 (June 2026)

**New constructs:**
- STATE MACHINE — complete finite state machine support
- CALCULATED SENSOR — virtual sensor expressions
- RECIPE — parameter set management
- ANALOG OUTPUT — 0-10V, 4-20mA, PWM output
- MODBUS DEVICE / READ / WRITE — industrial protocol support
- ALARM — formal alarm definition and management
- TIMER — dedicated timer construct
- PROGRAM header with metadata
- CONSTANT declarations
- VARIABLE declarations with type system

**Enhanced conditions:**
- Nested condition groups with parentheses
- BETWEEN / OUTSIDE range conditions
- FROZEN, SPIKE sensor health conditions
- RELAY ON_FOR / OFF_FOR duration conditions
- STATE machine conditions
- SEQUENCE state conditions
- MODBUS conditions
- TIMER conditions
- WEEKDAY / WEEKEND shortcuts

**Enhanced actions:**
- ANALOG_OUT with ramp support
- PID ENABLE/DISABLE/RESET/MODE
- RAMP construct for gradual changes
- TIMER start/stop/reset/pause/resume
- Enhanced LOG with HACCP/AUDIT/EVENT/CHANGE
- Message interpolation with {sensor_id} syntax
- ALARM raise/clear/ack/silence/suppress
- Modbus write actions
- STATE MACHINE GOTO action
- RELAY ALL ON/OFF

**Runtime improvements:**
- RETENTIVE attribute for state persistence
- MAX_DAILY trigger limit
- DEADBAND for alarm hysteresis
- Anti-windup for PID
- Derivative filter for PID
- Setpoint ramping for PID
- Cascade PID support

### v1.0.0 (May 2026)

Initial release covering 80% of industrial automation use cases.

---

## 23. IP Notice

**AAL (AKILI Automation Language) is the exclusive intellectual property of CrossTech Path.**

© 2026 CrossTech Path — Eric Fanane. All rights reserved.

**Intellectual property claimed:**
- The AKILI Automation Language v2.0 syntax as defined in this document
- The natural-language-style rule, sequence, and state machine constructs
- The integration of SFC sequences, FSM state machines, and event-driven rules in a single DSL
- The combination of PID control, recipe management, and natural language rule override
- The calculated sensor construct and expression evaluation model
- The AAL runtime execution model and priority system
- The AKILI Rule Engine runtime architecture v2.0

**Prior art establishment — v1.0:**
- INPI Enveloppe Soleau filed: May 31, 2026
- SHA256: `930351C2C267E26E396BEAFC28A2AF2DD09CDA09DFEB9B7D59D5BE8604647391`
- LinkedIn publication: May 30, 2026
- GitHub: github.com/ericfanane/akili-automation-language

**Prior art establishment — v2.0:**
- Publication date: June 2026
- Published in: AKILI — Good Wisdom (book), akilijuma.org, GitHub

Third parties wishing to implement an AAL-compatible runtime must contact CrossTech Path for licensing.

---

*CrossTech Path | akilijuma.org | info@akilijuma.org | Registered in France*  
*AKILI is a trademark of CrossTech Path*
