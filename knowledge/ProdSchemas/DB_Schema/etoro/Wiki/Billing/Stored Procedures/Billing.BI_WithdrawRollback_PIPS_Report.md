# Billing.BI_WithdrawRollback_PIPS_Report

> BI reporting procedure that returns cashout rollback records with provider fee (PIPsInUSD) calculations for a date window, sourced from Billing.CashoutRollbackTracking, providing the BI team with chargeback/reversal cost analysis.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns resultset (CID, WithdrawID, WithdrawPaymentID, CashoutStatusID, CardType, RollbackAmount, PIPsInUSD, MID, MIDName, ...) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BI_WithdrawRollback_PIPS_Report` provides the BI team with cashout reversal activity and associated provider fees. When a previously-processed cashout is reversed - for example, due to a chargeback by the card network, an operational error, or a fraud reversal - a rollback record is created in `Billing.CashoutRollbackTracking`. This procedure returns those rollback records within a date window alongside their PIPs (provider interchange fee) calculations.

This is the cashout-side counterpart to `Billing.BI_DepositRollback_PIPS_Report` which covers deposit rollbacks. Together they give the BI team a complete view of all reversal activity and associated costs.

The date filter applies to `Billing.CashoutRollbackTracking.ModificationDate`, making it consistent with how operations teams monitor cashout rollback activity.

---

## 2. Business Logic

### 2.1 Cashout Rollback Record Selection

**What**: Returns all cashout rollback records within the date window.

**Parameters/Columns Involved**: `@StartPoint`, `@EndPoint`, `Billing.CashoutRollbackTracking`

**Rules**:
- `FROM Billing.CashoutRollbackTracking as CRT`.
- Filter: `CRT.ModificationDate >= @StartPoint AND CRT.ModificationDate < @EndPoint`.
- `ORDER BY CRT.WitdrawToFundingID DESC` - most recent processing legs first.
- @EndPoint defaults to GETUTCDATE() if NULL.
- No status filter - all rollback records in the window are returned regardless of rollback type.

### 2.2 CashoutStatus Resolved from Current Processing Leg

**What**: Returns the current cashout status of the payment leg (not the rollback status itself).

**Rules**:
- `INNER JOIN Dictionary.CashoutStatus as DCS ON DCS.CashoutStatusID = BWTF.CashoutStatusID`.
- `DCS.Name as WithdrawProcessingIDStatus` - current status of the cashout payment leg.

### 2.3 PIPsInUSD

**What**: Provider fee for the rollback operation.

**Rules**:
- `(SELECT Billing.CalculateWithdrawRollbackPIPsUSD(CRT.WitdrawToFundingID, CRT.RollbackID)) as PIPsInUSD`.
- No ISNULL wrapping - can return NULL if not calculable.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartPoint | DATETIME | NO | - | VERIFIED | Start of date window (inclusive). Filters Billing.CashoutRollbackTracking.ModificationDate. |
| 2 | @EndPoint | DATETIME | YES | GETUTCDATE() | VERIFIED | End of date window (exclusive). Defaults to GETUTCDATE() if NULL. |

**Result set columns**:

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | CID | Billing.CashoutRollbackTracking | Customer ID. |
| 2 | WithdrawID | Billing.CashoutRollbackTracking | Withdrawal request ID. |
| 3 | WithdrawPaymentID | CRT.WitdrawToFundingID | Payment processing leg ID (note: typo in column alias - "Witdraw" not "Withdraw"). |
| 4 | WithdrawProcessingIDStatus | Dictionary.CashoutStatus.Name | Current cashout processing status name. |
| 5 | FundingID | Billing.WithdrawToFunding | Payment instrument ID. |
| 6 | DepotID | Billing.WithdrawToFunding | Payment depot/provider ID. |
| 7 | CardType | Dictionary.CardType | Card network name ('N/A' for non-card). |
| 8 | CardCategory | Dictionary.CountryBin | Card product class ('N/A' if not found). |
| 9 | RollbackAmount | CRT.RollbackAmountInCurrency | Reversed amount in original currency. |
| 10 | RollbackAmountInUSD | CRT.RollbackAmountInUSD | Reversed amount in USD. |
| 11 | BaseExchangeRate | CRT.BaseExchangeRate | FX rate used for the rollback. |
| 12 | ExchangeFee | CRT.ExchangeFee | Exchange fee on the rollback. |
| 13 | ExchangeRate | CRT.ExchangeRate | Exchange rate applied. |
| 14 | CurrencyID | CRT.CurrencyID | Currency of the rollback amount. |
| 15 | ExTransactionID | CRT.ReferenceNumber | External transaction reference from the provider. |
| 16 | ProtocolMIDSettingsID | Billing.WithdrawToFunding | Protocol MID settings for the original cashout. |
| 17 | MerchantAccountID | Billing.WithdrawToFunding | Merchant account for the original cashout. |
| 18 | PIPsInUSD | Billing.CalculateWithdrawRollbackPIPsUSD | Provider fee for the rollback (may be NULL). |
| 19 | MID | Billing.GetMIDDescription | Merchant ID code for the original cashout. |
| 20 | MIDName | Billing.GetMIDDescription | Human-readable merchant account name. |
| 21 | ModificationDate | CRT.ModificationDate | Rollback record modification timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CRT | Billing.CashoutRollbackTracking | READER | Primary rollback record source. |
| CRT.WitdrawToFundingID | Billing.WithdrawToFunding | READER | Original cashout payment leg details. |
| BWTF.FundingID | Billing.Funding | READER | Payment instrument XML card data. |
| BWTF.CashoutStatusID | Dictionary.CashoutStatus | READER | Current processing leg status name. |
| BF.FundingData | Dictionary.CardType | READER (LEFT JOIN) | Card type from XML. |
| BF.FundingData | Dictionary.CountryBin | READER (LEFT JOIN) | Card category from BIN. |
| (func) | Billing.CalculateWithdrawRollbackPIPsUSD | EXEC (UDF) | Provider fee for rollback. |
| (func) | Billing.GetMIDDescription | EXEC (TVF) | MID and description for original cashout. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from BI reporting systems.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BI_WithdrawRollback_PIPS_Report (procedure)
|- Billing.CashoutRollbackTracking (table)           [SELECT - rollback source]
|- Billing.WithdrawToFunding (table)                 [JOIN - original cashout leg]
|- Billing.Funding (table)                           [JOIN - XML card data]
|- Dictionary.CashoutStatus (table)                  [JOIN - status name]
|- Dictionary.CardType (table)                       [LEFT JOIN - card type]
|- Dictionary.CountryBin (table)                     [LEFT JOIN - card category]
|- Billing.CalculateWithdrawRollbackPIPsUSD (func)   [EXEC UDF - rollback PIPs]
+- Billing.GetMIDDescription (func/TVF)              [EXEC - MID lookup]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.CashoutRollbackTracking | Table | Primary source of cashout rollback records |
| Billing.WithdrawToFunding | Table | Original cashout payment leg (depot, FundingID, status) |
| Billing.Funding | Table | XML FundingData for card type and BIN |
| Dictionary.CashoutStatus | Table | Current processing status name |
| Dictionary.CardType | Table | Card network name |
| Dictionary.CountryBin | Table | Card product class |
| Billing.CalculateWithdrawRollbackPIPsUSD | Function | Provider fee per cashout rollback |
| Billing.GetMIDDescription | Function/TVF | MID and merchant name |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from BI reporting systems.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **Column alias typo**: `CRT.WitdrawToFundingID` is aliased as `WithdrawPaymentID` (note: "Witdraw" in the source column name is a typo in the original table/column definition that has been preserved).
- **No status filter**: Unlike BI_Withdraw_PIPS_Report which requires CashoutStatusID=3 (Approved), this report returns ALL cashout rollbacks regardless of the current payment leg status.

---

## 8. Sample Queries

### 8.1 Run cashout rollback PIPs report
```sql
EXEC Billing.BI_WithdrawRollback_PIPS_Report
    @StartPoint = '2026-03-01',
    @EndPoint   = '2026-03-17';
```

### 8.2 Run from a start date to now
```sql
EXEC Billing.BI_WithdrawRollback_PIPS_Report
    @StartPoint = '2026-03-01';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.BI_WithdrawRollback_PIPS_Report | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BI_WithdrawRollback_PIPS_Report.sql*
