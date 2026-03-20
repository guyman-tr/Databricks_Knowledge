# DWH_dbo.Dim_CostSubtype

> Small dictionary (7 rows) mapping integer IDs to cost subtype names that sub-classify fee categories in the HistoryCosts billing pipeline.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | HistoryCosts.Dictionary.CostSubtype |
| **Refresh** | Daily (SP_Dictionaries_DL_To_Synapse, full reload) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CostSubtypeId ASC) |
| | |
| **UC Target** | _Pending - resolved during write-objects_ |
| **UC Format** | _Pending - resolved during write-objects_ |
| **UC Partitioned By** | _Pending - resolved during write-objects_ |
| **UC Table Type** | _Pending - resolved during write-objects_ |

---

## 1. Business Meaning

`Dim_CostSubtype` is a 7-row reference dictionary that classifies billing cost events by sub-category within the HistoryCosts fee tracking pipeline. It provides a finer-grained classification than `Dim_CostType` or `Dim_CostConfigurationId` - distinguishing markup types, tax types (SDRT = Stamp Duty Reserve Tax, a UK financial transaction tax), and special fee categories like refunds and per-lot fees.

The source is `HistoryCosts.Dictionary.CostSubtype`, an internal lookup table in the HistoryCosts database. HistoryCosts is not in the Generic Pipeline - its staging tables are loaded via a direct database integration. The staging table `DWH_staging.HistoryCosts_Dictionary_CostSubtype` is loaded from HistoryCosts and then transformed into this DWH dimension by `SP_Dictionaries_DL_To_Synapse`. No upstream wiki exists for the HistoryCosts schema.

The ETL is a full TRUNCATE-and-INSERT reload. Column mapping is clean: `Id` -> `CostSubtypeId` (rename), `CostSubtype` -> `CostSubtype` (passthrough). `UpdateDate` is injected as GETDATE() by the SP. As of 2026-03-11 the table had 7 rows covering 7 distinct cost subtypes starting from ID=0.

---

## 2. Business Logic

### 2.1 Cost Subtype Classification

**What**: Seven categories sub-classify the type of fee within the HistoryCosts billing system.

**Columns Involved**: `CostSubtypeId`, `CostSubtype`

**Rules**:
- ID=0 (Markup): Standard bid/ask spread markup
- ID=1 (ConversionMarkup): Markup applied to currency conversion operations
- ID=2 (TicketFee): Fixed per-trade commission ticket fee
- ID=3 (SDRT): Stamp Duty Reserve Tax - UK financial transaction tax on stock purchases
- ID=4 (TransactionFee): General transaction processing fee
- ID=5 (Refund): Fee reversal/refund
- ID=6 (FixPerLotFee): Fixed fee charged per lot traded (common for futures/CFDs)

**Diagram**:
```
CostSubtypeId -> CostSubtype
0 -> Markup              (spread-based revenue)
1 -> ConversionMarkup    (FX conversion charge)
2 -> TicketFee           (flat trade commission)
3 -> SDRT                (UK stamp duty - regulatory)
4 -> TransactionFee      (processing fee)
5 -> Refund              (fee reversal)
6 -> FixPerLotFee        (per-lot charge for leveraged products)
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed (suboptimal for 7 rows - should be REPLICATE). Joining this table in Synapse may trigger data movement. The CLUSTERED INDEX on `CostSubtypeId` is appropriate for point lookups. For heavy analytical queries, consider materializing the join result.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, store as Delta (MANAGED), no partitioning needed (7 rows). No Z-ORDER required.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Decode cost subtype in fact table | `JOIN DWH_dbo.Dim_CostSubtype d ON f.CostSubtypeId = d.CostSubtypeId` |
| Filter regulatory fees only | `WHERE CostSubtypeId = 3` (SDRT) |
| List all fee subtypes | `SELECT * FROM DWH_dbo.Dim_CostSubtype ORDER BY CostSubtypeId` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Fact_History_Cost | ON f.CostSubtypeId = d.CostSubtypeId | Decode fee subtype in history cost facts |

### 3.4 Gotchas

- ID=0 exists (Markup) - unlike many DWH dims which start at 1. No separate ID=0 placeholder row for null/unknown.
- SDRT (ID=3) is UK-specific - Stamp Duty Reserve Tax on equity purchases. May not apply to all entity types or instruments.
- **ROUND_ROBIN distribution**: JOIN to this 7-row table will incur data movement in Synapse.
- ID=5 (Refund) is a reversal type - rows with this subtype reduce the cost total, not increase it.

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
| 1 | CostSubtypeId | int | YES | Primary key. Integer identifier for the cost subtype. Maps to: 0=Markup, 1=ConversionMarkup, 2=TicketFee, 3=SDRT (UK Stamp Duty), 4=TransactionFee, 5=Refund, 6=FixPerLotFee. DWH note: sourced from `Id` column in HistoryCosts staging (renamed to CostSubtypeId). (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 2 | CostSubtype | nvarchar(max) | YES | Human-readable name for the cost subtype. Values: Markup, ConversionMarkup, TicketFee, SDRT, TransactionFee, Refund, FixPerLotFee. Passthrough from source - column name unchanged from staging. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |
| 3 | UpdateDate | datetime | NO | ETL load timestamp - set to GETDATE() on each full reload by SP_Dictionaries_DL_To_Synapse. Reflects when the batch SP last ran, not when the source data changed. (Tier 2 - SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| CostSubtypeId | HistoryCosts.Dictionary.CostSubtype | Id | rename (Id -> CostSubtypeId) |
| CostSubtype | HistoryCosts.Dictionary.CostSubtype | CostSubtype | passthrough |
| UpdateDate | - | - | ETL-computed (GETDATE()) |

No upstream wiki available for HistoryCosts.Dictionary.CostSubtype (HistoryCosts schema has no wiki files in DB_Schema).

### 5.2 ETL Pipeline

```
HistoryCosts.Dictionary.CostSubtype
  -> [direct staging load - not via Generic Pipeline]
  -> DWH_staging.HistoryCosts_Dictionary_CostSubtype
  -> DWH_dbo.SP_Dictionaries_DL_To_Synapse
  -> DWH_dbo.Dim_CostSubtype
```

| Step | Object | Description |
|------|--------|-------------|
| Source | HistoryCosts.Dictionary.CostSubtype | Internal HistoryCosts cost-tracking dictionary. 7 cost subtype rows. |
| Lake | Unknown (not in Generic Pipeline mapping) | HistoryCosts is not in the Generic Pipeline; loaded via direct integration |
| Staging | DWH_staging.HistoryCosts_Dictionary_CostSubtype | Raw staging: [Id] int, [CostSubtype] nvarchar(max) |
| ETL | DWH_dbo.SP_Dictionaries_DL_To_Synapse | TRUNCATE + INSERT. Renames Id -> CostSubtypeId. Passthrough CostSubtype. Injects GETDATE() for UpdateDate. |
| Target | DWH_dbo.Dim_CostSubtype | Final DWH dimension (7 rows) |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| - | - | No outbound foreign key references. Self-contained lookup. |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.Fact_History_Cost | CostSubtypeId | History cost facts likely reference this table to sub-classify the fee type. [UNVERIFIED - no SP grep match found; relationship inferred from naming convention and shared HistoryCosts origin] |

---

## 7. Sample Queries

### 7.1 List all cost subtypes
```sql
SELECT CostSubtypeId, CostSubtype, UpdateDate
FROM [DWH_dbo].[Dim_CostSubtype]
ORDER BY CostSubtypeId;
```

### 7.2 Decode cost subtype in history cost facts
```sql
SELECT f.*, d.CostSubtype
FROM [DWH_dbo].[Fact_History_Cost] f
JOIN [DWH_dbo].[Dim_CostSubtype] d
    ON f.CostSubtypeId = d.CostSubtypeId;
```

### 7.3 Filter to regulatory fees (SDRT only)
```sql
SELECT f.*
FROM [DWH_dbo].[Fact_History_Cost] f
JOIN [DWH_dbo].[Dim_CostSubtype] d
    ON f.CostSubtypeId = d.CostSubtypeId
WHERE d.CostSubtype = 'SDRT';
```

---

## 8. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|-------------------------|
| [Fees](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/1137475986/Fees) | Confluence | CS-facing taxonomy of eToro fee types (incl. conversion and withdrawal fees)—business language for fee categories that align with cost-subtype style labels (markup, ticket, conversion). |
| [Conversion Fee](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/1137344864/Conversion+Fee) | Confluence | When conversion fees apply (deposits, withdrawals, open/close, dividends)—helps interpret **ConversionMarkup**-style subtypes vs cash-movement fees. |
| [DWH Daily Process Delayed (HistoryCosts.History.Costs) - 2025-07-16](https://etoro-jira.atlassian.net/wiki/spaces/BDP/pages/13279526914/DWH+Daily+Process+Delayed+HistoryCosts.History.Costs+-+2025-07-16) | Confluence | Confirms **HistoryCosts** cost history is part of the DWH daily dependency chain; relevant to HistoryCosts-sourced dimensions like cost subtype. |

---

*Generated: 2026-03-19 | Quality: 7.0/10 (3 stars) | Phases: 7/14 (simple-dict fast-path)*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 5/10, Relationships: 3/10, Sources: 8/10*
*Object: DWH_dbo.Dim_CostSubtype | Type: Table | Production Source: HistoryCosts.Dictionary.CostSubtype*
