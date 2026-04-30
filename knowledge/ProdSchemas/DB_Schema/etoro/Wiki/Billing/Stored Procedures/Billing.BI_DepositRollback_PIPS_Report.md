# Billing.BI_DepositRollback_PIPS_Report

> BI reporting procedure that returns deposit rollback records (full/partial refunds) with provider fee (PIPsInUSD) calculations for a date window, sourced from Billing.DepositRollbackTracking joined to History.ActiveCredit on rollback credit types (11 and 12).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns resultset (CID, DepositID, FundingID, DepotID, CardType, CardCategory, DepositStatus, RollbackAmount, RollbackAmountInUSD, PIPsInUSD, MID, MIDName, ...) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BI_DepositRollback_PIPS_Report` provides the BI team with a focused view of deposit refund (rollback) activity and associated provider fees. When a deposit is partially or fully reversed - for example, due to a chargeback, customer request, or processing error - a rollback record is created in `Billing.DepositRollbackTracking`. This procedure returns those rollback events within a date window alongside the CalculateDepositRollbackPIPsUSD fee for each.

The date filter applies to `History.ActiveCredit.Occurred` (the credit event timestamp), not to the rollback creation date. This aligns with how other BI deposit reports filter by the balance-engine event time, ensuring consistency when combining reports.

---

## 2. Business Logic

### 2.1 Rollback Record Selection

**What**: Returns deposit rollback records where a credit event of type 11 or 12 occurred in the date window.

**Parameters/Columns Involved**: `@StartPoint`, `@EndPoint`, `History.ActiveCredit.CreditTypeID`

**Rules**:
- Primary source: `Billing.DepositRollbackTracking` (BDRT).
- JOINs to: Billing.Deposit (for depot/merchant data), Billing.Funding (for card data), Dictionary.PaymentStatus, Dictionary.CardType, Dictionary.CountryBin, History.ActiveCredit.
- `INNER JOIN History.ActiveCredit ON HC.DepositRollbackID = BDRT.RollbackID AND HC.CID = BD.CID AND HC.CreditTypeID IN (11, 12)`.
  - CreditTypeID 11 = partial rollback; CreditTypeID 12 = full rollback.
- Filter: `HC.Occurred >= @StartPoint AND HC.Occurred < @EndPoint`.
- @EndPoint defaults to GETUTCDATE() if NULL.

### 2.2 DepositStatus from PaymentStatus Table

**What**: Returns the deposit status at the time of rollback.

**Rules**:
- `INNER JOIN Dictionary.PaymentStatus as DFT ON DFT.PaymentStatusID = BDRT.PaymentStatusID`.
- `DFT.Name AS DepositStatus`: human-readable status (e.g., "Approved", "Chargeback").
- Unlike BI_Deposit_State_Report which uses the BI_GetDepositStatus UDF, this report resolves the status directly from Dictionary.PaymentStatus.

### 2.3 PIPsInUSD

**What**: Provider fee for the rollback operation.

**Rules**:
- `(SELECT Billing.CalculateDepositRollbackPIPsUSD(BDRT.DepositID, BDRT.RollbackID)) as PIPsInUSD`.
- No ISNULL wrapping - could return NULL if not calculable.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartPoint | DATETIME | NO | - | VERIFIED | Start of date window (inclusive). Filters History.ActiveCredit.Occurred. |
| 2 | @EndPoint | DATETIME | YES | GETUTCDATE() | VERIFIED | End of date window (exclusive). Defaults to current UTC time if NULL. |

**Result set columns**:

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | CID | Billing.DepositRollbackTracking | Customer ID. |
| 2 | DepositID | Billing.DepositRollbackTracking | Original deposit ID. |
| 3 | FundingID | Billing.Funding | Payment instrument ID. |
| 4 | DepotID | Billing.Deposit | Processing depot ID. |
| 5 | CreditTypeID | History.ActiveCredit | Credit type (11=partial rollback, 12=full rollback). |
| 6 | CardType | Dictionary.CardType | Card network name ('N/A' if not card). |
| 7 | CardCategory | Dictionary.CountryBin | Card product class ('N/A' if not found). |
| 8 | DepositStatus | Dictionary.PaymentStatus.Name | Deposit status at time of rollback. |
| 9 | RollbackAmount | BDRT.RollbackAmountInCurrency | Refund amount in deposit currency. |
| 10 | RollbackAmountInUSD | BDRT.RollbackAmountInUSD | Refund amount in USD. |
| 11 | BaseExchangeRate | BDRT.BaseExchangeRate | FX rate used for the rollback. |
| 12 | ExchangeFee | BDRT.ExchangeFee | Exchange fee on the rollback. |
| 13 | ExchangeRate | BDRT.ExchangeRate | Exchange rate applied to the rollback. |
| 14 | CurrencyID | BDRT.CurrencyID | Currency of the rollback amount. |
| 15 | ExTransactionID | BDRT.ReferenceNumber | External transaction reference from the provider. |
| 16 | ProtocolMIDSettingsID | Billing.Deposit | Protocol MID settings for the original deposit. |
| 17 | MerchantAccountID | Billing.Deposit | Merchant account for the original deposit. |
| 18 | PIPsInUSD | Billing.CalculateDepositRollbackPIPsUSD | Provider fee for the rollback operation (may be NULL). |
| 19 | MID | Billing.GetMIDDescription | Merchant ID code for the original deposit. |
| 20 | MIDName | Billing.GetMIDDescription | Human-readable merchant account name. |
| 21 | ModificationDate | History.ActiveCredit.Occurred | Credit event timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BDRT | Billing.DepositRollbackTracking | READER | Primary source of rollback records. |
| BDRT.DepositID | Billing.Deposit | READER | Original deposit for depot/merchant data. |
| BD.FundingID | Billing.Funding | READER | Payment instrument for XML card extraction. |
| BDRT.PaymentStatusID | Dictionary.PaymentStatus | READER | Rollback status name. |
| BF.FundingData | Dictionary.CardType | READER (LEFT JOIN) | Card type from XML. |
| BF.FundingData | Dictionary.CountryBin | READER (LEFT JOIN) | Card product class. |
| BDRT.RollbackID | History.ActiveCredit | READER | Credit event timestamp filter. |
| (func) | Billing.CalculateDepositRollbackPIPsUSD | EXEC (UDF) | Provider fee for rollback. |
| (func) | Billing.GetMIDDescription | EXEC (TVF) | MID and description for original deposit. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from BI reporting systems.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BI_DepositRollback_PIPS_Report (procedure)
|- Billing.DepositRollbackTracking (table)           [SELECT - rollback source]
|- Billing.Deposit (table)                           [JOIN - original deposit metadata]
|- Billing.Funding (table)                           [JOIN - XML card data]
|- Dictionary.PaymentStatus (table)                  [JOIN - status name]
|- Dictionary.CardType (table)                       [LEFT JOIN - card type]
|- Dictionary.CountryBin (table)                     [LEFT JOIN - card category]
|- History.ActiveCredit (table)                      [JOIN - credit event filter]
|- Billing.CalculateDepositRollbackPIPsUSD (func)    [EXEC UDF - rollback PIPs]
+- Billing.GetMIDDescription (func/TVF)              [EXEC - MID lookup]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepositRollbackTracking | Table | Primary rollback data source |
| Billing.Deposit | Table | Original deposit depot and merchant account data |
| Billing.Funding | Table | XML card type and BIN code |
| Dictionary.PaymentStatus | Table | Status name resolution |
| Dictionary.CardType | Table | Card network name |
| Dictionary.CountryBin | Table | Card product class |
| History.ActiveCredit | Table | Event timestamp and rollback credit type filter |
| Billing.CalculateDepositRollbackPIPsUSD | Function | Rollback provider fee calculation |
| Billing.GetMIDDescription | Function/TVF | MID and merchant name |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from BI reporting systems.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Run rollback PIPs report for a date range
```sql
EXEC Billing.BI_DepositRollback_PIPS_Report
    @StartPoint = '2026-03-01',
    @EndPoint   = '2026-03-17';
```

### 8.2 Run from a start date to now
```sql
EXEC Billing.BI_DepositRollback_PIPS_Report
    @StartPoint = '2026-03-01';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.BI_DepositRollback_PIPS_Report | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BI_DepositRollback_PIPS_Report.sql*
