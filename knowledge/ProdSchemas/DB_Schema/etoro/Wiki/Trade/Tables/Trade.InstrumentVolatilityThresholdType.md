# Trade.InstrumentVolatilityThresholdType

> Per-instrument configuration for volatility measurement mode (Pips vs Percentage). Each instrument specifies whether its volatility threshold is evaluated in absolute pips or as a percentage change. System-versioned temporal table.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (INT, PK CLUSTERED) |
| **Row Count** | One per instrument (MCP verified) |
| **Indexes** | 1 (PK clustered) |
| **Temporal** | SYSTEM_VERSIONING ON → History.InstrumentVolatilityThresholdType |

---

## 1. Business Meaning

Trade.InstrumentVolatilityThresholdType configures how each traded instrument's volatility threshold is measured: in **pips** (absolute price movement) or **percentage** (relative change). The platform uses this to determine when an instrument is "too volatile" for normal trading—triggering spread widening, order rejection, or monitoring alerts.

VolatilityThresholdTypeID 1 (Pips) suits forex pairs where pip values are standardized. VolatilityThresholdTypeID 2 (Percentage) suits equities and crypto where the same absolute move has different implications at different price levels. Trade.InsertInstrumentRealTable populates a row when a new instrument is added; Trade.CheckValidInstruments verifies the instrument exists here as part of validation.

---

## 2. Business Logic

### 2.1 Per-Instrument Volatility Mode

**What**: Each instrument gets exactly one row specifying its volatility measurement mode.

**Columns/Parameters Involved**: `InstrumentID`, `VolatilityThresholdTypeID`

**Rules**:
- VolatilityThresholdTypeID 1 = Pips (absolute ticks)
- VolatilityThresholdTypeID 2 = Percentage (relative change)
- One row per InstrumentID; INSERT in Trade.InsertInstrumentRealTable uses ISNULL(@VolatilityThresholdTypeID, 0)—0 may map to a default or require validation
- System-versioned; history stored in History.InstrumentVolatilityThresholdType

**Diagram**:
```
Dictionary.VolatilityThresholdType ──► Trade.InstrumentVolatilityThresholdType
(1=Pips, 2=Percentage)                        (one row per instrument)
```

---

## 3. Data Overview

| InstrumentID | VolatilityThresholdTypeID | Meaning |
|--------------|---------------------------|---------|
| 0 | 1 | Pips (absolute) |
| 1 | 1 | Pips |
| 2 | 1 | Pips |
| 3 | 2 | Percentage (relative) |
| 4–9 | 1 | Pips |

Sample (MCP): Most instruments use type 1 (Pips); some (e.g., InstrumentID 3) use type 2 (Percentage).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | VERIFIED | Instrument. FK to Trade.Instrument |
| 2 | VolatilityThresholdTypeID | int | NO | - | VERIFIED | 1=Pips, 2=Percentage. FK to Dictionary.VolatilityThresholdType |
| 3 | SysStartTime | datetime2(7) | NO | getutcdate() | DDL | System period start (generated) |
| 4 | SysEndTime | datetime2(7) | NO | 9999-12-31… | DDL | System period end (generated) |
| 5 | UserName | nvarchar(128) | YES | suser_name() | DDL | Audit (computed) |

---

## 5. Relationships

### 5.1 References To

| Referenced Table | Column | Relationship |
|------------------|--------|--------------|
| Trade.Instrument | InstrumentID | FK (explicit) |
| Dictionary.VolatilityThresholdType | VolatilityThresholdTypeID | FK (explicit) |

### 5.2 Referenced By

| Referencing Object | Column | Type |
|--------------------|--------|------|
| Trade.InsertInstrumentRealTable | InstrumentVolatilityThresholdType | INSERT—adds row for new instrument |
| Trade.CheckValidInstruments | InstrumentVolatilityThresholdType | SELECT—validates instrument exists |

---

## 6. Dependencies

### 6.0 Chain

```
Trade.Instrument ──► Trade.InstrumentVolatilityThresholdType
Dictionary.VolatilityThresholdType ──► Trade.InstrumentVolatilityThresholdType
Trade.InstrumentVolatilityThresholdType ──► History.InstrumentVolatilityThresholdType
```

### 6.1 Depends On

| Object | Purpose |
|--------|---------|
| Trade.Instrument | InstrumentID domain |
| Dictionary.VolatilityThresholdType | VolatilityThresholdTypeID lookup |

### 6.2 Depended On By

| Object | Purpose |
|--------|---------|
| Trade.InsertInstrumentRealTable | Creates row on instrument setup |
| Trade.CheckValidInstruments | Validates instrument configuration |
| History.InstrumentVolatilityThresholdType | Temporal history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included | Fill Factor | Status |
|------------|------|-------------|----------|-------------|--------|
| PK_TradeInstrumentVolatilityThresholdType | CLUSTERED | InstrumentID ASC | - | default | Active |

### 7.2 Constraints

| Constraint | Type | Definition |
|------------|------|------------|
| PK_TradeInstrumentVolatilityThresholdType | PRIMARY KEY | InstrumentID |
| FK_InstrumentVolatilityThresholdTypeID_DictionaryVolatilityThresholdTypeID | FOREIGN KEY | VolatilityThresholdTypeID → Dictionary.VolatilityThresholdType |
| FK_InstrumentVolatilityThresholdType_TradeInstrumentID | FOREIGN KEY | InstrumentID → Trade.Instrument |

### 7.3 Temporal

| Property | Value |
|----------|-------|
| Period | SysStartTime, SysEndTime |
| History Table | History.InstrumentVolatilityThresholdType |

---

## 8. Sample Queries

```sql
SELECT InstrumentID, VolatilityThresholdTypeID
FROM Trade.InstrumentVolatilityThresholdType WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID;

SELECT ivt.InstrumentID, ivt.VolatilityThresholdTypeID, vtt.Name
FROM Trade.InstrumentVolatilityThresholdType ivt WITH (NOLOCK)
JOIN Dictionary.VolatilityThresholdType vtt WITH (NOLOCK) ON vtt.VolatilityThresholdTypeID = ivt.VolatilityThresholdTypeID
ORDER BY ivt.InstrumentID;

SELECT COUNT(*) AS InstrumentCount
FROM Trade.InstrumentVolatilityThresholdType WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

- No Jira/Confluence references found in this documentation pass.

---

*Generated: 2026-03-14 | Quality: 7.5/10*
