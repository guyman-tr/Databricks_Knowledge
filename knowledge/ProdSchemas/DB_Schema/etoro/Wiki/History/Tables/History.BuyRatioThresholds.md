# History.BuyRatioThresholds

> Temporal history table automatically maintained by SQL Server for Price.BuyRatioThresholds; each row captures one past version of a per-instrument buy ratio threshold-to-skew mapping with its validity interval.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (SysEndTime, SysStartTime) - clustered index (no PK; temporal managed by SQL Server) |
| **Partition** | No |
| **Indexes** | 1 active (clustered on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.BuyRatioThresholds is the auto-managed temporal history table for Price.BuyRatioThresholds. SQL Server's SYSTEM_VERSIONING feature writes here automatically whenever a threshold-to-skew mapping is updated or deleted in the parent table.

Price.BuyRatioThresholds is a step-function configuration table that maps buy ratio threshold levels to price skew values for each instrument. A buy ratio measures the proportion of customer positions that are long (buy) versus short (sell) on a given instrument. When eToro's pricing system detects that the buy ratio for an instrument has crossed a configured threshold, it applies the corresponding skew value to adjust the instrument's bid/ask spread. Multiple thresholds can be configured per instrument, creating a stepped response: a moderate buy imbalance triggers a small skew, a large imbalance triggers a larger skew.

Both Price.BuyRatioThresholds and this history table currently have 0 rows, indicating this feature is not actively configured in the current environment.

---

## 2. Business Logic

### 2.1 Step-Function Skew Configuration

**What**: Each row defines one threshold-to-skew mapping step for an instrument.

**Columns/Parameters Involved**: `InstrumentID`, `Threshold`, `Skew`

**Rules**:
- PK = (InstrumentID, Threshold) - one row per instrument per threshold level
- Multiple rows per instrument are expected: each represents a different buy ratio trigger point
- Threshold is a decimal(5,4) representing the buy ratio level (e.g., 0.6000 = 60% of positions are buys)
- Skew is the price adjustment applied when the buy ratio meets or exceeds the threshold; NULL means no skew adjustment at that threshold
- The pricing system selects the highest threshold that the current buy ratio has crossed and applies its corresponding skew
- Buy ratio data is written by Price.AddBuyRatio and stored in Price.BuyRatio (which includes a Skew column computed from these thresholds)

### 2.2 Temporal System Versioning

**What**: SQL Server automatically moves old threshold configurations here on UPDATE/DELETE.

**Rules**:
- Standard temporal pattern - clustered on (SysEndTime ASC, SysStartTime ASC) for efficient `FOR SYSTEM_TIME AS OF` queries
- Trigger TRG_T_BuyRatioThresholds on the parent table performs a self-join UPDATE on INSERT to force SysStartTime refresh
- ASM-auto-generated audit triggers (AuditDelete/Insert/Update) on the parent table write Skew changes to History.AuditHistory, with PK represented as 'InstrumentID,Threshold' string concatenation
- Use `FOR SYSTEM_TIME AS OF` on Price.BuyRatioThresholds for point-in-time queries

---

## 3. Data Overview

Both the history table and the parent table Price.BuyRatioThresholds are empty (0 rows). The feature is not configured in the current environment.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Identifies the instrument for which this threshold applies. FK to Trade.Instrument in parent table. Part of composite PK (InstrumentID, Threshold). |
| 2 | Threshold | decimal(5,4) | NO | - | CODE-BACKED | The buy ratio trigger level (0.0000 to 1.0000). When the instrument's current buy ratio equals or exceeds this value, the corresponding Skew is applied. Part of composite PK - multiple thresholds per instrument allowed. |
| 3 | Skew | decimal(10,4) | YES | - | CODE-BACKED | The price skew adjustment applied when the buy ratio meets or exceeds the Threshold. Nullable - NULL means no skew at this threshold step. Higher skew values widen the effective spread for instruments with high buy imbalance. |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login that modified the configuration row. Captured via suser_name() computed column in parent table. Audit trail for configuration changes. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level identity at time of change from context_info(). Typically NULL when changed via SSMS or deployment scripts. |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this threshold version became active. Managed by SQL Server temporal engine. |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version was superseded. Clustered index leads with SysEndTime for efficient point-in-time queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Price.BuyRatioThresholds | Temporal | This row is a past version of a parent table row |
| InstrumentID | Trade.Instrument | Implicit | The instrument whose threshold configuration is recorded (FK enforced in parent table) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.BuyRatioThresholds | HISTORY_TABLE | Temporal system | Parent table - SQL Server writes here automatically |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BuyRatioThresholds (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.BuyRatioThresholds | Table | Parent temporal table |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.BuyRatioThresholds | Table | SQL Server temporal engine writes here automatically on UPDATE/DELETE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_BuyRatioThresholds | Clustered | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

No constraints. Temporal history tables have no constraints - integrity enforced by SQL Server temporal engine.

Storage: ON [PRIMARY] filegroup with PAGE compression.

---

## 8. Sample Queries

### 8.1 View threshold change history for a specific instrument
```sql
SELECT InstrumentID, Threshold, Skew, DbLoginName, SysStartTime, SysEndTime
FROM [History].[BuyRatioThresholds]
WHERE InstrumentID = @InstrumentID
ORDER BY Threshold ASC, SysStartTime DESC
```

### 8.2 Point-in-time query using temporal syntax (preferred)
```sql
SELECT InstrumentID, Threshold, Skew
FROM [Price].[BuyRatioThresholds]
FOR SYSTEM_TIME AS OF '2024-06-01 00:00:00'
WHERE InstrumentID = @InstrumentID
ORDER BY Threshold ASC
```

### 8.3 Find all threshold changes in a date range
```sql
SELECT InstrumentID, Threshold, Skew, DbLoginName,
       SysStartTime AS ChangedAt, SysEndTime AS SupersededAt
FROM [History].[BuyRatioThresholds]
WHERE SysEndTime BETWEEN @StartDate AND @EndDate
ORDER BY SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (Price.AddBuyRatio writes to Price.BuyRatio, not this table) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BuyRatioThresholds | Type: Table | Source: etoro/etoro/History/Tables/History.BuyRatioThresholds.sql*
