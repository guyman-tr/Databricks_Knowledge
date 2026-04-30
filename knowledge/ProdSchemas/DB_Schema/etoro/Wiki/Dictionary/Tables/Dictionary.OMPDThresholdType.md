# Dictionary.OMPDThresholdType

> Defines the measurement units (pips or percentage) for OMPD (Open Market Price Deviation) thresholds that control price tolerance during trade execution.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ThresholdTypeID (int, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.OMPDThresholdType defines how OMPD (Open Market Price Deviation) thresholds are measured. OMPD controls how far the execution price can deviate from the quoted market price before a trade is rejected or re-quoted. This table specifies whether that tolerance is expressed in pips (absolute price units) or as a percentage of the market price.

Without this table, the trading system could not support both measurement modes for price deviation tolerance. Some instruments (forex) naturally use pips while others (stocks, indices) benefit from percentage-based thresholds.

---

## 2. Business Logic

### 2.1 Threshold Measurement Modes

**What**: Two ways to measure acceptable price deviation during execution.

**Columns/Parameters Involved**: `ThresholdTypeID`, `Name`, `Description`

**Rules**:
- Pips (1): Absolute price deviation measured in pips (minimum price increment for the instrument)
- Percentage (2): Relative price deviation measured as a percentage of the current market price
- Pips are more common for forex pairs; percentages for equities and crypto
- The threshold type is configured per instrument or instrument group

---

## 3. Data Overview

| ThresholdTypeID | Name | Description | Meaning |
|---|---|---|---|
| 1 | Pips | OMPD threshold in pips | Price deviation tolerance in absolute pip units — if execution price deviates by more than N pips from quoted price, the trade may be rejected |
| 2 | Percentage | OMPD threshold in Percentage | Price deviation tolerance as percentage of market price — better for instruments with wide price ranges where fixed pip thresholds would be too tight or too loose |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ThresholdTypeID | int | NO | - | CODE-BACKED | Unique identifier for the threshold measurement type: 1=Pips (absolute), 2=Percentage (relative). Used in instrument OMPD configuration. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Short label: "Pips" or "Percentage". Displayed in Configuration Manager instrument settings. |
| 3 | Description | varchar(300) | YES | - | VERIFIED | Explanatory text: "OMPD threshold in pips" or "OMPD threshold in Percentage". Provides context for configuration UI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Instrument OMPD configuration | ThresholdTypeID | Implicit | Instruments reference threshold type for execution deviation control |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT codebase beyond the DDL itself.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryOMPDThresholdTypeID | CLUSTERED PK | ThresholdTypeID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all OMPD threshold types
```sql
SELECT  ThresholdTypeID,
        Name,
        Description
FROM    [Dictionary].[OMPDThresholdType] WITH (NOLOCK)
ORDER BY ThresholdTypeID;
```

### 8.2 Find percentage-based threshold
```sql
SELECT  *
FROM    [Dictionary].[OMPDThresholdType] WITH (NOLOCK)
WHERE   Name = 'Percentage';
```

### 8.3 Both types with usage context
```sql
SELECT  ThresholdTypeID,
        Name,
        Description,
        CASE ThresholdTypeID
            WHEN 1 THEN 'Common for Forex pairs'
            WHEN 2 THEN 'Common for Stocks and Crypto'
        END AS TypicalUsage
FROM    [Dictionary].[OMPDThresholdType] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.OMPDThresholdType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.OMPDThresholdType.sql*
