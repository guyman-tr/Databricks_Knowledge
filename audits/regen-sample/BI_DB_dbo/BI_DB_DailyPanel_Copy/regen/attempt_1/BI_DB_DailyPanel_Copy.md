# BI_DB_dbo.BI_DB_DailyPanel_Copy

> 12.7M-row daily panel table tracking every active Popular Investor (PI), Smart Portfolio, and formerly-removed PI on the eToro platform -- capturing demographic attributes, equity/liability positions, copy-trading metrics (AUC, copiers, MIMO), portfolio composition, risk scores, and multi-horizon performance gains for each CID per snapshot date. Data spans Oct 2021 to present (~15,975 CIDs/day). Refreshed daily by SP_DailyPanel_Copy via DELETE+INSERT by DateID.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | ETL-computed by SP_DailyPanel_Copy from 15+ DWH/BI_DB source tables |
| **Refresh** | Daily -- DELETE WHERE DateID = @date_int, then INSERT from #final temp table |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | _Not_Migrated |
| **UC Format** | -- |
| **UC Partitioned By** | -- |
| **UC Table Type** | -- |

---

## 1. Business Meaning

`BI_DB_DailyPanel_Copy` is a daily operational panel for the eToro Popular Investor (PI) and Smart Portfolio programs. Each row represents one CID on one snapshot date and provides a 360-degree view of that copy-trading entity: who they are (demographics, regulation, club tier), how they are performing (equity, gains, risk score), who is copying them (copier count, AUC, PnL), what they trade (asset classification, top instruments, leverage profile), and how they engage (BIO length, avatar, privacy settings).

The table covers three populations:
- **PI** (5,162 per day): Active Popular Investors with GuruStatusID IN (2,3,4,5,6) AND IsValidCustomer=1
- **Portfolio** (5,431 per day): Smart Portfolio fund accounts (AccountTypeID=9)
- **RemovedPI** (5,382 per day): Customers who were formerly PIs (historical max GuruStatusID IN (2,3,4,5,6)) but are no longer active PIs

The SP builds this panel through a complex multi-step process: first identifying the population from `Fact_SnapshotCustomer` (using the DateRangeID SCD2 pattern), then enriching each CID with data from `Dim_Customer`, `V_Liabilities`, `etoroGeneral_History_GuruCopiers`, `Fact_CustomerAction` (MIMO), `Dim_Position` (trading activity), `BI_DB_PositionPnL` (leverage/value metrics), `DWH_CIDsDailyRisk` (risk score), `DWH_GainDaily` (performance), and several external staging tables (blocked operations, publications, customer settings).

As of 2026-04-25: 12,748,498 total rows, 15,975 distinct CIDs on the latest date, data from 2021-10-01 to 2026-04-25.

---

## 2. Business Logic

### 2.1 Population Selection — Three CopyTypes

**What**: The SP identifies three distinct populations that together form the daily panel.

**Columns Involved**: `CopyType`, `GuruStatusID`, `AccountTypeID`

**Rules**:
- **PI**: From `Fact_SnapshotCustomer` where `GuruStatusID IN (2,3,4,5,6)` AND `IsValidCustomer=1` on the snapshot date (DateRangeID filter). These are active Popular Investors.
- **Portfolio**: From `Fact_SnapshotCustomer` where `AccountTypeID=9` on the snapshot date. These are Smart Portfolio fund accounts.
- **RemovedPI**: Customers NOT in the PI population above, but whose historical `MAX(GuruStatusID) IN (2,3,4,5,6)` across all Fact_SnapshotCustomer history. These were once PIs but no longer hold active PI status. Their current-day snapshot attributes are joined back from Fact_SnapshotCustomer.

**Distribution** (2026-04-25): PI=5,162 (32.3%), Portfolio=5,431 (34.0%), RemovedPI=5,382 (33.7%).

### 2.2 TotalEquity Computation

**What**: Customer total balance from V_Liabilities.

**Columns Involved**: `TotalEquity`, `RealizedEquity`, `TotalPositionsAmount`, `PositionPnL`, `Credit`

**Rules**:
- `TotalEquity = ISNULL(Liabilities, 0) + ISNULL(ActualNWA, 0)` from V_Liabilities for the snapshot date
- This equals `RealizedEquity + PositionPnL` (see V_Liabilities wiki)
- `RealizedEquity`, `TotalPositionsAmount`, `PositionPnL`, and `Credit` are direct passthroughs from V_Liabilities

### 2.3 CopyAUC and NumOfCopiers

**What**: Aggregated copy-trading metrics from GuruCopiers history.

**Columns Involved**: `CopyAUC`, `CopyPnL`, `NumOfCopiers`

**Rules**:
- Source: `etoroGeneral_History_GuruCopiers` where `Timestamp = @datetimeToday` (day after @date)
- Only counts copiers who are valid depositors (`IsValidCustomer=1 AND IsDepositor=1`)
- `CopyAUC = SUM(Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL)` per ParentCID
- `CopyPnL = SUM(PnL + DetachedPosInvestment + Dit_PnL)` per ParentCID
- `NumOfCopiers = COUNT(CID)` per ParentCID

### 2.4 MIMO (Mirror In / Mirror Out)

**What**: Daily money flow into and out of copy relationships.

**Columns Involved**: `MI`, `MO`, `NetMI`

**Rules**:
- Source: `Fact_CustomerAction` joined to `Dim_Mirror` on MirrorID, filtered to `DateID = @date_int`
- `MI = SUM(-Amount) WHERE ActionTypeID IN (15, 17)` (Account-to-Mirror + Register New Mirror)
- `MO = SUM(Amount) WHERE ActionTypeID IN (16, 18)` (Mirror-to-Account + Unregister Mirror)
- `NetMI = SUM(-Amount)` for all mirror actions (15, 16, 17, 18)
- Only counts copiers who are valid depositors

### 2.5 Classification — Portfolio Asset Allocation

**What**: Classifies each PI/Portfolio by dominant asset class based on open positions.

**Columns Involved**: `Classification`

**Rules**:
```
Classification = CASE
  WHEN Equity_Percent >= 0.7 AND Equity_Buy >= 0.2 AND Equity_Short >= 0.2 THEN 'Long/Short Equity'
  WHEN Equity_Percent >= 0.7 AND Equity_Buy > 0.8 THEN 'Long Equity'
  WHEN Currencies_Percent >= 0.7 THEN 'Currencies'
  WHEN Commodities_Percent >= 0.7 THEN 'Commodities'
  WHEN Crypto_Percent >= 0.7 THEN 'Crypto'
  WHEN ETF_Percent >= 0.7 THEN 'ETF'
  WHEN Total_invest = 0 THEN '100% cash balance'
  ELSE 'Multi-Asset'
END
```
**Distribution** (2026-04-25): 100% cash balance=7,877, Long Equity=4,362, Multi-Asset=1,647, Crypto=1,248, ETF=671, Currencies=64, Commodities=53, Long/Short Equity=53.

### 2.6 RiskScore — Bucket Lookup

**What**: Maps daily portfolio risk (AvgSTD) to a discrete 1-10 risk score.

**Columns Involved**: `RiskScore`

**Rules**:
- Source: `DWH_CIDsDailyRisk.AvgSTD` for the snapshot date
- Lookup: `External_etoro_Internal_RiskScore` table maps AvgSTD ranges to RiskScore buckets
- `MAX(RiskScore)` per CID (in case of multiple matches due to rounding)

### 2.7 HoldsHighLevPosition — High Leverage Flag

**What**: Identifies PIs holding leveraged positions exceeding regulatory thresholds for >30 days.

**Columns Involved**: `HoldsHighLevPosition`, `HighLevHoldingDetail`, `BuyPercent`, `SellPercent`

**Rules**:
- Only considers positions open >30 days (`OpenDateID <= @PrevDateINT30`) with Leverage >= 5
- High-lev thresholds by asset class:
  - Stocks/ETF (InstrumentTypeID 5,6): Leverage >= 5
  - Indices (InstrumentTypeID 4): Leverage >= 10
  - Currencies/Commodities (InstrumentTypeID 1,2): Leverage >= 20
- `BuyPercent` / `SellPercent` are computed ONLY among these high-lev positions (not all positions)
- `HighLevHoldingDetail` = STRING_AGG of "Leverage-InstrumentType" pairs for flagged positions

### 2.8 Seniority and DaysAsPI

**What**: Tenure metrics for the PI/Portfolio.

**Columns Involved**: `Seniority`, `DaysAsPI`, `MonthsSinceFirstOpen`

**Rules**:
- `Seniority = DATEDIFF(MONTH, FirstDepositDate, first-of-month(@date))` from Dim_Customer
- `DaysAsPI = DATEDIFF(DAY, MIN(FullDate where GuruStatusID>=2), @date)` from Fact_SnapshotCustomer + Dim_Range + Dim_Date
- `MonthsSinceFirstOpen = DATEDIFF(Month, MIN(FirstOccurred), @date)` from Fact_FirstCustomerAction where ActionTypeID IN (1,2,17)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN distribution with HEAP. No clustered index. With 12.7M rows, always filter by `DateID` for efficient queries. ROUND_ROBIN means JOINs on CID will require data movement -- consider filtering to a single DateID first, then joining.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current panel for all PIs | `WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_DailyPanel_Copy) AND CopyType = 'PI'` |
| A specific PI's history | `WHERE CID = @cid ORDER BY DateID` |
| Top PIs by copier count | `WHERE DateID = @date AND CopyType = 'PI' ORDER BY NumOfCopiers DESC` |
| Active PIs by classification | `WHERE DateID = @date AND CopyType = 'PI' GROUP BY Classification` |
| Portfolio performance | `WHERE DateID = @date AND CopyType = 'Portfolio'` |
| Removed PIs tracking | `WHERE CopyType = 'RemovedPI' AND DateID = @date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Additional customer attributes not in panel |
| DWH_dbo.Dim_GuruStatus | ON GuruStatusID | Guru tier name (already denormalized as GuruStatus) |
| BI_DB_dbo.DWH_GainDaily | ON CID AND Date | Additional gain horizons not in panel |
| DWH_dbo.V_Liabilities | ON CID AND DateID | Full liability breakdown |

### 3.4 Gotchas

- **BuyPercent/SellPercent are NOT overall portfolio buy/sell ratios**: They are computed ONLY among high-leverage positions held >30 days (`Leverage >= 5`, `OpenDateID <= @PrevDateINT30`). If a PI has no qualifying high-lev positions, both will be NULL.
- **CopyType 'RemovedPI' includes current-day attributes**: RemovedPI rows still have current-day snapshot data from Fact_SnapshotCustomer -- they are NOT frozen at the time of PI removal.
- **GuruStatus 'No' dominates**: 10,810 of 15,975 rows (67.7%) have GuruStatus='No'. This includes all Portfolio accounts (AccountTypeID=9) and all RemovedPIs whose current GuruStatusID=0.
- **Value_percenet has a typo**: Column name is "Value_percenet" (not "Value_percent"). Use the exact DDL name.
- **AvgerageHoldingTime has a typo**: Column name is "AvgerageHoldingTime" (not "AverageHoldingTime"). Use the exact DDL name.
- **Seniority is months since first deposit**: Not months since registration. PIs who never deposited will have NULL Seniority.
- **TotalDaysInCurrentStatus only for CopyType='PI'**: The SP filters `CopyType='PI'` when computing days in current guru status. Portfolio and RemovedPI rows will have NULL.
- **DaysAsPI counts from first GuruStatusID>=2 date**: Not from current tier entry -- it measures total time as any PI tier.
- **ROUND_ROBIN distribution**: No hash key -- JOINs on CID require data movement. Filter by DateID first.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 | `(Tier 1 — upstream wiki, source)` — Dim-lookup passthrough, verbatim from upstream |
| ★★★☆☆ | Tier 2 | `(Tier 2 — source table)` — ETL-computed or aggregated from source |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Snapshot calendar date for this panel row. Set to @date SP parameter. (Tier 2 — SP_DailyPanel_Copy) |
| 2 | DateID | int | YES | Snapshot date as YYYYMMDD integer. CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). Used as DELETE+INSERT key. (Tier 2 — SP_DailyPanel_Copy) |
| 3 | CID | int | YES | Customer ID of the Popular Investor, Smart Portfolio, or Removed PI. From Fact_SnapshotCustomer.RealCID. (Tier 2 — Fact_SnapshotCustomer) |
| 4 | UserName | varchar(max) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). (Tier 1 — Customer.CustomerStatic) |
| 5 | Gender | char(1) | YES | Gender: M, F, or U (Unknown). CHECK constraint CCST_GENDER enforces these three values only. (Tier 1 — Customer.CustomerStatic) |
| 6 | Manager | varchar(max) | YES | Account manager full name (FirstName + ' ' + LastName from Dim_Manager). Concatenated in the SP. (Tier 2 — Dim_Manager) |
| 7 | Country | varchar(max) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country. (Tier 1 — Dictionary.Country) |
| 8 | Region | varchar(max) | YES | Manual override name for the marketing region, from Ext_Dim_Country. May differ from the automated MarketingRegion label (e.g., Albania: Region=ROE, MarketingRegionManualName=CEE). Passthrough from Dim_Country.MarketingRegionManualName. (Tier 1 — Ext_Dim_Country) |
| 9 | Language | char(50) | YES | Language display name. Used in back-office language selectors and reporting. Passthrough from Dim_Language. (Tier 1 — Dictionary.Language) |
| 10 | Club | varchar(max) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Passthrough from Dim_PlayerLevel.Name. (Tier 1 — Dictionary.PlayerLevel) |
| 11 | Regulation | varchar(max) | YES | Short code for the regulation. Values: None, CySEC, FCA, NFA, ASIC, BVI, eToroUS, FinCEN, FinCEN+FINRA, FSA Seychelles, ASIC&GAML, FSRA, FINRAONLY, MAS, NYDFS+FINRA. Passthrough from Dim_Regulation. (Tier 1 — Dictionary.Regulation) |
| 12 | Seniority | int | YES | Months since first deposit, computed as DATEDIFF(MONTH, FirstDepositDate, first-of-month(@date)). NULL if customer never deposited. (Tier 2 — Dim_Customer) |
| 13 | DaysAsPI | int | YES | Days since the customer first achieved any PI status (GuruStatusID >= 2). Computed from MIN(Fact_SnapshotCustomer FromDate where GuruStatusID >= 2). NULL for Portfolio accounts. (Tier 2 — Fact_SnapshotCustomer) |
| 14 | CopyType | varchar(max) | YES | Population classification: 'PI' = active Popular Investor (GuruStatusID 2-6, IsValidCustomer=1), 'Portfolio' = Smart Portfolio fund (AccountTypeID=9), 'RemovedPI' = former PI no longer in active PI status. (Tier 2 — Fact_SnapshotCustomer) |
| 15 | PortfolioType | varchar(max) | YES | Fund type label for Portfolio CopyType accounts. 1=TopTraders (copy-based), 2=Partners (external strategist), 3=Market (thematic index). NULL for PI and RemovedPI. Passthrough from Dim_FundType.FundTypeName via Dim_Fund. (Tier 1 — Dictionary.FundType) |
| 16 | GuruStatusID | smallint | YES | Popular Investor program status code from the snapshot date. 0=No (non-PI), 1=Certified, 2=Cadet, 3=Rising Star, 4=Champion, 5=Elite, 6=Elite Pro. Passthrough from Fact_SnapshotCustomer. (Tier 2 — Fact_SnapshotCustomer) |
| 17 | GuruStatus | varchar(max) | YES | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Passthrough from Dim_GuruStatus. (Tier 1 — Dictionary.GuruStatus) |
| 18 | PreviousGuruStatus | varchar(max) | YES | The GuruStatusID of the most recent different guru status for this CID. Determined via ROW_NUMBER over Fact_SnapshotCustomer history, filtering rows where GuruStatusID differs from the current status, ordered by ToDateID DESC. NULL if no previous status change found. Stored as the raw GuruStatusID integer (not the name). (Tier 2 — Fact_SnapshotCustomer) |
| 19 | TotalDaysInCurrentStatus | int | YES | Total calendar days the PI has held their current GuruStatusID, summed across potentially non-contiguous SCD2 date ranges. Only computed for CopyType='PI'. NULL for Portfolio and RemovedPI. (Tier 2 — Fact_SnapshotCustomer) |
| 20 | BIO_Len | int | YES | Character length of the PI's "About Me" biography text from their public profile. Source: LEN(AboutMe) from External_UserApiDB_dbo_Publications. NULL if no biography published. (Tier 2 — External_UserApiDB_dbo_Publications) |
| 21 | IsPrivate | int | YES | Whether the PI's profile is set to private. 0 if PrivacyPolicyID=2 (public), 1 otherwise (private). Derived from Dim_Customer.PrivacyPolicyID. (Tier 2 — Dim_Customer) |
| 22 | AllowDisplayFullName | int | YES | Whether the PI allows their full legal name to be displayed publicly. From External_etoroGeneral_Customer_Settings, windowed by ValidFrom/ValidTo to the snapshot date. (Tier 2 — External_etoroGeneral_Customer_Settings) |
| 23 | HasAvatar | int | YES | Whether customer has uploaded a custom avatar. Updated post-load from Avatars staging (excludes default/avatoros images). Passthrough from Dim_Customer. (Tier 2 — Dim_Customer) |
| 24 | RiskScore | int | YES | Discrete portfolio risk score (typically 1-10) derived from mapping the daily portfolio standard deviation (AvgSTD from DWH_CIDsDailyRisk) to risk buckets defined in External_etoro_Internal_RiskScore. Higher values = more volatile portfolio. MAX per CID. (Tier 2 — DWH_CIDsDailyRisk) |
| 25 | PlayerStatus | varchar(max) | YES | Human-readable restriction state label from the snapshot date. Values: Normal, Blocked, Chat Blocked, Blocked Upon Request, Warning, Under Investigation, Scalpers Block, PayPal Investigation, Trade & MIMO Blocked, Deposit Blocked, Social Index, Copy Block, Pending Verification, Failed Verification, Block Deposit & Trading. Passthrough from Dim_PlayerStatus. (Tier 1 — Dictionary.PlayerStatus) |
| 26 | LastBlockedDate | datetime | YES | Most recent date when copy-trading operations were blocked for this CID. Source: MAX(Occurred/BlockStart) from External_etoro_Customer_BlockedCustomerOperations and External_etoro_History_BlockedCustomerOperations where OperationTypeID=2. NULL if never blocked. (Tier 2 — External_etoro_Customer_BlockedCustomerOperations) |
| 27 | BlockReason | varchar(max) | YES | Human-readable reason for the most recent copy block event. Looked up from External_etoro_Dictionary_BlockUnBlockReason via BlockReasonID. NULL if never blocked. (Tier 2 — External_etoro_Dictionary_BlockUnBlockReason) |
| 28 | TotalEquity | decimal(20,4) | YES | Customer total balance on the snapshot date: ISNULL(Liabilities, 0) + ISNULL(ActualNWA, 0) from V_Liabilities. Equals RealizedEquity + PositionPnL. (Tier 2 — V_Liabilities) |
| 29 | RealizedEquity | money | YES | Realized equity (cash + credit + in-process cashouts) on the snapshot date. Direct passthrough from V_Liabilities.RealizedEquity. (Tier 1 — Fact_SnapshotEquity) |
| 30 | TotalPositionsAmount | money | YES | Total invested amount across all open positions on the snapshot date. Direct passthrough from V_Liabilities.TotalPositionsAmount. (Tier 1 — Fact_SnapshotEquity) |
| 31 | PositionPnL | decimal(16,4) | YES | Unrealized position profit/loss on the snapshot date. Direct passthrough from V_Liabilities.PositionPnL. (Tier 1 — Fact_CustomerUnrealized_PnL) |
| 32 | Credit | money | YES | Available credit balance on the snapshot date. Direct passthrough from V_Liabilities.Credit. (Tier 1 — Fact_SnapshotEquity) |
| 33 | NumOfCopiers | int | YES | Count of valid depositor customers currently copying this PI/Portfolio, from etoroGeneral_History_GuruCopiers where Timestamp = day-after-@date. Only counts IsValidCustomer=1 AND IsDepositor=1 copiers. (Tier 2 — etoroGeneral_History_GuruCopiers) |
| 34 | CopyAUC | money | YES | Total Assets Under Copy -- sum of Cash + Investment + PnL + DetachedPosInvestment + Dit_PnL across all valid copiers of this PI/Portfolio. (Tier 2 — etoroGeneral_History_GuruCopiers) |
| 35 | CopyPnL | money | YES | Total copy PnL -- sum of PnL + DetachedPosInvestment + Dit_PnL across all valid copiers of this PI/Portfolio. (Tier 2 — etoroGeneral_History_GuruCopiers) |
| 36 | MI | decimal(11,2) | YES | Mirror In -- daily inflow of funds into copy relationships where this CID is the copied person. SUM(-Amount) for ActionTypeID IN (15=Account-to-Mirror, 17=Register New Mirror) from Fact_CustomerAction on the snapshot date. (Tier 2 — Fact_CustomerAction) |
| 37 | MO | decimal(11,2) | YES | Mirror Out -- daily outflow of funds from copy relationships where this CID is the copied person. SUM(Amount) for ActionTypeID IN (16=Mirror-to-Account, 18=Unregister Mirror) from Fact_CustomerAction on the snapshot date. (Tier 2 — Fact_CustomerAction) |
| 38 | NetMI | decimal(11,2) | YES | Net Mirror In -- net daily money flow into copy relationships. SUM(-Amount) for all mirror ActionTypeIDs (15,16,17,18). Positive = net inflow, negative = net outflow. (Tier 2 — Fact_CustomerAction) |
| 39 | Trades | int | YES | Count of manual (non-copy) positions opened by this CID on the snapshot date. Source: COUNT from Dim_Position WHERE MirrorID=0 AND ISNULL(IsPartialCloseChild,0)=0 AND OpenDateID=@date_int. (Tier 2 — Dim_Position) |
| 40 | Top_3_Traded_Instruments | varchar(max) | YES | Comma-separated list of the top 3 instrument symbols by invested amount among open positions. Determined by ranking open positions by SUM(Amount) DESC per InstrumentID, then STRING_AGG of top 3 Symbol values. NULL if no open positions. (Tier 2 — Dim_Position / Dim_Instrument) |
| 41 | Top3TradedIndustries | varchar(max) | YES | Comma-separated list of the top 3 industries by invested amount among open positions. Ranked by SUM(Amount) DESC per Industry, then STRING_AGG of top 3. NULL if no open positions. (Tier 2 — Dim_Position / Dim_Instrument) |
| 42 | Lev_weighted_average | decimal(12,2) | YES | Amount-weighted average leverage across all open positions on the snapshot date. Formula: SUM(Leverage * Amount) / NULLIF(SUM(Amount), 0). Source: BI_DB_PositionPnL for the snapshot DateID. (Tier 2 — BI_DB_PositionPnL) |
| 43 | BuyPercent | decimal(12,2) | YES | Sell percentage among high-leverage positions held >30 days (Leverage >= 5, opened > 30 days ago). NOTE: despite the column name "BuyPercent", the SP actually stores the SELL ratio here (IsBuy=0 count / total count). NULL if no qualifying high-lev positions exist. (Tier 2 — Dim_Position) |
| 44 | SellPercent | decimal(12,2) | YES | Buy percentage among high-leverage positions held >30 days. Computed as 1 - BuyPercent. Despite the name "SellPercent", this is actually the BUY ratio (since BuyPercent stores the sell ratio). NULL if no qualifying high-lev positions. (Tier 2 — Dim_Position) |
| 45 | HoldsHighLevPosition | int | YES | 1 if the CID holds any position open >30 days with leverage exceeding asset-class thresholds (Stocks/ETF >= 5x, Indices >= 10x, Currencies/Commodities >= 20x). 0 otherwise. (Tier 2 — Dim_Position) |
| 46 | Classification | varchar(max) | YES | Portfolio asset allocation category based on open position volumes. Values: 'Long Equity' (>=70% equity, >80% buy), 'Long/Short Equity' (>=70% equity, >=20% buy AND >=20% short), 'Currencies', 'Commodities', 'Crypto', 'ETF' (each >=70%), '100% cash balance' (no positions), 'Multi-Asset' (default). (Tier 2 — Dim_Position) |
| 47 | Largest_Asset_Class | varchar(max) | YES | The single asset class (InstrumentType) with the highest total invested amount among open positions. Values: Stocks, Currencies, Commodities, Indices, ETF, Crypto Currencies. NULL if no open positions. (Tier 2 — Dim_Position / Dim_Instrument) |
| 48 | AvgerageHoldingTime | int | YES | Average holding time in days across all positions and mirrors opened/closed within the last 2 years. Includes both trading positions (Dim_Position) and copy relationships (Dim_Mirror). Open positions use @date as the close proxy. Note: column name has a typo ("Avgerageee" instead of "Average"). (Tier 2 — Dim_Position / Dim_Mirror) |
| 49 | TraderType | varchar(max) | YES | Classification of the PI by average holding time. 'Short term investor' if AvgerageHoldingTime < 22 days, 'Long term investor' otherwise. (Tier 2 — SP_DailyPanel_Copy) |
| 50 | HighLevHoldingDetail | varchar(max) | YES | Comma-separated list of "Leverage-InstrumentType" strings for all high-leverage positions held >30 days (same criteria as HoldsHighLevPosition). E.g., "5-Stocks, 10-Indices". NULL if no qualifying positions. (Tier 2 — Dim_Position / Dim_Instrument) |
| 51 | Value_percenet | decimal(16,4) | YES | Top position value as a fraction of total portfolio (positions + credit). Formula: ROUND(Position_Value / NULLIF(Total_Position_Value + Credit, 0), 3). Measures portfolio concentration. Note: column name has a typo ("percenet" instead of "percent"). (Tier 2 — BI_DB_PositionPnL / V_Liabilities) |
| 52 | UpdateDate | datetime | NOT NULL | ETL load timestamp. Set to GETDATE() when SP_DailyPanel_Copy runs. (Tier 2 — SP_DailyPanel_Copy) |
| 53 | Last_Day_Performance | float | YES | Daily compound portfolio return as a decimal. ISNULL(Gain_d, 0) from DWH_GainDaily for the snapshot date. 0.05 = 5% gain. (Tier 2 — DWH_GainDaily) |
| 54 | Gain_YTD | float | YES | Year-to-date compound portfolio return as a decimal. ISNULL(Gain_YTD, 0) from DWH_GainDaily. From Jan 1 to snapshot date. (Tier 2 — DWH_GainDaily) |
| 55 | Gain_QTD | float | YES | Quarter-to-date compound portfolio return as a decimal. ISNULL(Gain_QTD, 0) from DWH_GainDaily. From first of current quarter to snapshot date. (Tier 2 — DWH_GainDaily) |
| 56 | Gain_MTD | float | YES | Month-to-date compound portfolio return as a decimal. ISNULL(Gain_MTD, 0) from DWH_GainDaily. From first of current month to snapshot date. (Tier 2 — DWH_GainDaily) |
| 57 | MonthsSinceFirstOpen | int | YES | Months since the customer's first trading action (position open or mirror registration). DATEDIFF(Month, MIN(FirstOccurred), @date) from Fact_FirstCustomerAction WHERE ActionTypeID IN (1=ManualOpen, 2=CopyOpen, 17=RegisterMirror). (Tier 2 — Fact_FirstCustomerAction) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| Date, DateID | SP parameter | @date | Direct / CAST to int |
| CID | Fact_SnapshotCustomer | RealCID | Passthrough |
| UserName, Gender | Dim_Customer | UserName, Gender | Dim-lookup passthrough |
| Manager | Dim_Manager | FirstName, LastName | FirstName + ' ' + LastName |
| Country | Dim_Country | Name | Dim-lookup passthrough |
| Region | Dim_Country | MarketingRegionManualName | Dim-lookup passthrough |
| Language | Dim_Language | Name | Dim-lookup passthrough |
| Club | Dim_PlayerLevel | Name | Dim-lookup passthrough |
| Regulation | Dim_Regulation | Name | Dim-lookup passthrough |
| Seniority | Dim_Customer | FirstDepositDate | DATEDIFF(MONTH, FDD, first-of-month) |
| DaysAsPI | Fact_SnapshotCustomer + Dim_Range + Dim_Date | GuruStatusID, FromDateID | DATEDIFF from MIN date where GuruStatusID >= 2 |
| CopyType | Fact_SnapshotCustomer | AccountTypeID, GuruStatusID | CASE: 9=Portfolio, PI if active, else RemovedPI |
| PortfolioType | Dim_FundType via Dim_Fund | FundTypeName | Dim-lookup passthrough |
| GuruStatusID | Fact_SnapshotCustomer | GuruStatusID | Passthrough |
| GuruStatus | Dim_GuruStatus | GuruStatusName | Dim-lookup passthrough |
| PreviousGuruStatus | Fact_SnapshotCustomer | GuruStatusID | ROW_NUMBER over historical changes |
| TotalDaysInCurrentStatus | Fact_SnapshotCustomer + Dim_Range | DateRangeID | SUM of DATEDIFF per matching status range |
| BIO_Len | External_UserApiDB_dbo_Publications | AboutMe | LEN() |
| IsPrivate | Dim_Customer | PrivacyPolicyID | CASE WHEN 2 THEN 0 ELSE 1 |
| AllowDisplayFullName | External_etoroGeneral_Customer_Settings | AllowDisplayFullName | Windowed passthrough |
| HasAvatar | Dim_Customer | HasAvatar | Passthrough |
| RiskScore | DWH_CIDsDailyRisk + External_etoro_Internal_RiskScore | AvgSTD | Range-bucket lookup, MAX |
| PlayerStatus | Dim_PlayerStatus | Name | Dim-lookup passthrough |
| LastBlockedDate, BlockReason | External blocked operations tables | Occurred, Reason | ROW_NUMBER DESC, most recent |
| TotalEquity | V_Liabilities | Liabilities + ActualNWA | SUM |
| RealizedEquity, TotalPositionsAmount, Credit | V_Liabilities | Same | Passthrough |
| PositionPnL | V_Liabilities | PositionPnL | Passthrough |
| NumOfCopiers, CopyAUC, CopyPnL | etoroGeneral_History_GuruCopiers | Cash, Investment, PnL, etc. | SUM / COUNT |
| MI, MO, NetMI | Fact_CustomerAction + Dim_Mirror | Amount | SUM by ActionTypeID |
| Trades | Dim_Position | PositionID | COUNT |
| Top_3_Traded_Instruments | Dim_Position + Dim_Instrument | Symbol | STRING_AGG top 3 |
| Top3TradedIndustries | Dim_Position + Dim_Instrument | Industry | STRING_AGG top 3 |
| Lev_weighted_average | BI_DB_PositionPnL | Leverage, Amount | Weighted average |
| BuyPercent, SellPercent | Dim_Position + Dim_Instrument | IsBuy | Ratio among high-lev positions |
| HoldsHighLevPosition | Dim_Position + Dim_Instrument | Leverage, InstrumentTypeID | CASE flag |
| Classification | Dim_Position | Volume by InstrumentTypeID | CASE on asset-class percentages |
| Largest_Asset_Class | Dim_Position + Dim_Instrument | InstrumentType | ROW_NUMBER by SUM(Amount) |
| AvgerageHoldingTime, TraderType | Dim_Position + Dim_Mirror | OpenOccurred, CloseOccurred | AVG DATEDIFF + CASE |
| HighLevHoldingDetail | Dim_Position + Dim_Instrument | Leverage, InstrumentType | STRING_AGG |
| Value_percenet | BI_DB_PositionPnL + V_Liabilities | Position_Value, Credit | Ratio |
| UpdateDate | SP_DailyPanel_Copy | GETDATE() | ETL timestamp |
| Last_Day_Performance, Gain_YTD, Gain_QTD, Gain_MTD | DWH_GainDaily | Gain_d, Gain_YTD, Gain_QTD, Gain_MTD | ISNULL(x, 0) |
| MonthsSinceFirstOpen | Fact_FirstCustomerAction | FirstOccurred | DATEDIFF(Month, MIN, @date) |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (population: PI + Portfolio + RemovedPI)
DWH_dbo.Dim_Range, Dim_PlayerLevel, Dim_Language, Dim_Country, Dim_Manager,
  Dim_GuruStatus, Dim_Regulation, Dim_PlayerStatus (dimension lookups)
DWH_dbo.Dim_Customer (user profile)
DWH_dbo.Dim_Fund + Dim_FundType (portfolio type)
DWH_dbo.V_Liabilities (equity/liabilities)
general.etoroGeneral_History_GuruCopiers (copy AUC/PnL/copiers)
DWH_dbo.Fact_CustomerAction + Dim_Mirror (MIMO)
DWH_dbo.Dim_Position + Dim_Instrument (trading activity, classification)
BI_DB_dbo.BI_DB_PositionPnL (leverage, value metrics)
BI_DB_dbo.DWH_CIDsDailyRisk + External_etoro_Internal_RiskScore (risk score)
BI_DB_dbo.DWH_GainDaily (performance gains)
DWH_dbo.Fact_FirstCustomerAction (first trade date)
BI_DB_dbo.External_* tables (blocked ops, publications, customer settings)
  |
  |-- SP_DailyPanel_Copy @date (daily)
  |   Step 1: Build #CopiedPop1 (active PIs + Portfolios)
  |   Step 2: Build #histGuru (removed PIs)
  |   Step 3: UNION → #CopiedPop (full population)
  |   Step 4: Enrich via 15+ LEFT JOINs to temp tables
  |   Step 5: DELETE WHERE DateID = @date_int
  |   Step 6: INSERT INTO BI_DB_DailyPanel_Copy FROM #final
  v
BI_DB_dbo.BI_DB_DailyPanel_Copy (12.7M rows, accumulating daily)
```

| Step | Object | Description |
|------|--------|-------------|
| Population | Fact_SnapshotCustomer + Dim_Range | Identify PIs (GuruStatusID 2-6) + Portfolios (AccountTypeID=9) + RemovedPIs |
| Dimensions | 8 Dim tables | Resolve IDs to names (Country, Language, Club, Regulation, etc.) |
| Equity | V_Liabilities | TotalEquity, RealizedEquity, PositionPnL, Credit |
| Copy metrics | etoroGeneral_History_GuruCopiers | NumOfCopiers, CopyAUC, CopyPnL |
| MIMO | Fact_CustomerAction + Dim_Mirror | MI, MO, NetMI |
| Trading | Dim_Position + Dim_Instrument + BI_DB_PositionPnL | Trades, Top3, Leverage, Classification |
| Risk | DWH_CIDsDailyRisk | RiskScore |
| Performance | DWH_GainDaily | Last_Day_Performance, Gain_YTD/QTD/MTD |
| Load | SP_DailyPanel_Copy | DELETE @date_int + INSERT from #final |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer master dimension |
| GuruStatusID | DWH_dbo.Dim_GuruStatus | PI tier dimension |
| DateID | DWH_dbo.Dim_Date | Calendar dimension |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| (Ad-hoc BI queries) | — | Terminal analytical table for PI/Portfolio dashboards |

---

## 7. Sample Queries

### 7.1 Current panel for active PIs with copiers

```sql
SELECT CID, UserName, GuruStatus, Country, Regulation,
       NumOfCopiers, CopyAUC, TotalEquity, RiskScore,
       Last_Day_Performance, Gain_YTD, Classification
FROM BI_DB_dbo.BI_DB_DailyPanel_Copy
WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_dbo.BI_DB_DailyPanel_Copy)
  AND CopyType = 'PI'
  AND NumOfCopiers > 0
ORDER BY NumOfCopiers DESC;
```

### 7.2 PI tier distribution over time

```sql
SELECT DateID, GuruStatus, COUNT(*) AS PIs
FROM BI_DB_dbo.BI_DB_DailyPanel_Copy
WHERE CopyType = 'PI'
  AND DateID >= 20260101
GROUP BY DateID, GuruStatus
ORDER BY DateID, GuruStatus;
```

### 7.3 Portfolio classification breakdown

```sql
SELECT Classification, COUNT(*) AS cnt,
       AVG(TotalEquity) AS AvgEquity,
       AVG(Lev_weighted_average) AS AvgLeverage
FROM BI_DB_dbo.BI_DB_DailyPanel_Copy
WHERE DateID = 20260425
  AND CopyType = 'PI'
GROUP BY Classification
ORDER BY cnt DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode -- Phase 10 skipped).

---

*Generated: 2026-04-30 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 12 T1, 45 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 57/57, Logic: 9/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_DailyPanel_Copy | Type: Table | Production Source: SP_DailyPanel_Copy (multi-source ETL from 15+ DWH/BI_DB tables)*
