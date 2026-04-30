# Billing.BI_Withdraw_PIPS_Report

> BI reporting procedure that returns approved cashout records (CashoutStatusID=3) with provider fee (PIPsInUSD) calculations for a date window, sourced from History.WithdrawToFundingAction with a self-join to isolate the most recent approved state.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns resultset (CID, WithdrawID, WithdrawProcessingID, CashoutStatusID, Amount, AmountUSD, CardType, PIPsInUSD, FeeInPercentage, MID, MIDName, ...) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BI_Withdraw_PIPS_Report` provides the BI team with cashout-level fee analysis for approved (processed) withdrawals. For each cashout payment leg that reached CashoutStatusID=3 (Approved/Processed), it returns the payment details alongside the provider interchange fee (PIPs in USD) and fee percentage.

The procedure uses `History.WithdrawToFundingAction` as its event source (not History.ActiveCredit), self-joining to find action records where the final approved status (BWTFA_2.CashoutStatusID=3) is confirmed. The date filter is applied to the action record's ModificationDate rather than a credit event timestamp. Only records where the action date is at or after the approved-state date are included, ensuring the row represents the state at or after approval.

---

## 2. Business Logic

### 2.1 Approved Cashout Selection with Self-Join

**What**: Returns cashout action records that have a confirmed approval (CashoutStatusID=3) within the date window.

**Parameters/Columns Involved**: `@StartPoint`, `@EndPoint`, `History.WithdrawToFundingAction`

**Rules**:
- `FROM History.WithdrawToFundingAction as BWTFA`.
- `INNER JOIN History.WithdrawToFundingAction as BWTFA_2 ON BWTFA_2.BW2F_ID = BWTFA.BW2F_ID` - self-join on the same processing ID.
- Filter: `BWTFA_2.CashoutStatusID = 3` (approved) AND `BWTFA.ModificationDate > @StartPoint` AND `BWTFA.ModificationDate < @EndPoint`.
- `BWTFA.ModificationDate >= BWTFA_2.ModificationDate`: ensures BWTFA represents an action at or after the approval event.
- `SELECT DISTINCT`: removes duplicates since multiple BWTFA records may exist for the same BW2F_ID.
- @EndPoint defaults to GETUTCDATE() if NULL.

### 2.2 PIPsInUSD and FeeInPercentage

**What**: Provider fee and percentage calculated per cashout leg.

**Rules**:
- `PIPsInUSD = ISNULL(Billing.CalculateWithdrawPIPsUSD(BWTFA.BW2F_ID), 0)`.
- `FeeInPercentage = (PIPsInUSD / (BWTFA.Amount * BWTFA.ExchangeRate)) * 100`.
- @WithdrawActionID=2 is passed to GetMIDDescription (identifies this as a cashout context).

### 2.3 Card Metadata from FundingData XML

**What**: Card type and product class extracted from Billing.Funding.FundingData XML.

**Rules**:
- Same XML extraction pattern as BI_Deposit_PIPS_Report.
- `COALESCE(DCT.Name, 'N/A')` as CardType; `COALESCE(DCB.ProductType, 'N/A')` as CardCategory.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartPoint | DATETIME | NO | - | VERIFIED | Start of date window (exclusive on lower bound: ModificationDate > @StartPoint). |
| 2 | @EndPoint | DATETIME | YES | GETUTCDATE() | VERIFIED | End of date window (exclusive: ModificationDate < @EndPoint). Defaults to GETUTCDATE() if NULL. |

**Result set columns** (key columns):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | CID | Billing.Withdraw | Customer ID. |
| 2 | WithdrawID | Billing.Withdraw | Withdrawal request ID. |
| 3 | WithdrawProcessingID | BWTFA.BW2F_ID | Payment processing leg ID. |
| 4 | DepositID | Billing.WithdrawToFunding | Associated deposit ID (funding instrument linkage). |
| 5 | FundingID | BWTFA.FundingID | Payment instrument used for the withdrawal. |
| 6 | DepotID | Billing.WithdrawToFunding | Payment depot/provider ID. |
| 7 | CashoutStatusID | BWTFA.CashoutStatusID | Payment processing status. |
| 8 | Amount | BWTFA.Amount | Cashout amount in processing currency. |
| 9 | CurrencyID | BWTFA.ProcessCurrencyID | Currency of the amount. |
| 10 | AmountUSD | Amount * ExchangeRate | USD equivalent. |
| 11 | CardType | Dictionary.CardType | Card network name ('N/A' for non-card). |
| 12 | CardCategory | Dictionary.CountryBin | Card product class ('N/A' if not found). |
| 13 | BaseExchangeRate | BWTFA.BaseExchangeRate | FX rate. |
| 14 | ExchangeFee | BWTFA.ExchangeFee | Exchange fee. |
| 15 | ExchangeRate | BWTFA.ExchangeRate | Effective exchange rate. |
| 16 | ExTransactionID | Billing.WithdrawToFunding.VerificationCode | External transaction reference from provider. |
| 17 | ModificationDate | BWTFA.ModificationDate | Action event timestamp. |
| 18 | RequestDate | Billing.Withdraw.RequestDate | Date the customer submitted the withdrawal. |
| 19 | ProtocolMIDSettingsID | BWTFA.ProtocolMIDSettingsID | Protocol MID settings ID. |
| 20 | MerchantAccountID | BWTFA.MerchantAccountID | Merchant account identifier. |
| 21 | PIPsInUSD | Billing.CalculateWithdrawPIPsUSD | Provider fee in USD (0 if NULL). |
| 22 | FeeInPercentage | PIPsInUSD / AmountUSD * 100 | Fee as percentage of USD amount. |
| 23 | MID | Billing.GetMIDDescription | Merchant ID code. |
| 24 | MIDName | Billing.GetMIDDescription | Human-readable merchant account name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BWTFA, BWTFA_2 | History.WithdrawToFundingAction | READER | Action event source + self-join for approval confirmation. |
| BWTFA.BW2F_ID | Billing.WithdrawToFunding | READER | Processing leg details (DepositID, DepotID, VerificationCode). |
| BWTF.WithdrawID | Billing.Withdraw | READER | Withdrawal request (CID, RequestDate). |
| BWTF.FundingID | Billing.Funding | READER | Payment instrument XML card data. |
| BF.FundingData | Dictionary.CardType | READER (LEFT JOIN) | Card type. |
| BF.FundingData | Dictionary.CountryBin | READER (LEFT JOIN) | Card category. |
| (func) | Billing.CalculateWithdrawPIPsUSD | EXEC (UDF) | Provider fee per withdrawal leg. |
| (func) | Billing.GetMIDDescription | EXEC (TVF) | MID and description. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from BI reporting systems.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BI_Withdraw_PIPS_Report (procedure)
|- History.WithdrawToFundingAction (table)   [SELECT + self-JOIN for approval check]
|- Billing.WithdrawToFunding (table)         [JOIN - leg details]
|- Billing.Withdraw (table)                  [JOIN - withdrawal request data]
|- Billing.Funding (table)                   [JOIN - XML card data]
|- Dictionary.CardType (table)               [LEFT JOIN - card type]
|- Dictionary.CountryBin (table)             [LEFT JOIN - card category]
|- Billing.CalculateWithdrawPIPsUSD (func)   [EXEC UDF - provider fee]
+- Billing.GetMIDDescription (func/TVF)      [EXEC - MID lookup]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.WithdrawToFundingAction | Table | Primary source + self-join for approved status validation |
| Billing.WithdrawToFunding | Table | Processing leg DepotID, DepositID, VerificationCode |
| Billing.Withdraw | Table | CID and RequestDate |
| Billing.Funding | Table | XML FundingData for card type and BIN |
| Dictionary.CardType | Table | Card network name |
| Dictionary.CountryBin | Table | Card product class |
| Billing.CalculateWithdrawPIPsUSD | Function | Provider fee per withdrawal leg |
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

- **@StartPoint is exclusive** (`ModificationDate > @StartPoint`), unlike BI_Deposit_PIPS_Report which uses `>=`. Callers should account for this when selecting date boundaries.
- **Self-join on History.WithdrawToFundingAction**: The join on BW2F_ID where BWTFA_2.CashoutStatusID=3 AND BWTFA.ModificationDate >= BWTFA_2.ModificationDate allows returning multiple action rows (not just the approval row itself) while requiring that an approved state exists for the leg.

---

## 8. Sample Queries

### 8.1 Run withdrawal PIPs report
```sql
EXEC Billing.BI_Withdraw_PIPS_Report
    @StartPoint = '2026-03-01',
    @EndPoint   = '2026-03-17';
```

### 8.2 Run from a start date to now
```sql
EXEC Billing.BI_Withdraw_PIPS_Report
    @StartPoint = '2026-03-01';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.BI_Withdraw_PIPS_Report | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BI_Withdraw_PIPS_Report.sql*
