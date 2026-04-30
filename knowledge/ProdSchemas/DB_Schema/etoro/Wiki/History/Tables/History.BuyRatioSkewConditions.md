# History.BuyRatioSkewConditions

> Temporal history table automatically maintained by SQL Server for Price.BuyRatioSkewConditions; each row captures one past version of a per-instrument skew eligibility threshold configuration with its validity interval.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | (SysEndTime, SysStartTime) - clustered index (no PK; temporal managed by SQL Server) |
| **Partition** | No |
| **Indexes** | 1 active (clustered on SysEndTime, SysStartTime) |

---

## 1. Business Meaning

History.BuyRatioSkewConditions is the auto-managed temporal history table for Price.BuyRatioSkewConditions. SQL Server's SYSTEM_VERSIONING feature writes here automatically whenever a skew eligibility condition row is updated or deleted in the parent table.

Price.BuyRatioSkewConditions defines the minimum thresholds an instrument must meet before eToro's pricing system applies a buy ratio skew to its bid/ask prices. The two conditions are: a minimum number of distinct customers holding positions in the instrument (MinCIDCount) and a minimum aggregate USD volume across those positions (MinVolumeUSD). These gates prevent skew from being applied to instruments with thin, statistically unreliable position distributions - skew calculated from only a handful of customers could introduce pricing instability. Only one configuration row exists per instrument (InstrumentID is the PK).

Both Price.BuyRatioSkewConditions and this history table currently have 0 rows, indicating the feature is either inactive or unconfigured in the current environment.

---

## 2. Business Logic

### 2.1 Skew Eligibility Thresholds

**What**: Each row defines, for one instrument, the minimum activity level required before buy ratio skew is applied to pricing.

**Columns/Parameters Involved**: `InstrumentID`, `MinCIDCount`, `MinVolumeUSD`

**Rules**:
- One row per instrument (InstrumentID is the PK in the parent table)
- MinCIDCount: the pricing system checks that at least this many distinct customers hold open positions in the instrument before computing skew; default is 0 (no minimum enforced)
- MinVolumeUSD: the pricing system checks that total open position value in USD meets this threshold before computing skew; default is 0 (no minimum enforced)
- Both conditions must be satisfied simultaneously for skew to be applied
- Skew itself is computed and stored in Price.BuyRatio (Skew column); the SkewConditions table gates whether skew is applied at all

### 2.2 Temporal System Versioning

**What**: SQL Server automatically moves old configuration versions here on UPDATE/DELETE.

**Rules**:
- Standard temporal pattern - clustered on (SysEndTime ASC, SysStartTime ASC) for efficient `FOR SYSTEM_TIME AS OF` queries
- Trigger TRG_T_BuyRatioSkewConditions on the parent table performs a self-join UPDATE on INSERT to force SysStartTime refresh (same pattern as other Price temporal tables)
- ASM-auto-generated audit triggers (AuditDelete/Insert/Update) on the parent table also write MinCIDCount and MinVolumeUSD changes to History.AuditHistory
- Use `FOR SYSTEM_TIME AS OF` on Price.BuyRatioSkewConditions for point-in-time queries

---

## 3. Data Overview

Both the history table and the parent table Price.BuyRatioSkewConditions are empty (0 rows). The feature is unconfigured in the current environment.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | Identifies the instrument for which skew eligibility conditions are configured. FK to Trade.Instrument in parent table. PK of parent table - one row per instrument. |
| 2 | MinCIDCount | int | NO | 0 | CODE-BACKED | Minimum number of distinct customers that must hold open positions in this instrument before buy ratio skew is applied. Default 0 means no minimum enforced. Guards against skew on thin-market instruments. |
| 3 | MinVolumeUSD | money | NO | 0 | CODE-BACKED | Minimum total USD value of open positions across all customers for this instrument before skew is applied. Default 0 means no minimum enforced. Complements MinCIDCount to ensure statistical reliability. |
| 4 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | SQL Server login that modified the configuration row. Captured via suser_name() computed column in parent table. Audit trail for who made configuration changes. |
| 5 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Application-level identity at time of change from context_info(). Typically NULL when changed via SSMS or deployment scripts. |
| 6 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this configuration version became active. Managed by SQL Server temporal engine. |
| 7 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this version was superseded. Clustered index leads with SysEndTime for efficient point-in-time queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Price.BuyRatioSkewConditions | Temporal | This row is a past version of a parent table row |
| InstrumentID | Trade.Instrument | Implicit | The instrument whose skew conditions are recorded (FK enforced in parent table) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.BuyRatioSkewConditions | HISTORY_TABLE | Temporal system | Parent table - SQL Server writes here automatically |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BuyRatioSkewConditions (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.BuyRatioSkewConditions | Table | Parent temporal table |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.BuyRatioSkewConditions | Table | SQL Server temporal engine writes here automatically on UPDATE/DELETE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_BuyRatioSkewConditions | Clustered | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

No constraints. Temporal history tables have no constraints - integrity enforced by SQL Server temporal engine.

Storage: ON [PRIMARY] filegroup with PAGE compression.

---

## 8. Sample Queries

### 8.1 View change history for a specific instrument's skew conditions
```sql
SELECT InstrumentID, MinCIDCount, MinVolumeUSD, DbLoginName, SysStartTime, SysEndTime
FROM [History].[BuyRatioSkewConditions]
WHERE InstrumentID = @InstrumentID
ORDER BY SysStartTime DESC
```

### 8.2 Point-in-time query using temporal syntax (preferred)
```sql
SELECT InstrumentID, MinCIDCount, MinVolumeUSD
FROM [Price].[BuyRatioSkewConditions]
FOR SYSTEM_TIME AS OF '2024-06-01 00:00:00'
ORDER BY InstrumentID
```

### 8.3 Find all threshold changes in a date range
```sql
SELECT InstrumentID, MinCIDCount, MinVolumeUSD, DbLoginName,
       SysStartTime AS ChangedAt, SysEndTime AS SupersededAt
FROM [History].[BuyRatioSkewConditions]
WHERE SysEndTime BETWEEN @StartDate AND @EndDate
ORDER BY SysEndTime DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Price.AddBuyRatio) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BuyRatioSkewConditions | Type: Table | Source: etoro/etoro/History/Tables/History.BuyRatioSkewConditions.sql*
