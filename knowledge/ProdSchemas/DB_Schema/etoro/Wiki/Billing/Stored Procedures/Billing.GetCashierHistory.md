# Billing.GetCashierHistory

> Returns a customer's deposit and cashout credit history (CreditTypeID 1=Deposit, 2=Cashout) by merging the persistent History.Credit and in-memory History.ActiveCreditRecentMemoryBucket tables, with credit type labels joined from Dictionary.CreditType.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (Customer ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetCashierHistory` provides a customer's cashier transaction history — specifically deposit and cashout credit records — for display in the payment history section of the eToro platform. It targets `CreditTypeID IN (1, 2)`: type 1 is "Deposit" and type 2 is "Cashout" (from Dictionary.CreditType). The result includes the credit type name via a JOIN to Dictionary.CreditType, making the output immediately human-readable.

Like `Billing.GetBonusesByCID`, this procedure follows the dual-source pattern: it reads from both the persistent `History.Credit` table and the memory-optimized `History.ActiveCreditRecentMemoryBucket` to ensure recent records are included alongside historical ones. Results are ordered by `Occurred DESC` (most recent first).

The commented-out code `--OR CreditTypeID BETWEEN 5 AND 12` indicates the procedure was originally considered for a broader credit type range (covering Champ Winner, Compensation, Bonus, Reverse Cashout, Cashout Request, IB Sync, Chargeback, and Refund types). That range was narrowed to just deposits and cashouts (1, 2) in the delivered version.

Created in May 2021 by Shay Oren as MIMOPS-4603. The procedure is granted to the `PROD_BIadmins` role (found via SQL_SecurePay pattern in permissions).

---

## 2. Business Logic

### 2.1 Dual-Source History with Table Variable

**What**: Uses a `@LocalCredit` table variable (not a temp table) to buffer results from two sources before joining to the type lookup.

**Columns/Parameters Involved**: `History.Credit`, `History.ActiveCreditRecentMemoryBucket`

**Rules**:
- First INSERT: History.Credit WHERE CreditTypeID IN (1,2) for the customer — persistent history
- Second INSERT: History.ActiveCreditRecentMemoryBucket WHERE CreditTypeID IN (1,2) — recent in-memory records
- Unlike `GetBonusesByCID`, no `DISTINCT` is applied — potential duplicates if same record exists in both tables
- Final SELECT joins @LocalCredit to Dictionary.CreditType to add the human-readable credit type name
- `ORDER BY Occurred DESC` — most recent transactions first

### 2.2 CreditTypeID Scope: Deposits and Cashouts Only

**What**: Restricts to the two primary customer-facing money movement types.

**Columns/Parameters Involved**: `CreditTypeID`

**Rules**:
- CreditTypeID=1: Deposit - money received from the customer
- CreditTypeID=2: Cashout - money sent back to the customer
- Excluded types: Open/Close Position (3/4), Champ Winner (5), Compensation (6), Bonus (7), Reverse Cashout (8), Cashout Request (9), IB Sync (10), Chargeback (11), Refund (12)
- The commented-out `--OR CreditTypeID BETWEEN 5 AND 12` shows the originally intended broader scope was narrowed to keep the cashier history focused on core financial flows

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Customer ID to retrieve cashier history for. Filters both History.Credit and History.ActiveCreditRecentMemoryBucket. |

**Return Columns (from @LocalCredit JOIN Dictionary.CreditType):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | NO | - | VERIFIED | Unique identifier of the credit transaction from History.Credit / History.ActiveCreditRecentMemoryBucket. Identifies the specific credit record. |
| 2 | Payment | decimal(16,2) | NO | - | VERIFIED | Monetary value of the credit transaction. Positive = money in (deposit). Negative = money out (cashout). Stored with 2 decimal places. |
| 3 | CreditTypeID | int | NO | - | VERIFIED | Transaction type: 1=Deposit, 2=Cashout. Always one of these two values for this procedure's results. (Dictionary.CreditType) |
| 4 | Occurred | datetime | NO | - | VERIFIED | Timestamp when the credit transaction was recorded. Results ordered DESC by this column (most recent first). |
| 5 | (CreditType columns) | varchar | NO | - | CODE-BACKED | Additional columns from Dictionary.CreditType JOIN (e.g., Name='Deposit' or Name='Cashout'). Provides the human-readable credit type label alongside the numeric CreditTypeID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditTypeID filter | History.Credit | Read (cross-schema) | Reads deposit and cashout records from persistent credit history. |
| CreditTypeID filter | History.ActiveCreditRecentMemoryBucket | Read (cross-schema) | Reads recent deposit and cashout records from the in-memory credit cache. |
| CreditTypeID JOIN | Dictionary.CreditType | Lookup | Resolves CreditTypeID to human-readable name (1='Deposit', 2='Cashout'). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins (role) | EXECUTE permission | Permission | BI admin access to cashier history data. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCashierHistory (procedure)
├── History.Credit (table, cross-schema)
├── History.ActiveCreditRecentMemoryBucket (table, cross-schema)
└── Dictionary.CreditType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table (cross-schema) | Persistent credit transaction store. Filtered by CID and CreditTypeID IN (1,2). |
| History.ActiveCreditRecentMemoryBucket | Table (cross-schema) | Memory-optimized recent credit cache. Same filter as History.Credit. |
| Dictionary.CreditType | Table | JOIN to add CreditType.Name (and other columns) to the result set. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins (role) | Permission | Payment history / cashier view |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get cashier history for a customer
```sql
EXEC Billing.GetCashierHistory @CID = 12345
-- Returns deposit and cashout credit transactions, most recent first, with type labels
```

### 8.2 Direct query for deposits only
```sql
SELECT CreditID, Payment, CreditTypeID, Occurred
FROM History.Credit WITH (NOLOCK)
WHERE CID = 12345
  AND CreditTypeID = 1  -- Deposits only
ORDER BY Occurred DESC
```

### 8.3 Combined deposit/cashout history with net flow
```sql
SELECT CreditTypeID, ct.Name AS CreditTypeName,
       COUNT(*) AS TransactionCount,
       SUM(Payment) AS TotalAmount
FROM History.Credit hc WITH (NOLOCK)
JOIN Dictionary.CreditType ct WITH (NOLOCK) ON ct.CreditTypeID = hc.CreditTypeID
WHERE hc.CID = 12345
  AND hc.CreditTypeID IN (1, 2)
GROUP BY hc.CreditTypeID, ct.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetCashierHistory | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCashierHistory.sql*
