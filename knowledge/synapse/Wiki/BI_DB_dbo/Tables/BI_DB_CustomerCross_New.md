# BI_DB_dbo.BI_DB_CustomerCross_New

> 10.1M-row cross-asset-class first-action table tracking the earliest trade per customer per coarse instrument category (Crypto, FX/Commodities, Stocks/ETFs/Indices, Copy, Copy Fund) from August 2007 to present. Sibling of BI_DB_CustomerCross with an alternative, simplified asset grouping. Refreshed daily by SP_CustomerFirst5OpenPositions.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_CustomerAction + DWH_dbo.Dim_Instrument + DWH_dbo.Dim_Mirror via SP_CustomerFirst5OpenPositions |
| **Refresh** | Daily (SB_Daily, Priority 0). Incremental: DELETE+INSERT for customers with new positions yesterday |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (OccurredDateID ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Dan (2020-08-31), Cross New added 2021-02-21 |

---

## 1. Business Meaning

`BI_DB_CustomerCross_New` records the first time each customer ever traded in each coarse asset class. It is the sibling of `BI_DB_CustomerCross`, using an alternative grouping (`ActionTypeNew`) that merges some detailed categories:
- Stocks, ETFs, and Indices are combined into one group (vs. separate Real/CFD split in CustomerCross)
- FX and Commodities are separated from Indices (vs. combined in CustomerCross)

The grain is (RealCID, ActionTypeNew) — one row per customer per coarse asset category, with the earliest occurrence timestamp. The table is populated by the same SP_CustomerFirst5OpenPositions that writes CustomerCross, using the same population and action data but a different CASE classification.

---

## 2. Business Logic

### 2.1 ActionTypeNew Classification

**What**: Each trade action is classified into one of 5 coarse asset categories. This is a simplified alternative to ActionType_Detailed.
**Columns Involved**: `ActionTypeNew`
**Rules**:
- InstrumentTypeID=10 → `Crypto`
- InstrumentTypeID IN (1,2) → `FX/Commodities` (note: excludes type 4 = Indices)
- InstrumentTypeID IN (4,5,6) → `Stocks/ETFs/Indices` (note: includes Indices, no Real/CFD split)
- ParentCID is a CopyFund account → `Copy Fund`
- MirrorID IS NOT NULL → `Copy`

### 2.2 Key Difference from CustomerCross

**What**: ActionTypeNew groups assets differently from ActionType_Detailed.
**Rules**:
- Indices (InstrumentTypeID=4): In CustomerCross → FX/Commodities/Indices. In CustomerCross_New → Stocks/ETFs/Indices
- Stocks/ETFs: In CustomerCross → split into Real vs CFD based on Leverage/IsBuy. In CustomerCross_New → combined into Stocks/ETFs/Indices
- FX (type 1) + Commodities (type 2): In CustomerCross → combined with Indices. In CustomerCross_New → FX/Commodities only (no Indices)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on OccurredDateID. Same layout as CustomerCross.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| How many customers have traded Stocks/ETFs/Indices? | `SELECT COUNT(DISTINCT RealCID) WHERE ActionTypeNew = 'Stocks/ETFs/Indices'` |
| Compare coarse vs detailed cross-selling | JOIN with BI_DB_CustomerCross on RealCID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID = RealCID | Customer demographics |
| BI_DB_dbo.BI_DB_CustomerCross | RealCID = RealCID | Compare detailed vs coarse classification |

### 3.4 Gotchas

- **One blank ActionTypeNew row**: 1 row has empty ActionTypeNew — same edge case as CustomerCross.
- **Indices grouping differs from CustomerCross**: Indices (type 4) are grouped with Stocks/ETFs here, but with FX/Commodities in CustomerCross. Use the appropriate table based on the analysis need.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest |
| Tier 2 | SP code analysis | High |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | NO | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | ActionTypeNew | varchar(22) | YES | Coarse asset class category of the customer's first trade. Values: Crypto, FX/Commodities, Stocks/ETFs/Indices, Copy, Copy Fund. Alternative grouping to ActionType_Detailed in BI_DB_CustomerCross. (Tier 2 — SP_CustomerFirst5OpenPositions) |
| 3 | Occurred | datetime | YES | Timestamp of the customer's first trade in this coarse asset class. MIN(Occurred) across all actions for the (RealCID, ActionTypeNew) group. (Tier 2 — SP_CustomerFirst5OpenPositions) |
| 4 | OccurredDateID | int | YES | Date integer (YYYYMMDD) of the first trade in this asset class. MIN(DateID) across all actions for the group. (Tier 2 — SP_CustomerFirst5OpenPositions) |
| 5 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | DWH_dbo.Fact_CustomerAction | RealCID | Passthrough |
| ActionTypeNew | DWH_dbo.Dim_Instrument + Dim_Mirror | InstrumentTypeID, MirrorID | CASE classification (coarse) |
| Occurred | DWH_dbo.Fact_CustomerAction | Occurred | MIN per group |
| OccurredDateID | DWH_dbo.Fact_CustomerAction | DateID | MIN per group |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (population)
  + DWH_dbo.Dim_Position (yesterday's opens)
  + DWH_dbo.Fact_CustomerAction (ActionTypeID IN (1,17))
  |-- #yesterdayactions ---|
  v
  + DWH_dbo.Dim_Instrument (InstrumentTypeID)
  + DWH_dbo.Dim_Mirror (MirrorID → ParentCID)
  |-- #actionType2 (ActionTypeNew CASE) ---|
  v
  |-- #crossnew (MIN Occurred per RealCID, ActionTypeNew) ---|
  v
BI_DB_dbo.BI_DB_CustomerCross_New (DELETE+INSERT)

UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension |

### 6.2 Referenced By (other objects point to this)

No known consumers identified in this batch.

---

## 7. Sample Queries

### 7.1 Cross-Selling Penetration by Coarse Asset Class

```sql
SELECT ActionTypeNew,
       COUNT(DISTINCT RealCID) AS customers
FROM BI_DB_dbo.BI_DB_CustomerCross_New
WHERE ActionTypeNew IS NOT NULL AND ActionTypeNew <> ''
GROUP BY ActionTypeNew
ORDER BY customers DESC
```

### 7.2 Customers Who Tried Multiple Asset Classes

```sql
SELECT RealCID, COUNT(DISTINCT ActionTypeNew) AS asset_classes
FROM BI_DB_dbo.BI_DB_CustomerCross_New
WHERE ActionTypeNew IS NOT NULL AND ActionTypeNew <> ''
GROUP BY RealCID
HAVING COUNT(DISTINCT ActionTypeNew) >= 3
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 1 T1, 3 T2, 0 T3, 0 T4, 1 T5 | Elements: 5/5, Logic: 9/10, Completeness: 10/10*
*Object: BI_DB_dbo.BI_DB_CustomerCross_New | Type: Table | Production Source: DWH_dbo dimensions+facts via SP_CustomerFirst5OpenPositions*
