# Dictionary.SubCreditTypeID

> Classifies credit transactions as Regular or Partial for the financial ledger system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, PK) |
| **Row Count** | 2 |
| **Indexes** | 1 (clustered PK, FILLFACTOR 95) |

---

## 1. Business Meaning

### What It Is
Dictionary.SubCreditTypeID is a lookup table that sub-classifies credit transactions into "Regular" or "Partial" categories. It provides a secondary classification dimension beyond the primary `CreditTypeID` for financial ledger entries.

### Why It Exists
The eToro financial system records every balance-affecting event as a credit entry (deposits, withdrawals, position P&L, fees, etc.). While `Dictionary.CreditType` classifies the *type* of operation, `SubCreditTypeID` classifies *how much* of the operation was applied — either the full amount (Regular) or a partial amount (Partial). This distinction is critical for bonus deduction calculations and withdrawal reversal processing.

### How It Works
The `SubCreditTypeID` column (named `ID` in this table) is stored in the `History.ActiveCredit` family of tables and exposed through the `History.Credit` unified view. When a credit transaction is inserted via `Customer.SetBalanceInsertCredit_Native`, the sub-credit type is passed as a parameter. Procedures like `Billing.WithdrawalService_EstimateBonusDeduction` and `Billing.WithdrawRequestReverse` use this classification to handle partial vs. full financial operations differently.

---

## 2. Business Logic

### Value Map (Complete — 2 rows)

| ID | SubCreditName | Business Meaning |
|----|--------------|------------------|
| 0 | Regular | Full/standard credit transaction — the complete amount was applied |
| 1 | Partial | Partial credit transaction — only a portion of the expected amount was applied |

### Zero-Based Convention
Uses `0` as the default/regular value (not `1`), which is consistent with how nullable int columns default — a NULL or 0 means "regular".

---

## 3. Data Overview

| ID | SubCreditName | Scenario |
|----|--------------|----------|
| 0 | Regular | User deposits $1000 and full amount is credited to their account |
| 1 | Partial | During withdrawal reversal, only a portion of the bonus deduction is reversed |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | — | HIGH | Primary key identifying the sub-credit type. `0`=Regular, `1`=Partial. Referenced by `SubCreditTypeID` columns across History.ActiveCredit tables and related views. |
| 2 | SubCreditName | varchar(40) | NO | — | HIGH | Human-readable label for the sub-credit classification. |

---

## 5. Relationships

### Referenced By (Implicit — no declared FK)

| Consumer Table | Column | Relationship | Evidence |
|----------------|--------|-------------|----------|
| History.ActiveCredit (partitioned) | SubCreditTypeID | Implicit FK → ID | Column in credit ledger tables |
| History.ActiveCreditOld | SubCreditTypeID | Implicit FK → ID | Legacy credit archive |
| History.ActiveCreditRecentMemoryBucket | SubCreditTypeID | Implicit FK → ID | Memory-optimized recent credits |
| History.ActiveCredit_BIGINT | SubCreditTypeID | Implicit FK → ID | BigInt credit archive |

### View Consumers

| View | Purpose |
|------|---------|
| History.Credit | Unified credit view across all yearly partitions (NULLs SubCreditTypeID for pre-2014 data) |
| History.ActiveCreditBucket_VW | Union of ActiveCredit + RecentMemoryBucket |
| History.ActiveCreditView | Credit view with SubCreditTypeID column |

### Procedure Consumers

| Procedure | Operation | Context |
|-----------|-----------|---------|
| Customer.SetBalanceInsertCredit_Native | INSERT (passes @SubCreditTypeID) | Writes credit entries with sub-type classification |
| Customer.SetBalanceClosePosition | INSERT | Position close credit with sub-type |
| Customer.SetBalanceChangeCredit | UPDATE | Credit modification with sub-type |
| Trade.InsertActiveCredit | INSERT | Active credit entry creation |
| Trade.InsertActiveCreditPartition | INSERT | Partitioned credit insertion |
| Trade.PositionClose | INSERT | Position close ledger entry |
| Billing.WithdrawalService_EstimateBonusDeduction | SELECT | Reads sub-type for bonus deduction logic |
| Billing.WithdrawRequestReverse | SELECT | Reads sub-type during reversal processing |
| Billing.WithdrawRequestToReverse | SELECT | Identifies reversible entries by sub-type |
| Billing.GetDepositsCustomerCardPCIVersion | SELECT | Reads credit history with sub-type |
| BackOffice.GetCustomerByCID | SELECT | Customer overview includes credit sub-types |
| History.HistoryGetUnifiedbyCID (Function) | SELECT | Unified history retrieval |

---

## 6. Dependencies

### Depends On
None — leaf dictionary table with no foreign keys.

### Depended On By
- `History.ActiveCredit` family — stores SubCreditTypeID on every credit ledger entry
- 12+ procedures for credit/withdrawal/billing operations
- `History.Credit` unified view (NULLs this field for pre-2014 legacy data)

---

## 7. Technical Details

| Index Name | Type | Key Columns | Notes |
|-----------|------|-------------|-------|
| PK_DictionarySubCreditTypeID | CLUSTERED PK | ID ASC | FILLFACTOR 95 |

---

## 8. Sample Queries

```sql
-- Get all sub-credit types
SELECT  ID AS SubCreditTypeID,
        SubCreditName
FROM    Dictionary.SubCreditTypeID WITH (NOLOCK)
ORDER BY ID;

-- Count credit entries by sub-type
SELECT  sct.SubCreditName,
        COUNT(*) AS CreditCount
FROM    History.ActiveCredit ac WITH (NOLOCK)
JOIN    Dictionary.SubCreditTypeID sct WITH (NOLOCK)
        ON ac.SubCreditTypeID = sct.ID
GROUP BY sct.SubCreditName;

-- Find partial credits for a customer
SELECT  ac.CreditID,
        ac.Credit,
        ac.Occurred,
        sct.SubCreditName
FROM    History.ActiveCredit ac WITH (NOLOCK)
JOIN    Dictionary.SubCreditTypeID sct WITH (NOLOCK)
        ON ac.SubCreditTypeID = sct.ID
WHERE   ac.CID = @CID
AND     sct.SubCreditName = 'Partial';
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira references found for `SubCreditTypeID`.

---

*Generated: 2026-03-14 | Quality: 9.2/10*
*Object: Dictionary.SubCreditTypeID | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.SubCreditTypeID.sql*
