# Trade.RolloverFeeAlertThreshold

> Configures the maximum acceptable rollover (overnight) fee percentage per instrument type. When a rollover fee exceeds the threshold, an alert is triggered for the trading operations team.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentTypeID (INT, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Trade.RolloverFeeAlertThreshold is a configuration table that defines the maximum acceptable rollover (overnight holding) fee percentage for each instrument type (Stocks, Currencies, Commodities, Indices, ETFs, Crypto). Rollover fees are charged when positions are held overnight; excessive fees indicate misconfiguration, data issues, or abnormal market conditions. When the calculated rollover fee for a position exceeds the threshold for its instrument type, an alert is raised so the trading operations team can investigate.

This table exists to prevent excessive overnight fees from being silently charged to customers. Without it, the system would have no baseline to detect anomalous rollover fee calculations. It supports compliance and customer protection by ensuring fee outliers are flagged for human review.

Data flows: Trade.UpdateRolloverFeeThreshold and related procedures UPDATE rows when operations adjusts thresholds. Trade.RolloverFeesAlertIfNeeded compares calculated fees against these thresholds and triggers alerts. Trade.GetRolloverFeeAlertThresholds reads the current thresholds for display and configuration. The table is system-versioned (temporal); History.RolloverFeeAlertThreshold stores all historical values.

---

## 2. Business Logic

### 2.1 Per-Instrument-Type Thresholds

**What**: Each instrument type has its own rollover fee alert threshold. Different asset classes have different typical fee ranges.

**Columns/Parameters Involved**: `InstrumentTypeID`, `RolloverFeeThreshold`, `UpdatedByUser`, `BeginTime`, `EndTime`

**Rules**:
- InstrumentTypeID maps to Dictionary.InstrumentType (1=Stocks, 2=Currencies, 4=Commodities, 5=Indices, 6=ETFs, 10=Crypto).
- RolloverFeeThreshold is a decimal percentage. E.g., 6.09 means alert if fee exceeds 6.09%.
- UpdatedByUser tracks who last changed the threshold (email or username).
- BeginTime/EndTime are system-versioned columns; history is in History.RolloverFeeAlertThreshold.

**Diagram**:
```
InstrumentTypeID=1 (Stocks)    -> Threshold 6.09%
InstrumentTypeID=2 (Currencies)-> Threshold 3%
InstrumentTypeID=4 (Commodities)-> Threshold 0.5%
InstrumentTypeID=5 (Indices)   -> Threshold 10%
InstrumentTypeID=6 (ETFs)     -> Threshold 11%
InstrumentTypeID=10 (Crypto)  -> Threshold 20%
        |
        v
[Rollover fee calculated] -> Compare to threshold -> Exceeded? -> Alert Ops
```

### 2.2 Temporal History

**What**: All threshold changes are retained in the history table for audit.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`, `History.RolloverFeeAlertThreshold`

**Rules**:
- BeginTime: When this version of the row became active (GENERATED ALWAYS AS ROW START).
- EndTime: When this version was superseded (GENERATED ALWAYS AS ROW END). '9999-12-31' for current row.
- Query FOR SYSTEM_TIME AS OF to retrieve historical thresholds.

---

## 3. Data Overview

| InstrumentTypeID | RolloverFeeThreshold | UpdatedByUser | Meaning |
|-----------------|----------------------|---------------|---------|
| 1 | 6.09 | opstest01@etoro.com | Stocks: Alert if overnight fee exceeds 6.09%. |
| 2 | 3.00 | rachelsa@etoro.com | Currencies: Lower threshold (3%) - forex typically has tighter fee bands. |
| 4 | 0.50 | rachelsa@etoro.com | Commodities: Very low (0.5%) - commodity overnight fees are usually small. |
| 5 | 10.00 | initial script | Indices: Higher tolerance (10%) - index products may have wider ranges. |
| 6 | 11.00 | igorve@etoro.com | ETFs: Slightly higher than indices (11%). |
| 10 | 20.00 | yevgenymi@etoro.com | Crypto: Highest (20%) - crypto volatility and funding rates vary widely. |

**Selection criteria**: All 6 rows shown. Covers every configured instrument type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentTypeID | int | NO | - | CODE-BACKED | PK. References Dictionary.InstrumentType. 1=Stocks, 2=Currencies, 4=Commodities, 5=Indices, 6=ETFs, 10=Crypto. |
| 2 | RolloverFeeThreshold | decimal(16,8) | NO | - | CODE-BACKED | Maximum acceptable rollover fee percentage. Alert when calculated fee exceeds this value. |
| 3 | UpdatedByUser | varchar(50) | NO | - | CODE-BACKED | User who last updated the threshold. Email or Windows username. |
| 4 | BeginTime | datetime2(7) | NO | GENERATED | CODE-BACKED | System-versioned row start. When this version became active. |
| 5 | EndTime | datetime2(7) | NO | GENERATED | CODE-BACKED | System-versioned row end. When superseded. '9999-12-31' for current. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentTypeID | Dictionary.InstrumentType | Implicit FK | Instrument type (Stocks, Forex, Crypto, etc.). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.RolloverFeesAlertIfNeeded | SELECT/Compare | Reader | Compares calculated fees to thresholds, triggers alerts. |
| Trade.GetRolloverFeeAlertThresholds | SELECT | Reader | Returns current thresholds for display/config. |
| Trade.UpdateRolloverFeeThreshold | UPDATE | Modifier | Updates threshold values. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.RolloverFeeAlertThreshold (table)
(no code-level dependencies - table is leaf)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.InstrumentType | Table | Implicit FK target for InstrumentTypeID. |
| History.RolloverFeeAlertThreshold | Table | System-versioning history table. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.RolloverFeesAlertIfNeeded | Stored Procedure | Reads thresholds, triggers alerts. |
| Trade.GetRolloverFeeAlertThresholds | Stored Procedure | Reads thresholds. |
| Trade.UpdateRolloverFeeThreshold | Stored Procedure | Updates thresholds. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_RolloverFeeAlertThreshold | CLUSTERED | InstrumentTypeID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_RolloverFeeAlertThreshold | PRIMARY KEY | Unique InstrumentTypeID. |
| PERIOD FOR SYSTEM_TIME | System Versioning | BeginTime, EndTime for temporal history. |

---

## 8. Sample Queries

### 8.1 Current rollover fee thresholds

```sql
SELECT
    InstrumentTypeID,
    RolloverFeeThreshold,
    UpdatedByUser,
    BeginTime,
    EndTime
FROM Trade.RolloverFeeAlertThreshold WITH (NOLOCK)
ORDER BY InstrumentTypeID;
```

### 8.2 Thresholds with instrument type names

```sql
SELECT
    r.InstrumentTypeID,
    it.InstrumentTypeName,
    r.RolloverFeeThreshold,
    r.UpdatedByUser
FROM Trade.RolloverFeeAlertThreshold r WITH (NOLOCK)
LEFT JOIN Dictionary.InstrumentType it WITH (NOLOCK) ON it.InstrumentTypeID = r.InstrumentTypeID
ORDER BY r.InstrumentTypeID;
```

### 8.3 Historical threshold changes (temporal)

```sql
SELECT
    InstrumentTypeID,
    RolloverFeeThreshold,
    UpdatedByUser,
    BeginTime,
    EndTime
FROM Trade.RolloverFeeAlertThreshold
FOR SYSTEM_TIME ALL
ORDER BY InstrumentTypeID, BeginTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.4/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RolloverFeeAlertThreshold | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.RolloverFeeAlertThreshold.sql*
