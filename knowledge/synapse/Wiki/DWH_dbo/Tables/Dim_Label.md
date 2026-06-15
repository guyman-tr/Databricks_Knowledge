# DWH_dbo.Dim_Label

> Small 26-row dictionary table mapping LabelID to the white-label broker brand name -- identifying which eToro-platform white-label partner (e.g., RetailFX, ICMarkets, eToroUSA) a customer account was acquired under or associated with.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Dictionary.Label (etoroDB-REAL) |
| **Refresh** | Daily (TRUNCATE + INSERT via SP_Dictionaries_DL_To_Synapse) |
| | |
| **Synapse Distribution** | REPLICATE |
| **Synapse Index** | CLUSTERED INDEX (LabelID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label` |
| **UC Format** | parquet |
| **UC Partitioned By** | None (26 rows) |
| **UC Table Type** | Gold export (Generic Pipeline, Override, 1440min) |

---

## 1. Business Meaning

`DWH_dbo.Dim_Label` is a reference dictionary for eToro's white-label broker network -- the companies that licensed the eToro platform to offer it under their own brand to customers in specific regions. Each row maps a LabelID to a brand name (e.g., `RetailFX`, `ICMarkets`, `eToroUSA`, `Euroforex`). The label identifies which white-label channel a customer account originated from or is associated with.

The table has 26 rows. Most entries represent historical white-label partners from eToro's early expansion phase (2010-2015), when the platform was licensed to regional brokers. Some remain active (e.g., `eToroUSA`, `eToroChina`); others (e.g., `JCLyons`, `BT`, `Trend-Online`) are legacy brands that are no longer active. LabelID 0 (`eToro`) and LabelID 1 (`eToro`) are both the core eToro brand -- the distinction between 0 and 1 is a legacy artifact.

ETL is part of the bulk `SP_Dictionaries_DL_To_Synapse` stored procedure (runs daily). Source is `DWH_staging.etoro_Dictionary_Label`, which is loaded from the Generic Pipeline Bronze export of the production `Dictionary.Label` table.

---

## 2. Business Logic

### 2.1 White-Label Brand Identification

**What**: Each customer account in the DWH has an associated LabelID identifying the broker brand under which they were onboarded.

**Rules**:
- LabelID=0 and LabelID=1 both map to `eToro` -- legacy dual-entry. Use `IN (0, 1)` or join to Name for eToro's own customers.
- Most white-label partners (LabelID 2-31) represent historical licensee brands. Many are no longer actively onboarding customers.
- `eToroUSA` (LabelID=14), `eToroRussia` (LabelID=29), `eToroChina` (LabelID=31) are eToro's own regional sub-brands.
- `eToro-Partners` (LabelID=27), `etoro-raf` (LabelID=28) may represent internal partner/referral channels.
- `Dealing` (LabelID=30) likely represents accounts assigned to the dealing desk.

### 2.2 DWHLabelID Redundancy

**What**: `DWHLabelID` is always equal to `LabelID` -- a standard DWH denormalization pattern seen across all Dim tables.

**Rule**: `DWHLabelID = LabelID` (from SP: `[LabelID] as [DWHLabelID]`). Do not use DWHLabelID for JOINs; use LabelID.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

REPLICATE-distributed (26 rows fit trivially on every node). CLUSTERED INDEX on LabelID. Zero JOIN overhead when joining to fact tables on LabelID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get label name for customer account | `JOIN Dim_Label ON LabelID; SELECT Name` |
| Find all eToro-brand accounts | `WHERE LabelID IN (0, 1, 14, 29, 31)` (eToro core + regional sub-brands) |
| Segment by white-label vs eToro-direct | `WHERE LabelID BETWEEN 2 AND 13` (legacy white-label partners) |

### 3.3 Gotchas

- **LabelID 0 and 1 both = eToro**: Use `IN (0, 1)` or `Name = 'eToro'` for the core eToro brand.
- **StatusID is always 1**: ETL hardcodes StatusID=1 for all rows. Not a meaningful filter.
- **UpdateDate/InsertDate are both GETDATE()**: ETL timestamps from the daily load, not production modification dates.
- **Legacy brands**: Most non-eToro labels are historical. Volume in fact tables for these LabelIDs will be concentrated in earlier years.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★ | Tier 1 -- Upstream dictionary | `(Tier 1 — Dictionary.Label)` |
| ★★★ | Tier 2 -- Synapse SP code / DDL | `(Tier 2 -SP_Dictionaries_DL_To_Synapse)` |
| ★★ | Tier 3 -- live data / structure | `(Tier 3 -live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | LabelID | int | NO | Primary key identifying the platform brand/label. 0/1/9=eToro (primary), 2=RetailFX, 10-26=white-label partners, 14=eToroUSA, 27=eToro-Partners, 29=eToroRussia, 30=Dealing, 31=eToroChina. Stored in customer records and referenced across billing, reporting, and registration procedures. (Tier 1 — Dictionary.Label) |
| 2 | Name | varchar(50) | NO | Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = 'eToro'). (Tier 1 — Dictionary.Label) |
| 3 | DWHLabelID | int | YES | Always equal to LabelID. Standard DWH DWH{X}ID redundancy pattern (ETL: `[LabelID] as [DWHLabelID]`). Do not use for JOINs. (Tier 2 -SP_Dictionaries_DL_To_Synapse) |
| 4 | StatusID | int | YES | Hardcoded to 1 for all rows (ETL: `1 as StatusID`). Conveys no business information. (Tier 2 -SP_Dictionaries_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp -- GETDATE() at load time. Does not reflect production modification date. (Tier 2 -SP_Dictionaries_DL_To_Synapse) |
| 6 | InsertDate | datetime | YES | ETL load timestamp -- GETDATE() at load time, identical to UpdateDate (TRUNCATE + INSERT pattern). Does not reflect production insertion date. (Tier 2 -SP_Dictionaries_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| LabelID | etoro.Dictionary.Label | LabelID | passthrough |
| Name | etoro.Dictionary.Label | Name | passthrough |
| DWHLabelID | etoro.Dictionary.Label | LabelID | rename (= LabelID) |
| StatusID | -- | -- | ETL-computed: hardcoded 1 |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |
| InsertDate | -- | -- | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Dictionary.Label  (etoroDB-REAL)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Dictionary_Label
  |-- SP_Dictionaries_DL_To_Synapse (TRUNCATE + INSERT, daily) ---|
  v
DWH_dbo.Dim_Label  (26 rows)
  |-- Generic Pipeline (Override, 1440min, parquet) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_Label/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_label)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None -- leaf dimension table.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Customer account dimension tables | LabelID | Identifies the white-label brand for customer accounts |
| DWH_dbo.SP_Dictionaries_DL_To_Synapse | (loads this table) | Bulk dictionary ETL SP |

---

## 7. Sample Queries

### 7.1 List all active white-label brands

```sql
SELECT LabelID, Name
FROM [DWH_dbo].[Dim_Label]
ORDER BY LabelID;
```

### 7.2 Segment accounts by eToro-brand vs white-label

```sql
SELECT
    CASE
        WHEN l.LabelID IN (0, 1, 14, 29, 31) THEN 'eToro Brand'
        ELSE 'White-Label Partner'
    END AS BrandType,
    l.Name,
    COUNT(DISTINCT f.CustomerID) AS CustomerCount
FROM [DWH_dbo].[SomeFact] f
JOIN [DWH_dbo].[Dim_Label] l ON f.LabelID = l.LabelID
GROUP BY l.LabelID, l.Name
ORDER BY CustomerCount DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- Atlassian MCP not available in this session.)

---

*Generated: 2026-03-19 | Quality: 8.1/10 (★★★★☆) | Phases: 6/14 (Simple Dictionary Fast-Path)*
*Tiers: 2 T1, 4 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 6/6, Logic: 8/10, Relationships: 7/10, Sources: 9/10*
*Object: DWH_dbo.Dim_Label | Type: Table | Production Source: etoro.Dictionary.Label*
