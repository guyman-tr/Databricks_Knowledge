# History.PriceAlgoThresholds

> Temporal history table storing all past versions of Price.PriceAlgoThresholds - the volume threshold and skew amount configuration per instrument for the price algorithm.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - clustered on (SysEndTime, SysStartTime) |
| **Partition** | No (ON [PRIMARY] filegroup) |
| **Indexes** | 1 (1 clustered) |

---

## 1. Business Meaning

`History.PriceAlgoThresholds` is the **temporal history backing table** for `Price.PriceAlgoThresholds`. SQL Server's system-versioned temporal tables automatically move old rows here whenever the live table is updated or deleted, preserving a complete version history. This table is never written to directly.

The live table `Price.PriceAlgoThresholds` configures the price skewing algorithm's per-instrument settings: a `Threshold` (volume trigger expressed as a fraction/ratio, decimal(5,4)) and a `Skew` (price adjustment amount to apply, decimal(16,6)). When eToro's net position in an instrument crosses a threshold, the skew is applied to shift bid/ask prices to incentivize offsetting trades from customers. When these parameters are tuned by the pricing team, the old configuration is automatically versioned here.

A trigger `Price.TRG_T_PriceAlgoThresholds` on the live table captures audit information (`DbLoginName`, `AppLoginName`) before the temporal history is recorded. The combination of DbLoginName/AppLoginName + SysStartTime/SysEndTime provides a complete audit trail of who tuned the algorithm and when.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Table - Automatic Versioning

**What**: Every change to Price.PriceAlgoThresholds automatically writes the previous version here.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- `SysStartTime` = when this row became the active configuration in Price.PriceAlgoThresholds
- `SysEndTime` = when this configuration was superseded by a change
- Rows in this table are past configurations only (expired versions)
- Current configuration remains in Price.PriceAlgoThresholds

**Diagram**:
```
Price.PriceAlgoThresholds (live - current thresholds)
    SYSTEM_VERSIONING = ON
    HISTORY_TABLE = History.PriceAlgoThresholds
    |
    v
History.PriceAlgoThresholds (this table - past threshold configurations)
```

### 2.2 Threshold and Skew Relationship

**What**: The threshold triggers skew activation; the skew amount determines how much to adjust the price.

**Columns/Parameters Involved**: `InstrumentID`, `Threshold`, `Skew`

**Rules**:
- `Threshold` (decimal(5,4) - up to 9.9999): triggers the skew when instrument net position ratio crosses this value
- `Skew` (decimal(16,6)): the price adjustment amount applied once threshold is crossed. NULL means no skew adjustment defined for this threshold level
- Works in conjunction with History.PriceAlgoSkewConditions which defines MinCIDCount/MinVolumeUSD activation conditions

---

## 3. Data Overview

Table is empty (0 rows) in current environment - Price.PriceAlgoThresholds has not been modified since temporal versioning was enabled, or versioning was recently activated. Historical rows would contain past threshold/skew configurations.

| InstrumentID | Threshold | Skew | DbLoginName | AppLoginName | SysStartTime | SysEndTime | Meaning |
|---|---|---|---|---|---|---|---|
| 50 | 0.0500 | 0.000250 | etoro\pricing_ops | PricingAPI | 2024-03-01 00:00:00 | 2024-09-15 10:00:00 | Threshold of 5% with skew of 0.00025 for instrument 50, active for ~6.5 months |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Financial instrument this threshold configuration applies to. Implicit FK to instrument lookup. Inherited from Price.PriceAlgoThresholds. |
| 2 | Threshold | decimal(5,4) | NO | - | CODE-BACKED | The trigger level (as a ratio/fraction, max value 9.9999) that must be crossed before the associated skew is applied. Represents the net position imbalance level at which eToro activates price adjustment for this instrument. |
| 3 | Skew | decimal(16,6) | YES | - | CODE-BACKED | Price adjustment (skew) amount to apply when Threshold is crossed, in price units with 6 decimal precision. NULL means no skew adjustment is configured for this threshold level. The sign/direction depends on application logic in the pricing service. |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL login name captured by trigger Price.TRG_T_PriceAlgoThresholds when this row was last modified in the live table. Identifies the DBA or service account that updated the threshold configuration. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level identity of the system or user that made the change. May be a service name, API endpoint, or user identifier from the pricing management system. |
| 6 | SysStartTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this threshold configuration became active in Price.PriceAlgoThresholds. Set by SQL Server temporal engine. The starting boundary of this configuration's validity period. |
| 7 | SysEndTime | datetime2(7) | NO | - | VERIFIED | UTC timestamp when this configuration was superseded. Set by SQL Server temporal engine. The end boundary of this configuration's validity period (exclusive). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Instrument lookup | Implicit | The instrument these threshold settings apply to |
| (all columns) | Price.PriceAlgoThresholds | Temporal | This is the history backing table for the live Price table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Server temporal engine | (auto) | System | Rows moved here automatically when Price.PriceAlgoThresholds is modified |
| Price.TRG_T_PriceAlgoThresholds | Trigger | Related | Trigger on live table that captures DbLoginName/AppLoginName audit fields |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PriceAlgoThresholds (table)
(temporal history backing table - no code-level dependencies)
```

---

### 6.1 Objects This Depends On

No dependencies. Written entirely by SQL Server temporal table engine.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.PriceAlgoThresholds | Table | Live table - SQL Server moves expired rows here automatically |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_PriceAlgoThresholds | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

*DATA_COMPRESSION=PAGE. Clustered on (SysEndTime, SysStartTime) - standard temporal history pattern optimizing FOR SYSTEM_TIME AS OF queries.*

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Point-in-time threshold configuration (via live table)

```sql
SELECT InstrumentID, Threshold, Skew, DbLoginName, SysStartTime, SysEndTime
FROM Price.PriceAlgoThresholds
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00'
ORDER BY InstrumentID
```

### 8.2 Full change history for a specific instrument

```sql
SELECT InstrumentID, Threshold, Skew, DbLoginName, AppLoginName, SysStartTime, SysEndTime,
    DATEDIFF(DAY, SysStartTime, SysEndTime) AS DaysActive
FROM History.PriceAlgoThresholds WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
ORDER BY SysStartTime ASC
```

### 8.3 Recent threshold changes across all instruments

```sql
SELECT InstrumentID, Threshold, Skew, DbLoginName, AppLoginName, SysStartTime, SysEndTime
FROM History.PriceAlgoThresholds WITH (NOLOCK)
WHERE SysEndTime >= DATEADD(DAY, -30, GETDATE())
ORDER BY SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.8/10 (Elements: 9.3/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PriceAlgoThresholds | Type: Table | Source: etoro/etoro/History/Tables/History.PriceAlgoThresholds.sql*
