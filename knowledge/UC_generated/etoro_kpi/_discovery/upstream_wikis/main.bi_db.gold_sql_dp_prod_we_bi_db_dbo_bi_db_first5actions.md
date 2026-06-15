# BI_DB_First5Actions

> Customer onboarding behavior profile. One row per depositor. Records the first five trading actions each customer took, the asset classes they touched, key revenue/deposit/equity milestones at 1/7/14/30/60/90/180/360-day windows post-FTD, and demographics from registration. The primary analytical use case is understanding "what did this customer do first after depositing?" — a critical input for activation and retention analysis. Used directly by SP_DepositUsersFirstTouchPoints.

**Schema**: BI_DB_dbo | **Object Type**: Table | **Quality**: 8.8/10

---

## Properties

| Property | Value |
|---|---|
| **Distribution** | HASH(CID) |
| **Index** | CLUSTERED INDEX (FirstDepositDate ASC) |
| **Row Count** | ~46.3M rows (one per depositor) |
| **FTD Range** | 1900-01-01 (sentinel) to 2026-04-12 |
| **NULL FirstAction** | ~88.3% (deposited but never traded within first 5 actions window) |
| **Writer SP** | SP_First5Actions |
| **Write Pattern** | TRUNCATE + INSERT (full refresh, no date parameter) |
| **UC Status** | Not Migrated |
| **LTV Column** | Disabled — hardcoded to 0 since 2022-06-02 |

---

## Business Context

`BI_DB_First5Actions` answers the question: *"What did this customer do first after depositing, and how did they perform in subsequent weeks/months?"*

The table is scoped to **depositors only** — the SP filters `BI_DB_CIDFirstDates WHERE FirstDepositDate IS NOT NULL`. Customers who registered but never deposited are excluded.

The 88.3% NULL `FirstAction` rate reflects that most depositors never open a trading position — they deposit money but do not actively trade within the system's tracking window for the first 5 position-opening actions.

The **cross columns** (`FirstCross`, `FirstCrossNew`, etc.) represent "asset class crossings" — each time a customer trades in a *different* asset class from their previous trade. The legacy series (`FirstCross..FifthCross`) uses the older `BI_DB_CustomerCross` source; the new series (`FirstCrossNew..FifthCrossNew`) uses `BI_DB_CustomerCross_New` with the updated `ActionTypeNew` taxonomy.

**Action type taxonomies**:
| Column Group | Values |
|---|---|
| FirstAction..FifthAction (coarse) | Crypto, FX/Commodities/Indices, Stocks/ETFs, Copy, Copy Fund |
| FirstActionTypeNew (mid-level) | Crypto, FX/Commodities, Stocks/ETFs/Indices, Copy, Copy Fund |
| FirstAction_Detailed (granular) | Crypto, FX/Commodities/Indices, Real Stocks/ETFs, CFD Stocks/ETFs, Copy, Copy Fund |
| FirstCross..FifthCross (legacy) | Same as ActionType_Detailed |
| FirstCrossNew..FifthCrossNew (new) | Same as ActionTypeNew |

**Real vs CFD Stocks distinction** (FirstAction_Detailed only):
- Real Stocks/ETFs = `InstrumentTypeID IN (5,6) AND Leverage=1 AND IsBuy=1`
- CFD Stocks/ETFs = `InstrumentTypeID IN (5,6) AND (Leverage>1 OR IsBuy=0)`

---

## Column Elements

### Identity & Acquisition

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 1 | CID | int | NO | Tier 1 | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 2 | AffiliateID | int | YES | Tier 1 | Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. (Tier 1 — Customer.CustomerStatic) |
| 7 | Channel | nvarchar(500) | NO | Tier 2 | Marketing acquisition channel. Passed through from BI_DB_CIDFirstDates.Channel (resolved via Dim_Affiliate → Dim_Channel). ISNULL(,'Direct'). Values: Direct, Affiliate, SEM, etc. |
| 8 | SubChannel | nvarchar(500) | NO | Tier 2 | Marketing sub-channel. Passed through from BI_DB_CIDFirstDates.SubChannel. ISNULL(,'Direct'). Values: Direct, Google Brand, Affiliate, etc. |

### Geography

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 5 | Region | nvarchar(500) | NO | Tier 2 | Marketing region at time of registration. From BI_DB_CIDFirstDates.Region (Dim_Country.Region). Values: North Europe, French, Eastern Europe, LATAM, etc. |
| 6 | Country | varchar(500) | YES | Tier 2 | Country of residence name in English. From BI_DB_CIDFirstDates.Country (Dim_Country.Name via CountryID). |
| 75 | NewMarketingRegion | varchar(50) | YES | Tier 2 | Updated marketing region grouping. From BI_DB_CIDFirstDates.NewMarketingRegion (Dim_Country.MarketingRegionManualName). Introduced 2021-02-10. Preferred over Region for current segmentation. |

### First Deposit

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 3 | FirstDepositDate | datetime | YES | Tier 2 | Date and time of customer's first successful deposit. From BI_DB_CIDFirstDates.FirstDepositDate (Dim_Customer.FirstDepositDate ← CustomerFinanceDB.FirstTimeDeposits). 1900-01-01 = no deposit (sentinel — these rows exist in CIDFirstDates but are filtered out by this SP). |
| 4 | FirstDepositAmount | money | YES | Tier 2 | Amount in USD of customer's first deposit. From BI_DB_CIDFirstDates.FirstDepositAmount (Dim_Customer.FirstDepositAmount ← CustomerFinanceDB.FirstTimeDeposits). YTD avg ~$696. Default 0 for $0 deposits. |

### First Action (coarse classification)

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 9 | FirstAction | varchar(22) | YES | Tier 2 | Asset class of the customer's 1st open position. CASE on InstrumentTypeID+MirrorID: 'Crypto' (typeID=10), 'FX/Commodities/Indices' (1/2/4), 'Stocks/ETFs' (5/6), 'Copy Fund' (CopyFund manager), 'Copy'. NULL if no position opened (~88.3%). Distribution: Crypto 5.3%, Stocks/ETFs 3.6%, Copy 1.4%, FX/Commodities/Indices 1.3%, Copy Fund 0.1%. |
| 10 | FirstActionDate | datetime | YES | Tier 2 | Datetime of 1st open position. From BI_DB_CustomerCross PIVOT (rn=1, MAX(Occurred)). |
| 11 | FirstInstrument | varchar(50) | YES | Tier 2 | Display name of the first traded instrument. ISNULL(ParentUserName, InstrumentName): for Copy positions, shows the copied trader's username; for direct trades, shows Dim_Instrument.Name. |
| 12 | SecondAction | varchar(22) | YES | Tier 2 | Asset class of 2nd open position. Same CASE as FirstAction. NULL if fewer than 2 positions. |
| 13 | SecondInstrument | varchar(50) | YES | Tier 2 | Display name for 2nd position (same pattern as FirstInstrument). |
| 14 | ThirdAction | varchar(22) | YES | Tier 2 | Asset class of 3rd open position. |
| 15 | ThirdInstrument | varchar(50) | YES | Tier 2 | Display name for 3rd position. |
| 16 | FourthAction | varchar(22) | YES | Tier 2 | Asset class of 4th open position. |
| 17 | FourthInstrument | varchar(50) | YES | Tier 2 | Display name for 4th position. |
| 18 | FifthAction | varchar(22) | YES | Tier 2 | Asset class of 5th open position. |
| 19 | FifthInstrument | varchar(50) | YES | Tier 2 | Display name for 5th position. |

### Action Dates & Leverages (2nd–5th)

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 35 | FirstLeverage | int | YES | Tier 2 | Leverage used for 1st open position. From BI_DB_CustomerFirst5OpenPositions.Leverage, rank=1. 1 = real (unlevered) stock purchase. >1 = CFD/leveraged position. |
| 36 | SecondActionDate | date | YES | Tier 2 | Date of 2nd open position (Occurred, rank=2). |
| 37 | ThirdActionDate | date | YES | Tier 2 | Date of 3rd open position (rank=3). |
| 38 | FourthActionDate | date | YES | Tier 2 | Date of 4th open position (rank=4). |
| 39 | FifthActionDate | date | YES | Tier 2 | Date of 5th open position (rank=5). |
| 40 | SecondLeverage | int | YES | Tier 2 | Leverage for 2nd position (rank=2). |
| 41 | ThirdLeverage | int | YES | Tier 2 | Leverage for 3rd position (rank=3). |
| 42 | FourthLeverage | int | YES | Tier 2 | Leverage for 4th position (rank=4). |
| 43 | FifthLeverage | int | YES | Tier 2 | Leverage for 5th position (rank=5). |

### Detailed Action Classification

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 44 | FirstAction_Detailed | varchar(50) | YES | Tier 2 | Granular asset class for 1st position. Distinguishes 'Real Stocks/ETFs' (Leverage=1, IsBuy=1) from 'CFD Stocks/ETFs' (Leverage>1 or IsBuy=0). Values: Crypto, FX/Commodities/Indices, Real Stocks/ETFs, CFD Stocks/ETFs, Copy, Copy Fund. |
| 69 | SecondAction_Detailed | varchar(22) | YES | Tier 2 | Granular asset class for 2nd position (same schema as FirstAction_Detailed). |
| 70 | ThirdAction_Detailed | varchar(22) | YES | Tier 2 | Granular asset class for 3rd position. |
| 71 | FourthAction_Detailed | varchar(22) | YES | Tier 2 | Granular asset class for 4th position. |
| 72 | FifthAction_Detailed | varchar(22) | YES | Tier 2 | Granular asset class for 5th position. |
| 76 | FirstActionTypeNew | nvarchar(50) | YES | Tier 2 | First position asset class using the new 3-way taxonomy. CASE on ActionTypeNew: 'Crypto', 'FX/Commodities' (typeID 1/2), 'Stocks/ETFs/Indices' (typeID 4/5/6), 'Copy Fund', 'Copy'. Merges Indices into Stocks bucket vs. legacy. |

### Traded Asset Flags

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 20 | Traded_FX/Commodities/Indices | int | YES | Tier 2 | 1 if FirstAction or any of the 5 cross positions = 'FX/Commodities/Indices'. 0 otherwise. Useful for "ever touched FX" segmentation. |
| 21 | Traded_Stocks/ETFs | int | YES | Tier 2 | 1 if FirstAction or any cross = 'Stocks/ETFs', 'Real Stocks/ETFs', or 'CFD Stocks/ETFs'. 0 otherwise. |
| 22 | TradedCrypto | int | YES | Tier 2 | 1 if FirstAction or any cross = 'Crypto'. 0 otherwise. |
| 23 | TradedCopy | int | YES | Tier 2 | 1 if FirstAction or any cross = 'Copy'. 0 otherwise. |
| 24 | TradedCopyFund | int | YES | Tier 2 | 1 if FirstAction or any cross = 'Copy Fund'. 0 otherwise. |

### Legacy Cross-Asset Sequence (BI_DB_CustomerCross)

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 25 | FirstCross | varchar(22) | YES | Tier 2 | Detailed asset class of 1st position (legacy). From BI_DB_CustomerCross PIVOT (ActionType_Detailed, rn=1). Same values as FirstAction_Detailed. ~6.5% non-NULL. |
| 26 | FirstCrossDate | datetime | YES | Tier 2 | Datetime of 1st cross event (from BI_DB_CustomerCross.Occurred, rn=1). |
| 27 | SecondCross | varchar(22) | YES | Tier 2 | Detailed asset class of 2nd cross position (rn=2). |
| 28 | SecondCrossDate | datetime | YES | Tier 2 | Datetime of 2nd cross (rn=2). |
| 29 | ThirdCross | varchar(22) | YES | Tier 2 | Detailed asset class of 3rd cross (rn=3). |
| 30 | ThirdCrossDate | datetime | YES | Tier 2 | Datetime of 3rd cross (rn=3). |
| 31 | FourthCross | varchar(22) | YES | Tier 2 | Detailed asset class of 4th cross (rn=4). |
| 32 | FourthCrossDate | datetime | YES | Tier 2 | Datetime of 4th cross (rn=4). |
| 73 | FifthCross | varchar(22) | YES | Tier 2 | Detailed asset class of 5th cross (rn=5). |
| 74 | FifthCrossDate | datetime | YES | Tier 2 | Datetime of 5th cross (rn=5). |

### New Cross-Asset Sequence (BI_DB_CustomerCross_New)

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 86 | FirstCrossNew | nvarchar(50) | YES | Tier 2 | Asset class of 1st position using new ActionTypeNew taxonomy (BI_DB_CustomerCross_New, rn=1). Values: Crypto, FX/Commodities, Stocks/ETFs/Indices, Copy, Copy Fund. Preferred over FirstCross for new analyses. |
| 77 | FirstCrossDateNew | date | YES | Tier 2 | Date of 1st new-taxonomy cross (BI_DB_CustomerCross_New.Occurred, rn=1). |
| 78 | SecondCrossNew | nvarchar(50) | YES | Tier 2 | 2nd cross position (new taxonomy, rn=2). |
| 79 | SecondCrossDateNew | date | YES | Tier 2 | Date of 2nd new cross (rn=2). |
| 80 | ThirdCrossNew | nvarchar(50) | YES | Tier 2 | 3rd cross position (rn=3). |
| 81 | ThirdCrossDateNew | date | YES | Tier 2 | Date of 3rd new cross (rn=3). |
| 82 | FourthCrossNew | nvarchar(50) | YES | Tier 2 | 4th cross position (rn=4). |
| 83 | FourthCrossDateNew | date | YES | Tier 2 | Date of 4th new cross (rn=4). |
| 84 | FifthCrossNew | nvarchar(50) | YES | Tier 2 | 5th cross position (rn=5). |
| 85 | FifthCrossDateNew | date | YES | Tier 2 | Date of 5th new cross (rn=5). |

### Revenue Windows (post-FTD)

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 45 | Revenue1day | decimal(38,2) | YES | Tier 2 | Company revenue from this customer in the 1 day following FTD. From BI_DB_CID_BalanceDays. NULL if elapsed days since FTD < 0. |
| 46 | Revenue7days | decimal(38,2) | YES | Tier 2 | Revenue in 7 days post-FTD. NULL if < 6 days elapsed. |
| 47 | Revenue14days | decimal(38,2) | YES | Tier 2 | Revenue in 14 days post-FTD. NULL if < 13 days elapsed. |
| 48 | Revenue30days | decimal(38,2) | YES | Tier 2 | Revenue in 30 days post-FTD. NULL if < 29 days elapsed. ~10% populated; min=-$15,567, max=$1.54M, avg=$68.80. |
| 49 | Revenue60days | decimal(38,2) | YES | Tier 2 | Revenue in 60 days post-FTD. NULL if < 59 days. |
| 50 | Revenue90days | decimal(38,2) | YES | Tier 2 | Revenue in 90 days post-FTD. NULL if < 89 days. |
| 51 | Revenue180days | decimal(38,2) | YES | Tier 2 | Revenue in 180 days post-FTD. NULL if < 179 days. |
| 52 | Revenue360days | decimal(38,2) | YES | Tier 2 | Revenue in 360 days post-FTD. Sourced from BI_DB_CID_BalanceDays.Revenue365days (column name mismatch). NULL if < 364 days elapsed. |

### Deposit Windows (post-FTD)

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 53 | Deposit1day | decimal(38,2) | YES | Tier 2 | Total deposit amount in 1 day post-FTD. From BI_DB_CID_BalanceDays.Deposit1day. |
| 54 | Deposit7days | decimal(38,2) | YES | Tier 2 | Total deposits in 7 days post-FTD (includes FTD itself). NULL if < 6 days elapsed. |
| 55 | Deposit14days | decimal(38,2) | YES | Tier 2 | Total deposits in 14 days post-FTD. |
| 56 | Deposit30days | decimal(38,2) | YES | Tier 2 | Total deposits in 30 days post-FTD. ~12.6% populated. |
| 57 | Deposit60days | decimal(38,2) | YES | Tier 2 | Total deposits in 60 days post-FTD. |
| 58 | Deposit90days | decimal(38,2) | YES | Tier 2 | Total deposits in 90 days post-FTD. |
| 59 | Deposit180days | decimal(38,2) | YES | Tier 2 | Total deposits in 180 days post-FTD. |
| 60 | Deposit360days | decimal(38,2) | YES | Tier 2 | Total deposits in 360 days post-FTD. Sourced from BI_DB_CID_BalanceDays.Deposit365days. |

### Equity Windows (post-FTD)

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 61 | Equity1day | decimal(38,4) | YES | Tier 2 | Account equity snapshot 1 day post-FTD. From BI_DB_CID_BalanceDays.Equity1day. |
| 62 | Equity7days | decimal(38,4) | YES | Tier 2 | Equity 7 days post-FTD. NULL if < 6 days elapsed. |
| 63 | Equity14days | decimal(38,4) | YES | Tier 2 | Equity 14 days post-FTD. |
| 64 | Equity30days | decimal(38,4) | YES | Tier 2 | Equity 30 days post-FTD. ~12.6% populated. |
| 65 | Equity60days | decimal(38,4) | YES | Tier 2 | Equity 60 days post-FTD. |
| 66 | Equity90days | decimal(38,4) | YES | Tier 2 | Equity 90 days post-FTD. |
| 67 | Equity180days | decimal(38,4) | YES | Tier 2 | Equity 180 days post-FTD. |
| 68 | Equity360days | decimal(38,4) | YES | Tier 2 | Equity 360 days post-FTD. Sourced from BI_DB_CID_BalanceDays.Equity365days. |

### Metadata

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 33 | UpdateDate | datetime | NO | Tier 2 | Timestamp of SP execution that wrote this row. GETDATE() at INSERT time. |
| 34 | LTV | float | YES | Tier 2 | **DISABLED** — hardcoded to 0 for all rows since 2022-06-02 (Jan change). Previously intended to store lifetime value. Do not use. |

---

## ETL Pipeline

```
BI_DB_CIDFirstDates (WHERE FirstDepositDate IS NOT NULL)
  ├─ demographics: CID, AffiliateID, FTD dates/amounts, Channel, SubChannel, Region, Country
  │
BI_DB_CustomerFirst5OpenPositions (ActionNumber IN 1..5)
  ├─ + Dim_Instrument (InstrumentTypeID → ActionType CASE)
  ├─ + Dim_Mirror (MirrorID → ParentUserName for Copy)
  ├─ + Dim_Customer (AccountTypeID=9 → Copy Fund IDs)
  │     → #Actions2 (pivot 5 actions per customer with types)
  │
BI_DB_CustomerCross → #final (legacy cross sequence)
BI_DB_CustomerCross_New → #final2 (new cross sequence)
BI_DB_CID_BalanceDays → Revenue/Deposit/Equity 1d..360d windows
  │
  |-- SP_First5Actions (TRUNCATE + full INSERT) --|
  v
BI_DB_dbo.BI_DB_First5Actions (46.3M rows, one per depositor)
  |-- UC: Not Migrated --|
```

---

## Sample Queries

```sql
-- First-action distribution for 2024 depositors
SELECT
    ISNULL(FirstAction, 'No Trade') AS first_action,
    COUNT(*) AS cnt,
    CAST(100.0 * COUNT(*) / SUM(COUNT(*)) OVER () AS DECIMAL(5,1)) AS pct
FROM BI_DB_dbo.BI_DB_First5Actions
WHERE FirstDepositDate >= '2024-01-01' AND YEAR(FirstDepositDate) != 1900
GROUP BY FirstAction
ORDER BY cnt DESC;
```

```sql
-- Revenue 30 days after FTD by first action type
SELECT
    ISNULL(FirstAction, 'No Trade') AS first_action,
    COUNT(*) AS depositors,
    AVG(Revenue30days) AS avg_rev_30d,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY Revenue30days)
        OVER (PARTITION BY FirstAction) AS median_rev_30d
FROM BI_DB_dbo.BI_DB_First5Actions
WHERE Revenue30days IS NOT NULL
GROUP BY FirstAction
ORDER BY avg_rev_30d DESC;
```

```sql
-- Cross-asset rate: what % traded multiple asset classes?
SELECT
    ISNULL(FirstAction, 'No Trade') AS first_action,
    COUNT(*) AS total,
    SUM(CASE WHEN SecondCrossNew IS NOT NULL THEN 1 ELSE 0 END) AS crossed_once,
    SUM(CASE WHEN ThirdCrossNew IS NOT NULL THEN 1 ELSE 0 END) AS crossed_twice
FROM BI_DB_dbo.BI_DB_First5Actions
GROUP BY FirstAction;
```

---

## Relationships

| Related Object | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Country, regulation, player level enrichment |
| BI_DB_dbo.BI_DB_CIDFirstDates | ON CID = CID | Upstream demographics source |
| BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions | ON CID = RealCID | Source for first 5 actions |
| BI_DB_dbo.BI_DB_CID_BalanceDays | ON CID = CID | Revenue/Deposit/Equity window metrics |
| BI_DB_dbo.BI_DB_DepositUsersFirstTouchPoints | ON CID = CID | Downstream consumer |
