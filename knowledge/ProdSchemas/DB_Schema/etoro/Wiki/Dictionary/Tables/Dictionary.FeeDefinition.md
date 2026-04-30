# Dictionary.FeeDefinition

> Lookup table defining the fee billing frequency categories — No Fee, Daily Fee, or Weekly Fee — applied to trading positions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | FeeID (TINYINT, PK CLUSTERED) |
| **Partition** | No — on PRIMARY |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.FeeDefinition categorizes the billing frequency for trading fees applied to open positions. Each instrument is assigned a fee definition that determines whether the instrument incurs no fee, a daily fee, or a weekly fee. This controls the scheduling dimension of the fee engine — separate from the calculation formula (FeeCalculationTypes) and the operation phase (FeeOperationTypes).

This table supports the overnight fee (swap/rollover) processing pipeline. The fee process runs on a schedule and uses FeeID to determine which instruments need fee calculation today. "No Fee" instruments are skipped; "Daily Fee" instruments are processed every trading day; "Weekly Fee" instruments are processed once per week (typically on Wednesdays with a 3x multiplier for weekend carry).

The FeeID is stored on `Trade.InstrumentMetaData` and `Trade.ExchangeInstrumentFeeDefinition`, and consumed by `Trade.GetPositionsForFeeProcess`, `Trade.GetPositionsForFeeBulkGeneral`, and `Monitor.CheckIfFeeProcessExecute`.

---

## 2. Business Logic

### 2.1 Fee Billing Frequency

**What**: Determines how often overnight/holding fees are charged on open positions for a given instrument.

**Columns/Parameters Involved**: `FeeID`, `FeeDescription`

**Rules**:
- **No Fee (0)**: Instrument is exempt from overnight fees. Common for certain real stock positions or promotional instruments.
- **Daily Fee (1)**: Overnight fee is calculated and charged every trading day the position is held past market close.
- **Weekly Fee (2)**: Overnight fee is calculated once per week. Historically used for certain instrument categories. The weekly charge typically equals 7× the daily rate.

**Diagram**:
```
Position Held Overnight
        │
        ├── FeeID = 0 → No fee charged (exempt)
        │
        ├── FeeID = 1 → Daily fee process runs
        │   └── Fee calculated & charged each trading day
        │
        └── FeeID = 2 → Weekly fee process runs
            └── Fee calculated & charged once per week
```

---

## 3. Data Overview

| FeeID | FeeDescription | Meaning |
|---|---|---|
| 0 | No Fee | Instrument is exempt from overnight/holding fees. Position can be held indefinitely without incurring rollover charges. Used for promotional offers or certain real stock positions. |
| 1 | Daily Fee | Standard billing frequency — overnight fee calculated and applied every trading day the position remains open past market close. Most common for CFD instruments. |
| 2 | Weekly Fee | Fee charged once per week rather than daily. Used for specific instrument categories where daily charging is not appropriate. Weekly amount typically equals 7× the equivalent daily rate. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FeeID | tinyint | NO | - | VERIFIED | Fee billing frequency: **0**=No Fee (exempt from overnight charges), **1**=Daily Fee (charged each trading day), **2**=Weekly Fee (charged once per week). Referenced by Trade.InstrumentMetaData.FeeID and Trade.ExchangeInstrumentFeeDefinition. |
| 2 | FeeDescription | nvarchar(100) | NO | - | VERIFIED | Human-readable fee frequency label: "No Fee", "Daily Fee", "Weekly Fee". Used in instrument configuration UIs and reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InstrumentMetaData | FeeID | Implicit | Defines the fee frequency for each instrument |
| Trade.ExchangeInstrumentFeeDefinition | FeeID | Implicit | Exchange-specific fee frequency overrides |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.FeeDefinition (table)
```

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | Stores FeeID per instrument |
| Trade.ExchangeInstrumentFeeDefinition | Table | Exchange-level fee frequency overrides |
| Trade.GetPositionsForFeeProcess | Stored Procedure | Filters positions by FeeID to determine which need fee calculation |
| Trade.GetPositionsForFeeBulkGeneral | Stored Procedure | Bulk fee processing — reads FeeID to select eligible positions |
| Trade.GetPositionsForFeeBulkGeneral_Aus | Stored Procedure | Australian regulation variant of bulk fee processing |
| Monitor.CheckIfFeeProcessExecute | Stored Procedure | Monitors whether fee process has run for instruments with non-zero FeeID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | CLUSTERED PK | FeeID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK (unnamed) | PRIMARY KEY | Unique fee definition, FILLFACTOR 95, PRIMARY filegroup |

---

## 8. Sample Queries

### 8.1 List all fee definitions
```sql
SELECT  FeeID,
        FeeDescription
FROM    Dictionary.FeeDefinition WITH (NOLOCK)
ORDER BY FeeID;
```

### 8.2 Count instruments by fee frequency
```sql
SELECT  fd.FeeDescription,
        COUNT(*)            AS InstrumentCount
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
JOIN    Dictionary.FeeDefinition fd WITH (NOLOCK)
        ON imd.FeeID = fd.FeeID
GROUP BY fd.FeeDescription
ORDER BY COUNT(*) DESC;
```

### 8.3 Find instruments exempt from overnight fees
```sql
SELECT  c.SymbolFull,
        c.InstrumentID,
        fd.FeeDescription
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
JOIN    Dictionary.FeeDefinition fd WITH (NOLOCK)
        ON imd.FeeID = fd.FeeID
JOIN    Dictionary.Currency c WITH (NOLOCK)
        ON imd.InstrumentID = c.InstrumentID
WHERE   imd.FeeID = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.FeeDefinition | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.FeeDefinition.sql*
