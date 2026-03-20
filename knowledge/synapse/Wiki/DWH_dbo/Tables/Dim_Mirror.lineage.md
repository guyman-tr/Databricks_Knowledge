# Column Lineage: DWH_dbo.Dim_Mirror

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Mirror` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror` |
| **Primary Source** | `etoro.Trade.Mirror` (active mirrors, etoroDB-REAL) + `etoro.History.Mirror` (closed events) |
| **ETL SP** | `DWH_dbo.SP_Dim_Mirror_DL_To_Synapse` |
| **Secondary Sources** | `etoro.BackOffice.Customer` (AccountTypeID=9, for IsCopyFundMirror) |
| **Generated** | 2026-03-19 |

## Lineage Chain

```
etoro.Trade.Mirror  (active/open mirrors, etoroDB-REAL)
etoro.History.Mirror  (close/open events, etoroDB-REAL)
etoro.BackOffice.Customer  (AccountTypeID=9, Fund accounts)
  |-- Generic Pipeline (Bronze export) ---|
  v
DWH_staging.etoro_Trade_Mirror
DWH_staging.etoro_History_Mirror
DWH_staging.etoro_BackOffice_Customer
  |-- SP_Dim_Mirror_DL_To_Synapse @dt (incremental MERGE, daily) ---|
  v
DWH_dbo.Dim_Mirror  (11,145,368 rows; never fully truncated)
  |-- Generic Pipeline (Override, 1440min, delta) ---|
  v
Gold/sql_dp_prod_we/DWH_dbo/Dim_Mirror/
  (dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from staging. |
| **rename** | Same value, different column name. |
| **ETL-computed** | Derived by SP logic; not from a single source column. |
| **post-load UPDATE** | Set via a separate UPDATE after main INSERT/MERGE. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| MirrorID | etoro.Trade.Mirror | MirrorID | passthrough | PK and HASH distribution key |
| CID | etoro.Trade.Mirror | CID | passthrough | Copier customer ID |
| ParentCID | etoro.Trade.Mirror | ParentCID | passthrough | Copied person / fund account ID |
| ParentUserName | etoro.Trade.Mirror | ParentUserName | passthrough | Username at open time; may be stale |
| Amount | etoro.Trade.Mirror | Amount | passthrough | Current copy portfolio value in USD |
| OpenOccurred | etoro.Trade.Mirror | Occurred | rename | Renamed from Occurred (open event timestamp) |
| OpenDateID | etoro.Trade.Mirror | Occurred | ETL-computed | yyyymmdd integer from Occurred |
| CloseOccurred | etoro.History.Mirror | ModificationDate | passthrough | Close event datetime; '1900-01-01' sentinel for open |
| CloseDateID | etoro.History.Mirror | ModificationDate | ETL-computed | yyyymmdd integer from ModificationDate; 0 for open |
| MirrorTypeID | etoro.Trade.Mirror | MirrorTypeID | passthrough | FK to Dim_MirrorType |
| CloseMirrorActionType | etoro.Trade.Mirror | CloseMirrorActionType | passthrough | Close reason code |
| IsActive | etoro.Trade.Mirror | IsActive | passthrough | Production active flag |
| IsOpenOpen | etoro.Trade.Mirror | IsOpenOpen | passthrough | Has open positions flag |
| PauseCopy | etoro.Trade.Mirror | PauseCopy | passthrough | Copy paused flag |
| MirrorSL | etoro.Trade.Mirror | MirrorSL | passthrough | Stop-loss absolute amount USD |
| MirrorSLPercentage | etoro.Trade.Mirror | MirrorSLPercentage | passthrough | Stop-loss as % of InitialInvestment |
| RealizedEquity | etoro.Trade.Mirror | RealizedEquity | passthrough | Accumulated closed positions value |
| InitialInvestment | etoro.Trade.Mirror | InitialInvestment | passthrough | USD amount at mirror open |
| WithdrawalSummary | etoro.Trade.Mirror | WithdrawalSummary | passthrough | Running total withdrawals |
| DepositSummary | etoro.Trade.Mirror | DepositSummary | passthrough | Running total additional deposits |
| RealziedPnL | etoro.History.Mirror | NetProfit | rename | Typo in column name; final P&L at close (running for open) |
| GuruTPV | etoro.Trade.Mirror | GuruTPV | passthrough | Guru total portfolio value |
| UseCopyDividend | etoro.Trade.Mirror | UseCopyDividend | passthrough | Dividend reinvestment flag |
| UpdateDate | -- | -- | ETL-computed | GETDATE() on each MERGE/UPDATE |
| SessionID | etoro.History.Mirror (MirrorOperationID=1) | SessionID | post-load UPDATE | Open event session ID; NULL for historical rows |
| IsCopyFundMirror | etoro.BackOffice.Customer | AccountTypeID=9 membership | ETL-computed | 1 if ParentCID is a Fund account; post-load flag |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 19 |
| **Rename** | 2 |
| **ETL-computed** | 3 |
| **Post-load UPDATE** | 2 |
| **Total** | 26 |
