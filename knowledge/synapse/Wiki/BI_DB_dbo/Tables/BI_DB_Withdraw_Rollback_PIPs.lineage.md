# Lineage: BI_DB_dbo.BI_DB_Withdraw_Rollback_PIPs

## Source Objects

| # | Source Object | Source Type | Schema | Relationship | Wiki |
|---|--------------|------------|--------|-------------|------|
| 1 | External_etoro_Billing_CashoutRollbackTracking | External Table | BI_DB_dbo | Primary rollback event source | — (no wiki) |
| 2 | Fact_BillingWithdraw | Table | DWH_dbo | Withdrawal payment details, amounts, exchange rates | [Fact_BillingWithdraw.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_BillingWithdraw.md) |
| 3 | External_etoro_billing_vWithdrawToFunding_Alltime | External Table | BI_DB_dbo | WithdrawToFunding execution details | — (no wiki) |
| 4 | Dealing_staging.External_Etoro_History_WithdrawToFundingAction | External Table | Dealing_staging | WTF action history for MerchantAccountID | — (no wiki) |
| 5 | External_Etoro_History_vWithdrawToFundingAction | External Table | BI_DB_dbo | WTF action history for CashoutStatusID matching | — (no wiki) |
| 6 | Fact_CustomerAction | Table | DWH_dbo | Cashout rollback events (ActionTypeID=42) | [Fact_CustomerAction.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_CustomerAction.md) |
| 7 | Fact_SnapshotCustomer | Table | DWH_dbo | Point-in-time customer attributes (regulation, label, player level) | [Fact_SnapshotCustomer.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_SnapshotCustomer.md) |
| 8 | Dim_Range | Table | DWH_dbo | Snapshot date range resolution | [Dim_Range.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Range.md) |
| 9 | Dim_Customer | Table | DWH_dbo | Customer ExternalID, CountryID, CountryIDByIP, LabelID, PlayerLevelID | [Dim_Customer.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Customer.md) |
| 10 | Dim_Currency | Table | DWH_dbo | Currency abbreviation for ProcessCurrencyID | [Dim_Currency.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Currency.md) |
| 11 | Dim_CashoutStatus | Table | DWH_dbo | Cashout status name decode | [Dim_CashoutStatus.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_CashoutStatus.md) |
| 12 | Dim_Regulation | Table | DWH_dbo | Regulation name decode | [Dim_Regulation.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Regulation.md) |
| 13 | Dim_Label | Table | DWH_dbo | Label/brand name decode | [Dim_Label.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Label.md) |
| 14 | Dim_BillingDepot | Table | DWH_dbo | Depot name decode | [Dim_BillingDepot.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_BillingDepot.md) |
| 15 | Dim_FundingType | Table | DWH_dbo | Funding type / payment method name | [Dim_FundingType.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_FundingType.md) |
| 16 | Dim_CountryBin | Table | DWH_dbo | BIN-to-card-type lookup | [Dim_CountryBin.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_CountryBin.md) |
| 17 | Dim_CardType | Table | DWH_dbo | Card brand name decode | [Dim_CardType.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_CardType.md) |
| 18 | Dim_PlayerLevel | Table | DWH_dbo | Player level / club name decode | [Dim_PlayerLevel.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PlayerLevel.md) |
| 19 | Dim_PlayerStatus | Table | DWH_dbo | Player status name decode | [Dim_PlayerStatus.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_PlayerStatus.md) |
| 20 | Dim_Country | Table | DWH_dbo | Country name decode (registration + IP) | [Dim_Country.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Country.md) |
| 21 | Dim_Instrument | Table | DWH_dbo | Instrument data for reciprocal forex detection | [Dim_Instrument.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Instrument.md) |
| 22 | Fact_BillingDeposit | Table | DWH_dbo | Deposit depot for refund-linked withdrawals | [Fact_BillingDeposit.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_BillingDeposit.md) |
| 23 | Dim_BillingProtocolMIDSettingsID | Table | DWH_dbo | MID routing configuration | [Dim_BillingProtocolMIDSettingsID.md](../../../../knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_BillingProtocolMIDSettingsID.md) |
| 24 | BI_DB_DepositWithdrawFee | Table | BI_DB_dbo | Original PIPs calculation for ratio computation | [BI_DB_DepositWithdrawFee.md](../../../../knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DepositWithdrawFee.md) |
| 25 | External_eToro_Dictionary_MerchantAccount | External Table | BI_DB_dbo | Merchant account name/description | — (no wiki) |
| 26 | External_eToro_Dictionary_MapMerchantCodeToMid | External Table | BI_DB_dbo | Merchant code to MID mapping | — (no wiki) |
| 27 | External_eToro_Billing_MerchantAccountRouting | External Table | BI_DB_dbo | Merchant account routing config | — (no wiki) |

## Column Lineage

| # | Column | Source Object | Source Column | Transform |
|---|--------|--------------|---------------|-----------|
| 1 | DateID | SP_Withdraw_Rollback_PIPs | @StartDateInt | ETL parameter: CAST(FORMAT(@Date,'yyyyMMdd') AS INT) |
| 2 | CID | External_etoro_Billing_CashoutRollbackTracking | CID | Passthrough |
| 3 | DepositWithdrawID | External_etoro_Billing_CashoutRollbackTracking | WithdrawID | Rename |
| 4 | Occurred | External_etoro_Billing_CashoutRollbackTracking | ModificationDate | Rename (StatusModificationTime in SP) |
| 5 | CreditTypeID | SP_Withdraw_Rollback_PIPs | — | Hardcoded 33 |
| 6 | TransactionID | Fact_BillingWithdraw | WithdrawPaymentID | CAST(WithdrawPaymentID AS VARCHAR(30)) + 'W' |
| 7 | Date | External_etoro_Billing_CashoutRollbackTracking | ModificationDate | CAST(ModificationDate AS DATE) |
| 8 | Customer | Dim_Customer | ExternalID | Passthrough (via JOIN on CID=RealCID) |
| 9 | TransactionType | Dim_CashoutStatus / SP logic | WithdrawProcessingIDStatus | CASE: Reversed/Partially Reversed='CashoutRollback', Processed='CancelledCashoutRollback', else 'NA' |
| 10 | PaymentMethod | Dim_FundingType | Name | COALESCE(FundingTypeID_Funding.Name, FundingTypeID_Withdraw.Name) |
| 11 | Amount | External_etoro_Billing_CashoutRollbackTracking | RollbackAmountInCurrency | Passthrough |
| 12 | Currency | Dim_Currency | Abbreviation | Passthrough (via Fact_BillingWithdraw.ProcessCurrencyID) |
| 13 | ExchangeRate | External_etoro_Billing_CashoutRollbackTracking | ExchangeRate | Passthrough |
| 14 | AmountUSD | External_etoro_Billing_CashoutRollbackTracking | RollbackAmountInUSD | Passthrough |
| 15 | RegulationID | Fact_SnapshotCustomer | RegulationID | Passthrough (point-in-time via Dim_Range) |
| 16 | LabelID | Dim_Customer | LabelID | Passthrough |
| 17 | PlayerLevelID | Dim_Customer | PlayerLevelID | Passthrough |
| 18 | Regulation | Dim_Regulation | Name | Dim-lookup passthrough (via #fsc.RegulationID) |
| 19 | Label | Dim_Label | Name | Dim-lookup passthrough (via fi.LabelID) |
| 20 | IsValidCustomer | Dim_Customer | IsValidCustomer | Passthrough (ETL-computed in Dim_Customer) |
| 21 | UpdateDate | SP_Withdraw_Rollback_PIPs | — | GETDATE() |
| 22 | BaseExchangeRate | Fact_BillingWithdraw | BaseExchangeRate | Conditional inversion for reciprocal forex pairs |
| 23 | ExchangeFee | Fact_BillingWithdraw | ExchangeFee | Passthrough (via #rollbackTracking) |
| 24 | ExternalTransactionID | External_etoro_Billing_CashoutRollbackTracking | ReferenceNumber | Rename |
| 25 | Depot | Dim_BillingDepot | Name | Dim-lookup passthrough (via Fact_BillingWithdraw.DepotID) |
| 26 | MIDValue | SP_Withdraw_Rollback_PIPs (multi-source) | COALESCE(MIDNew, oldWayMID) | Complex: depot-specific CASE logic across MerchantAccount, BPMS, BackOffice sources |
| 27 | Club | Dim_PlayerLevel | Name | Dim-lookup passthrough (via #fsc.PlayerLevelID) |
| 28 | PlayerStatus | Dim_PlayerStatus | Name | Dim-lookup passthrough (via #fsc.PlayerStatusID) |
| 29 | PIPsCalculation | Fact_BillingWithdraw / BI_DB_DepositWithdrawFee | BaseExchangeRate, Amount, PIPsCalculation | Complex: ratio-based PIPs recalculation with old/new fallback |
| 30 | RegCountry | Dim_Country | Name | Dim-lookup passthrough (via Dim_Customer.CountryID) |
| 31 | RegCountryByIP | Dim_Country | Name | Dim-lookup passthrough (via Dim_Customer.CountryIDByIP) |
| 32 | CardType | Dim_CardType | CarTypeName | Dim-lookup passthrough (via Dim_CountryBin.CardTypeID) |
| 33 | CardCategory | SP_Withdraw_Rollback_PIPs | — | Hardcoded 'NA' |
| 34 | BinCountry | SP_Withdraw_Rollback_PIPs | — | Hardcoded 'NA' |
| 35 | MOPCountry | SP_Withdraw_Rollback_PIPs | — | Hardcoded 'NA' |
| 36 | IsGermanBaFin | SP_Withdraw_Rollback_PIPs | — | Hardcoded NULL |
| 37 | Entity | SP_Withdraw_Rollback_PIPs (multi-source) | COALESCE(MIDNameNew, OldWayMIDName) | Complex: depot-specific CASE logic for MID entity name |
