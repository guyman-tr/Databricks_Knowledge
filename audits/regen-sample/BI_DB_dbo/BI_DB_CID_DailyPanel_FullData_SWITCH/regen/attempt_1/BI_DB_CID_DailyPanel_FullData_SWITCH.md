# BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH

> Partition-switch shadow table for `BI_DB_CID_DailyPanel_FullData` — a transient staging artifact with 169 columns, identical schema to the parent table. Created empty via `SELECT TOP 0 *`, used to receive old partition data during daily partition swap, then immediately truncated. Persistently empty (0 rows); data resides here only for the duration of a single `ALTER TABLE ... SWITCH PARTITION` operation.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (partition-switch shadow) |
| **Production Source** | SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE (creates), SP_BI_DB_CID_DailyPanel_FullData_SWITCH (orchestrates swap) |
| **Refresh** | On-demand — created/dropped by SP_CREATE_SWITCH_SINGLE before each daily load; truncated after each partition swap |
| | |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |
| **Partition** | RANGE LEFT on DateID, daily partitions 20180101-20210430 (DDL snapshot; dynamically rebuilt by SP) |
| | |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_CID_DailyPanel_FullData_SWITCH is a **transient infrastructure table** — it has no independent business meaning. It exists solely as a partition-switching shadow for `BI_DB_CID_DailyPanel_FullData`, the primary daily depositor panel.

The daily ETL flow works as follows:
1. `SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE` drops and re-creates both `_SWITCH` and `_SWITCH_SINGLE` as empty schema clones (`SELECT TOP 0 * FROM BI_DB_CID_DailyPanel_FullData`).
2. `SP_CID_DailyPanel_FullData` inserts the day's data into `_SWITCH_SINGLE`.
3. `SP_BI_DB_CID_DailyPanel_FullData_SWITCH` executes a three-step partition swap:
   - **Step 1**: `ALTER TABLE BI_DB_CID_DailyPanel_FullData SWITCH PARTITION N TO BI_DB_CID_DailyPanel_FullData_SWITCH PARTITION M` — moves the old partition data from the main table into this shadow table.
   - **Step 2**: `ALTER TABLE BI_DB_CID_DailyPanel_FullData_SWITCH_SINGLE SWITCH PARTITION M TO BI_DB_CID_DailyPanel_FullData PARTITION N WITH (TRUNCATE_TARGET = ON)` — moves new data from `_SWITCH_SINGLE` into the main table.
   - **Step 3**: `TRUNCATE TABLE BI_DB_CID_DailyPanel_FullData_SWITCH` — clears the old partition data from this shadow table.

The table is **always empty** outside the brief window between Steps 1 and 3. It holds 0 rows at rest.

All 169 columns are structurally identical to `BI_DB_CID_DailyPanel_FullData`. The DDL snapshot in SSDT contains partitions 20180101-20210430; the SP dynamically creates partitions around the target date at runtime.

---

## 2. Business Logic

### 2.1 Partition Switch Mechanism

**What**: Three-phase atomic partition swap using Synapse `ALTER TABLE ... SWITCH PARTITION`.

**Columns Involved**: All (structural clone)

**Rules**:
- The SP reads `sys.partitions`, `sys.partition_functions`, and `sys.partition_range_values` to determine the correct partition number for the target DateID.
- If `DateID <= MinValue` of the partition range, partition 1 is used.
- If `DateID > MaxValue`, the last partition is used.
- Otherwise, the first partition whose boundary value >= DateID is selected.
- The same logic runs independently for both `_SWITCH` and `_SWITCH_SINGLE` tables, as they may have different partition ranges.

### 2.2 No Data Transformation

**What**: This table performs zero data transformation. Data passes through via partition switching without any column-level modification.

**Columns Involved**: All 169 columns

**Rules**:
- Schema is created via `SELECT TOP 0 * FROM BI_DB_CID_DailyPanel_FullData` — identical columns, types, nullability.
- Distribution (HASH on CID) and index (CLUSTERED INDEX on DateID ASC) match the parent table to enable partition switching.
- No INSERT, UPDATE, or CASE logic touches this table — data moves via metadata-only `ALTER TABLE SWITCH`.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- Distribution: HASH(CID) — matches `BI_DB_CID_DailyPanel_FullData` for partition switching compatibility.
- Index: CLUSTERED COLUMNSTORE INDEX (DDL); SP creates with CLUSTERED INDEX (DateID ASC) at runtime.
- Partition: RANGE LEFT on DateID. DDL shows daily partitions 20180101-20210430; SP dynamically creates 3 partitions around the target date.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| What data is in the switch table? | `SELECT TOP 10 * FROM BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH` — will return 0 rows (table is always empty at rest) |
| How does the partition swap work? | Read SP_BI_DB_CID_DailyPanel_FullData_SWITCH source code |
| What is the parent table? | Query `BI_DB_dbo.BI_DB_CID_DailyPanel_FullData` — that is where the business data lives |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| BI_DB_CID_DailyPanel_FullData | Same schema, partition switch target | Data origin — this table is its structural clone |
| BI_DB_CID_DailyPanel_FullData_SWITCH_SINGLE | Same schema, sibling staging table | Holds new daily data before swap into main table |

### 3.4 Gotchas

- **Always empty**: Do not query this table for business data. It holds 0 rows at rest. Use `BI_DB_CID_DailyPanel_FullData` instead.
- **DDL partition mismatch**: The SSDT DDL shows partitions 20180101-20210430, but the SP dynamically creates 3 partitions around the target date at runtime. The DDL is a snapshot, not the runtime state.
- **Schema drift**: If columns are added to `BI_DB_CID_DailyPanel_FullData`, this table must also be updated (via the CREATE SP) or partition switching will fail. The SSDT DDL has 169 columns vs. the parent's 183 — the SP handles this by re-creating from `SELECT TOP 0 *` at each run.
- **Drop/recreate pattern**: This table is dropped and recreated before each daily load. It is not a persistent staging table.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (BI_DB_CID_DailyPanel_FullData) — passthrough via partition switch |
| Tier 2 | ETL-computed in the parent table's writer SP (SP_CID_DailyPanel_FullData) — inherited as-is |
| Tier 4 | Deprecated or inferred — no live data; inherited from parent table's documentation |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | eToro customer ID (Real CID). Only depositors (IsDepositor=1) present. FK to DWH_dbo.Dim_Customer.RealCID. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 1 — DWH_dbo.Dim_Customer) |
| 2 | DateID | int | NO | Partition key: date in YYYYMMDD format. One row per CID per day. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 3 | Active_Month | int | YES | YYYYMM of this row's date. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 4 | ActiveDate | date | YES | Calendar date of this row. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 5 | Seniority | int | YES | Months since customer's first deposit (FTDdate) as of start of the current month. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 6 | Seniority_Seg | varchar(11) | NO | Seniority bucket label: '<1month', '1-2month', '<2-3month', ... '<11-12month', '12+month'. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 7 | Reg_Month | int | YES | YYYYMM of customer registration. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Customer.RegisteredReal) |
| 8 | RegDate | date | YES | Customer registration date. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Customer.RegisteredReal) |
| 9 | IsReg_ThisD | int | NO | 1 if customer registered on this specific date. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 10 | FTD_Month | int | YES | YYYYMM of customer's first-time deposit (FTD). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Customer.FirstDepositDate) |
| 11 | FTDdate | date | YES | Customer's first-time deposit date. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Customer.FirstDepositDate) |
| 12 | IsFTD_ThisD | int | NO | 1 if customer made their first deposit on this specific date. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 13 | FTDA | money | YES | First-time deposit amount (USD). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Customer.FirstDepositAmount) |
| 14 | Region | nvarchar(500) | NO | Geographic region label (e.g., 'French', 'Arabic GCC', 'Australia', 'North Europe'). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 1 — DWH_dbo.Dim_Country.Region) |
| 15 | Country | varchar(500) | YES | Customer's country name at snapshot date. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 1 — DWH_dbo.Dim_Country.Name) |
| 16 | Channel | nvarchar(500) | NO | Acquisition channel (e.g., 'Direct', 'Affiliate', 'SEM', 'SEO', 'Friend Referral', 'Mobile Acquisition'). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_CIDFirstDates.Channel) |
| 17 | SubChannel | nvarchar(500) | NO | Acquisition sub-channel detail. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_CIDFirstDates.SubChannel) |
| 18 | AffiliateID | int | YES | Affiliate serial ID for affiliate-acquired customers; NULL for direct/organic. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_CIDFirstDates.SerialID) |
| 19 | FirstAction | varchar(22) | YES | Deprecated -- always NULL. Originally planned first action type. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 4 — SP: NULL AS FirstAction) |
| 20 | FirstInstrument | varchar(50) | YES | Deprecated -- always NULL. Originally planned first instrument traded. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 4 — SP: NULL AS FirstInstrument) |
| 21 | V2_Complete | int | NO | 1 if customer has completed verification level 2 as of this date. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Customer.VerificationLevel2Date) |
| 22 | V3_Complete | int | NO | 1 if customer has completed full KYC (verification level 3) as of this date. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Customer.VerificationLevel3Date) |
| 23 | IsPro | int | NO | 1 if customer is classified as professional client (MifidCategorizationID IN 2,3 in Fact_SnapshotCustomer). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_SnapshotCustomer.MifidCategorizationID) |
| 24 | IsOTD | int | YES | 1 if customer has made exactly one prior deposit (One Trade Done). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 25 | Daily_Classification | varchar(50) | YES | Customer segment label (e.g., 'Traders', 'Crypto'). Set by separate SP_CID_DailyPanel_UpdateCluster SP. As of 2026 all rows are empty string -- appears non-operational post-Synapse migration. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 4 — SP_CID_DailyPanel_UpdateCluster) |
| 26 | EOD_Club | varchar(50) | NO | Loyalty tier at EOD: 'LowBronze', 'HighBronze', 'Silver', 'Gold', 'Platinum', 'Platinum Plus', 'Diamond'. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_PlayerLevel.Name) |
| 27 | EOD_Regulation | varchar(50) | NO | Regulatory jurisdiction name at EOD (e.g., 'CySEC', 'FCA', 'ASIC & GAML', 'FinCEN+FINRA'). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — DWH_dbo.Dim_Regulation.Name) |
| 28 | Equity | decimal(23,4) | YES | Total EOD equity (USD): NWA (net worth of assets) + Liabilities from DWH_dbo.V_Liabilities. Includes all open positions at market value. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — DWH_dbo.V_Liabilities) |
| 29 | RealizedEquity | money | YES | Realized equity component (cash + closed positions only), excluding open unrealized positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — DWH_dbo.V_Liabilities.RealizedEquity) |
| 30 | AUM | money | YES | Assets Under Management: value of assets the customer holds in copy-trading and portfolio products. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — DWH_dbo.V_Liabilities.AUM) |
| 31 | Credit | money | NO | Credit/margin balance: funds provided as credit (e.g., bonus credits). V_Liabilities.EOD_Balance. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — DWH_dbo.V_Liabilities.EOD_Balance) |
| 32 | ActiveUser | int | NO | 1 if customer logged in (ActionTypeID=14) on this date. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 33 | Active | int | NO | 1 if customer had any position open or closed on this date (any instrument, including partial close children excluded). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 34 | ActiveOpen | int | NO | 1 if customer opened a new position today -- manual trade OR started/added a mirror (AirDrop excluded). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 35 | IsOpen_Copy | int | NO | 1 if customer opened a new copy relationship (started copying a trader) today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 36 | Count_Opened_Copy | int | NO | Number of distinct copy relationships opened today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 37 | Count_Closed_Copy | int | NO | Number of distinct copy relationships closed today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 38 | MoneyIn_Copy | decimal(38,2) | NO | Total funds allocated into copy positions today (negative Amount from AT=17,15). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 39 | MoneyOut_Copy | decimal(38,2) | NO | Total funds returned from closed copy positions today (Amount from AT=18,16). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 40 | IsOpen_CopyPortfolio | int | NO | 1 if customer opened a CopyPortfolio (managed portfolio product) today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 41 | Count_Opened_CopyPortfolio | int | NO | Number of CopyPortfolio relationships opened today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 42 | Count_Closed_CopyPortfolio | int | NO | Number of CopyPortfolio relationships closed today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 43 | MoneyIn_CopyPortfolio | decimal(38,2) | NO | Total funds into CopyPortfolio positions today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 44 | MoneyOut_CopyPortfolio | decimal(38,2) | NO | Total funds returned from CopyPortfolio positions today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 45 | Active_Copy | int | NO | 1 if customer has an open copy position on this date (MirrorID>0). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 46 | Active_Real_Stocks | int | NO | 1 if customer has an open settled stock position (IsSettled=1, InstrumentTypeID IN 5,6, non-AirDrop). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 47 | Active_CFD_Stocks | int | NO | 1 if customer has an open CFD stock position (IsSettled=0, InstrumentTypeID IN 5,6). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 48 | Active_Real_Crypto | int | NO | 1 if customer has an open settled crypto position (IsSettled=1, InstrumentTypeID=10, non-AirDrop). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 49 | Active_CFD_Crypto | int | NO | 1 if customer has an open CFD crypto position (IsSettled=0, InstrumentTypeID=10). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 50 | Active_FX/Comm/Ind | int | NO | 1 if customer has an open FX/commodities/indices position (InstrumentTypeID IN 1,2,4). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 51 | ActiveOpen_Copy | int | NO | 1 if opened a copy position today (MirrorID>0, non-portfolio, OpenDateID=today). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 52 | ActiveOpen_Real_Stocks | int | NO | 1 if opened a settled stock position today (non-AirDrop). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 53 | ActiveOpen_CFD_Stocks | int | NO | 1 if opened a CFD stock position today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 54 | ActiveOpen_Real_Crypto | int | NO | 1 if opened a settled crypto position today (non-AirDrop). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 55 | ActiveOpen_CFD_Crypto | int | NO | 1 if opened a CFD crypto position today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 56 | ActiveOpen_FX/Comm/Ind | int | NO | 1 if opened a FX/Comm/Ind position today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 57 | NewTrades_Copy | int | NO | Count of new copy positions opened today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 58 | NewTrades_Real_Stocks | int | NO | Count of new settled stock positions opened today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 59 | NewTrades_CFD_Stocks | int | NO | Count of new CFD stock positions opened today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 60 | NewTrades_Real_Crypto | int | NO | Count of new settled crypto positions opened today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 61 | NewTrades_CFD_Crypto | int | NO | Count of new CFD crypto positions opened today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 62 | NewTrades_FX/Comm/Ind | int | NO | Count of new FX/Comm/Ind positions opened today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 63 | NewTrades_Total | int | YES | Total count of all new positions opened today across all instrument types. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 64 | AmountIn_NewTrades_Copy | money | NO | Total USD invested in new copy positions today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 65 | AmountIn_NewTrades_Real_Stocks | money | NO | Total USD in new settled stock positions today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 66 | AmountIn_NewTrades_CFD_Stocks | money | NO | Total USD in new CFD stock positions today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 67 | AmountIn_NewTrades_Real_Crypto | money | NO | Total USD in new settled crypto positions today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 68 | AmountIn_NewTrades_CFD_Crypto | money | NO | Total USD in new CFD crypto positions today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 69 | AmountIn_NewTrades_FX/Comm/Ind | money | NO | Total USD in new FX/Comm/Ind positions today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 70 | AmountIn_NewTrades_Total | money | YES | Total USD invested in all new positions today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 71 | Revenue_Copy | decimal(38,2) | NO | Daily revenue from copy positions (FullCommissions + RollOverFee) + TicketFeeByPercent_Copy. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_DailyCommisionReport) |
| 72 | Revenue_Real_Stocks | decimal(38,2) | NO | Revenue from settled stock positions + flat ticket fees. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_DailyCommisionReport) |
| 73 | Revenue_CFD_Stocks | decimal(38,2) | NO | Revenue from CFD stock positions + ticket fee by percent (Stocks CFD). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_DailyCommisionReport) |
| 74 | Revenue_Real_Crypto | decimal(38,2) | NO | Revenue from settled crypto positions + ticket fee by percent (Crypto Real). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_DailyCommisionReport) |
| 75 | Revenue_CFD_Crypto | decimal(38,2) | NO | Revenue from CFD crypto positions + ticket fee by percent (Crypto CFD). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_DailyCommisionReport) |
| 76 | Revenue_FX/Comm/Ind | decimal(38,2) | NO | Revenue from FX/Commodities/Indices positions + ticket fee by percent. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_DailyCommisionReport) |
| 77 | Revenue_Total | decimal(38,2) | YES | Total daily revenue across all instruments + all fee types (commissions + rollover + ticket + conversion + Islamic). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 78 | PnL_Copy | decimal(38,4) | NO | Customer-side PnL on copy positions on this date. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 79 | PnL_Real_Stocks | decimal(38,4) | NO | Customer-side PnL on settled stock positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 80 | PnL_CFD_Stocks | decimal(38,4) | NO | Customer-side PnL on CFD stock positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 81 | PnL_Real_Crypto | decimal(38,4) | NO | Customer-side PnL on settled crypto positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 82 | PnL_CFD_Crypto | decimal(38,4) | NO | Customer-side PnL on CFD crypto positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 83 | PnL_FX/Comm/Ind | decimal(38,4) | NO | Customer-side PnL on FX/Comm/Ind positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 84 | PnL_Total | decimal(38,4) | YES | Total customer-side PnL across all instruments (sum of Copy + Real_Stocks + CFD_Stocks + Real_Crypto + CFD_Crypto + FX/Comm/Ind). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 85 | TotalDeposits | decimal(38,2) | NO | Total deposit amount (USD) on this date (Fact_CustomerAction ActionTypeID=7). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 86 | CountDeposits | int | NO | Number of deposits on this date. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 87 | TotalCashouts | decimal(38,2) | NO | Total cashout amount (USD) on this date (ActionTypeID=8). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 88 | TotalCoFee | money | NO | Copy-out fee charged on copy position closure (ActionTypeID=30, Commission field). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 89 | NetDeposits | decimal(38,2) | YES | TotalDeposits minus TotalCashouts for this date. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 90 | ACC_Revenue_Copy | decimal(38,2) | YES | Lifetime accumulated revenue from copy positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 91 | ACC_Revenue_Real_Stocks | decimal(38,2) | YES | Lifetime accumulated revenue from settled stocks. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 92 | ACC_Revenue_CFD_Stocks | decimal(38,2) | YES | Lifetime accumulated revenue from CFD stocks. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 93 | ACC_Revenue_Real_Crypto | decimal(38,2) | YES | Lifetime accumulated revenue from settled crypto. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 94 | ACC_Revenue_CFD_Crypto | decimal(38,2) | YES | Lifetime accumulated revenue from CFD crypto. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 95 | ACC_Revenue_FX/Comm/Ind | decimal(38,2) | YES | Lifetime accumulated revenue from FX/Comm/Ind. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 96 | ACC_Revenue_Total | decimal(38,2) | YES | Lifetime accumulated total revenue (all instruments + all fee types). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 97 | ACC_PnL_Copy | decimal(38,4) | YES | Lifetime accumulated customer PnL on copy positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 98 | ACC_PnL_Real_Stocks | decimal(38,4) | YES | Lifetime accumulated customer PnL on settled stocks. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 99 | ACC_PnL_CFD_Stocks | decimal(38,4) | YES | Lifetime accumulated customer PnL on CFD stocks. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 100 | ACC_PnL_Real_Crypto | decimal(38,4) | YES | Lifetime accumulated customer PnL on settled crypto. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 101 | ACC_PnL_CFD_Crypto | decimal(38,4) | YES | Lifetime accumulated customer PnL on CFD crypto. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 102 | ACC_PnL_FX/Comm/Ind | decimal(38,4) | YES | Lifetime accumulated customer PnL on FX/Comm/Ind. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 103 | ACC_PnL_Total | decimal(38,4) | YES | Lifetime accumulated total customer PnL. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 104 | ACC_TotalDeposits | decimal(38,2) | YES | Lifetime total deposits (USD). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 105 | ACC_CountDeposits | int | YES | Lifetime total deposit count. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 106 | ACC_TotalCashouts | decimal(38,2) | YES | Lifetime total cashouts (USD). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 107 | ACC_TotalCoFee | money | YES | Lifetime total copy-out fees paid. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 108 | ACC_NetDeposits | decimal(38,2) | YES | Lifetime net deposits (TotalDeposits - TotalCashouts cumulative). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 109 | UpdateDate | datetime | NO | ETL timestamp: GETDATE() at time of SP execution. Reflects the most recent daily ETL run for this partition. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 110 | AccountManager | varchar(101) | YES | Account manager full name (FirstName + ' ' + LastName) from Dim_Manager. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — DWH_dbo.Dim_Manager) |
| 111 | IsIslamic | int | NO | 1 if customer has a swap-free/Islamic account (WeekendFeePrecentage=0). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — DWH_dbo.Dim_Customer.WeekendFeePrecentage) |
| 112 | IsContacted | int | NO | 1 if customer was contacted through bonus/CRM channel on this date. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_NewBonusReport) |
| 113 | IsContactedAmount | money | NO | Total deposit amount from contacted periods on this date. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_NewBonusReport) |
| 114 | EOD_IsFunded | int | NO | 1 if EOD_Equity >= $25 (original funded customer threshold). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 115 | WithdrawalToWallet | decimal(38,2) | NO | Cashout amount directed to eToro Money wallet (FundingTypeID=27). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 116 | ACC_WithdrawalToWallet | decimal(38,2) | YES | Lifetime total withdrawals to eToro Money wallet. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 117 | LastApplicationProAccountDate | date | NO | Date of most recent professional account application; '1900-01-01' sentinel if never applied. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — External_BI_OUTPUT_Customer_ProfessionalCustomers) |
| 118 | LastPosOpenDate | date | YES | Most recent date customer opened a position (ActionTypeID IN 1,2), max of today vs. yesterday's carry-forward. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 119 | LastLoggedIn | date | YES | Most recent login date (ActionTypeID=14), max of today vs. yesterday's carry-forward. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Fact_CustomerAction) |
| 120 | EOD_Equity_Copy | money | YES | EOD equity in active copy/mirror positions (Amount + PositionPnL for MirrorID>0). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 121 | EOD_Equity_Real_Crypto | money | YES | EOD equity in settled cryptocurrency positions (IsSettled=1, InstrumentTypeID=10). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 122 | EOD_Equity_Real_Stocks | money | YES | EOD equity in settled stock/ETF positions (IsSettled=1, InstrumentTypeID IN 5,6). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 123 | EOD_Equity_CFD_Crypto | money | YES | EOD equity in leveraged crypto CFD positions (IsSettled=0, InstrumentTypeID=10). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 124 | EOD_Equity_CFD_Stocks | money | YES | EOD equity in leveraged stock/ETF CFD positions (IsSettled=0, InstrumentTypeID IN 5,6). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 125 | EOD_Equity_FX/Comm/Ind | money | YES | EOD equity in FX, commodities, and indices positions (InstrumentTypeID IN 1,2,4). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 126 | EOD_Equity_Real_Crypto_Lev1 | money | YES | EOD equity in crypto positions where Leverage=1 AND IsBuy=1 (unlevered long). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 127 | EOD_Equity_Real_Stocks_LevCFD | money | YES | EOD equity in stock positions where Leverage>1 OR IsBuy=0 (levered or short). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 128 | EOD_Equity_CFD_Crypto_Lev1 | money | YES | EOD equity in CFD-Crypto positions where Leverage=1 AND IsBuy=1. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 129 | EOD_Equity_CFD_Stocks_LevCFD | money | YES | EOD equity in CFD-Stocks positions where Leverage>1 OR IsBuy=0. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 130 | Active_Real_Stocks_Lev1 | tinyint | YES | 1 if customer has an open stock position with Leverage=1 AND IsBuy=1. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 131 | Active_CFD_Stocks_LevCFD | tinyint | YES | 1 if customer has an open stock position with Leverage>1 OR IsBuy=0. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 132 | Active_Real_Crypto_Lev1 | tinyint | YES | 1 if customer has an open crypto position with Leverage=1 AND IsBuy=1. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 133 | Active_CFD_Crypto_LevCFD | tinyint | YES | 1 if customer has an open crypto position with Leverage>1 OR IsBuy=0. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 134 | ActiveOpen_Real_Stocks_Lev1 | tinyint | YES | 1 if opened a stock position (Leverage=1, IsBuy=1) today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 135 | ActiveOpen_CFD_Stocks_LevCFD | tinyint | YES | 1 if opened a leveraged/short stock position today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 136 | ActiveOpen_Real_Crypto_Lev1 | tinyint | YES | 1 if opened a crypto position (Leverage=1, IsBuy=1) today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 137 | ActiveOpen_CFD_Crypto_LevCFD | tinyint | YES | 1 if opened a leveraged/short crypto position today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 138 | NewTrades_Real_Stocks_Lev1 | int | YES | Count of new Lev1 stock positions (Leverage=1, IsBuy=1) today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 139 | NewTrades_CFD_Stocks_LevCFD | int | YES | Count of new leveraged/short stock positions today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 140 | NewTrades_Real_Crypto_Lev1 | int | YES | Count of new Lev1 crypto positions today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 141 | NewTrades_CFD_Crypto_LevCFD | int | YES | Count of new leveraged/short crypto positions today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 142 | AmountIn_NewTrades_Real_Stocks_Lev1 | money | YES | USD in new Lev1 stock positions today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 143 | AmountIn_NewTrades_CFD_Stocks_LevCFD | money | YES | USD in new leveraged/short stock positions today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 144 | AmountIn_NewTrades_Real_Crypto_Lev1 | money | YES | USD in new Lev1 crypto positions today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 145 | AmountIn_NewTrades_CFD_Crypto_LevCFD | money | YES | USD in new leveraged/short crypto positions today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 146 | Revenue_Real_Stocks_Lev1 | money | YES | Revenue from Lev1 stock positions + flat ticket fees. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_DailyCommisionReport) |
| 147 | Revenue_CFD_Stocks_LevCFD | money | YES | Revenue from leveraged/short stock positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_DailyCommisionReport) |
| 148 | Revenue_Real_Crypto_Lev1 | money | YES | Revenue from Lev1 crypto positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_DailyCommisionReport) |
| 149 | Revenue_CFD_Crypto_LevCFD | money | YES | Revenue from leveraged/short crypto positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_DailyCommisionReport) |
| 150 | PnL_Real_Stocks_Lev1 | money | YES | PnL on Lev1 stock positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 151 | PnL_CFD_Stocks_LevCFD | money | YES | PnL on leveraged/short stock positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 152 | PnL_Real_Crypto_Lev1 | money | YES | PnL on Lev1 crypto positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 153 | PnL_CFD_Crypto_LevCFD | money | YES | PnL on leveraged/short crypto positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 154 | IsFunded_New | int | YES | 1 if EOD_Equity > 0 AND VerificationLevelID=3 AND FirstActionDate < tomorrow (stricter funded definition). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |
| 155 | NewMarketingRegion | varchar(50) | YES | Marketing team region classification (e.g., 'Arabic', 'French', 'Norway', 'ROW'). Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Country.MarketingRegionManualName) |
| 156 | Active_FX | int | YES | 1 if customer has an open FX (Currencies, InstrumentTypeID=1) position. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 157 | Active_Comm | int | YES | 1 if customer has an open Commodities (InstrumentTypeID=2) position. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 158 | Active_Ind | int | YES | 1 if customer has an open Indices (InstrumentTypeID=4) position. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 159 | ActiveOpen_FX | int | YES | 1 if opened a FX position today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 160 | ActiveOpen_Comm | int | YES | 1 if opened a Commodities position today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 161 | ActiveOpen_Ind | int | YES | 1 if opened an Indices position today. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — Dim_Position) |
| 162 | Revenue_FX | decimal(38,2) | YES | Revenue from FX (Currencies) positions + Currencies CFD ticket fee by percent. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_DailyCommisionReport) |
| 163 | Revenue_Comm | decimal(38,2) | YES | Revenue from Commodities positions + Commodities CFD ticket fee by percent. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_DailyCommisionReport) |
| 164 | Revenue_Ind | decimal(38,2) | YES | Revenue from Indices positions + Indices CFD ticket fee by percent. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_DailyCommisionReport) |
| 165 | PnL_FX | decimal(38,2) | YES | Customer-side PnL on FX (Currencies) positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 166 | PnL_Comm | decimal(38,2) | YES | Customer-side PnL on Commodities positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 167 | PnL_Ind | decimal(38,2) | YES | Customer-side PnL on Indices positions. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_PositionPnL) |
| 168 | FirstNewFundedDate | date | YES | Date when customer first satisfied the IsFunded_New criteria (first VL3-verified funded day). NULL if never funded under new definition. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — BI_DB_CIDFirstDates.FirstNewFundedDate) |
| 169 | ACC_ChurnDays | int | YES | Consecutive days since first funded date where customer was not in IsFunded_New state. Resets to 0 when IsFunded_New=1. Passthrough from BI_DB_CID_DailyPanel_FullData. (Tier 2 — SP_CID_DailyPanel_FullData) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| All 169 columns | BI_DB_CID_DailyPanel_FullData | Same column name | Partition switch passthrough (no transformation) |

### 5.2 ETL Pipeline

```
[BI_DB_dbo production tables — multi-source ETL]
        |
        v
  SP_CID_DailyPanel_FullData (@date)
  [Priority 0, SB_Daily process]
        |  INSERT INTO BI_DB_CID_DailyPanel_FullData_SWITCH_SINGLE
        v
  BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH_SINGLE
  [Temporary staging — holds new daily data]
        |
        |  SP_BI_DB_CID_DailyPanel_FullData_SWITCH:
        |    Step 1: ALTER TABLE FullData SWITCH PARTITION → _SWITCH (old data out)
        |    Step 2: ALTER TABLE _SWITCH_SINGLE SWITCH PARTITION → FullData (new data in)
        |    Step 3: TRUNCATE TABLE _SWITCH (discard old data)
        v
  BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH   ← THIS TABLE (transient shadow)
  [HASH(CID), CLUSTERED COLUMNSTORE, partitioned on DateID]
  [0 rows at rest — holds old partition data only between Step 1 and Step 3]
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| (all columns) | BI_DB_CID_DailyPanel_FullData | Schema source — structural clone via SELECT TOP 0 * |

### 6.2 Referenced By (other objects point to this)

| Object | Schema | Description |
|---|---|---|
| SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE | BI_DB_dbo | Creates this table as empty schema clone |
| SP_BI_DB_CID_DailyPanel_FullData_SWITCH | BI_DB_dbo | Orchestrates partition swap: moves old data in, then truncates |
| SP_CID_DailyPanel_FullData | BI_DB_dbo | Comments reference this table in partition switch workflow |

---

## 7. Sample Queries

### 7.1 Verify Table Is Empty (Expected State)

```sql
SELECT COUNT(*) AS row_count
FROM [BI_DB_dbo].[BI_DB_CID_DailyPanel_FullData_SWITCH]
-- Expected: 0 (table is always empty at rest)
```

### 7.2 Check Partition Structure at Runtime

```sql
SELECT
    prt.partition_number,
    CAST(rng.value AS INT) AS boundary_value,
    prt.rows
FROM sys.tables tbl
INNER JOIN sys.partitions prt ON tbl.object_id = prt.object_id
INNER JOIN sys.indexes idx ON prt.object_id = idx.object_id AND prt.index_id = idx.index_id
INNER JOIN sys.data_spaces ds ON idx.data_space_id = ds.data_space_id
INNER JOIN sys.partition_schemes ps ON ds.data_space_id = ps.data_space_id
INNER JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
LEFT JOIN sys.partition_range_values rng ON pf.function_id = rng.function_id AND rng.boundary_id = prt.partition_number
WHERE tbl.object_id = OBJECT_ID('BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH')
ORDER BY prt.partition_number
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources found for this infrastructure/staging table.

---

*Generated: 2026-04-28 | Quality: 8/10 | Phases: 12/14*
*Tiers: 3 T1, 164 T2, 0 T3, 2 T4 | Elements: 169/169, Logic: 2/10, Query: 3/10*
*Object: BI_DB_dbo.BI_DB_CID_DailyPanel_FullData_SWITCH | Type: Table (partition-switch shadow) | Production Source: SP_BI_DB_CID_DailyPanel_FullData_CREATE_SWITCH_SINGLE*
