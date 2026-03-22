# BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New

> Daily client balance rollup -- same measures as `BI_DB_Client_Balance_CID_Level_New`, aggregated by regulation, geography, account attributes, and transfer flags (no CID). Built in the same ETL run as the CID table from temp table `#RegAgg` (`SUM` over `#CIDAgg` with a wide `GROUP BY`).


| Property                 | Value                                                                                         |
| ------------------------ | --------------------------------------------------------------------------------------------- |
| **Schema**               | BI_DB_dbo                                                                                     |
| **Object Type**          | Table (Fact -- BI reporting layer, aggregate grain)                                           |
| **Production Source**    | Derived -- rollup of `BI_DB_Client_Balance_CID_Level_New` in `SP_Client_Balance_New`          |
| **Refresh**              | Daily                                                                                         |
| **OpsDB**                | Priority 99, ProcessType 3 (same batch as CID Client Balance)                                   |
|                          |                                                                                               |
| **Synapse Distribution** | ROUND_ROBIN                                                                                   |
| **Synapse Index**        | CLUSTERED INDEX (DateID ASC)                                                                  |
|                          |                                                                                               |
| **UC Target**            | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_aggregate_level_new` (expected)    |
| **UC Format**            | Delta                                                                                         |
| **UC Copy Strategy**     | Append, 1440 min (daily)                                                                      |
| **Generic Pipeline ID**  | 943 (sibling of CID Client Balance pipeline)                                                  |


---

## 1. Business Meaning

`BI_DB_Client_Balance_Aggregate_Level_New` is the **aggregate (non-CID) sibling** of `BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New`. Every numeric measure in the CID table is **summed** across customers that share the same combination of classification columns (for example `Regulation`, `Label`, `Country`, `TransferDirection`, `IsCreditReportValidCB`, DLT flags, `TanganyStatus`, `US_State`, and calendar attributes).

Use this table for **segment-level** dashboards, regulatory summaries by jurisdiction, and marketing or operations views where customer-level detail is not required. For **customer-level** balance, reconciliation, cycle-gap checks, and audit trails, use `BI_DB_Client_Balance_CID_Level_New` (and remember to `SUM` by `CID` when transfer rows exist).

### Grain and double counting

- **Grain**: One row per unique combination of all `GROUP BY` keys in `#RegAgg` for a given `DateID` (plus `TanganyStatus` and `US_State` where populated).
- **Transfer rows**: `TransferDirection` and credit-valid transfer flags behave as in the CID table. Aggregated rows still represent the split between current and prior regulation or CB-validity paths -- do not mix with CID-level counts without understanding transfer logic (see `BI_DB_Client_Balance_CID_Level_New`).

### Terminology (shared with CID wiki)

- **NWA** -- Non-Withdrawable Amount (bonus principal not cashable).
- **TRS** -- Total Return Swap (crypto settlement type).
- **DLT** -- Distributed Ledger Technology (Tangany wallet context).
- **SDRT** -- Stamp Duty Reserve Tax (UK).
- **C2P** -- Copy to Portfolio (copied trades as independent positions; column tracks related compensation flow per CID wiki).

---

## 2. Business Logic

### 2.1 ETL pattern -- DELETE + INSERT from `#RegAgg`

After `#CIDAgg` is populated (same logic as the CID insert), the SP builds `#RegAgg`:

- `SELECT` from `#CIDAgg` with `SUM(cast(... AS decimal(18,4)))` on all monetary and measure columns.
- `GROUP BY` all dimension keys: `TransferDirection`, `Regulation`, `IsCreditReportValidCB`, `DidRegulationTransfer`, `DidCBValidTransfer`, `DidDLTTransfer`, `IsDLTUser`, `IsEtoroTradingCID`, `eToroTradingGroupUser`, `IsGlenEagleAccount`, `Region`, `FromRegulation`, `ToRegulation`, `AccountType`, `Label`, `Country`, `MifidCategory`, `Club`, `PlayerStatus`, `DateID`, `IsGermanBaFin`, `IsValidCustomer`, `Date`, `YearMonth`, `YearQuarter`, `Year`, `TanganyStatus`, `US_State`.

Then `DELETE ... WHERE DateID = @dateID` and `INSERT INTO BI_DB_Client_Balance_Aggregate_Level_New` selecting from `#RegAgg` with `ISNULL(..., 0)` on most measures, `GETDATE()` for `UpdateDate`, and `NULL` literals for `DepositConversionFee` and `WithdrawConversionFee` (placeholders, same as CID table).

### 2.2 Balance cycle at aggregate level

The **CID-level** balance equation (Opening + flows = Closing) holds per customer path. **Summing** `OpeningBalance` or `ClosingBalance` across this aggregate grain **does not** generally reproduce a single platform-wide balance without careful filters -- many measures are additive at this grain, but interpret totals with finance for official reconciliation.

### 2.3 Internal transfer columns

`InternalTransferDeposits` is loaded from the rolled-up `DepositsInternalTransfer` column in `#RegAgg` (which sums the CID-level internal deposit transfer metric). `InternalTransferWithdraws` rolls up `CashoutsInternalTransfer` from `#CIDAgg` / `#RegAgg`.

---

## 3. Query Advisory

### 3.1 Distribution and indexing

- **ROUND_ROBIN**: No hash key; full scans are typical for broad reporting. Filter on `DateID` to use the clustered index.
- **Clustered index on `DateID`**: Prefer `WHERE DateID = @d` or bounded ranges.

### 3.2 Relationship to CID table

To validate or drill down: join or filter the CID table on the same dimensions, then compare `SUM` of measures to the aggregate row (allowing for floating-point / money rounding).

### 3.3 Data freshness

Loaded in the **same** `SP_Client_Balance_New` execution as `BI_DB_Client_Balance_CID_Level_New` (Priority 99, daily).

### 3.4 View

`V_BI_DB_Client_Balance_Aggregate_Level_New` -- `SELECT * WHERE DateID >= 20200101` (same pattern as CID view with a different cutoff).

---

## 4. Elements

### Confidence Tier Legend

| Stars   | Tiers  | Meaning                                                                      |
| ------- | ------ | ---------------------------------------------------------------------------- |
| 4 stars | Tier 1 | Upstream wiki verbatim (dim names via Dictionary)                            |
| 3 stars | Tier 2 | From Synapse SP code (`SP_Client_Balance_New`) and CID table lineage         |
| 2 stars | Tier 3 | Computed at insert only (`GETDATE()`, NULL placeholders)                     |
| 1 star  | Tier 4 | Inferred from column name -- `[UNVERIFIED]`                                  |


### Dimension and classification (GROUP BY keys)

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 1 | TransferDirection | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TransferDirection) |
| 2 | Regulation | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Regulation) |
| 3 | IsCreditReportValidCB | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.IsCreditReportValidCB) |
| 4 | DidRegulationTransfer | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.DidRegulationTransfer) |
| 5 | DidCBValidTransfer | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.DidCBValidTransfer) |
| 6 | IsEtoroTradingCID | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.IsEtoroTradingCID) |
| 7 | eToroTradingGroupUser | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.eToroTradingGroupUser) |
| 8 | IsGlenEagleAccount | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.IsGlenEagleAccount) |
| 9 | Region | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Region) |
| 10 | FromRegulation | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.FromRegulation) |
| 11 | ToRegulation | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ToRegulation) |
| 12 | AccountType | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.AccountType) |
| 13 | Label | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Label) |
| 14 | Country | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Country) |
| 15 | MifidCategory | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.MifidCategory) |
| 16 | Club | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Club) |
| 17 | PlayerStatus | [varchar](100) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PlayerStatus) |

### Date

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 18 | DateID | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.DateID) |

### Balance components

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 19 | OpeningBalance | [money] | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.OpeningBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.OpeningBalance) |
| 20 | Deposits | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Deposits`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Deposits) |
| 21 | CompensationDeposit | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationDeposit`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationDeposit) |
| 22 | Bonus | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Bonus`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Bonus) |
| 23 | Compensation | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Compensation`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Compensation) |
| 24 | CompensationPI | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationPI`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationPI) |
| 25 | CompensationToAffiliate | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationToAffiliate`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationToAffiliate) |
| 26 | NWAAdjustment | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NWAAdjustment`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NWAAdjustment) |
| 27 | NegativeRefill | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NegativeRefill`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NegativeRefill) |
| 28 | Cashouts | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Cashouts`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Cashouts) |
| 29 | CashoutsIncludingRedeem | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CashoutsIncludingRedeem`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CashoutsIncludingRedeem) |
| 30 | CompensationCashouts | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationCashouts`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationCashouts) |
| 31 | CashoutFee | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CashoutFee`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CashoutFee) |
| 32 | Chargeback | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Chargeback`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Chargeback) |
| 33 | Refund | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Refund`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Refund) |
| 34 | OvernightFee | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.OvernightFee`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.OvernightFee) |
| 35 | LostDebt | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.LostDebt`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.LostDebt) |
| 36 | ChargebackLoss | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ChargebackLoss`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ChargebackLoss) |
| 37 | OtherNegatives | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.OtherNegatives`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.OtherNegatives) |
| 38 | Foreclosure | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.Foreclosure`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Foreclosure) |
| 39 | CompensationPnLAdjustments | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationPnLAdjustments`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationPnLAdjustments) |
| 40 | CompensationDormantFee | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationDormantFee`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationDormantFee) |
| 41 | ClientBalanceRealizedPnL | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnL`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnL) |
| 42 | ClientBalanceRealizedPnLCFD | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLCFD`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLCFD) |
| 43 | ClientBalanceRealizedPnLRealStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLRealStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLRealStocks) |
| 44 | ClientBalanceRealizedPnLRealCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLRealCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLRealCrypto) |
| 45 | TransferCoins | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TransferCoins`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TransferCoins) |
| 46 | TransferCoinFees | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TransferCoinFees`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TransferCoinFees) |
| 47 | ClosingBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClosingBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClosingBalance) |
| 48 | realizedEquity | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.realizedEquity`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.realizedEquity) |
| 49 | RealCryptoOpenBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.RealCryptoOpenBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.RealCryptoOpenBalance) |

### Sub-balance buckets

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 50 | RealCryptoClosingBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.RealCryptoClosingBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.RealCryptoClosingBalance) |
| 51 | ClientMoneyOpenBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientMoneyOpenBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientMoneyOpenBalance) |
| 52 | ClientMoneyClosingBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientMoneyClosingBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientMoneyClosingBalance) |
| 53 | RealStocksOpeningBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.RealStocksOpeningBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.RealStocksOpeningBalance) |
| 54 | RealStocksClosingBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.RealStocksClosingBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.RealStocksClosingBalance) |
| 55 | ClientBalanceFullCommission | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommission`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommission) |
| 56 | ClientBalanceCommission | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommission`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommission) |

### Commission breakdown

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 57 | ClientBalanceFullCommissionCFD | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionCFD`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionCFD) |
| 58 | ClientBalanceCommissionCFD | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionCFD`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionCFD) |
| 59 | ClientBalanceFullCommissionRealCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionRealCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionRealCrypto) |
| 60 | ClientBalanceCommissionRealCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionRealCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionRealCrypto) |
| 61 | ClientBalanceFullCommissionRealStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionRealStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionRealStocks) |
| 62 | ClientBalanceCommissionRealStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionRealStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionRealStocks) |
| 63 | DividendsPaid | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.DividendsPaid`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.DividendsPaid) |
| 64 | TotalLiability | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalLiability`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalLiability) |

### Liability and position metrics

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 65 | TotalNegativeLiability | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalNegativeLiability`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalNegativeLiability) |
| 66 | WithdrawableLiability | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.WithdrawableLiability`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.WithdrawableLiability) |
| 67 | NegativeWithdrawableLiability | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NegativeWithdrawableLiability`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NegativeWithdrawableLiability) |
| 68 | LiabilityInUsedMargin | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.LiabilityInUsedMargin`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.LiabilityInUsedMargin) |
| 69 | NegativeLiabilityInUsedMargin | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NegativeLiabilityInUsedMargin`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NegativeLiabilityInUsedMargin) |
| 70 | InProcessCashout | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.InProcessCashout`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.InProcessCashout) |
| 71 | NegativeInProcessCashout | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NegativeInProcessCashout`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NegativeInProcessCashout) |
| 72 | NOPCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOPCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOPCrypto) |
| 73 | NOPCryptoCFD | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOPCryptoCFD`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOPCryptoCFD) |
| 74 | NOPStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOPStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOPStocks) |
| 75 | NOPStocksCFD | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOPStocksCFD`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOPStocksCFD) |
| 76 | TotalRealCryptoLoan | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalRealCryptoLoan`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalRealCryptoLoan) |
| 77 | TotalRealCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalRealCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalRealCrypto) |
| 78 | TotalRealStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalRealStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalRealStocks) |
| 79 | PositionPNLCryptoReal | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionPNLCryptoReal`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionPNLCryptoReal) |
| 80 | PositionPNLStocksReal | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionPNLStocksReal`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionPNLStocksReal) |
| 81 | PositionPNL | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionPNL`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionPNL) |
| 82 | AvailableCash | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.AvailableCash`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.AvailableCash) |
| 83 | CashInCopy | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CashInCopy`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CashInCopy) |
| 84 | NOP | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOP`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOP) |
| 85 | PositionAmount | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionAmount`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionAmount) |
| 86 | StockOrders | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.StockOrders`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.StockOrders) |
| 87 | actualNWA | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.actualNWA`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.actualNWA) |
| 88 | UsedBonus | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UsedBonus`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UsedBonus) |

### Unrealized changes

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 89 | UnrealizedCommissionChange | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedCommissionChange`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedCommissionChange) |
| 90 | UnrealizedFullCommissionChange | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedFullCommissionChange`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedFullCommissionChange) |
| 91 | UnrealizedPnLChange | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedPnLChange`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedPnLChange) |
| 92 | UnrealizedPnLChangeCFD | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedPnLChangeCFD`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedPnLChangeCFD) |
| 93 | UnrealizedPnLChangeCryptoReal | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedPnLChangeCryptoReal`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedPnLChangeCryptoReal) |
| 94 | UnrealizedPnLChangeStocksReal | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedPnLChangeStocksReal`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedPnLChangeStocksReal) |
| 95 | UnrealizedFullCommissionChangeRealStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedFullCommissionChangeRealStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedFullCommissionChangeRealStocks) |

### Transfer metrics

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 96 | TotalNetTransfers | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalNetTransfers`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalNetTransfers) |
| 97 | TotalTransfersInvestedRealStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalTransfersInvestedRealStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalTransfersInvestedRealStocks) |
| 98 | TotalTransfersInvestedRealCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalTransfersInvestedRealCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalTransfersInvestedRealCrypto) |
| 99 | NetTransfersNWA | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NetTransfersNWA`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NetTransfersNWA) |
| 100 | NetTransfersUnrealizedPnL | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NetTransfersUnrealizedPnL`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NetTransfersUnrealizedPnL) |
| 101 | NetTransfersLiability | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NetTransfersLiability`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NetTransfersLiability) |
| 102 | NetLiabilityTransferStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NetLiabilityTransferStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NetLiabilityTransferStocks) |
| 103 | NetUnrealizedPnLTransferStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NetUnrealizedPnLTransferStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NetUnrealizedPnLTransferStocks) |

### System

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 104 | UpdateDate | [datetime] | YES | Load timestamp at insert (`GETDATE()` in final SELECT); not aggregated from CID. (Tier 3 -- computed) |

### Position PnL by asset

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 105 | PositionPnLCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionPnLCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionPnLCrypto) |
| 106 | PositionPnLStocks | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionPnLStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionPnLStocks) |
| 107 | TotalCryptoPositionAmount | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalCryptoPositionAmount`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalCryptoPositionAmount) |
| 108 | TotalStocksPositionAmount | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalStocksPositionAmount`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalStocksPositionAmount) |

### Flags

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 109 | IsGermanBaFin | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.IsGermanBaFin) |
| 110 | IsValidCustomer | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.IsValidCustomer) |

### Date variants

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 111 | Date | [date] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Date) |
| 112 | YearMonth | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.YearMonth) |
| 113 | YearQuarter | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.YearQuarter) |
| 114 | Year | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.Year) |

### Additional commission detail

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 115 | UnrealizedCommissionChangeRealStocks | [money] | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedCommissionChangeRealStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedCommissionChangeRealStocks) |
| 116 | TotalRealStocksEquityChange | [money] | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalRealStocksEquityChange`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalRealStocksEquityChange) |
| 117 | CompensationsApexUSStocks | [money] | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationsApexUSStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationsApexUSStocks) |
| 118 | UnrealizedFullCommissionChangeCFDStocks | [money] | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedFullCommissionChangeCFDStocks`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedFullCommissionChangeCFDStocks) |
| 119 | UnrealizedFullCommissionChangeRealCrypto | [money] | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedFullCommissionChangeRealCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedFullCommissionChangeRealCrypto) |
| 120 | UnrealizedFullCommissionChangeCFDCrypto | [money] | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedFullCommissionChangeCFDCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedFullCommissionChangeCFDCrypto) |

### TRS crypto

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 121 | TRSCryptoOpeningBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TRSCryptoOpeningBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TRSCryptoOpeningBalance) |
| 122 | TRSCryptoClosingBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TRSCryptoClosingBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TRSCryptoClosingBalance) |
| 123 | UnrealizedPnLChangeCryptoTRS | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedPnLChangeCryptoTRS`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedPnLChangeCryptoTRS) |
| 124 | TotalCryptoPositionAmountTRS | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalCryptoPositionAmountTRS`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalCryptoPositionAmountTRS) |
| 125 | ClientBalanceRealizedPnLRealCryptoTRS | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLRealCryptoTRS`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLRealCryptoTRS) |
| 126 | ClientBalanceFullCommissionTRSCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionTRSCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionTRSCrypto) |
| 127 | ClientBalanceCommissionTRSCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionTRSCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionTRSCrypto) |
| 128 | UnrealizedFullCommissionChangeTRSCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedFullCommissionChangeTRSCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedFullCommissionChangeTRSCrypto) |
| 129 | NOPCryptoTRS | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOPCryptoTRS`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOPCryptoTRS) |
| 130 | PositionPNLCryptoTRS | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionPNLCryptoTRS`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionPNLCryptoTRS) |
| 131 | TotalTRSCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalTRSCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalTRSCrypto) |

### Adjustment fields

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 132 | CashoutRollback | [decimal](18, 4) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CashoutRollback`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CashoutRollback) |
| 133 | ReverseDeposit | [decimal](18, 4) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ReverseDeposit`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ReverseDeposit) |
| 134 | DepositConversionFee | [decimal](18, 4) | YES | Placeholder; `NULL` literal in final INSERT (same as CID table). (Tier 3 -- computed) |
| 135 | WithdrawConversionFee | [decimal](18, 4) | YES | Placeholder; `NULL` literal in final INSERT (same as CID table). (Tier 3 -- computed) |
| 136 | SDRT | [float] | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.SDRT`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.SDRT) |
| 137 | TanganyStatus | [varchar](20) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TanganyStatus) |

### Trading fees and internal transfers

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 138 | TradingFees | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TradingFees`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TradingFees) |
| 139 | InternalTransferDeposits | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.InternalTransferDeposits`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.InternalTransferDeposits) |
| 140 | InternalTransferWithdraws | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.InternalTransferWithdraws`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.InternalTransferWithdraws) |
| 141 | UnrealizedCommissionChangeRealCrypto | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedCommissionChangeRealCrypto`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedCommissionChangeRealCrypto) |
| 142 | TicketFee | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TicketFee`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TicketFee) |

### DLT and crypto transfers

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 143 | TotalRealCryptoEquityChange | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalRealCryptoEquityChange`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalRealCryptoEquityChange) |
| 144 | NetTransfersUnrealizedPnLCryptoReal | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NetTransfersUnrealizedPnLCryptoReal`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NetTransfersUnrealizedPnLCryptoReal) |
| 145 | NetTransfersLiabilityCryptoReal | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NetTransfersLiabilityCryptoReal`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NetTransfersLiabilityCryptoReal) |
| 146 | DidDLTTransfer | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.DidDLTTransfer) |
| 147 | IsDLTUser | [int] | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.IsDLTUser) |
| 148 | CompensationCryptoTransferOut | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.CompensationCryptoTransferOut`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.CompensationCryptoTransferOut) |

### Real futures

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 149 | ClientBalanceRealizedPnLRealFutures | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLRealFutures`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceRealizedPnLRealFutures) |
| 150 | RealFuturesOpenBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.RealFuturesOpenBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.RealFuturesOpenBalance) |
| 151 | RealFuturesClosingBalance | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.RealFuturesClosingBalance`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.RealFuturesClosingBalance) |
| 152 | ClientBalanceFullCommissionRealFutures | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionRealFutures`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceFullCommissionRealFutures) |
| 153 | ClientBalanceCommissionRealFutures | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionRealFutures`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.ClientBalanceCommissionRealFutures) |
| 154 | NOP_FuturesReal | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOP_FuturesReal`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOP_FuturesReal) |
| 155 | TotalRealFutures | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalRealFutures`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalRealFutures) |
| 156 | PositionPNLFuturesReal | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionPNLFuturesReal`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionPNLFuturesReal) |
| 157 | UnrealizedPnLChangeFuturesReal | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedPnLChangeFuturesReal`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedPnLChangeFuturesReal) |
| 158 | TotalTransfersInvestedRealFutures | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalTransfersInvestedRealFutures`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalTransfersInvestedRealFutures) |
| 159 | UnrealizedFullCommissionChangeRealFutures | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedFullCommissionChangeRealFutures`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedFullCommissionChangeRealFutures) |
| 160 | UnrealizedCommissionChangeRealFutures | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.UnrealizedCommissionChangeRealFutures`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.UnrealizedCommissionChangeRealFutures) |
| 161 | TotalRealFuturesEquityChange | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalRealFuturesEquityChange`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalRealFuturesEquityChange) |
| 162 | NetTransfersUnrealizedPnLFuturesReal | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NetTransfersUnrealizedPnLFuturesReal`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NetTransfersUnrealizedPnLFuturesReal) |
| 163 | NetTransfersLiabilityFuturesReal | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NetTransfersLiabilityFuturesReal`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NetTransfersLiabilityFuturesReal) |
| 164 | TotalFuturesProviderMargin | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalFuturesProviderMargin`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalFuturesProviderMargin) |
| 165 | TotalFuturesLockedCash | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalFuturesLockedCash`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalFuturesLockedCash) |

### Late additions

| # | Column | Type | Nullable | Description |
| --- | --- | --- | --- | --- |
| 166 | TicketFeeByPercent | [decimal](18, 6) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TicketFeeByPercent`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TicketFeeByPercent) |
| 167 | US_State | [varchar](2) | YES | `GROUP BY` key preserved from CID grain; same semantics as CID wiki. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.US_State) |
| 168 | NOP_StocksMargin | [decimal](18, 4) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NOP_StocksMargin`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NOP_StocksMargin) |
| 169 | PositionPnLStocksMargin | [decimal](18, 4) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.PositionPnLStocksMargin`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.PositionPnLStocksMargin) |
| 170 | TotalStocksMargin | [decimal](18, 4) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalStocksMargin`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalStocksMargin) |
| 171 | TotalStockMarginLoanValue | [decimal](18, 4) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.TotalStockMarginLoanValue`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.TotalStockMarginLoanValue) |
| 172 | NetTransferCommission | [decimal](18, 4) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.NetTransferCommission`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.NetTransferCommission) |
| 173 | C2P | [decimal](18, 4) | YES | Aggregated `SUM` from `#RegAgg` over matching CID rows; meaning per `BI_DB_Client_Balance_CID_Level_New.C2P`. (Tier 2 -- SP_Client_Balance_New, BI_DB_Client_Balance_CID_Level_New.C2P) |

---

## 5. Lineage

### 5.1 Immediate source

| Source | Role |
| ------ | ---- |
| `#RegAgg` (temp) | `SUM` of `#CIDAgg` / `BI_DB_Client_Balance_CID_Level_New` measures with wide `GROUP BY` |
| `BI_DB_dbo.SP_Client_Balance_New` | Sole writer; `DELETE` + `INSERT` per `DateID` |

### 5.2 Upstream (transitive)

All columns ultimately trace through `BI_DB_Client_Balance_CID_Level_New` to the same DWH facts, views, and dimensions documented in that wiki (`Fact_SnapshotCustomer`, `Fact_SnapshotEquity`, `V_Liabilities`, `Fact_CustomerAction`, Dim tables, `V_GermanBaFin`, Tangany dictionary). See `BI_DB_Client_Balance_CID_Level_New.md` Section 5 and `BI_DB_Client_Balance_Aggregate_Level_New.lineage.md`.

### 5.3 Downstream

Typically Tableau and internal reports that do not require CID. Confirm consumers via repo search for object name.

---

## 6. Relationships

### 6.1 Upstream

| Object | Pattern |
| ------ | ------- |
| `BI_DB_Client_Balance_CID_Level_New` | Logical source rowset (`#CIDAgg`) before aggregation |
| Same DWH stack as CID table | See CID wiki |

### 6.2 Sibling

| Table | Notes |
| ----- | ----- |
| `BI_DB_Client_Balance_CID_Level_New` | Customer-level grain; authoritative for reconciliation |

---

## 7. Sample Queries

```sql
-- Segment totals by regulation (valid customers, current transfer row)
SELECT Regulation, DateID,
       SUM(Deposits) AS Deposits,
       SUM(ClosingBalance) AS ClosingBalance,
       SUM(ClientBalanceRealizedPnL) AS RealizedPnL
FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New
WHERE DateID = 20260310 AND IsValidCustomer = 1 AND TransferDirection = 1
GROUP BY Regulation, DateID
ORDER BY Regulation;

-- Reconcile slice to CID (same filters)
SELECT 'Agg' AS Src, SUM(Deposits) AS Deposits
FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New a
WHERE a.DateID = 20260310 AND a.IsValidCustomer = 1 AND a.TransferDirection = 1
UNION ALL
SELECT 'CID', SUM(Deposits)
FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New c
WHERE c.DateID = 20260310 AND c.IsValidCustomer = 1 AND c.TransferDirection = 1;
```

---

## 8. Atlassian Knowledge Sources

Inherit context from `BI_DB_Client_Balance_CID_Level_New` (Client Balance masterclass, RegTech completeness, Finance report incidents). This aggregate is the same business dataset at a coarser grain -- no separate Confluence page was required for documentation.

| Source | Note |
| ------ | ---- |
| Client Balance (RegTech / BIA) | Cycle and transfer-direction logic applies before aggregation |
| BI Dictionary | Describes CID-level client balance metrics; aggregate is SUM by segment |

---

*Quality: 9.0/10*

*Generated by DWH Semantic Documentation Pipeline -- Batch 6.*

*Tiers: 7 Tier 1 eligible dim names (via CID), 170 Tier 2, 3 Tier 3 (`UpdateDate`, `DepositConversionFee`, `WithdrawConversionFee`) -- see `.lineage.md` and CID wiki for transitive Tier 1.*

*Object: BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New | Type: Table | 173 columns*
