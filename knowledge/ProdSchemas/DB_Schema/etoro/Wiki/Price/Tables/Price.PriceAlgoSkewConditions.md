# Price.PriceAlgoSkewConditions

> Per-instrument configuration table that defines the minimum market conditions (minimum position count and minimum volume) that must be met before the pricing algorithm applies skew adjustments to an instrument's price.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

PriceAlgoSkewConditions defines guard conditions for the pricing algorithm's skew application logic. "Skew" in pricing refers to adjusting the mid-price bid/ask to favor one side based on the current open position imbalance (more buyers than sellers -> push ask up, or vice versa). However, applying skew before sufficient market participation exists can lead to artificially moved prices.

This table allows operators to configure per-instrument thresholds: `MinCIDCount` (minimum number of copy-instrument positions or client interest data points) and `MinVolumeUSD` (minimum total open volume in USD) that must be present before the algorithm activates skew for that instrument. If either condition is not met, skew is suppressed and the instrument is priced without adjustment.

The table is currently empty (0 rows) and not referenced by any stored procedures or views in the Price schema SSDT repo. Combined with the temporal versioning and ASM-generated trigger, it was provisioned as part of the pricing algorithm infrastructure but has not been populated or integrated into active pricing logic.

---

## 2. Business Logic

### 2.1 Skew Activation Conditions

**What**: An instrument can be configured to require minimum market participation before skew is applied. Both MinCIDCount and MinVolumeUSD default to 0, meaning skew is effectively always enabled unless overridden.

**Columns/Parameters Involved**: `InstrumentID`, `MinCIDCount`, `MinVolumeUSD`

**Rules**:
- PK on InstrumentID enforces one condition set per instrument
- MinCIDCount defaults to 0 (no minimum position count required)
- MinVolumeUSD defaults to $0 (no minimum volume required)
- Setting MinCIDCount=100 means skew is only applied when at least 100 positions exist for that instrument
- Setting MinVolumeUSD=1000000 means skew is only applied when total open volume exceeds $1M
- Both conditions must presumably be satisfied simultaneously (AND logic), though no procedures are available to confirm enforcement
- No consumers currently read this table - the conditions are not enforced by any known procedure

---

## 3. Data Overview

The table is currently empty (0 rows). No skew activation conditions are configured.

*When populated, rows would appear as:*

| InstrumentID | MinCIDCount | MinVolumeUSD | Meaning |
|---|---|---|---|
| 1 (EUR/USD) | 500 | 5000000.00 | Skew only applied to EUR/USD when >= 500 positions exist AND volume >= $5M |
| 5 | 0 | 0.00 | Instrument 5 has no conditions - skew always applied (default behavior) |
| 100 | 100 | 1000000.00 | Instrument 100 requires 100+ positions and $1M+ volume before skew is activated |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | VERIFIED | Primary key. FK to Trade.Instrument. The instrument for which these skew activation conditions apply. One condition set per instrument. (Trade.Instrument) |
| 2 | MinCIDCount | int | NOT NULL | 0 | NAME-INFERRED | Minimum number of CID (Copy-Instrument Details / client position count) entries required before skew is activated for this instrument. Default=0 means no minimum. The acronym CID likely refers to individual client positions or copy-trade units. Exact enforcement by consuming application code. |
| 3 | MinVolumeUSD | money | NOT NULL | 0 | NAME-INFERRED | Minimum total open position volume in USD required before skew is activated. money type (4 decimal places). Default=0 means no minimum volume required. Ensures skew is not applied to thinly traded instruments with low participation. |
| 4 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. Auto-set on DML. |
| 5 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity from context_info(). |
| 6 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal period start. Auto-managed by SQL Server system versioning. |
| 7 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31 23:59:59.9999999' | CODE-BACKED | Temporal period end. Historical row versions in History.PriceAlgoSkewConditions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_PriceAlgoSkewConditions_InstrumentID) | The instrument whose skew activation conditions are defined here |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No stored procedures or views currently reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.PriceAlgoSkewConditions (table)
|- Trade.Instrument (table, FK target - leaf)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target - InstrumentID must reference a valid instrument |

### 6.2 Objects That Depend On This

No dependents found. The table is currently not referenced by any stored procedures or views.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PriceAlgoSkewConditions | CLUSTERED PK | InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PriceAlgoSkewConditions | PRIMARY KEY | One skew condition set per instrument (InstrumentID) |
| FK_PriceAlgoSkewConditions_InstrumentID | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| DF_MinCIDCount | DEFAULT | MinCIDCount = 0 |
| DF_MinVolumeUSD | DEFAULT | MinVolumeUSD = 0 |
| DF_PriceAlgoSkewConditions_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_PriceAlgoSkewConditions_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | Full history in History.PriceAlgoSkewConditions |
| Tr_T_PriceAlgoSkewConditions_INSERT | TRIGGER (INSERT) | ASM no-op: self-update on InstrumentID after insert |

---

## 8. Sample Queries

### 8.1 View all skew conditions with instrument names

```sql
SELECT
    SC.InstrumentID,
    SC.MinCIDCount,
    SC.MinVolumeUSD,
    SC.SysStartTime AS ConfiguredSince
FROM Price.PriceAlgoSkewConditions SC WITH (NOLOCK)
ORDER BY SC.InstrumentID;
```

### 8.2 Find instruments with non-zero skew activation thresholds

```sql
SELECT
    InstrumentID,
    MinCIDCount,
    MinVolumeUSD
FROM Price.PriceAlgoSkewConditions WITH (NOLOCK)
WHERE MinCIDCount > 0 OR MinVolumeUSD > 0
ORDER BY InstrumentID;
```

### 8.3 View change history (temporal)

```sql
SELECT
    InstrumentID,
    MinCIDCount,
    MinVolumeUSD,
    DbLoginName,
    SysStartTime,
    SysEndTime
FROM Price.PriceAlgoSkewConditions
FOR SYSTEM_TIME ALL
ORDER BY InstrumentID, SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 8/10, Logic: 5/10, Relationships: 5/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 1, 2, 4, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.PriceAlgoSkewConditions | Type: Table | Source: etoro/etoro/Price/Tables/Price.PriceAlgoSkewConditions.sql*
