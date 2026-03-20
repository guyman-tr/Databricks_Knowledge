# DWH_dbo.Dim_CostConfigurationId

> Small dictionary mapping integer IDs to cost configuration type names used in the HistoryCosts billing fee pipeline.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | HistoryCosts.Dictionary.CostConfigurationId |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, full reload) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CostConfigurationId ASC) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_CostConfigurationId` is a small reference dictionary (4 rows) that maps integer IDs to human-readable cost configuration type names. It classifies the four types of trading fees tracked in the HistoryCosts fee pipeline: real-account markup, CFD markup, ticket fees, and currency conversion markups.

The source is `HistoryCosts.Dictionary.CostConfigurationId`, a lookup table in the HistoryCosts database. HistoryCosts is an internal cost-tracking database (not exported via the Generic Pipeline). The staging table `DWH_staging.HistoryCosts_Dictionary_CostConfigurationId` is loaded directly from HistoryCosts via the Data Lake pipeline, then transformed into this DWH dimension by `SP_Dictionaries_DL_To_Synapse`. No upstream wiki exists for the HistoryCosts schema.

The ETL is a full TRUNCATE-and-INSERT reload executed by `DWH_dbo.SP_Dictionaries_DL_To_Synapse`. The table had `UpdateDate = 2026-03-11` at last observation (see etl_freshness_alert in batch context - SP may be 7+ days stale). Note: the source column named `CostConfigurationId` (nvarchar) is renamed to `CostConfiguration` in DWH to avoid collision with the integer PK column of the same name.

---

## 2. Business Logic

### 2.1 Cost Configuration Types

**What**: Four categories classify the type of fee charged in each HistoryCosts billing event.

**Columns Involved**: `CostConfigurationId`, `CostConfiguration`

**Rules**:
- ID=1 (MarkupReal): Spread/markup applied to real-account trades
- ID=2 (MarkupCfd): Spread/markup applied to CFD instrument trades
- ID=3 (TicketFee): Flat per-trade ticket fee charged on execution
- ID=4 (CurrencyConversionMarkup): Markup applied when converting between account currency and instrument currency

**Diagram**:
```
CostConfigurationId -> CostConfiguration
1 -> MarkupReal
2 -> MarkupCfd
3 -> TicketFee
4 -> CurrencyConversionMarkup
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on `CostConfigurationId`. ROUND_ROBIN is suboptimal for a 4-row dictionary (should be REPLICATE for broadcast joins). Joining this table in Synapse will trigger a data movement operation. For high-frequency queries, consider applying a REPLICATE hint or materializing the join result. The CLUSTERED INDEX on `CostConfigurationId` is the correct choice for point lookups.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this is a tiny lookup table. Store as Delta (MANAGED), no partitioning needed (4 rows). No Z-ORDER required.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode cost type in Fact_History_Cost | `JOIN DWH_dbo.Dim_CostConfigurationId d ON f.CostConfigurationId = d.CostConfigurationId` |
| List all fee types | `SELECT * FROM DWH_dbo.Dim_CostConfigurationId ORDER BY CostConfigurationId` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_History_Cost | ON f.CostConfigurationId = d.CostConfigurationId | Decode fee category in history cost facts |

### 3.4 Gotchas

- Only 4 rows - complete value set as of 2026-03-11
- **ROUND_ROBIN distribution**: any JOIN to this 4-row table incurs data movement in Synapse - acceptable for infrequent use, inefficient in heavy analytical queries
- Source naming confusion: in `HistoryCosts.Dictionary.CostConfigurationId`, the column called `CostConfigurationId` is the *name string* (nvarchar). DWH renames it to `CostConfiguration` and uses `Id` (int) as the key renamed to `CostConfigurationId`
- No ID=0 placeholder row - unlike many other DWH dictionaries, this table does not have a null/unknown sentinel row

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
| 1 | CostConfigurationId | int | YES | Primary key. Integer identifier for the cost configuration type. Maps to: 1=MarkupReal, 2=MarkupCfd, 3=TicketFee, 4=CurrencyConversionMarkup. DWH note: sourced from `Id` column in HistoryCosts staging (renamed to avoid collision with the name field). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 2 | CostConfiguration | nvarchar(max) | YES | Human-readable name for the cost configuration type. Values observed: MarkupReal, MarkupCfd, TicketFee, CurrencyConversionMarkup. DWH note: sourced from the staging column also named `CostConfigurationId` (nvarchar) in HistoryCosts, renamed here to avoid collision with the integer PK. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp - set to GETDATE() on each full reload by SP_Dictionaries_DL_To_Synapse. Reflects when the batch SP last ran, not when the source data changed. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CostConfigurationId | HistoryCosts.Dictionary.CostConfigurationId | Id | rename (Id -> CostConfigurationId) |
| CostConfiguration | HistoryCosts.Dictionary.CostConfigurationId | CostConfigurationId | rename (CostConfigurationId -> CostConfiguration) |
| UpdateDate | — | — | ETL-computed (GETDATE()) |

No upstream wiki available for HistoryCosts.Dictionary.CostConfigurationId (HistoryCosts schema has no wiki files in DB_Schema).

### 5.2 ETL Pipeline

```
HistoryCosts.Dictionary.CostConfigurationId -> [direct staging load] -> DWH_staging.HistoryCosts_Dictionary_CostConfigurationId -> SP_Dictionaries_DL_To_Synapse -> DWH_dbo.Dim_CostConfigurationId
```

| Step | Object | Description |
|------|--------|-------------|
| Source | HistoryCosts.Dictionary.CostConfigurationId | Internal HistoryCosts cost-tracking database dictionary. 4 cost category rows. |
| Lake | Unknown (not in Generic Pipeline mapping) | HistoryCosts is not in the Generic Pipeline; loaded directly |
| Staging | DWH_staging.HistoryCosts_Dictionary_CostConfigurationId | Raw staging: [Id] int, [CostConfigurationId] nvarchar(max) |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Renames Id -> CostConfigurationId, CostConfigurationId -> CostConfiguration. Injects GETDATE() for UpdateDate. |
| Target | DWH_dbo.Dim_CostConfigurationId | Final DWH dimension (4 rows) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| — | — | No outbound foreign key references. Self-contained lookup. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_History_Cost | CostConfigurationId | History cost facts reference this table to classify the fee type per billing event. [UNVERIFIED - no SP grep match found; relationship inferred from naming convention] |

---

## 7. Sample Queries

### 7.1 List all cost configuration types
```sql
SELECT CostConfigurationId, CostConfiguration, UpdateDate
FROM [DWH_dbo].[Dim_CostConfigurationId]
ORDER BY CostConfigurationId;
```

### 7.2 Decode cost type in history cost facts
```sql
SELECT f.*, d.CostConfiguration
FROM [DWH_dbo].[Fact_History_Cost] f
JOIN [DWH_dbo].[Dim_CostConfigurationId] d
    ON f.CostConfigurationId = d.CostConfigurationId;
```

### 7.3 Check ETL freshness
```sql
SELECT MAX(UpdateDate) AS LastRefresh
FROM [DWH_dbo].[Dim_CostConfigurationId];
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|-------------------------|
| [DWH Process Data Sources](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/11466244151/DWH+Process+Data+Sources) | Confluence | Inventory of DWH daily sources including **etoro Billing** objects (e.g. deposit/withdraw flows)—operational context for billing/cost pipelines feeding the warehouse. |
| [DWH Daily Process Delayed (HistoryCosts.History.Costs) - 2025-07-16](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/13279526914/DWH+Daily+Process+Delayed+HistoryCosts.History.Costs+-+2025-07-16) | Confluence | Incident post-mortem: **HistoryCosts/History/Costs** lake copy delayed the DWH daily process—confirms HistoryCosts cost data is on the critical DWH ingestion path. |
| [BI Dictionary](https://etoro-jira.atlassian.net/wiki/spaces/BI/pages/13060931862/BI+Dictionary) | Confluence | Describes DWH fact/dim usage patterns for billing analytics (e.g. when a column is not in Fact Billing Deposit, downstream joins may be unnecessary). |

---

*Generated: 2026-03-19 | Quality: 7.0/10 (3 stars) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 3/10, Sources: 8/10*
*Object: DWH_dbo.Dim_CostConfigurationId | Type: Table | Production Source: HistoryCosts.Dictionary.CostConfigurationId*
