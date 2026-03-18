# Column Lineage: DWH_dbo.Fact_Reverse_Deposits

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Fact_Reverse_Deposits` |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_reverse_deposits` (expected) |
| **Primary Source** | `BackOffice.GetRiskExposureReportPCIVersion` (SP) via `DWH_staging.etoro_BackOffice_GetRiskExposureReportPCIVersion` (staging - no longer exists) |
| **ETL SP** | `DWH_dbo.SP_Fact_Reverse_Deposits_DL_To_Synapse` |
| **Secondary Sources** | None |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
BackOffice.GetRiskExposureReportPCIVersion (production SP, risk exposure report)
  -> DWH_staging.etoro_BackOffice_GetRiskExposureReportPCIVersion (materialized staging, NOW GONE)
       -> SP_Fact_Reverse_Deposits_DL_To_Synapse (@dt daily param)
            DELETE WHERE ModificationDateID in date range
            INSERT WHERE DepositStatusModificationTime in date range
            -> DWH_dbo.Fact_Reverse_Deposits (9,904 rows, frozen 2024-06-28)

NOTE: Pipeline stopped ~June 2024. Both staging table and feed are gone.
      ETL pattern: proper daily DELETE+INSERT upsert (unlike Fact_Deposit_Fees).
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **ETL-computed** | Derived by ETL, not from source. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| CID | BackOffice.GetRiskExposureReportPCIVersion | CID | passthrough | int |
| WhiteLabelID | BackOffice.GetRiskExposureReportPCIVersion | WhiteLabelID | passthrough | int; brand integer ID |
| DepositID | BackOffice.GetRiskExposureReportPCIVersion | DepositID | passthrough | int |
| DepositTime | BackOffice.GetRiskExposureReportPCIVersion | DepositTime | passthrough | datetime2(7) |
| DepositAmount | BackOffice.GetRiskExposureReportPCIVersion | DepositAmount | passthrough | decimal(38,18) |
| DepositUSDAmount | BackOffice.GetRiskExposureReportPCIVersion | DepositUSDAmount | passthrough | decimal(38,18); USD-normalized |
| Currency | BackOffice.GetRiskExposureReportPCIVersion | Currency | passthrough | nvarchar |
| DepositStatus | BackOffice.GetRiskExposureReportPCIVersion | DepositStatus | passthrough | nvarchar; 6 values |
| PreviousDepositStatus | BackOffice.GetRiskExposureReportPCIVersion | PreviousDepositStatus | passthrough | nvarchar; pre-reversal state |
| DepositStatusModificationTime | BackOffice.GetRiskExposureReportPCIVersion | DepositStatusModificationTime | passthrough | datetime2(7); ETL filter key |
| RollbackDate | BackOffice.GetRiskExposureReportPCIVersion | RollbackDate | passthrough | datetime2(7); range 2021-2024 |
| RollbackAmount | BackOffice.GetRiskExposureReportPCIVersion | RollbackAmount | passthrough | decimal(38,18); in deposit currency |
| RollbackUSDAmount | BackOffice.GetRiskExposureReportPCIVersion | RollbackUSDAmount | passthrough | decimal(38,18); USD-normalized |
| RollbackReason | BackOffice.GetRiskExposureReportPCIVersion | RollbackReason | passthrough | nvarchar; 30 distinct values |
| RollbackCanceled | BackOffice.GetRiskExposureReportPCIVersion | RollbackCanceled | passthrough | nvarchar |
| ExchangeRate | BackOffice.GetRiskExposureReportPCIVersion | ExchangeRate | passthrough | decimal(38,18) |
| ConversionFee | BackOffice.GetRiskExposureReportPCIVersion | ConversionFee | passthrough | decimal(38,18) |
| PIPsInUSD | BackOffice.GetRiskExposureReportPCIVersion | PIPsInUSD | passthrough | decimal(38,18) |
| Balance | BackOffice.GetRiskExposureReportPCIVersion | Balance | passthrough | decimal(38,18); customer snapshot at rollback |
| TotalDeposits | BackOffice.GetRiskExposureReportPCIVersion | TotalDeposits | passthrough | decimal(38,18); customer lifetime |
| TotalProcessedCashouts | BackOffice.GetRiskExposureReportPCIVersion | TotalProcessedCashouts | passthrough | decimal(38,18) |
| TotalCommissions | BackOffice.GetRiskExposureReportPCIVersion | TotalCommissions | passthrough | decimal(38,18) |
| TotalPnL | BackOffice.GetRiskExposureReportPCIVersion | TotalPnL | passthrough | decimal(38,18) |
| TotalCompensations | BackOffice.GetRiskExposureReportPCIVersion | TotalCompensations | passthrough | decimal(38,18) |
| TotalCredits | BackOffice.GetRiskExposureReportPCIVersion | TotalCredits | passthrough | decimal(38,18) |
| FundingMethod | BackOffice.GetRiskExposureReportPCIVersion | FundingMethod | passthrough | nvarchar |
| Brand | BackOffice.GetRiskExposureReportPCIVersion | Brand | passthrough | nvarchar; card brand |
| FundingID | BackOffice.GetRiskExposureReportPCIVersion | FundingID | passthrough | int |
| Depot | BackOffice.GetRiskExposureReportPCIVersion | Depot | passthrough | nvarchar; payment processor |
| MIDName | BackOffice.GetRiskExposureReportPCIVersion | MIDName | passthrough | nvarchar |
| MID | BackOffice.GetRiskExposureReportPCIVersion | MID | passthrough | nvarchar |
| PaymentDetails | BackOffice.GetRiskExposureReportPCIVersion | PaymentDetails | passthrough | nvarchar |
| ThreedsParameters | BackOffice.GetRiskExposureReportPCIVersion | ThreedsParameters | passthrough | nvarchar |
| ThreedsResponse | BackOffice.GetRiskExposureReportPCIVersion | ThreedsResponse | passthrough | nvarchar |
| OldPaymentID | BackOffice.GetRiskExposureReportPCIVersion | OldPaymentID | passthrough | int |
| ReferenceNumber | BackOffice.GetRiskExposureReportPCIVersion | ReferenceNumber | passthrough | nvarchar |
| Regulation | BackOffice.GetRiskExposureReportPCIVersion | Regulation | passthrough | nvarchar |
| WhiteLabel | BackOffice.GetRiskExposureReportPCIVersion | WhiteLabel | passthrough | nvarchar |
| CustomerStatus | BackOffice.GetRiskExposureReportPCIVersion | CustomerStatus | passthrough | nvarchar |
| RiskStatus | BackOffice.GetRiskExposureReportPCIVersion | RiskStatus | passthrough | nvarchar |
| VerificationLevel | BackOffice.GetRiskExposureReportPCIVersion | VerificationLevel | passthrough | nvarchar |
| CustomerLevel | BackOffice.GetRiskExposureReportPCIVersion | CustomerLevel | passthrough | nvarchar |
| CountryByRegIP | BackOffice.GetRiskExposureReportPCIVersion | CountryByRegIP | passthrough | nvarchar |
| AccountManager | BackOffice.GetRiskExposureReportPCIVersion | AccountManager | passthrough | nvarchar |
| ModificationDateID | ETL from DepositStatusModificationTime | - | ETL-computed | convert(int,convert(varchar,dateadd(day,datediff(day,0,[DepositStatusModificationTime]),0),112)) -> YYYYMMDD |
| UpdateDate | ETL execution time | - | ETL-computed | getdate() |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 46 (all source columns) |
| **ETL-computed** | 2 (ModificationDateID, UpdateDate) |
| **Total** | 48 |
