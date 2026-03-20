# DWH_dbo.Dim_CostType

> Small dictionary (4 rows) mapping integer IDs to top-level cost category names in the HistoryCosts billing fee pipeline.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | HistoryCosts.Dictionary.CostType |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, full reload) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CostTypeId ASC) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_CostType` is a 4-row reference dictionary that provides the top-level classification of billing costs in the HistoryCosts fee tracking pipeline. It groups fees into four high-level buckets: spread-based income (Markup), currency conversion charges (CurrencyMarkup), explicit fees (Fee), and regulatory/government taxes (Tax). This is the coarsest classification level in the HistoryCosts taxonomy - used alongside `Dim_CostSubtype` and `Dim_CostConfigurationId` for multi-dimensional cost analysis.

The source is `HistoryCosts.Dictionary.CostType`, an internal lookup table in the HistoryCosts database (not in the Generic Pipeline). The staging table `DWH_staging.HistoryCosts_Dictionary_CostType` is loaded from HistoryCosts and then transformed by `SP_Dictionaries_DL_To_Synapse` via TRUNCATE-and-INSERT full reload. UpdateDate reflects the ETL run time (GETDATE()). No upstream wiki exists for the HistoryCosts schema.

---

## 2. Business Logic

### 2.1 Top-Level Cost Categories

**What**: Four top-level categories group all HistoryCosts billing events by economic nature.

**Columns Involved**: `CostTypeId`, `CostType`

**Rules**:
- ID=1 (Markup): Revenue from bid/ask spread charged to trades (spread income)
- ID=2 (CurrencyMarkup): Markup applied when the trade currency differs from account currency (FX conversion revenue)
- ID=3 (Fee): Explicit fee charged per trade or event (ticket fee, per-lot fee, etc.)
- ID=4 (Tax): Regulatory or government-imposed tax (e.g., Stamp Duty SDRT)

**Diagram**:
```
CostTypeId -> CostType    -> Relationship to Dim_CostSubtype
1          -> Markup       -> CostSubtype: Markup (0)
2          -> CurrencyMarkup -> CostSubtype: ConversionMarkup (1)
3          -> Fee          -> CostSubtype: TicketFee (2), TransactionFee (4), FixPerLotFee (6)
4          -> Tax          -> CostSubtype: SDRT (3)
Note: Refund (CostSubtypeId=5) cuts across types
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed (suboptimal for 4 rows - should be REPLICATE). JOINs will cause data movement. CLUSTERED INDEX on CostTypeId is correct for point lookups.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, store as Delta (MANAGED), no partitioning needed (4 rows).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode top-level cost category | `JOIN DWH_dbo.Dim_CostType d ON f.CostTypeId = d.CostTypeId` |
| Compare markup revenue vs explicit fees | `GROUP BY d.CostType WHERE d.CostTypeId IN (1,3)` |
| Separate regulatory taxes from trading costs | `WHERE CostTypeId = 4` (Tax only) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_History_Cost | ON f.CostTypeId = d.CostTypeId | Decode top-level fee category in cost facts |

### 3.4 Gotchas

- IDs start from 1 (not 0 like Dim_CostSubtype). No ID=0 placeholder row.
- **ROUND_ROBIN distribution**: Any JOIN incurs data movement in Synapse.
- Markup (ID=1) and CurrencyMarkup (ID=2) are both spread-based revenue - the distinction is whether an FX conversion was involved.
- Tax (ID=4) exclusively maps to SDRT in the current 7-row Dim_CostSubtype (ID=3). Other taxes may be added in future.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Meaning |
|-------|------|---------|
| 4 stars | Tier 1 | Upstream wiki verbatim |
| 3 stars | Tier 2 | Synapse SP/DDL code |
| 2 stars | Tier 3 | Live data sampling / DDL structure |
| 1 star | Tier 4-Inferred [UNVERIFIED] | Column name guessing |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CostTypeId | int | YES | Primary key. Top-level cost category ID. Maps to: 1=Markup (spread revenue), 2=CurrencyMarkup (FX conversion charge), 3=Fee (explicit per-trade fee), 4=Tax (regulatory tax). DWH note: sourced from `Id` column in HistoryCosts staging, renamed to CostTypeId. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 2 | CostType | nvarchar(max) | YES | Human-readable cost type name. Values: Markup, CurrencyMarkup, Fee, Tax. Passthrough from source - same column name as staging. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp - set to GETDATE() on each full reload by SP_Dictionaries_DL_To_Synapse. Reflects ETL run time, not source data change time. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CostTypeId | HistoryCosts.Dictionary.CostType | Id | rename (Id -> CostTypeId) |
| CostType | HistoryCosts.Dictionary.CostType | CostType | passthrough |
| UpdateDate | - | - | ETL-computed (GETDATE()) |

No upstream wiki available for HistoryCosts.Dictionary.CostType (HistoryCosts schema has no wiki files).

### 5.2 ETL Pipeline

```
HistoryCosts.Dictionary.CostType
  -> [direct load - not via Generic Pipeline]
  -> DWH_staging.HistoryCosts_Dictionary_CostType
  -> DWH_dbo.SP_Dictionaries_DL_To_Synapse
  -> DWH_dbo.Dim_CostType
```

| Step | Object | Description |
|------|--------|-------------|
| Source | HistoryCosts.Dictionary.CostType | Internal HistoryCosts cost-tracking dictionary. 4 top-level cost categories. |
| Lake | Unknown (not in Generic Pipeline) | HistoryCosts loaded via direct integration |
| Staging | DWH_staging.HistoryCosts_Dictionary_CostType | Raw staging: [Id] int, [CostType] nvarchar(max) |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Renames Id -> CostTypeId. Passthrough CostType. Injects GETDATE() for UpdateDate. |
| Target | DWH_dbo.Dim_CostType | Final DWH dimension (4 rows) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| - | - | No outbound foreign key references. Self-contained lookup. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_History_Cost | CostTypeId | History cost facts reference this table for top-level fee categorization. [UNVERIFIED - no SP grep match; inferred from shared HistoryCosts origin and naming convention] |

---

## 7. Sample Queries

### 7.1 List all cost types
```sql
SELECT CostTypeId, CostType, UpdateDate
FROM [DWH_dbo].[Dim_CostType]
ORDER BY CostTypeId;
```

### 7.2 Decode cost type in fact table
```sql
SELECT f.*, t.CostType
FROM [DWH_dbo].[Fact_History_Cost] f
JOIN [DWH_dbo].[Dim_CostType] t ON f.CostTypeId = t.CostTypeId;
```

### 7.3 Combine cost type and subtype labels
```sql
SELECT t.CostType, s.CostSubtype, COUNT(*) AS EventCount
FROM [DWH_dbo].[Fact_History_Cost] f
JOIN [DWH_dbo].[Dim_CostType] t ON f.CostTypeId = t.CostTypeId
JOIN [DWH_dbo].[Dim_CostSubtype] s ON f.CostSubtypeId = s.CostSubtypeId
GROUP BY t.CostType, s.CostSubtype
ORDER BY EventCount DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|-------------------------|
| [DWH Process Data Sources](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11466244151/DWH+Process+Data+Sources) | Confluence | Lists **etoro Billing** sources (deposit/withdraw, etc.) used in the DWH process—aligns top-level cost buckets (Markup/Fee/Tax) with billing-system provenance. |
| [Deposit conversion fee](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/11705909430/Deposit+conversion+fee) | Confluence | Explains deposit-side FX conversion fee behavior—supports interpreting **CurrencyMarkup** vs **Markup** in customer-facing terms. |
| [Withdrawal fees and conversion fees](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/11699453953/Withdrawal+fees+and+conversion+fees) | Confluence | Withdrawal fee rules and when conversion fees apply on cash-out—context for fee-related cost typing and tax/charges storytelling. |

---

*Generated: 2026-03-19 | Quality: 7.0/10 (3 stars) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 3/10, Sources: 8/10*
*Object: DWH_dbo.Dim_CostType | Type: Table | Production Source: HistoryCosts.Dictionary.CostType*
