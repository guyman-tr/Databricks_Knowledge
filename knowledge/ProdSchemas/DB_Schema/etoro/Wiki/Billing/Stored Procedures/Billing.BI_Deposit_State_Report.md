# Billing.BI_Deposit_State_Report

> BI reporting procedure that returns the full deposit event history for a date window, including deposit credits, rollbacks, and intermediate status events (CreditTypeIDs 1,6,7,11,12,16,17,32), enriched with dynamically-computed DepositStatus, PreviousStatus, TransactionType, and fee calculations.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns resultset (CreditID, CID, DepositID, PaymentStatusID, CardType, MID, Amount, AmountInUSD, DepositStatus, PreviousStatus, TransactionType, PIPsInUSD, ...) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BI_Deposit_State_Report` provides the BI team with a comprehensive view of all deposit-related credit events within a date window. Unlike `Billing.BI_Deposit_PIPS_Report` which focuses only on approved deposits and fee analysis, this report covers ALL deposit-related credit types including rollbacks, bonuses, and position credits associated with deposit events.

The report is built on `History.ActiveCredit` as the event source, which means each row represents a credit event at a point in time - not just the final state of a deposit. This makes it suitable for state transition analysis: tracking how deposits moved through approval, rollback, and bonus stages.

Three scalar UDFs compute business labels for each event row:
- `Billing.BI_GetDepositStatus(CreditTypeID, RollbackID)` -> the current status name
- `Billing.BI_GetDepositPreviousStatus(CID, DepositID, CreditID)` -> the status before this event
- `Billing.BI_GetDeposit_TransactionType(CID, DepositID, CreditID, CreditTypeID, RollbackID)` -> transaction type classification

Special handling: LeanMOP deposits (FundingTypeID=43) use a different ExTransactionID field (from PaymentData XML) rather than the standard ExTransactionID column.

---

## 2. Business Logic

### 2.1 Multi-CreditType Event Coverage

**What**: The report covers all deposit-associated credit types, not just successful deposits.

**Parameters/Columns Involved**: `@StartDate`, `@EndDate`, `History.ActiveCredit.CreditTypeID`

**Rules**:
- Filter: `HC.CreditTypeID IN (1, 6, 7, 11, 12, 16, 17, 32)`.
  - 1 = Deposit credit
  - 6 = Manual credit
  - 7 = Bonus credit
  - 11 = Deposit partial rollback
  - 12 = Deposit full rollback
  - 16 = (Reversed type)
  - 17 = (Partially reversed type)
  - 32 = (Additional deposit credit type)
- Date filter: `HC.Occurred >= @StartDate AND HC.Occurred < @EndDate`.
- Ordered by HC.CreditID (chronological within the event log).

### 2.2 Amount and ExTransactionID by Credit Type

**What**: Amount and ExTransactionID differ based on whether the event is a credit or rollback.

**Parameters/Columns Involved**: `HC.CreditTypeID`, `BD.Amount`, `DRT.RollbackAmountInCurrency`, `BD.ExTransactionID`, `BD.PaymentData`

**Rules**:
- `Amount = IIF(HC.CreditTypeID = 1, ABS(BD.Amount), ABS(DRT.RollbackAmountInCurrency))` - for deposits (type=1) use deposit amount; for rollbacks use rollback amount.
- `AmountInUSD = ABS(HC.Payment)` - USD equivalent from the credit event (absolute value).
- ExTransactionID for CreditTypeID=1 (Deposit):
  - Standard: `BD.ExTransactionID`
  - LeanMOP (FundingTypeID=@LeanMOP=43): `BD.PaymentData.value('Deposit[1]/ReceivingBankReferenceIdAsString[1]', 'varchar(50)')` - extracted from XML.
  - `IIF(BF.FundingTypeID <> 43, BD.ExTransactionID, ...)` selects between the two.
- ExTransactionID for rollbacks: `DRT.ReferenceNumber`.

### 2.3 Dynamic Status and Type UDFs

**What**: Three scalar UDFs compute BI-facing business labels per event row.

**Rules**:
- `DepositStatus = Billing.BI_GetDepositStatus(HC.CreditTypeID, DRT.RollbackID)` - current state name.
- `PreviousStatus = Billing.BI_GetDepositPreviousStatus(HC.CID, HC.DepositID, HC.CreditID)` - state before this event.
- `TransactionType = Billing.BI_GetDeposit_TransactionType(HC.CID, HC.DepositID, HC.CreditID, HC.CreditTypeID, DRT.RollbackID)` - classification.
- These UDFs likely query History.Credit or History.ActiveCredit internally to compute the context.

### 2.4 PIPs/Fee Calculation Split by Credit Type

**What**: PIPsInUSD uses different calculation functions for credits vs rollbacks.

**Rules**:
- `PIPsInUSD = IIF(HC.CreditTypeID = 1, ISNULL(CalculateDepositPIPsUSD(BD.DepositID), 0), ISNULL(CalculateDepositRollbackPIPsUSD(BD.DepositID, DRT.RollbackID), 0))`.
- `FeeInPercentage = CASE WHEN BD.Amount = 0 THEN 0 ELSE (CalculateDepositPIPsUSD(BD.DepositID) / (BD.Amount * BD.ExchangeRate)) * 100 END` - only deposits (always uses deposit PIPs even for rollback rows in this column - different from PIPsInUSD).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | DATETIME | NO | - | VERIFIED | Start of reporting window (inclusive). Filters History.ActiveCredit.Occurred. |
| 2 | @EndDate | DATETIME | NO | - | VERIFIED | End of reporting window (exclusive). Filters History.ActiveCredit.Occurred. |

**Result set columns** (key columns):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | CreditID | History.ActiveCredit | Credit event primary key - unique per event row. |
| 2 | FromDate / EndDate | Literal params | Query window boundaries echoed back in the resultset. |
| 3 | CID | History.ActiveCredit | Customer ID. |
| 4 | CurrencyID | Billing.Deposit | Deposit currency. |
| 5 | DepositID | History.ActiveCredit | Deposit record ID. |
| 6 | DepotID | Billing.Deposit | Processing depot ID. |
| 7 | FundingID | Billing.Deposit | Payment instrument ID. |
| 8 | PaymentStatusID | Billing.Deposit | Current deposit status code. |
| 9 | CardType | Dictionary.CardType | Card network name ('N/A' for non-card). |
| 10 | CardCategory | Dictionary.CountryBin | Card product class ('N/A' if not found). |
| 11 | MID / MIDName | Billing.GetMIDDescription | Merchant ID and description. |
| 12 | ModificationDate | History.ActiveCredit.Occurred | Credit event timestamp. |
| 13 | AmountInUSD | ABS(HC.Payment) | USD amount from the credit event. |
| 14 | Amount | BD.Amount or DRT.RollbackAmountInCurrency | Amount in deposit currency (type-dependent). |
| 15 | ExTransactionID | BD.ExTransactionID or XML or DRT.ReferenceNumber | External transaction reference (source varies by type and FundingType). |
| 16 | DepositStatus | Billing.BI_GetDepositStatus | Business status label for this credit event. |
| 17 | PreviousStatus | Billing.BI_GetDepositPreviousStatus | Business status label before this event. |
| 18 | TransactionType | Billing.BI_GetDeposit_TransactionType | Classification of the event (Deposit/DepositRollback/etc). |
| 19 | PIPsInUSD | Computed (type-dependent UDF) | Provider fee in USD. 0 if NULL. |
| 20 | FeeInPercentage | PIPsInUSD / AmountUSD * 100 | Fee as percentage of deposit (always uses deposit PIPs). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HC.DepositID | History.ActiveCredit | READER | Event source for all deposit-related credits. |
| HC.DepositID | Billing.Deposit | READER | Deposit amounts, depot, funding, payment data. |
| BD.FundingID | Billing.Funding | READER | Payment instrument for XML card extraction. |
| BF.FundingData | Dictionary.CardType | READER (LEFT JOIN) | Card type from XML. |
| BF.FundingData | Dictionary.CountryBin | READER (LEFT JOIN) | Card category from BIN code. |
| HC.DepositRollbackID | Billing.DepositRollbackTracking | READER (LEFT JOIN) | Rollback amounts and reference for rollback event rows. |
| (func) | Billing.GetMIDDescription | EXEC (TVF) | MID and merchant name. |
| (func) | Billing.BI_GetDepositStatus | EXEC (UDF) | Status label computation. |
| (func) | Billing.BI_GetDepositPreviousStatus | EXEC (UDF) | Previous status label computation. |
| (func) | Billing.BI_GetDeposit_TransactionType | EXEC (UDF) | Transaction type classification. |
| (func) | Billing.CalculateDepositPIPsUSD | EXEC (UDF) | Deposit PIPs for CreditTypeID=1. |
| (func) | Billing.CalculateDepositRollbackPIPsUSD | EXEC (UDF) | Rollback PIPs for non-deposit credit types. |

### 5.2 Referenced By (other objects point to this)

Not analyzed - no callers found in the Billing schema SP files. Called from BI reporting systems.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BI_Deposit_State_Report (procedure)
|- History.ActiveCredit (table)                  [READER - deposit event source]
|- Billing.Deposit (table)                       [JOIN - deposit amounts and metadata]
|- Billing.Funding (table)                       [JOIN - payment instrument XML data]
|- Dictionary.CardType (table)                   [LEFT JOIN - card type]
|- Dictionary.CountryBin (table)                 [LEFT JOIN - card category]
|- Billing.DepositRollbackTracking (table)        [LEFT JOIN - rollback amounts]
|- Billing.GetMIDDescription (func/TVF)           [EXEC - MID lookup]
|- Billing.BI_GetDepositStatus (func)             [EXEC - status label]
|- Billing.BI_GetDepositPreviousStatus (func)     [EXEC - previous status label]
|- Billing.BI_GetDeposit_TransactionType (func)   [EXEC - type classification]
|- Billing.CalculateDepositPIPsUSD (func)         [EXEC - deposit PIPs]
+- Billing.CalculateDepositRollbackPIPsUSD (func) [EXEC - rollback PIPs]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | Table | Primary event source (CreditTypeID IN 1,6,7,11,12,16,17,32) |
| Billing.Deposit | Table | Deposit amounts, currencies, ExTransactionID, PaymentData |
| Billing.Funding | Table | XML FundingData for card type and BIN extraction |
| Dictionary.CardType | Table | Card network name |
| Dictionary.CountryBin | Table | Card product class |
| Billing.DepositRollbackTracking | Table | Rollback amount, reference number for non-deposit events |
| Billing.GetMIDDescription | Function/TVF | MID and merchant name |
| Billing.BI_GetDepositStatus | Function | Deposit status label |
| Billing.BI_GetDepositPreviousStatus | Function | Previous deposit status label |
| Billing.BI_GetDeposit_TransactionType | Function | Transaction type classification |
| Billing.CalculateDepositPIPsUSD | Function | Provider fee for deposit events |
| Billing.CalculateDepositRollbackPIPsUSD | Function | Provider fee for rollback events |

### 6.2 Objects That Depend On This

No dependents found in the Billing schema SP files. Called from BI reporting systems.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

### 7.3 Notable Implementation Details

- **LeanMOP special case (@LeanMOP=43)**: FundingTypeID=43 uses PaymentData XML for ExTransactionID. This accommodates a payment method that stores the bank reference inside XML rather than in the standard ExTransactionID column.
- **Multiple scalar UDF calls per row**: The BI_Get* UDFs are called per-row, which may be a performance consideration for large date ranges.
- **FeeInPercentage always uses deposit PIPs**: Even for rollback event rows, FeeInPercentage computes `CalculateDepositPIPsUSD(BD.DepositID)` rather than rollback PIPs. This is intentional for the "original deposit cost" perspective.

---

## 8. Sample Queries

### 8.1 Run state report for today
```sql
EXEC Billing.BI_Deposit_State_Report
    @StartDate = CAST(CAST(GETUTCDATE() AS DATE) AS DATETIME),
    @EndDate   = GETUTCDATE();
```

### 8.2 Run for a specific period
```sql
EXEC Billing.BI_Deposit_State_Report
    @StartDate = '2026-03-01',
    @EndDate   = '2026-03-17';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos (SKIPPED - no Billing repos configured) | Corrections: 0 applied*
*Object: Billing.BI_Deposit_State_Report | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.BI_Deposit_State_Report.sql*
