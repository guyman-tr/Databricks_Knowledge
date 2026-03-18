# Column Lineage: DWH_dbo.Fact_Cashout_Rollback

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Fact_Cashout_Rollback` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `Billing.CashoutRollbackTracking` (`etoro`) |
| **ETL SP** | `DWH_dbo.SP_Fact_Cashout_Rollback_DL_To_Synapse` |
| **Secondary Sources** | `Billing.WithdrawToFunding`, `Billing.Withdraw`, `Dictionary.Currency`, `Dictionary.FundingType`, `Dictionary.CardType`, `Billing.Depot`, `Dictionary.Regulation`, `History.WithdrawToFundingAction`, `BackOffice.Customer`, `Billing.FundingPaymentDetailsForWithdraw`, `Customer.Customer`, `Billing.Deposit`, `Billing.ProtocolMIDSettings`, `Billing.MapMerchantCodeToMid` |
| **Generated** | 2026-03-18 |

## Lineage Chain

```
Billing.CashoutRollbackTracking + 15 joined tables (etoroDB-REAL)
    |
    v
Billing.GetRollbackedPaymentOrdersReport (production report SP)
    |
    v
DWH.Billing_GetRollbackedPaymentOrdersReport (DWH wrapper — strips column name spaces)
    |
    v
ADF / Generic Pipeline (daily export to data lake)
    |
    v
DWH_staging.etoro_Billing_GetRollbackedPaymentOrdersReport (Synapse staging)
    |
    v
DWH_dbo.SP_Fact_Cashout_Rollback_DL_To_Synapse (daily delete-insert by ModificationDateID)
    |
    v
DWH_dbo.Fact_Cashout_Rollback (ROUND_ROBIN, CLUSTERED INDEX on CID)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. Same name, same value. |
| **rename** | Same value, different column name in DWH. |
| **cast/convert** | Type conversion only (e.g., money→decimal, ISNULL default). |
| **ETL-computed** | Derived/calculated by ETL SP. Not in any single source. |
| **join-enriched** | Joined from a secondary source table during the production report SP. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| CID | Billing.Withdraw | CID | passthrough | Via Billing.CashoutRollbackTracking → Billing.Withdraw lookup. Alias BWIT in prod SP |
| WithdrawprocessingID | Billing.WithdrawToFunding | ID | rename | Aliased as `[Withdraw processing ID]` in prod SP, spaces stripped by DWH wrapper |
| WithdrawID | Billing.Withdraw | WithdrawID | passthrough | Via BWIT alias in prod SP |
| ProcessTime | Billing.WithdrawToFunding | ProcessorValueDate | rename | Aliased as `[Process Time]` in prod SP |
| NetAmount | Billing.WithdrawToFunding | RefundAmountInDepositCurrency | rename + cast | `ISNULL(BWTF.RefundAmountInDepositCurrency, 0)`. Aliased as `[Net Amount]` |
| Currency | Dictionary.Currency | Abbreviation | join-enriched | Joined via WithdrawToFunding.ProcessCurrencyID → Dictionary.Currency.CurrencyID |
| NetUSDAmount | Billing.WithdrawToFunding | Amount | rename + cast | `CAST(ISNULL(BWTF.Amount, 0) AS decimal(16, 2))`. Aliased as `[Net $ Amount]` |
| RollbackDate | Billing.CashoutRollbackTracking | RollbackDate | passthrough | Via CRT alias in prod SP |
| RollbackAmount | Billing.CashoutRollbackTracking | RollbackAmountInCurrency | rename | Aliased as `[Rollback Amount]` in prod SP |
| ExchangeRate | Billing.CashoutRollbackTracking | ExchangeRate | cast | `CAST(ISNULL(CRT.ExchangeRate, 1) AS decimal(16, 4))` |
| FeeInPIPs | Billing.WithdrawToFunding | ExchangeFee | rename | Aliased as `[Fee In PIPs]` in prod SP |
| RollbackUSDAmount | Billing.CashoutRollbackTracking | RollbackAmountInUSD | rename | Aliased as `[Rollback $ Amount]` in prod SP |
| ReferenceNumber | Billing.CashoutRollbackTracking | ReferenceNumber | passthrough | Aliased as `[Reference Number]` |
| RollbackReason | Billing.CashoutRollbackTracking | RollbackReasonID | rename | Aliased as `[Rollback Reason]` |
| PaymentStatusID | Billing.CashoutRollbackTracking | PaymentStatusID | passthrough | Always 2 in production |
| FundingMethod | Dictionary.FundingType | Name | join-enriched | Joined via FundingPaymentDetailsForWithdraw.FundingTypeID. Aliased as `[Funding Method]` |
| Brand | Dictionary.CardType | Name | join-enriched | LEFT JOIN via XML-parsed CardTypeID from FundingData. NULL for non-card methods |
| PaymentDetails | Multiple | Various XML fields | ETL-computed | Complex CASE by FundingTypeID: bank=BSB+address, PayPal=email, eToroMoney=AccountID+PurseID, Trustly=IBAN+BIC, Skrill=details+BirthDate |
| FundingID | Billing.WithdrawToFunding | FundingID | passthrough | Via BWTF alias. Aliased as `[Funding ID]` |
| Depot | Billing.Depot | Name | join-enriched | LEFT JOIN via WithdrawToFunding.DepotID |
| VerificationCode | Billing.WithdrawToFunding | VerificationCode | passthrough | Aliased as `[Verification Code]` |
| Regulation | Dictionary.Regulation | Name | join-enriched | Joined via BackOffice.Customer.RegulationID → Dictionary.Regulation.ID |
| MIDName | Multiple | Various | ETL-computed | Complex CASE by DepotID range: depots 35-43 use deposit ProtocolMIDSettings regulation; depots 1,24,25,26,78,79,80,4,75,86 use GetMerchantDetailsForOneAccountByDepotOnly; bank transfers use BPMS1.Description; else GetMerchantDetails |
| MID | Multiple | Various | ETL-computed | Complex CASE by DepotID range: similar to MIDName but returns MID value. Falls through ProtocolMIDSettings, GetMerchantDetails, MapMerchantCodeToMid |
| PaymentOrderStatus | History.WithdrawToFundingAction | CashoutStatusID | rename + join-enriched | LEFT JOIN via CashoutRollbackTracking.WithdrawToFundingActionID. Aliased as `[Payment Order Status]` |
| StatusModificationTime | Billing.CashoutRollbackTracking | ModificationDate | rename | Aliased as `[Status Modification Time]` |
| ModificationDateID | — | — | ETL-computed | `CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY, 0, StatusModificationTime), 0), 112))` |
| UpdateDate | — | — | ETL-computed | `GETDATE()` — set on each ETL load |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 8 |
| **Rename** | 8 |
| **Cast/Convert** | 3 |
| **Join-Enriched** | 5 |
| **ETL-Computed** | 4 |
| **Total** | 28 |
