# DWH_dbo.Dim_CalculationType

> Lookup dimension defining the 8 calculation methods used in HistoryCosts fee/cost computations (e.g., FixPerUnit, PipsPerUnit, PercentOfTrade). Sourced from HistoryCosts.Dictionary.CalculationType via SP_Dictionaries_DL_To_Synapse.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | HistoryCosts.Dictionary.CalculationType |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, TRUNCATE + INSERT) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CalculationTypeId) |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

Dim_CalculationType is the DWH version of HistoryCosts.Dictionary.CalculationType. It classifies how a historical cost or fee is calculated for a given position or trade event. The 8 methods cover unit-based fixed fees, pip-based pricing, trade-based flat fees, percentage-based calculations, and markup/override modes used in HistoryCosts cost attribution.

Source: HistoryCosts.Dictionary.CalculationType on a HistoryCosts SQL Server instance. The production table is exported daily to the data lake and staged into DWH_staging.HistoryCosts_Dictionary_CalculationType. SP_Dictionaries_DL_To_Synapse loads from that staging table. The production Id column is renamed to CalculationTypeId in DWH.

8 rows (IDs 1-8). No upstream wiki found -- descriptions are derived from live data value names.

**Note**: This table uses ROUND_ROBIN distribution despite having only 8 rows. REPLICATE would be more appropriate for a table this small.

---

## 2. Business Logic

### 2.1 Calculation Method Types

**What**: Defines how a fee or cost amount is computed from the underlying position or trade parameters.

**Columns Involved**: `CalculationTypeId`, `CalculationType`

**Rules** (derived from live data value names):
- FixPerUnit (1): Flat fee per unit of the instrument traded
- PipsPerUnit (2): Fee expressed as pips per unit (used for FX and CFD instruments)
- FixPerTrade (3): Flat fee per trade event, regardless of size
- PercentOfTrade (4): Fee as a percentage of the total trade value
- PercentOfMarketDataMarkup (5): Fee as a percentage of the market data spread/markup component
- PercentOfFees (6): Fee as a percentage of other fees already charged
- Override (7): Manual or system override amount bypassing the standard calculation
- FixPerLot (8): Flat fee per standardized lot

| CalculationTypeId | CalculationType | Meaning |
|---|---|---|
| 1 | FixPerUnit | Fixed monetary fee per traded unit |
| 2 | PipsPerUnit | Pip-based fee per traded unit (FX/CFD) |
| 3 | FixPerTrade | Fixed fee per trade event |
| 4 | PercentOfTrade | Percentage of total trade notional value |
| 5 | PercentOfMarketDataMarkup | Percentage of the market data markup component |
| 6 | PercentOfFees | Percentage of other fees charged on the trade |
| 7 | Override | Manual/system override - bypasses standard calculation |
| 8 | FixPerLot | Fixed fee per standardized lot |

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on CalculationTypeId. ROUND_ROBIN is unusual for an 8-row table -- REPLICATE would eliminate data movement on JOINs. This may be an ETL default applied without consideration of table size.

**Performance note**: JOINs on this table with ROUND_ROBIN distribution will cause data movement. Consider requesting a distribution change to REPLICATE.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, no partitioning needed for 8 rows. Expected as a MANAGED Delta table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Resolve calculation type ID to name | JOIN Dim_CalculationType ON CalculationTypeId |
| Cost breakdown by calculation method | GROUP BY CalculationTypeId in HistoryCosts fact tables |

### 3.3 Gotchas

- **ROUND_ROBIN on 8-row table**: This causes data movement on every JOIN. Unlike other DWH lookup tables, this one is NOT replicated across nodes.
- **No ID=0 placeholder**: Unlike most DWH Dim_ tables, there is no ID=0 (N/A) row. NULL CalculationTypeId in fact tables cannot be joined to this dimension.
- **CalculationType is nvarchar(max)**: DWH column is nvarchar(max) while production is varchar(50). This may affect query performance for string operations.
- **Production source is HistoryCosts (not etoro)**: Unlike most DWH dimensions sourced from etoroDB-REAL, this comes from the HistoryCosts cost attribution database.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| 3 stars | Tier 2 - SP ETL code | (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 2 stars | Tier 3 - name-inferred from live data values | (Tier 3 - name-inferred, live data) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CalculationTypeId | int | YES | Primary key identifying the calculation method. 1=FixPerUnit, 2=PipsPerUnit, 3=FixPerTrade, 4=PercentOfTrade, 5=PercentOfMarketDataMarkup, 6=PercentOfFees, 7=Override, 8=FixPerLot. Renamed from `Id` in production Dictionary.CalculationType. (Tier 3 - name-inferred, live data) |
| 2 | CalculationType | nvarchar(max) | YES | Human-readable name for the calculation method. 8 distinct values (FixPerUnit through FixPerLot). Self-descriptive code-style names used in HistoryCosts cost computation. (Tier 3 - name-inferred, live data) |
| 3 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() on each daily reload by SP_Dictionaries_DL_To_Synapse. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CalculationTypeId | HistoryCosts.Dictionary.CalculationType | Id | Passthrough (renamed: Id -> CalculationTypeId) |
| CalculationType | HistoryCosts.Dictionary.CalculationType | CalculationType | Passthrough |
| UpdateDate | - | - | ETL-computed: GETDATE() at load time |

### 5.2 ETL Pipeline

```
HistoryCosts.Dictionary.CalculationType -> Generic Pipeline (daily, Override) -> Bronze/HistoryCosts/Dictionary/CalculationType/ -> DWH_staging.HistoryCosts_Dictionary_CalculationType -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_CalculationType
```

| Step | Object | Description |
|------|--------|-------------|
| Source | HistoryCosts.Dictionary.CalculationType | 8-row calculation method catalog |
| Lake | Bronze/HistoryCosts/Dictionary/CalculationType/ | Daily full export (Override, parquet) |
| Staging | DWH_staging.HistoryCosts_Dictionary_CalculationType | Raw staging import |
| ETL | SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT; Id renamed to CalculationTypeId; UpdateDate=GETDATE() |
| Target | DWH_dbo.Dim_CalculationType | 8 rows (IDs 1-8) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CalculationTypeId | HistoryCosts.Dictionary.CalculationType | Production source (upstream reference) |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| HistoryCosts fact tables in DWH | CalculationTypeId | Cost calculation method lookup |

---

## 7. Sample Queries

### 7.1 List all calculation types

```sql
SELECT CalculationTypeId, CalculationType
FROM [DWH_dbo].[Dim_CalculationType]
ORDER BY CalculationTypeId
-- Returns: 1=FixPerUnit, 2=PipsPerUnit, ..., 8=FixPerLot
```

### 7.2 ETL freshness check

```sql
SELECT MAX(UpdateDate) AS LastLoad, COUNT(*) AS RowCount
FROM [DWH_dbo].[Dim_CalculationType]
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Relevance |
|--------|------|-----------|
| [Fees](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12171248211/Fees) | Confluence | `CalculationType` as calculation format in centralized fee design |
| [Cost Calculation — Multi-Currency Support](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14039384096/Cost+Calculation+Multi-Currency+Support) | Confluence | Per-CalculationType behavior and CostCalculator calculation types |
| [DWH Daily Process Delayed (HistoryCosts.History.Costs)](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/13279526914/DWH+Daily+Process+Delayed+HistoryCosts.History.Costs+-+2025-07-16) | Confluence | DWH pipeline linkage to HistoryCosts cost data |
| [BI Dictionary](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060931862/BI+Dictionary) | Confluence | DWH table layer and analyst-facing dictionary context |
| [TRADEA-1718 Cost Enums To Dictionary Tables](https://etoro-jira.atlassian.net/browse/TRADEA-1718) | Jira | HistoryCosts dictionary / cost enum migration to dictionary tables |

---

*Generated: 2026-03-18 | Quality: 6.9/10 (2 stars) | Phases: 9/14 (simple-dict fast-path: P3/P5/P6/P7/P9B skipped; Phase 10 applied)*
*Tiers: 0 T1, 1 T2, 2 T3, 0 T4-Inferred, 0 T5 | Elements: 7.0/10, Logic: 6.0/10, Relationships: 4.0/10, Sources: 8.0/10*
*Object: DWH_dbo.Dim_CalculationType | Type: Table | Production Source: HistoryCosts.Dictionary.CalculationType*
