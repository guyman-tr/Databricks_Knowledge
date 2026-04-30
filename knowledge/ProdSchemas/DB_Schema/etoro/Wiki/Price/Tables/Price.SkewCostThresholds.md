# Price.SkewCostThresholds

> Per-instrument configuration table that stores a single skew cost threshold value for each instrument, defining the minimum cost-of-carry or spread cost level at which price skew adjustments are triggered.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

SkewCostThresholds defines a single threshold value per instrument that the pricing engine uses to determine when the cost component of skew (financing cost, spread cost, or carry cost) is significant enough to activate cost-aware price skewing. Unlike `Price.PriceAlgoThresholds` (which stores multiple buy-ratio threshold levels per instrument), this table stores exactly one threshold per instrument.

The table is currently empty (0 rows) and is not referenced by any stored procedures or views in the Price schema SSDT repo. It was provisioned with temporal versioning (SYSTEM_VERSIONING) and the standard ASM no-op trigger, indicating it was prepared as part of pricing algorithm infrastructure. The FK to `Trade.Instrument` ensures only valid instruments can be configured.

The `Threshold` column is `decimal(10,4)`, supporting values up to 999999.9999 with 4 decimal places - appropriate for either pips-based or currency-amount cost thresholds.

---

## 2. Business Logic

### 2.1 Single Skew Cost Threshold per Instrument

**What**: Each instrument has at most one cost-based threshold value. This threshold gates whether cost-of-carry skew is applied.

**Columns/Parameters Involved**: `InstrumentID`, `Threshold`

**Rules**:
- PK on InstrumentID enforces one threshold per instrument
- No procedures currently read or write this table - the threshold comparison logic resides in consuming application code
- The distinction from PriceAlgoThresholds (stepped multi-level) suggests this table handles a single "on/off" cost threshold rather than a graduated skew function

---

## 3. Data Overview

The table is currently empty (0 rows). No skew cost thresholds are configured.

*When populated, rows would appear as:*

| InstrumentID | Threshold | Meaning |
|---|---|---|
| 1 (EUR/USD) | 2.5000 | Apply cost-aware skew when carry cost exceeds 2.5 pips for EUR/USD |
| 5 | 0.0050 | Apply cost skew when cost exceeds 0.005 (0.5 basis points) for instrument 5 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | VERIFIED | Primary key. FK to Trade.Instrument. The instrument for which this skew cost threshold applies. One threshold per instrument. (Trade.Instrument) |
| 2 | Threshold | decimal(10,4) | NOT NULL | - | NAME-INFERRED | The cost threshold value at which cost-aware skew is activated for this instrument. Exact semantics (pips, percentage, or currency amount) depend on consuming application code. No procedures currently read this value. |
| 3 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. Auto-set on DML. |
| 4 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity from context_info(). |
| 5 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal period start. Auto-managed by SQL Server system versioning. |
| 6 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31 23:59:59.9999999' | CODE-BACKED | Temporal period end. Historical versions in History.SkewCostThresholds. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | FK (FK_SkewCostThresholdInstrumentID_TradeInstrumentID) | The instrument for which this cost threshold is configured |

### 5.2 Referenced By (other objects point to this)

No dependents found. The table is currently not referenced by any stored procedures or views.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.SkewCostThresholds (table)
|- Trade.Instrument (table, FK target - leaf)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Instrument | Table | FK target - InstrumentID must reference a valid instrument |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Price_SkewCostThresholds | CLUSTERED PK | InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Price_SkewCostThresholds | PRIMARY KEY | One cost threshold per instrument |
| FK_SkewCostThresholdInstrumentID_TradeInstrumentID | FK | InstrumentID -> Trade.Instrument(InstrumentID) |
| DF_SkewCostThresholds_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_SkewCostThresholds_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | Full history in History.SkewCostThresholds |
| TRG_T_SkewCostThresholds | TRIGGER (INSERT) | ASM no-op: self-update on InstrumentID after insert |

---

## 8. Sample Queries

### 8.1 View all configured skew cost thresholds

```sql
SELECT
    SCT.InstrumentID,
    SCT.Threshold,
    SCT.SysStartTime AS ConfiguredSince
FROM Price.SkewCostThresholds SCT WITH (NOLOCK)
ORDER BY SCT.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 8/10, Logic: 5/10, Relationships: 5/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 1, 2, 4, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.SkewCostThresholds | Type: Table | Source: etoro/etoro/Price/Tables/Price.SkewCostThresholds.sql*
