# Lineage: BI_DB_dbo.BI_DB_Finance_Cashout_RollbackDetails

Generated: 2026-04-22 | Phase 10B

## ETL Pipeline

```
BI_DB_dbo.External_etoro_Billing_CashoutRollbackTracking (rollback events: RollbackDate, ModificationDate,
    RollbackReasonID, RollbackAmountInCurrency, RollbackAmountInUSD, ExchangeRate, Comments, ReferenceNumber)
  + DWH_dbo.Fact_BillingWithdraw (Amount_WithdrawToFunding, ExchangeRate, ProcessorValueDate,
    ExchangeFee, VerificationCode, ProtocolMIDSettingsID, DepotID, FundingTypeID_Funding,
    FundingTypeID_Withdraw, BinCodeAsString, ProcessCurrencyID)
  + BI_DB_dbo.External_etoro_Billimg_vWithdrawToFunding_FUll (FundingID lookup by WitdrawToFundingID)
  + BI_DB_dbo.External_etoro_History_vWithdrawToFundingAction (CashoutStatusID for each action event)
  + DWH_dbo.Dim_Currency (currency abbreviation from ProcessCurrencyID)
  + DWH_dbo.Dim_CashoutStatus (status name from CashoutStatusID)
  + DWH_dbo.Dim_Customer (RealCID → LabelID, RegulationID)
  + DWH_dbo.Dim_Regulation (regulation name from RegulationID)
  + DWH_dbo.Dim_Label (white label name from LabelID)
  + DWH_dbo.Dim_BillingProtocolMIDSettingsID (MID name/value from ProtocolMIDSettingsID)
  + DWH_dbo.Dim_BillingDepot (depot name and DepotID from DepotID)
  + DWH_dbo.Dim_FundingType (funding method name from FundingTypeID)
  + DWH_dbo.Dim_CountryBin (card sub-type, card category from BinCodeAsString)
  + DWH_dbo.Dim_CardType (card type name → Brand from CardTypeID)
  + DWH_dbo.Dim_PlayerLevel (player level/club name from Dim_Customer.PlayerLevelID)
    |-- SP_Finance_Cashout_RollbackDetails @Date (Daily, SB_Daily Priority 20) ---|
    |   #rollback → #allstatuses → #previousstatus (LAG window)                   |
    |   #withdraw → #withdraw2 (PIPsCalculation)                                   |
    |   #details (DISTINCT join of rollback + withdraw2 + PlayerLevel)             |
    |   #final (join #details + #previousstatus)                                   |
    |   DELETE WHERE [Status Modification Time] BETWEEN @Date AND @Date+1          |
    |   INSERT 31 columns                                                           |
    v
BI_DB_dbo.BI_DB_Finance_Cashout_RollbackDetails
  (107 rows, Jan 2023 – Mar 2026, daily event records)
  UC Target: Not Migrated
```

## Column Lineage

| # | Column | Source | Transform | Tier |
|---|--------|--------|-----------|------|
| 1 | CID | External_etoro_Billing_CashoutRollbackTracking | t.CID (matched to Dim_Customer.RealCID) | Tier 2 |
| 2 | White Label | DWH_dbo.Dim_Label | dl.Name via Dim_Customer.LabelID | Tier 2 |
| 3 | Withdraw Payment ID | External_etoro_Billing_CashoutRollbackTracking | t.WitdrawToFundingID (note SP source has typo "Witdraw") | Tier 2 |
| 4 | WithdrawID | External_etoro_Billing_CashoutRollbackTracking | t.WithdrawID — internal withdrawal request ID | Tier 2 |
| 5 | Process Time | DWH_dbo.Fact_BillingWithdraw | BW.ProcessorValueDate — date payment was processed by payment processor | Tier 2 |
| 6 | Status Modification Time | External_etoro_Billing_CashoutRollbackTracking | t.ModificationDate — ETL delete key; daily DELETE WHERE BETWEEN @Date AND @Date+1 | Tier 2 |
| 7 | Net Amount | DWH_dbo.Fact_BillingWithdraw | (BW.Amount_WithdrawToFunding / BW.ExchangeRate) — withdrawal amount in local currency | Tier 2 |
| 8 | Currency | DWH_dbo.Dim_Currency | CURR1.Abbreviation via BW.ProcessCurrencyID — payment processing currency | Tier 2 |
| 9 | Net USD Amount | DWH_dbo.Fact_BillingWithdraw | BW.Amount_WithdrawToFunding — withdrawal amount in USD | Tier 2 |
| 10 | Withdraw Processing Id Stauts | DWH_dbo.Dim_CashoutStatus | cs.Name via wfa.CashoutStatusID — note: column name has typo "Stauts" (not "Status") | Tier 2 |
| 11 | Rollback Date | External_etoro_Billing_CashoutRollbackTracking | t.RollbackDate — date the rollback was executed | Tier 2 |
| 12 | Rollback Amount | External_etoro_Billing_CashoutRollbackTracking | t.RollbackAmountInCurrency — rollback amount in local currency | Tier 2 |
| 13 | Exchange Rate | External_etoro_Billing_CashoutRollbackTracking | t.ExchangeRate — exchange rate at time of rollback | Tier 2 |
| 14 | Fee PIPs | DWH_dbo.Fact_BillingWithdraw | r.ExchangeFee (from BW.ExchangeFee) — exchange fee, not a PIP count; always 0 for wire transfers | Tier 2 |
| 15 | Rollback USD Amount | External_etoro_Billing_CashoutRollbackTracking | t.RollbackAmountInUSD — rollback amount converted to USD | Tier 2 |
| 16 | Reference Number | External_etoro_Billing_CashoutRollbackTracking | t.ReferenceNumber — external payment reference | Tier 2 |
| 17 | RollbackReason | External_etoro_Billing_CashoutRollbackTracking | CASE t.RollbackReasonID: 1=ReturnedPayment, 2=RejectOrFailedPayment, 3=AdjustDiscrepancy, 4=CancelRollback | Tier 2 |
| 18 | Funding Method | DWH_dbo.Dim_FundingType | CASE WHEN FT.Name IS NULL THEN FT1.Name ELSE FT.Name — from FundingTypeID_Funding then FundingTypeID_Withdraw | Tier 2 |
| 19 | Brand | DWH_dbo.Dim_CardType | ct.CarTypeName (card type name from BinCode lookup) — NULL/empty for wire transfers (no card bin) | Tier 2 |
| 20 | Payment Details | SP_Finance_Cashout_RollbackDetails | Hardcoded literal string 'Payment Details' — static placeholder, never populated with actual data | Tier 2 |
| 21 | FundingID | BI_DB_dbo.External_etoro_Billimg_vWithdrawToFunding_FUll | WTF.FundingID — internal funding method record ID | Tier 2 |
| 22 | Depot | DWH_dbo.Dim_BillingDepot | d.Name — payment processing depot name | Tier 2 |
| 23 | VerificationCode | DWH_dbo.Fact_BillingWithdraw | BW.VerificationCode — payment verification/authorization code from billing system | Tier 2 |
| 24 | Regulation | DWH_dbo.Dim_Regulation | dr.Name via Dim_Customer.RegulationID | Tier 2 |
| 25 | Mid Name | DWH_dbo.Dim_BillingProtocolMIDSettingsID | BPMS1.Description — merchant/protocol MID description | Tier 2 |
| 26 | MID | DWH_dbo.Dim_BillingProtocolMIDSettingsID | CASE WHEN DepotID IN (7,8,93) THEN BPMS1.Description ELSE BPMS1.Value — depot-conditional MID value | Tier 2 |
| 27 | Comments | External_etoro_Billing_CashoutRollbackTracking | t.Comments — free-text notes on the rollback | Tier 2 |
| 28 | PlayerLevel | DWH_dbo.Dim_PlayerLevel | dpl.Name via Dim_Customer.PlayerLevelID | Tier 2 |
| 29 | PIPs in USD | (derived in #withdraw2) | ((-1 * AmountUSD / BaseExchangeRate) + Amount) * BaseExchangeRate — exchange difference in USD; 0 for USD withdrawals | Tier 2 |
| 30 | PreviousCS | (derived in #previousstatus) | LAG([Withdraw Processing Id Stauts], 1, 0) OVER (PARTITION BY WitdrawToFundingID ORDER BY ModificationDate) — prior cashout status | Tier 2 |
| 31 | UpdateDate | SP_Finance_Cashout_RollbackDetails | GETDATE() at INSERT | Tier 2 |

## Tier Summary

- **Tier 1**: 0 columns (no DWH_dbo upstream wiki passthrough applicable)
- **Tier 2**: 31 columns (SP code and DDL explicit for all columns)
- **UC Target**: Not Migrated

## Notes

- Column name typo in DDL: `[Withdraw Processing Id Stauts]` (misspelling of "Status") — matches SP alias exactly.
- Column name typo in source: SP source table uses `WitdrawToFundingID` (missing 'h') in CashoutRollbackTracking — preserved in `[Withdraw Payment ID]`.
- `[Payment Details]` is hardcoded as the literal string `'Payment Details'` in every row — it is a static placeholder never populated with real data.
- `[Brand]` comes from Dim_CardType (card type name) via BinCode — always empty for wire transfers and MoneyBookers which have no card bin.
- `[Fee PIPs]` is `BW.ExchangeFee` from Fact_BillingWithdraw — it is an exchange fee, not measured in PIPs; always 0 for wire transfers.
- Refresh deletes only rows WHERE Status Modification Time between @Date and @Date+1 — the table is append/replace per date, not a full reload.
- Data is heavily concentrated: BVI regulation = 57% of rows; ReturnedPayment via WireTransfer = largest cohort.
