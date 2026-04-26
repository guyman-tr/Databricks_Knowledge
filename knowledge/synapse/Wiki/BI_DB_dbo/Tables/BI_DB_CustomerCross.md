# BI_DB_dbo.BI_DB_CustomerCross

> 11.2M-row cross-asset-class first-action table tracking the earliest trade per customer (5.4M distinct RealCIDs) per detailed instrument category (Crypto, Real Stocks/ETFs, CFD Stocks/ETFs, FX/Commodities/Indices, Copy, Copy Fund) from August 2007 to present. Refreshed daily by SP_CustomerFirst5OpenPositions via incremental DELETE+INSERT for customers who opened positions yesterday.

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
| **Author** | Dan (2020-08-31), Cross section added 2020-09-16 |

---

## 1. Business Meaning

`BI_DB_CustomerCross` records the first time each customer ever traded in each detailed asset class. It answers "when did CID X first buy Crypto?" or "when did CID Y first use CopyTrader?". The grain is (RealCID, ActionType_Detailed) — one row per customer per asset category, with the earliest occurrence timestamp.

The table is populated by the "Cross Procedure" section of SP_CustomerFirst5OpenPositions. It processes only customers who opened at least one position yesterday and don't already have 5 actions logged. For each such customer, it classifies their actions by instrument type and copy status into 6 categories, then takes the MIN(Occurred) per category.

The classification uses a priority CASE chain: Crypto > FX/Commodities/Indices > Real Stocks/ETFs > CFD Stocks/ETFs > Copy Fund > Copy. The distinction between Real and CFD Stocks/ETFs depends on Leverage (1=Real if IsBuy=1) and direction (Sell=always CFD).

Sibling table: `BI_DB_CustomerCross_New` uses an alternative, coarser asset classification (ActionTypeNew).

---

## 2. Business Logic

### 2.1 ActionType_Detailed Classification

**What**: Each trade action is classified into exactly one of 6 detailed asset categories based on instrument type, leverage, direction, and copy status.
**Columns Involved**: `ActionType_Detailed`
**Rules**:
- InstrumentTypeID=10 → `Crypto`
- InstrumentTypeID IN (1,2,4) → `FX/Commodities/Indices`
- InstrumentTypeID IN (5,6), Leverage=1, IsBuy=1 → `Real Stocks/ETFs`
- InstrumentTypeID IN (5,6), Leverage>1 → `CFD Stocks/ETFs`
- InstrumentTypeID IN (5,6), IsBuy=0 → `CFD Stocks/ETFs`
- ParentCID is a CopyFund account (AccountTypeID=9, registered after 2016-01-01, or specific hardcoded CIDs) → `Copy Fund`
- MirrorID IS NOT NULL (and not Copy Fund) → `Copy`
- NULL if no classification matches (1 row observed)

### 2.2 First Occurrence Per Category

**What**: For each (RealCID, ActionType_Detailed) combination, only the earliest action is kept.
**Columns Involved**: `Occurred`, `OccurredDateID`
**Rules**:
- `Occurred = MIN(Occurred)` — earliest timestamp for that customer in that asset class
- `OccurredDateID = MIN(DateID)` — corresponding date integer

### 2.3 CopyFund Detection

**What**: Copy Fund positions are identified by checking if the copied trader (ParentCID from Dim_Mirror) is a known CopyFund account.
**Columns Involved**: `ActionType_Detailed`
**Rules**:
- CopyFund accounts: AccountTypeID=9 registered after 2016-01-01, plus 6 hardcoded CIDs (4657450, 4657433, 4657429, 4657444, 4657439, 4657462)
- CopyFund detection takes priority over generic Copy classification

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on OccurredDateID. Date-range queries are efficient. JOINs to Dim_Customer require data movement (not co-located).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| When did a customer first trade crypto? | `WHERE RealCID = @cid AND ActionType_Detailed = 'Crypto'` |
| How many customers tried each asset class? | `SELECT ActionType_Detailed, COUNT(DISTINCT RealCID) GROUP BY ActionType_Detailed` |
| Cross-selling funnel (% who tried 2+ asset classes) | Self-JOIN or GROUP BY RealCID HAVING COUNT(DISTINCT ActionType_Detailed) >= 2 |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID = RealCID | Customer demographics/segmentation |
| BI_DB_dbo.BI_DB_CustomerCross_New | RealCID = RealCID | Compare detailed vs coarse asset classification |
| BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions | RealCID = RealCID | Correlate first-cross with first 5 positions |

### 3.4 Gotchas

- **One blank/NULL ActionType_Detailed row exists**: 1 row has empty ActionType_Detailed — likely an edge case where no classification matched.
- **Copy Fund hardcoded CIDs**: Six specific CIDs are always treated as CopyFund accounts regardless of AccountTypeID. These are likely legacy/test CopyFund accounts.
- **IsBuy from Dim_Position, not Fact_CustomerAction**: The IsBuy flag used for Real vs CFD Stock/ETF classification comes from a LEFT JOIN to Dim_Position, which may be NULL if the position record is missing.
- **ActionTypeID filter**: Only actions with ActionTypeID IN (1=Open, 17=Copy Open) are included. Close, deposit, and other action types are excluded.

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
| 2 | ActionType_Detailed | varchar(22) | YES | Detailed asset class category of the customer's first trade. Values: Crypto, FX/Commodities/Indices, Real Stocks/ETFs, CFD Stocks/ETFs, Copy, Copy Fund. Derived from InstrumentTypeID, Leverage, IsBuy, and copy relationship status. (Tier 2 — SP_CustomerFirst5OpenPositions) |
| 3 | Occurred | datetime | YES | Timestamp of the customer's first trade in this asset class. MIN(Occurred) across all actions for the (RealCID, ActionType_Detailed) group. (Tier 2 — SP_CustomerFirst5OpenPositions) |
| 4 | OccurredDateID | int | YES | Date integer (YYYYMMDD) of the first trade in this asset class. MIN(DateID) across all actions for the group. Range: 20070827–20260412. (Tier 2 — SP_CustomerFirst5OpenPositions) |
| 5 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| RealCID | DWH_dbo.Fact_CustomerAction | RealCID | Passthrough |
| ActionType_Detailed | DWH_dbo.Dim_Instrument + Dim_Mirror | InstrumentTypeID, MirrorID | CASE classification chain |
| Occurred | DWH_dbo.Fact_CustomerAction | Occurred | MIN per group |
| OccurredDateID | DWH_dbo.Fact_CustomerAction | DateID | MIN per group |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (population: IsDepositor=1, IsValidCustomer=1)
  |-- #pop ---|
  v
BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions (exclude users with ActionNumber=5)
  |-- #exclude_users_with_5_actions_already ---|
  v
DWH_dbo.Dim_Position (OpenDateID=@yesterdayINT, IsAirDrop IS NULL)
  + DWH_dbo.Fact_CustomerAction (ActionTypeID IN (1,17))
  |-- #yesterdayactions ---|
  v
  + DWH_dbo.Dim_Instrument (InstrumentTypeID classification)
  + DWH_dbo.Dim_Mirror (MirrorID → ParentCID)
  + DWH_dbo.Dim_Customer (CopyFund accounts: AccountTypeID=9)
  |-- #actionType2 (ActionType_Detailed CASE) ---|
  v
  |-- #cross (MIN Occurred per RealCID, ActionType_Detailed) ---|
  v
BI_DB_dbo.BI_DB_CustomerCross (DELETE+INSERT)

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

### 7.1 Customer's First Asset Class Timeline

```sql
SELECT RealCID, ActionType_Detailed, Occurred
FROM BI_DB_dbo.BI_DB_CustomerCross
WHERE RealCID = 12345678
ORDER BY Occurred
```

### 7.2 Cross-Selling Penetration by Asset Class

```sql
SELECT ActionType_Detailed,
       COUNT(DISTINCT RealCID) AS customers
FROM BI_DB_dbo.BI_DB_CustomerCross
WHERE ActionType_Detailed IS NOT NULL AND ActionType_Detailed <> ''
GROUP BY ActionType_Detailed
ORDER BY customers DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14*
*Tiers: 1 T1, 3 T2, 0 T3, 0 T4, 1 T5 | Elements: 5/5, Logic: 9/10, Completeness: 10/10*
*Object: BI_DB_dbo.BI_DB_CustomerCross | Type: Table | Production Source: DWH_dbo dimensions+facts via SP_CustomerFirst5OpenPositions*
