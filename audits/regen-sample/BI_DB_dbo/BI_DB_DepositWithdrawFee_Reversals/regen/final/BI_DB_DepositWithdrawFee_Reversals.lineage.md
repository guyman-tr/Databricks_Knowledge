# Lineage: BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals

> **Writer SP**: `BI_DB_dbo.SP_DepositWithdrawFee`
> **Primary Sources**: `DWH_dbo.Fact_Deposit_State` (WHERE TransactionType != 'Deposit'), `DWH_dbo.Fact_Cashout_State` (WHERE TransactionType != 'Withdraw')
> **Secondary Sources**: `DWH_dbo.Fact_BillingDeposit`, `DWH_dbo.Fact_BillingWithdraw` (deduped), `DWH_dbo.Dim_Customer`, `DWH_dbo.Fact_SnapshotCustomer`, `DWH_dbo.Dim_Range`, `DWH_dbo.Dim_FundingType`, `DWH_dbo.Dim_Currency`, `DWH_dbo.Dim_Regulation`, `DWH_dbo.Dim_Label`, `DWH_dbo.Dim_BillingDepot`, `DWH_dbo.Dim_PlayerLevel`, `DWH_dbo.Dim_PlayerStatus`, `DWH_dbo.Dim_Country`, `DWH_dbo.Dim_CardType`, `DWH_dbo.Dim_GuruStatus`, `DWH_dbo.Fact_CustomerAction`

---

## Source Objects

| Source Object | Schema | Type | Role |
|--------------|--------|------|------|
| Fact_Deposit_State | DWH_dbo | Table | Deposit reversal events (TransactionType != 'Deposit') |
| Fact_Cashout_State | DWH_dbo | Table | Withdraw reversal events (TransactionType != 'Withdraw') |
| Fact_BillingDeposit | DWH_dbo | Table | Deposit billing metadata (FundingTypeID, FlowID, BinCountryIDAsInteger) |
| Fact_BillingWithdraw | DWH_dbo | Table | Withdraw billing metadata (deduped; FundingTypeID_Funding, CardTypeIDAsInteger, BinCountryIDAsInteger, CardCategory, FlowID) |
| Dim_Customer | DWH_dbo | Table | ExternalID (Customer column), CountryIDByIP, CountryID (deposit LabelID path) |
| Fact_SnapshotCustomer | DWH_dbo | Table | Point-in-time customer attributes (RegulationID, LabelID, PlayerLevelID, IsValidCustomer, CountryID, PlayerStatusID, GuruStatusID) |
| Dim_Range | DWH_dbo | Table | Snapshot date range validity bridge (DateRangeID, FromDateID, ToDateID) |
| Dim_Regulation | DWH_dbo | Table | Regulation name lookup |
| Dim_Label | DWH_dbo | Table | Label name lookup |
| Dim_BillingDepot | DWH_dbo | Table | Depot name lookup |
| Dim_PlayerLevel | DWH_dbo | Table | Club/tier name lookup |
| Dim_PlayerStatus | DWH_dbo | Table | Player status name lookup |
| Dim_Country | DWH_dbo | Table | Country name lookup (RegCountry, RegCountryByIP, BinCountry) |
| Dim_CardType | DWH_dbo | Table | Card type name lookup (withdraw path only) |
| Dim_Currency | DWH_dbo | Table | Currency abbreviation lookup |
| Dim_FundingType | DWH_dbo | Table | Payment method name lookup |
| Dim_GuruStatus | DWH_dbo | Table | Guru status name lookup |
| Fact_CustomerAction | DWH_dbo | Table | Post-load PIPsCalculation sign corrections for CashoutRollback/CancelledCashoutRollback/CancelledChargebackReversal edge cases |

---

## Column Lineage

| DWH Column | Source Object | Source Column | Transform |
|-----------|--------------|---------------|-----------|
| DateID | SP_DepositWithdrawFee | @StartDateID | ETL-computed: CONVERT(VARCHAR(8), @StartDate, 112) |
| CID | Fact_Deposit_State / Fact_Cashout_State | CID | Passthrough |
| DepositWithdrawID | Fact_Deposit_State / Fact_Cashout_State | DepositID / WithdrawID | Passthrough (DepositID on deposit path, WithdrawID on withdraw path) |
| Occurred | Fact_Deposit_State / Fact_Cashout_State | ModificationDate | Passthrough |
| CreditTypeID | — | — | ETL-computed: intentionally NULL (legacy column retired per SR-313302) |
| TransactionID | Fact_Deposit_State / Fact_Cashout_State | DepositID / WPID | ETL-computed: CAST(DepositID AS VARCHAR(50)) + 'D' or CAST(WPID AS VARCHAR(50)) + 'W' |
| Date | Fact_Deposit_State / Fact_Cashout_State | ModificationDate | ETL-computed: CAST(ModificationDate AS DATE) |
| Customer | Dim_Customer | ExternalID | Dim-lookup: CAST(dc.ExternalID AS VARCHAR(50)) via CID = RealCID |
| TransactionType | Fact_Deposit_State / Fact_Cashout_State | TransactionType | Passthrough (filtered: != 'Deposit' or != 'Withdraw') |
| PaymentMethod | Dim_FundingType | Name | Dim-lookup via Fact_BillingDeposit.FundingTypeID (deposit) or Fact_BillingWithdraw.FundingTypeID_Funding (withdraw) |
| Amount | Fact_Deposit_State / Fact_Cashout_State | Amount | ETL-computed: ABS(Amount) at insert, then signed via #amountDirections + edge-case corrections |
| Currency | Dim_Currency | Abbreviation | Dim-lookup via Fact_*_State.CurrencyID |
| ExchangeRate | Fact_Deposit_State / Fact_Cashout_State | ExchangeRate | Passthrough |
| AmountUSD | Fact_Deposit_State / Fact_Cashout_State | AmountInUSD | ETL-computed: ABS(AmountInUSD) at insert, then signed via #amountDirections + edge-case corrections |
| RegulationID | Fact_SnapshotCustomer | RegulationID | Snapshot lookup via CID + Dim_Range date bridge |
| LabelID | Fact_SnapshotCustomer / Dim_Customer | LabelID | Snapshot lookup (withdraw path: fsc.LabelID) or Dim_Customer (deposit path: dc.LabelID) |
| PlayerLevelID | Fact_SnapshotCustomer | PlayerLevelID | Snapshot lookup |
| Regulation | Dim_Regulation | Name | Dim-lookup via fsc.RegulationID = dr1.DWHRegulationID |
| Label | Dim_Label | Name | Dim-lookup via LabelID |
| IsValidCustomer | Fact_SnapshotCustomer | IsValidCustomer | Snapshot lookup |
| UpdateDate | — | — | ETL-computed: GETDATE() at insert time |
| BaseExchangeRate | Fact_Deposit_State / Fact_Cashout_State | BaseExchangeRate | Passthrough |
| ExchangeFee | Fact_Deposit_State / Fact_Cashout_State | ExchangeFee | Passthrough |
| ExternalTransactionID | Fact_Deposit_State / Fact_Cashout_State | ExTransactionID | Passthrough (rename) |
| Depot | Dim_BillingDepot | Name | Dim-lookup via Fact_*_State.DepotID |
| MIDValue | Fact_Deposit_State / Fact_Cashout_State | MID | Passthrough (rename) |
| Club | Dim_PlayerLevel | Name | Dim-lookup via fsc.PlayerLevelID |
| PlayerStatus | Dim_PlayerStatus | Name | Dim-lookup via fsc.PlayerStatusID |
| PIPsCalculation | Fact_Deposit_State / Fact_Cashout_State | PIPsInUSD | ETL-computed: ABS(ISNULL(PIPsInUSD,0)) at insert, then signed via #amountDirections, then edge-case corrections via Fact_CustomerAction JOIN |
| RegCountry | Dim_Country | Name | Dim-lookup via fsc.CountryID (withdraw) or dc.CountryID (deposit) |
| RegCountryByIP | Dim_Country | Name | Dim-lookup via dc.CountryIDByIP |
| CardType | Fact_Deposit_State (deposit) / Dim_CardType (withdraw) | CardType / CarTypeName | Deposit path: passthrough from fds.CardType; Withdraw path: dim-lookup via fbw.CardTypeIDAsInteger |
| CardCategory | Fact_Deposit_State (deposit) / Fact_BillingWithdraw (withdraw) | CardCategory | Passthrough from respective source |
| BinCountry | Dim_Country | Name | Dim-lookup via fbd.BinCountryIDAsInteger (deposit) or fbw.BinCountryIDAsInteger (withdraw) |
| MOPCountry | — | — | ETL-computed: NULL literal (not populated) |
| IsGermanBaFin | — | — | ETL-computed: NULL literal (not populated) |
| IsIBANTrade | Fact_BillingDeposit / Fact_BillingWithdraw | FlowID | ETL-computed: CASE WHEN FlowID = 1 THEN 1 ELSE 0 END (deposit) or CASE WHEN FlowID = 2 THEN 1 ELSE 0 END (withdraw) |
| MIDName | Fact_Deposit_State / Fact_Cashout_State | MIDName | Passthrough |
| GuruStatus | Dim_GuruStatus | GuruStatusName | Dim-lookup via fsc.GuruStatusID |
| PreviousTransactionStatus | Fact_Deposit_State / Fact_Cashout_State | PreviousStatus | Passthrough (rename) |
| TransactionStatus | Fact_Deposit_State / Fact_Cashout_State | DepositStatus / CashoutStatus | Passthrough (DepositStatus on deposit path, CashoutStatus on withdraw path) |
| DepositID | Fact_Deposit_State | DepositID | Passthrough (deposit rows only; NULL on withdraw rows) |
| WithdrawPaymentID | Fact_BillingWithdraw | WithdrawPaymentID | Passthrough (withdraw rows only; NULL on deposit rows) |
| CreditID | Fact_Deposit_State / Fact_Cashout_State | CreditID | Passthrough |
| ExchangeFeePercentage | Fact_Deposit_State / Fact_Cashout_State | FeeInPercentage / ExchaFeeInPercentage | Passthrough (FeeInPercentage on deposit path, ExchaFeeInPercentage on withdraw path) |
