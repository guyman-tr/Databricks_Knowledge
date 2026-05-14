# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform` |
| **UC Target** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform` (Databricks MCP `DESCRIBE` not confirmed this session — re-resolve before ALTER) |
| **Primary Sources** | `DWH_dbo.Fact_CustomerAction`, `DWH_dbo.Fact_BillingDeposit`, `DWH_dbo.Fact_BillingWithdraw`, `DWH_dbo.Dim_Currency`, `DWH_dbo.Dim_Customer`, `BI_DB_dbo.BI_DB_DepositWithdrawFee` |
| **Production origins (indirect)** | Billing / History-driven facts (see sibling DWH wikis); not a Generic-Pipeline-backed physical export of a single production table |
| **ETL SP** | `BI_DB_dbo.SP_DDR_Fact_MIMO_Trading_Platform` (@date DATE) |
| **Orchestration** | OpsDB: `SB_Daily`, `ProcedureName = BI_DB_dbo.SP_DDR_Fact_MIMO_Trading_Platform` → `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform` (`Priority`: main row lists `60` vs some dependency rows — confirm in OpsDB UI) |
| **Generated** | 2026-05-14 |

## Source Objects

| Source Object | Role |
|---------------|------|
| `DWH_dbo.Fact_CustomerAction` | Primary ledger for deposits/cashouts: `WHERE ActionTypeID IN (7,44)` (#depositsTP) and `WHERE ActionTypeID IN (8,45)` (#cashoutTP); supplies `RealCID`, `Amount` (USD), `DepositID` / `WithdrawPaymentID`, `IsFTD` (withdraw leg), `IsRedeem`, `ActionTypeID`, `MoveMoneyReasonID`, joins |
| `DWH_dbo.Fact_BillingDeposit` | Deposit enrichment: `Amount`, `FundingTypeID`, `CurrencyID`, `IsRecurring` via `fca.DepositID = fbd.DepositID` |
| `DWH_dbo.Fact_BillingWithdraw` | Withdraw enrichment: `FundingTypeID_Funding`, `ProcessCurrencyID`, `Amount_WithdrawToFunding`, `ExchangeRate`; join `fca.WithdrawPaymentID = fbw.WithdrawPaymentID` |
| `DWH_dbo.Dim_Currency` | Ticker/text: `dc.Abbreviation AS Currency` on `CurrencyID` / `ProcessCurrencyID` |
| `DWH_dbo.Dim_Customer` | FTD coercion on deposits: `dc1.FTDTransactionID = fca.DepositID AND dc1.FTDPlatformID = 1`; post-insert FTD recovery UPDATE |
| `BI_DB_dbo.BI_DB_DepositWithdrawFee` | Alternate withdraw payout amount when present: JOIN on `fca.DateID = bddwf.DateID AND bddwf.TransactionType = 'Withdraw' AND TRY_CAST(REPLACE(bddwf.TransactionID, 'W', '') AS INT) = fca.WithdrawPaymentID` |

## Lineage Chain

```
History.Credit + Billing Deposit/Withdraw (production) ──► DWH_dbo Fact_CustomerAction / Fact_Billing* / Dim_*
       │
       └── BI_DB_dbo.SP_DDR_Fact_MIMO_Trading_Platform (@date)
              │  #depositsTP + #cashoutTP
              │  UNION ALL ─► #mimoTP (ROW_NUMBER dedupe RN=1)
              │  DELETE FROM target WHERE DateID=@dateID
              │  INSERT … SELECT … + GETDATE()
              │  UPDATE IsFTD recoveries (deposit rows, Dim_Customer FTD match, DateID>=20250901)
              ▼
       BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Same semantic value carried from DWH column (maybe renamed in UNION) |
| **ETL-computed** | Literal, CASE, ISNULL wrapper, CAST, aggregate of multiple inputs, GETDATE |
| **SP-adjusted** | Source value overwritten or coerced elsewhere in same SP |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|------------|--------------|---------------|-----------|---------------------|-------|
| DateID | Fact_CustomerAction | DateID | passthrough | Direct: `@dateID` propagated into `#depositsTP`/`#cashoutTP` (`CAST(CONVERT(varchar(8),@date,112) AS int)`) | Partition key |
| Date | SP parameter | @date | ETL-computed | INSERT selects `@date AS [Date]` | Calendar mirror of DateID |
| RealCID | Fact_CustomerAction | RealCID | passthrough | Direct: `fca.RealCID` | HASH key on target |
| MIMOAction | — | — | ETL-computed | `'Deposit'` union `'Withdraw'` | |
| OrigIdentifier | — | — | ETL-computed | `'DepositID'` union `'WithdrawPaymentID'` | |
| TransactionID | Fact_CustomerAction | DepositID / WithdrawPaymentID | rename | `DepositID` as TransactionID ; `WithdrawPaymentID` as TransactionID | |
| AmountUSD | Fact_CustomerAction | Amount | passthrough | Direct: `fca.Amount AS AmountUSD` | Credit-side USD amount |
| AmountOrigCurrency | Fact_BillingDeposit / Fact_BillingWithdraw / BI_DB_DepositWithdrawFee | Amount / Amount_WithdrawToFunding / Amount | SP-adjusted | Deposit: `fbd.Amount`. Withdraw: `COALESCE(bddwf.Amount, ROUND(ROUND(fbw.Amount_WithdrawToFunding,6)/ROUND(fbw.ExchangeRate,6),6))` | |
| FundingTypeID | Fact_BillingDeposit / Fact_BillingWithdraw | FundingTypeID / FundingTypeID_Funding | passthrough | Deposit: `fbd.FundingTypeID`. Withdraw: `fbw.FundingTypeID_Funding` | Same column holds both semantics |
| CurrencyID | Fact_BillingDeposit / Fact_BillingWithdraw | CurrencyID / ProcessCurrencyID | passthrough | Deposit: `fbd.CurrencyID`. Withdraw: `fbw.ProcessCurrencyID` | |
| Currency | Dim_Currency | Abbreviation | passthrough | `dc.Abbreviation AS Currency` | Join key matches CurrencyID branch |
| IsFTD | Dim_Customer + Fact_CustomerAction | FTDTransactionID & DepositID | SP-adjusted | Deposit leg in `#depositsTP`: `CASE WHEN dc1.FTDTransactionID = fca.DepositID THEN 1 ELSE 0 END` (`dc1` = `Dim_Customer`, `dc1.FTDPlatformID = 1`). Final UNION zeros withdraw rows: `'Withdraw' … , 0 AS IsFTD`. INSERT `ISNULL(t.IsFTD,0)`. Post-INSERT UPDATE sets `IsFTD=1` when `JOIN Dim_Customer … FTDPlatformID=1 AND TransactionID=FTDTransactionID AND IsFTD=0 AND MIMOAction='Deposit' AND DateID>=20250901` | |
| IsInternalTransfer | Fact_BillingDeposit / Fact_BillingWithdraw | FundingTypeID / FundingTypeID_Funding | ETL-computed | `CASE WHEN fbd.FundingTypeID = 33 THEN 1 ELSE 0`; `CASE WHEN fbw.FundingTypeID_Funding = 33 THEN 1 ELSE 0` | |
| IsRedeem | Fact_CustomerAction / SP union | IsRedeem | SP-adjusted | Deposit temp: `NULL AS IsRedeem` then UNION `0 AS IsRedeem`. Withdraw: `fca.IsRedeem`. INSERT `ISNULL(IsRedeem,0)` | See wiki — transfercoin semantics |
| UpdateDate | — | — | ETL-computed | `GETDATE()` on INSERT | |
| IsIBANTrade | Fact_CustomerAction | ActionTypeID | ETL-computed | Deposit: `CASE WHEN fca.ActionTypeID = 44 THEN 1 ELSE 0`; Withdraw: `CASE WHEN fca.ActionTypeID = 45 THEN 1 ELSE 0` | IBAN internal deposit / withdraw sweep |
| IsCryptoToFiat | SP literal | 0 | ETL-computed | `0 AS IsCryptoToFiat` | Placeholder column |
| IsRecurring | Fact_BillingDeposit | IsRecurring | SP-adjusted | Deposit: `ISNULL(t.IsRecurring,0)`. Withdraw UNION forces `0` | |
| IsIBANQuickTransfer | Fact_CustomerAction | MoveMoneyReasonID | ETL-computed | `CASE WHEN fca.MoveMoneyReasonID = 6 THEN 1 ELSE 0` | Reason 6 = internal-transfer pattern per SP changelog |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough / rename** | 6 |
| **ETL-computed / literals** | 8 |
| **SP-adjusted / COALESCE** | 5 |
| **Total** | 19 |
