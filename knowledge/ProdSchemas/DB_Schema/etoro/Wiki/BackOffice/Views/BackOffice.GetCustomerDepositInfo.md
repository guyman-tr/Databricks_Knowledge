# BackOffice.GetCustomerDepositInfo

> Unified deposit history view combining legacy Billing.Payment and current Billing.Deposit records into a single ranked, currency-converted deposit timeline per customer.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | CustomerDepositNumber (RANK per CID, not unique across all rows) |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.GetCustomerDepositInfo` provides a unified, sequential deposit history for every customer by merging two deposit record sources:

1. **Billing.Payment** (legacy deposit model): Rows with `PaymentStatusID = 2` (approved). Amount is stored as cents x exchange rate - converted by `(Amount * ExchangeRate) / 100.0`. PaymentID is set; DepositID is NULL.

2. **Billing.Deposit** (current deposit model): Rows with `PaymentStatusID = 2` (approved). Amount is stored in currency units - converted by `Amount * ExchangeRate`. DepositID is set; PaymentID is NULL. FundingTypeID comes from the joined `Billing.Funding` record.

The view applies a `RANK()` window function per CID ordered by `ModificationDate` to number each customer's deposits chronologically. This lets consumers identify the first deposit (Rank=1), second deposit, etc., which is critical for FTD (First-Time Deposit) attribution, onboarding milestones, and deposit velocity analysis.

Only approved deposits (`PaymentStatusID = 2`) from both sources are included - pending, rejected, or rolled-back deposits are excluded.

---

## 2. Business Logic

### 2.1 Dual-Source Approved Deposit Merge with Sequential Ranking

**What**: Combines approved Payment and Deposit records into a single ranked timeline per customer.

**Columns Involved**: All output columns

**Rules**:
- Both branches filter `PaymentStatusID = 2` (approved only). Other statuses (pending, declined, chargeback) are excluded.
- **Payment branch**: `Amount = (Payment.Amount * Payment.ExchangeRate) / 100.0` - legacy amounts are stored in cents.
- **Deposit branch**: `Amount = Deposit.Amount * Deposit.ExchangeRate` - modern amounts in currency units. Requires JOIN to Billing.Funding to get FundingTypeID.
- **RANK()**: Applied over the merged UNION ALL result, `PARTITION BY CID ORDER BY ModificationDate ASC`. Ties in ModificationDate get the same rank.
- `CustomerDepositNumber = 1` identifies each customer's FTD (first-time deposit).
- `PaymentID` is NULL in the Deposit branch; `DepositID` is NULL in the Payment branch - callers must handle this NULLability.
- The `Approved` and `ManagerID` columns are passed through from the source tables directly.

**Diagram**:
```
Billing.Payment WHERE PaymentStatusID=2
  PaymentID=X, DepositID=NULL
  Amount = (Amount * ExchangeRate) / 100.0
       |
       UNION ALL
       |
Billing.Deposit WHERE PaymentStatusID=2
  JOIN Billing.Funding ON FundingID
  PaymentID=NULL, DepositID=Y
  Amount = Amount * ExchangeRate
       |
       v
  RANK() OVER (PARTITION BY CID ORDER BY ModificationDate)
       |
       v
BackOffice.GetCustomerDepositInfo
  CustomerDepositNumber | CID | Amount$ | PaymentDate | FundingTypeID | ...
  1                     | 123 | 500.00  | 2024-01-15  | 3             | ...
  2                     | 123 | 250.00  | 2024-03-10  | 5             | ...
  1                     | 456 | 100.00  | 2025-06-01  | 3             | ...
```

---

## 3. Data Overview

Combined row count from Billing.Payment (PaymentStatusID=2) + Billing.Deposit (PaymentStatusID=2). Covers all approved deposits from the legacy payment system and the current deposit system.

---

## 4. Elements

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | CustomerDepositNumber | bigint | CODE-BACKED | Sequential rank of this deposit for the customer, ordered by ModificationDate ASC. 1 = first deposit (FTD). Ties get the same rank. |
| 2 | CID | int | CODE-BACKED | Customer ID. Matches Billing.Payment.CID / Billing.Deposit.CID. |
| 3 | Amount$ | money | CODE-BACKED | Deposit amount in USD (or base currency after exchange rate conversion). Legacy: (Amount*ExchangeRate)/100.0. Modern: Amount*ExchangeRate. |
| 4 | PaymentDate | datetime | CODE-BACKED | Date the payment was processed/received. From Billing.Payment.PaymentDate or Billing.Deposit.PaymentDate. |
| 5 | ModificationDate | datetime | CODE-BACKED | Most recent status modification date. Used as the ORDER BY for RANK(). From the respective table. |
| 6 | FundingTypeID | int | CODE-BACKED | Funding method type (e.g., CreditCard, BankTransfer, CryptoWallet). From Billing.Payment directly, or via Billing.Funding JOIN for Deposit branch. FK to Dictionary.FundingType. |
| 7 | CurrencyID | int | CODE-BACKED | Currency of the deposit. FK to Dictionary.Currency. |
| 8 | PaymentID | int | YES | CODE-BACKED | Billing.Payment PK. NULL for rows sourced from Billing.Deposit. |
| 9 | DepositID | int | YES | CODE-BACKED | Billing.Deposit PK. NULL for rows sourced from Billing.Payment. |
| 10 | TransactionID | nvarchar | CODE-BACKED | External payment processor transaction reference. |
| 11 | Approved | bit | CODE-BACKED | Approval flag. Both branches filter PaymentStatusID=2 so this is effectively always 1. |
| 12 | ManagerID | int | CODE-BACKED | Back-office manager who approved/processed the deposit, if applicable. NULL if automated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Payment branch | Billing.Payment | Base Table | Legacy approved deposits (PaymentStatusID=2) |
| Deposit branch | Billing.Deposit | Base Table | Modern approved deposits (PaymentStatusID=2) |
| FundingTypeID | Billing.Funding | JOIN | FundingTypeID lookup for Deposit branch (Deposit -> Funding JOIN) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No BackOffice SP consumers identified in SSDT repo) | - | - | Likely consumed by application layer for deposit history display and FTD detection |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerDepositInfo (view)
+-- Billing.Payment (PaymentStatusID=2)
+-- Billing.Deposit (PaymentStatusID=2)
      +-- Billing.Funding (JOIN for FundingTypeID)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Payment | Table (cross-schema) | Legacy deposit branch - approved payments |
| Billing.Deposit | Table (cross-schema) | Modern deposit branch - approved deposits |
| Billing.Funding | Table (cross-schema) | Joined to Deposit to resolve FundingTypeID |

### 6.2 Objects That Depend On This

No stored procedure consumers identified in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Performance depends on:
- `Billing.Payment` index on `(CID, PaymentStatusID)`
- `Billing.Deposit` index on `(CID, PaymentStatusID)`
- `Billing.Funding` PK on FundingID

### 7.2 Constraints

N/A for View. Both branches filter PaymentStatusID=2, ensuring only approved deposits appear.

---

## 8. Sample Queries

### 8.1 Get all deposits for a customer in chronological order

```sql
SELECT CustomerDepositNumber, CID, Amount$, PaymentDate, FundingTypeID, CurrencyID
FROM BackOffice.GetCustomerDepositInfo WITH (NOLOCK)
WHERE CID = 12345
ORDER BY CustomerDepositNumber;
```

### 8.2 Get first-time deposit info for a set of customers

```sql
SELECT CID, Amount$ AS FTDAmount, PaymentDate AS FTDDate, FundingTypeID
FROM BackOffice.GetCustomerDepositInfo WITH (NOLOCK)
WHERE CustomerDepositNumber = 1
  AND PaymentDate >= '2026-01-01';
```

### 8.3 Identify source of each deposit row

```sql
SELECT CustomerDepositNumber,
       CID,
       Amount$,
       CASE WHEN PaymentID IS NOT NULL THEN 'Legacy (Payment)'
            WHEN DepositID IS NOT NULL THEN 'Modern (Deposit)'
       END AS Source
FROM BackOffice.GetCustomerDepositInfo WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this view.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11 (DDL, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerDepositInfo | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.GetCustomerDepositInfo.sql*
