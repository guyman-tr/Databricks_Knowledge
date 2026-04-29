# BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH

> Partition-switching shadow table for BI_DB_CID_DailyPanel_FullData — schema-identical staging surface used by `SP_BI_DB_CID_DailyPanel_FullData_SWITCH` to perform metadata-only `ALTER TABLE ... SWITCH PARTITION` operations during historical partition loads. 169 columns, normally 0 rows (truncated after each switch). Created at runtime by `SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE`.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (partition-switch shadow) |
| **Production Source** | BI_DB_CID_DailyPanel_FullData via ALTER TABLE ... SWITCH PARTITION (metadata-only, zero ETL) |
| **Refresh** | On-demand — created/populated/truncated during historical partition switching only |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **Partition** | RANGE LEFT on DateID, 3-partition window centered on target date (created dynamically by SP) |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_CID_DailyPanel_FullData_SWITCH is a **partition-switching shadow table** — it exists solely as a staging surface for the Synapse `ALTER TABLE ... SWITCH PARTITION` mechanism used to load historical partitions into `BI_DB_CID_DailyPanel_FullData`.

The table has an **identical schema** to `BI_DB_CID_DailyPanel_FullData` (169 of that table's 183 columns — the SWITCH DDL predates the 2024–2025 column additions). It is:
- **Created** by `SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE` as `SELECT TOP 0 * FROM BI_DB_CID_DailyPanel_FullData` with a 3-partition window (previous day, target day, next day).
- **Used** by `SP_BI_DB_CID_DailyPanel_FullData_SWITCH` to receive the old partition data from the main table (step 1), then swap the new data from `_SWITCH_SINGLE` into the main table (step 2).
- **Truncated** at the end of the switch operation — it is always empty at rest.

This is a **metadata-only operation** — no rows are transformed, no ETL logic is applied. Data passes through this table byte-for-byte via Synapse partition switching.

**Typical state**: 0 rows. The table is transiently populated only during the milliseconds of the partition switch operation.

---

## 2. Business Logic

### 2.1 Partition Switch Mechanism

**What**: The SWITCH table temporarily holds the OLD partition data while new data is swapped in.

**Columns Involved**: All 169 columns (schema-identical to parent)

**Rules**:
```
Step 1: ALTER TABLE BI_DB_CID_DailyPanel_FullData SWITCH PARTITION @P
        TO BI_DB_CID_DailyPanel_FullData_SWITCH PARTITION @P_SGL
        → Moves existing date's data OUT of main table into this shadow

Step 2: ALTER TABLE BI_DB_CID_DailyPanel_FullData_SWITCH_SINGLE SWITCH PARTITION @P_SGL
        TO BI_DB_CID_DailyPanel_FullData PARTITION @P WITH (TRUNCATE_TARGET = ON)
        → Moves new day's data IN to main table (overwrites old)

Step 3: TRUNCATE TABLE BI_DB_CID_DailyPanel_FullData_SWITCH
        → Discards the old partition data held temporarily
```

### 2.2 Schema Requirements for Partition Switching

**What**: Synapse requires source and target tables to have identical column schemas, distribution, and compatible partition structures for SWITCH to succeed.

**Columns Involved**: N/A (structural constraint)

**Rules**:
- Distribution must match: HASH(CID)
- Index must match: CLUSTERED INDEX (DateID ASC)
- Column types and nullability must be identical to the main table
- Partition boundaries must contain the target partition value

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH(CID) — matches parent table for partition switch compatibility
- **Index**: CLUSTERED INDEX (DateID ASC) — matches parent table
- **Partition**: Dynamic 3-partition window (previous/current/next day)

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Is a partition switch in progress? | `SELECT COUNT(*) FROM BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH` — non-zero means switch is active |
| What date is being switched? | `SELECT DISTINCT DateID FROM BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH` |

### 3.3 Common JOINs

This table should NOT be joined in analytical queries. It is an infrastructure-only table.

### 3.4 Gotchas

- **Always empty at rest**: Do not expect to find data here. If rows are present, a switch operation is either in progress or failed mid-execution.
- **Schema drift**: The SWITCH table's SSDT DDL has 169 columns vs the parent's 183. The 14 newer columns (added 2024–2025) are not in this DDL. At runtime, `SP_CREATE_SWITCH_SINGLE` re-creates the table from `SELECT TOP 0 * FROM BI_DB_CID_DailyPanel_FullData`, so it matches the parent's current schema regardless of the SSDT DDL.
- **CLUSTERED COLUMNSTORE vs CLUSTERED INDEX**: The SSDT DDL declares CLUSTERED COLUMNSTORE INDEX, but the runtime SP creates the table with CLUSTERED INDEX (DateID ASC). The runtime state is authoritative.
- **Not for analytics**: This table serves no reporting purpose. Query `BI_DB_CID_DailyPanel_FullData` instead.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Passthrough from BI_DB_CID_DailyPanel_FullData — metadata-only partition switch, zero transformation. Descriptions quoted verbatim from parent wiki. |
| Tier 3 | No traceable source (not applicable — all columns trace to parent). |

> All 169 columns are schema-identical passthroughs from `BI_DB_CID_DailyPanel_FullData` via `ALTER TABLE ... SWITCH PARTITION`. No ETL is performed on this table.

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | eToro customer ID (Real CID). Only depositors (IsDepositor=1) present. FK to DWH_dbo.Dim_Customer.RealCID (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 2 | DateID | int | NO | Partition key: date in YYYYMMDD format. One row per CID per day (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 3 | Active_Month | int | YES | YYYYMM of this row's date (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 4 | ActiveDate | date | YES | Calendar date of this row (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 5 | Seniority | int | YES | Months since customer's first deposit (FTDdate) as of start of the current month (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 6 | Seniority_Seg | varchar(11) | NO | Seniority bucket label: '<1month', '1-2month', '<2-3month', ... '<11-12month', '12+month' (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 7 | Reg_Month | int | YES | YYYYMM of customer registration (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 8 | RegDate | date | YES | Customer registration date (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 9 | IsReg_ThisD | int | NO | 1 if customer registered on this specific date (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 10 | FTD_Month | int | YES | YYYYMM of customer's first-time deposit (FTD) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 11 | FTDdate | date | YES | Customer's first-time deposit date (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 12 | IsFTD_ThisD | int | NO | 1 if customer made their first deposit on this specific date (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 13 | FTDA | money | YES | First-time deposit amount (USD) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 14 | Region | nvarchar(500) | NO | Geographic region label (e.g., 'French', 'Arabic GCC', 'Australia', 'North Europe') (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 15 | Country | varchar(500) | YES | Customer's country name at snapshot date (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 16 | Channel | nvarchar(500) | NO | Acquisition channel (e.g., 'Direct', 'Affiliate', 'SEM', 'SEO', 'Friend Referral', 'Mobile Acquisition') (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 17 | SubChannel | nvarchar(500) | NO | Acquisition sub-channel detail (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 18 | AffiliateID | int | YES | Affiliate serial ID for affiliate-acquired customers; NULL for direct/organic (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 19 | FirstAction | varchar(22) | YES | Deprecated — always NULL. Originally planned first action type (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 20 | FirstInstrument | varchar(50) | YES | Deprecated — always NULL. Originally planned first instrument traded (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 21 | V2_Complete | int | NO | 1 if customer has completed verification level 2 as of this date (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 22 | V3_Complete | int | NO | 1 if customer has completed full KYC (verification level 3) as of this date (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 23 | IsPro | int | NO | 1 if customer is classified as professional client (MifidCategorizationID IN 2,3 in Fact_SnapshotCustomer) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 24 | IsOTD | int | YES | 1 if customer has made exactly one prior deposit (One Trade Done) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 25 | Daily_Classification | varchar(50) | YES | Customer segment label (e.g., 'Traders', 'Crypto'). Set by separate SP_CID_DailyPanel_UpdateCluster SP. As of 2026 all rows are empty string — appears non-operational post-Synapse migration (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 26 | EOD_Club | varchar(50) | NO | Loyalty tier at EOD: 'LowBronze', 'HighBronze', 'Silver', 'Gold', 'Platinum', 'Platinum Plus', 'Diamond' (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 27 | EOD_Regulation | varchar(50) | NO | Regulatory jurisdiction name at EOD (e.g., 'CySEC', 'FCA', 'ASIC & GAML', 'FinCEN+FINRA') (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 28 | Equity | decimal(23,4) | YES | Total EOD equity (USD): NWA (net worth of assets) + Liabilities from DWH_dbo.V_Liabilities. Includes all open positions at market value (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 29 | RealizedEquity | money | YES | Realized equity component (cash + closed positions only), excluding open unrealized positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 30 | AUM | money | YES | Assets Under Management: value of assets the customer holds in copy-trading and portfolio products (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 31 | Credit | money | NO | Credit/margin balance: funds provided as credit (e.g., bonus credits). V_Liabilities.EOD_Balance (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 32 | ActiveUser | int | NO | 1 if customer logged in (ActionTypeID=14) on this date (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 33 | Active | int | NO | 1 if customer had any position open or closed on this date (any instrument, including partial close children excluded) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 34 | ActiveOpen | int | NO | 1 if customer opened a new position today — manual trade OR started/added a mirror (AirDrop excluded). See parent wiki §2.3 (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 35 | IsOpen_Copy | int | NO | 1 if customer opened a new copy relationship (started copying a trader) today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 36 | Count_Opened_Copy | int | NO | Number of distinct copy relationships opened today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 37 | Count_Closed_Copy | int | NO | Number of distinct copy relationships closed today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 38 | MoneyIn_Copy | decimal(38,2) | NO | Total funds allocated into copy positions today (negative Amount from AT=17,15) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 39 | MoneyOut_Copy | decimal(38,2) | NO | Total funds returned from closed copy positions today (Amount from AT=18,16) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 40 | IsOpen_CopyPortfolio | int | NO | 1 if customer opened a CopyPortfolio (managed portfolio product) today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 41 | Count_Opened_CopyPortfolio | int | NO | Number of CopyPortfolio relationships opened today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 42 | Count_Closed_CopyPortfolio | int | NO | Number of CopyPortfolio relationships closed today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 43 | MoneyIn_CopyPortfolio | decimal(38,2) | NO | Total funds into CopyPortfolio positions today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 44 | MoneyOut_CopyPortfolio | decimal(38,2) | NO | Total funds returned from CopyPortfolio positions today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 45 | Active_Copy | int | NO | 1 if customer has an open copy position on this date (MirrorID>0) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 46 | Active_Real_Stocks | int | NO | 1 if customer has an open settled stock position (IsSettled=1, InstrumentTypeID IN 5,6, non-AirDrop) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 47 | Active_CFD_Stocks | int | NO | 1 if customer has an open CFD stock position (IsSettled=0, InstrumentTypeID IN 5,6) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 48 | Active_Real_Crypto | int | NO | 1 if customer has an open settled crypto position (IsSettled=1, InstrumentTypeID=10, non-AirDrop) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 49 | Active_CFD_Crypto | int | NO | 1 if customer has an open CFD crypto position (IsSettled=0, InstrumentTypeID=10) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 50 | Active_FX/Comm/Ind | int | NO | 1 if customer has an open FX/commodities/indices position (InstrumentTypeID IN 1,2,4) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 51 | ActiveOpen_Copy | int | NO | 1 if opened a copy position today (MirrorID>0, non-portfolio, OpenDateID=today) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 52 | ActiveOpen_Real_Stocks | int | NO | 1 if opened a settled stock position today (non-AirDrop) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 53 | ActiveOpen_CFD_Stocks | int | NO | 1 if opened a CFD stock position today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 54 | ActiveOpen_Real_Crypto | int | NO | 1 if opened a settled crypto position today (non-AirDrop) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 55 | ActiveOpen_CFD_Crypto | int | NO | 1 if opened a CFD crypto position today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 56 | ActiveOpen_FX/Comm/Ind | int | NO | 1 if opened a FX/Comm/Ind position today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 57 | NewTrades_Copy | int | NO | Count of new copy positions opened today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 58 | NewTrades_Real_Stocks | int | NO | Count of new settled stock positions opened today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 59 | NewTrades_CFD_Stocks | int | NO | Count of new CFD stock positions opened today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 60 | NewTrades_Real_Crypto | int | NO | Count of new settled crypto positions opened today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 61 | NewTrades_CFD_Crypto | int | NO | Count of new CFD crypto positions opened today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 62 | NewTrades_FX/Comm/Ind | int | NO | Count of new FX/Comm/Ind positions opened today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 63 | NewTrades_Total | int | YES | Total count of all new positions opened today across all instrument types (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 64 | AmountIn_NewTrades_Copy | money | NO | Total USD invested in new copy positions today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 65 | AmountIn_NewTrades_Real_Stocks | money | NO | Total USD in new settled stock positions today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 66 | AmountIn_NewTrades_CFD_Stocks | money | NO | Total USD in new CFD stock positions today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 67 | AmountIn_NewTrades_Real_Crypto | money | NO | Total USD in new settled crypto positions today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 68 | AmountIn_NewTrades_CFD_Crypto | money | NO | Total USD in new CFD crypto positions today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 69 | AmountIn_NewTrades_FX/Comm/Ind | money | NO | Total USD in new FX/Comm/Ind positions today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 70 | AmountIn_NewTrades_Total | money | YES | Total USD invested in all new positions today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 71 | Revenue_Copy | decimal(38,2) | NO | Daily revenue from copy positions (FullCommissions + RollOverFee) + TicketFeeByPercent_Copy (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 72 | Revenue_Real_Stocks | decimal(38,2) | NO | Revenue from settled stock positions + flat ticket fees (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 73 | Revenue_CFD_Stocks | decimal(38,2) | NO | Revenue from CFD stock positions + ticket fee by percent (Stocks CFD) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 74 | Revenue_Real_Crypto | decimal(38,2) | NO | Revenue from settled crypto positions + ticket fee by percent (Crypto Real) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 75 | Revenue_CFD_Crypto | decimal(38,2) | NO | Revenue from CFD crypto positions + ticket fee by percent (Crypto CFD) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 76 | Revenue_FX/Comm/Ind | decimal(38,2) | NO | Revenue from FX/Commodities/Indices positions + ticket fee by percent (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 77 | Revenue_Total | decimal(38,2) | YES | Total daily revenue across all instruments + all fee types (commissions + rollover + ticket + conversion + Islamic). See parent wiki §2.6 (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 78 | PnL_Copy | decimal(38,4) | NO | Customer-side PnL on copy positions on this date (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 79 | PnL_Real_Stocks | decimal(38,4) | NO | Customer-side PnL on settled stock positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 80 | PnL_CFD_Stocks | decimal(38,4) | NO | Customer-side PnL on CFD stock positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 81 | PnL_Real_Crypto | decimal(38,4) | NO | Customer-side PnL on settled crypto positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 82 | PnL_CFD_Crypto | decimal(38,4) | NO | Customer-side PnL on CFD crypto positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 83 | PnL_FX/Comm/Ind | decimal(38,4) | NO | Customer-side PnL on FX/Comm/Ind positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 84 | PnL_Total | decimal(38,4) | YES | Total customer-side PnL across all instruments (sum of Copy + Real_Stocks + CFD_Stocks + Real_Crypto + CFD_Crypto + FX/Comm/Ind) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 85 | TotalDeposits | decimal(38,2) | NO | Total deposit amount (USD) on this date (Fact_CustomerAction ActionTypeID=7) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 86 | CountDeposits | int | NO | Number of deposits on this date (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 87 | TotalCashouts | decimal(38,2) | NO | Total cashout amount (USD) on this date (ActionTypeID=8) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 88 | TotalCoFee | money | NO | Copy-out fee charged on copy position closure (ActionTypeID=30, Commission field) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 89 | NetDeposits | decimal(38,2) | YES | TotalDeposits minus TotalCashouts for this date (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 90 | ACC_Revenue_Copy | decimal(38,2) | YES | Lifetime accumulated revenue from copy positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 91 | ACC_Revenue_Real_Stocks | decimal(38,2) | YES | Lifetime accumulated revenue from settled stocks (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 92 | ACC_Revenue_CFD_Stocks | decimal(38,2) | YES | Lifetime accumulated revenue from CFD stocks (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 93 | ACC_Revenue_Real_Crypto | decimal(38,2) | YES | Lifetime accumulated revenue from settled crypto (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 94 | ACC_Revenue_CFD_Crypto | decimal(38,2) | YES | Lifetime accumulated revenue from CFD crypto (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 95 | ACC_Revenue_FX/Comm/Ind | decimal(38,2) | YES | Lifetime accumulated revenue from FX/Comm/Ind (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 96 | ACC_Revenue_Total | decimal(38,2) | YES | Lifetime accumulated total revenue (all instruments + all fee types) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 97 | ACC_PnL_Copy | decimal(38,4) | YES | Lifetime accumulated customer PnL on copy positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 98 | ACC_PnL_Real_Stocks | decimal(38,4) | YES | Lifetime accumulated customer PnL on settled stocks (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 99 | ACC_PnL_CFD_Stocks | decimal(38,4) | YES | Lifetime accumulated customer PnL on CFD stocks (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 100 | ACC_PnL_Real_Crypto | decimal(38,4) | YES | Lifetime accumulated customer PnL on settled crypto (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 101 | ACC_PnL_CFD_Crypto | decimal(38,4) | YES | Lifetime accumulated customer PnL on CFD crypto (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 102 | ACC_PnL_FX/Comm/Ind | decimal(38,4) | YES | Lifetime accumulated customer PnL on FX/Comm/Ind (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 103 | ACC_PnL_Total | decimal(38,4) | YES | Lifetime accumulated total customer PnL (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 104 | ACC_TotalDeposits | decimal(38,2) | YES | Lifetime total deposits (USD) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 105 | ACC_CountDeposits | int | YES | Lifetime total deposit count (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 106 | ACC_TotalCashouts | decimal(38,2) | YES | Lifetime total cashouts (USD) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 107 | ACC_TotalCoFee | money | YES | Lifetime total copy-out fees paid (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 108 | ACC_NetDeposits | decimal(38,2) | YES | Lifetime net deposits (TotalDeposits - TotalCashouts cumulative) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 109 | UpdateDate | datetime | NO | ETL timestamp: GETDATE() at time of SP execution. Reflects the most recent daily ETL run for this partition (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 110 | AccountManager | varchar(101) | YES | Account manager full name (FirstName + ' ' + LastName) from Dim_Manager (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 111 | IsIslamic | int | NO | 1 if customer has a swap-free/Islamic account (WeekendFeePrecentage=0). See parent wiki §2.11 (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 112 | IsContacted | int | NO | 1 if customer was contacted through bonus/CRM channel on this date (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 113 | IsContactedAmount | money | NO | Total deposit amount from contacted periods on this date (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 114 | EOD_IsFunded | int | NO | 1 if EOD_Equity >= $25 (original funded customer threshold) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 115 | WithdrawalToWallet | decimal(38,2) | NO | Cashout amount directed to eToro Money wallet (FundingTypeID=27) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 116 | ACC_WithdrawalToWallet | decimal(38,2) | YES | Lifetime total withdrawals to eToro Money wallet (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 117 | LastApplicationProAccountDate | date | NO | Date of most recent professional account application; '1900-01-01' sentinel if never applied (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 118 | LastPosOpenDate | date | YES | Most recent date customer opened a position (ActionTypeID IN 1,2), max of today vs. yesterday's carry-forward (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 119 | LastLoggedIn | date | YES | Most recent login date (ActionTypeID=14), max of today vs. yesterday's carry-forward (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 120 | EOD_Equity_Copy | money | YES | EOD equity in active copy/mirror positions (Amount + PositionPnL for MirrorID>0) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 121 | EOD_Equity_Real_Crypto | money | YES | EOD equity in settled cryptocurrency positions (IsSettled=1, InstrumentTypeID=10) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 122 | EOD_Equity_Real_Stocks | money | YES | EOD equity in settled stock/ETF positions (IsSettled=1, InstrumentTypeID IN 5,6) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 123 | EOD_Equity_CFD_Crypto | money | YES | EOD equity in leveraged crypto CFD positions (IsSettled=0, InstrumentTypeID=10) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 124 | EOD_Equity_CFD_Stocks | money | YES | EOD equity in leveraged stock/ETF CFD positions (IsSettled=0, InstrumentTypeID IN 5,6) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 125 | EOD_Equity_FX/Comm/Ind | money | YES | EOD equity in FX, commodities, and indices positions (InstrumentTypeID IN 1,2,4) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 126 | EOD_Equity_Real_Crypto_Lev1 | money | YES | EOD equity in crypto positions where Leverage=1 AND IsBuy=1 (unlevered long) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 127 | EOD_Equity_Real_Stocks_LevCFD | money | YES | EOD equity in stock positions where Leverage>1 OR IsBuy=0 (levered or short) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 128 | EOD_Equity_CFD_Crypto_Lev1 | money | YES | EOD equity in CFD-Crypto positions where Leverage=1 AND IsBuy=1 (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 129 | EOD_Equity_CFD_Stocks_LevCFD | money | YES | EOD equity in CFD-Stocks positions where Leverage>1 OR IsBuy=0 (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 130 | Active_Real_Stocks_Lev1 | tinyint | YES | 1 if customer has an open stock position with Leverage=1 AND IsBuy=1 (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 131 | Active_CFD_Stocks_LevCFD | tinyint | YES | 1 if customer has an open stock position with Leverage>1 OR IsBuy=0 (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 132 | Active_Real_Crypto_Lev1 | tinyint | YES | 1 if customer has an open crypto position with Leverage=1 AND IsBuy=1 (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 133 | Active_CFD_Crypto_LevCFD | tinyint | YES | 1 if customer has an open crypto position with Leverage>1 OR IsBuy=0 (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 134 | ActiveOpen_Real_Stocks_Lev1 | tinyint | YES | 1 if opened a stock position (Leverage=1, IsBuy=1) today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 135 | ActiveOpen_CFD_Stocks_LevCFD | tinyint | YES | 1 if opened a leveraged/short stock position today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 136 | ActiveOpen_Real_Crypto_Lev1 | tinyint | YES | 1 if opened a crypto position (Leverage=1, IsBuy=1) today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 137 | ActiveOpen_CFD_Crypto_LevCFD | tinyint | YES | 1 if opened a leveraged/short crypto position today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 138 | NewTrades_Real_Stocks_Lev1 | int | YES | Count of new Lev1 stock positions (Leverage=1, IsBuy=1) today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 139 | NewTrades_CFD_Stocks_LevCFD | int | YES | Count of new leveraged/short stock positions today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 140 | NewTrades_Real_Crypto_Lev1 | int | YES | Count of new Lev1 crypto positions today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 141 | NewTrades_CFD_Crypto_LevCFD | int | YES | Count of new leveraged/short crypto positions today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 142 | AmountIn_NewTrades_Real_Stocks_Lev1 | money | YES | USD in new Lev1 stock positions today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 143 | AmountIn_NewTrades_CFD_Stocks_LevCFD | money | YES | USD in new leveraged/short stock positions today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 144 | AmountIn_NewTrades_Real_Crypto_Lev1 | money | YES | USD in new Lev1 crypto positions today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 145 | AmountIn_NewTrades_CFD_Crypto_LevCFD | money | YES | USD in new leveraged/short crypto positions today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 146 | Revenue_Real_Stocks_Lev1 | money | YES | Revenue from Lev1 stock positions + flat ticket fees (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 147 | Revenue_CFD_Stocks_LevCFD | money | YES | Revenue from leveraged/short stock positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 148 | Revenue_Real_Crypto_Lev1 | money | YES | Revenue from Lev1 crypto positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 149 | Revenue_CFD_Crypto_LevCFD | money | YES | Revenue from leveraged/short crypto positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 150 | PnL_Real_Stocks_Lev1 | money | YES | PnL on Lev1 stock positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 151 | PnL_CFD_Stocks_LevCFD | money | YES | PnL on leveraged/short stock positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 152 | PnL_Real_Crypto_Lev1 | money | YES | PnL on Lev1 crypto positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 153 | PnL_CFD_Crypto_LevCFD | money | YES | PnL on leveraged/short crypto positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 154 | IsFunded_New | int | YES | 1 if EOD_Equity > 0 AND VerificationLevelID=3 AND FirstActionDate < tomorrow (stricter funded definition) (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 155 | NewMarketingRegion | varchar(50) | YES | Marketing team region classification (e.g., 'Arabic', 'French', 'Norway', 'ROW') (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 156 | Active_FX | int | YES | 1 if customer has an open FX (Currencies, InstrumentTypeID=1) position (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 157 | Active_Comm | int | YES | 1 if customer has an open Commodities (InstrumentTypeID=2) position (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 158 | Active_Ind | int | YES | 1 if customer has an open Indices (InstrumentTypeID=4) position (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 159 | ActiveOpen_FX | int | YES | 1 if opened a FX position today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 160 | ActiveOpen_Comm | int | YES | 1 if opened a Commodities position today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 161 | ActiveOpen_Ind | int | YES | 1 if opened an Indices position today (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 162 | Revenue_FX | decimal(38,2) | YES | Revenue from FX (Currencies) positions + Currencies CFD ticket fee by percent (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 163 | Revenue_Comm | decimal(38,2) | YES | Revenue from Commodities positions + Commodities CFD ticket fee by percent (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 164 | Revenue_Ind | decimal(38,2) | YES | Revenue from Indices positions + Indices CFD ticket fee by percent (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 165 | PnL_FX | decimal(38,2) | YES | Customer-side PnL on FX (Currencies) positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 166 | PnL_Comm | decimal(38,2) | YES | Customer-side PnL on Commodities positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 167 | PnL_Ind | decimal(38,2) | YES | Customer-side PnL on Indices positions (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 168 | FirstNewFundedDate | date | YES | Date when customer first satisfied the IsFunded_New criteria (first VL3-verified funded day). NULL if never funded under new definition (Tier 1 — BI_DB_CID_DailyPanel_FullData) |
| 169 | ACC_ChurnDays | int | YES | Consecutive days since first funded date where customer was not in IsFunded_New state. Resets to 0 when IsFunded_New=1. See parent wiki §2.5 (Tier 1 — BI_DB_CID_DailyPanel_FullData) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| All 169 columns | BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | Same column name | None — metadata-only partition switch |

### 5.2 ETL Pipeline

```
SP_CID_DailyPanel_FullData (@date)
  |-- INSERT INTO BI_DB_CID_DailyPanel_FullData (daily ETL) ---|
  v
BI_DB_dbo.BI_DB_CID_DailyPanel_FullData
  [HASH(CID), CLUSTERED INDEX(DateID), 183 cols, partitioned daily]
  |
  |-- SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE (@dt)
  |   Creates: BI_DB_CID_DailyPanel_FullData_SWITCH (SELECT TOP 0 *)
  |   Creates: BI_DB_CID_DailyPanel_FullData_SWITCH_SINGLE (SELECT TOP 0 *)
  |
  |-- [Data loaded into _SWITCH_SINGLE for target date]
  |
  |-- SP_BI_DB_CID_DailyPanel_FullData_SWITCH
  |   Step 1: ALTER TABLE ...FullData SWITCH PARTITION → ...FullData_SWITCH
  |   Step 2: ALTER TABLE ...SWITCH_SINGLE SWITCH PARTITION → ...FullData
  |   Step 3: TRUNCATE TABLE ...FullData_SWITCH
  v
BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH
  [Always empty after operation completes — temporary staging only]
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| (all columns) | BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | Schema-identical parent table — data flows via partition switch |

### 6.2 Referenced By (other objects point to this)

| Object | Schema | Description |
|---|---|---|
| SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE | BI_DB_dbo | Creates this table at runtime |
| SP_BI_DB_CID_DailyPanel_FullData_SWITCH | BI_DB_dbo | Receives old partition data, then is truncated |

---

## 7. Sample Queries

### 7.1 Check if a partition switch is in progress

```sql
SELECT COUNT(*) AS rows_in_switch
FROM [BI_DB_dbo].[BI_DB_CID_DailyPanel_FullData_SWITCH]
-- Non-zero result = switch operation in progress or failed
```

### 7.2 Identify which date partition is staged

```sql
SELECT DISTINCT DateID
FROM [BI_DB_dbo].[BI_DB_CID_DailyPanel_FullData_SWITCH]
-- Empty = normal state (table truncated after switch)
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources found specific to this shadow table. See parent table `BI_DB_CID_DailyPanel_FullData` wiki for full business context.

---

*Generated: 2026-04-28 | Quality: pending/10 | Phases: 11/14*
*Tiers: 169 T1, 0 T2, 0 T3, 0 T4 | Elements: 169/169, Logic: 2/10, Lineage: complete*
*Object: BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH | Type: Table (partition-switch shadow) | Production Source: BI_DB_CID_DailyPanel_FullData via ALTER TABLE SWITCH PARTITION*
