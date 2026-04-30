# BackOffice.SanityCheck

> Data integrity auditor that runs a series of cross-schema consistency checks (credit vs history, deposit vs payment, balance vs aggregations) and dispatches violation alerts via BackOffice.SanitySend when discrepancies are found. Most checks are commented out; 4 remain active.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | IF EXISTS (cross-schema integrity query) -> EXECUTE BackOffice.SanitySend @Description, @XMLData |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.SanityCheck` is the BackOffice data integrity monitoring procedure. It cross-references Customer, Billing, and History schemas to detect inconsistencies that should not exist in a healthy system - for example, a credit entry without a matching approved payment, or a customer's live balance that does not match the sum of their credit history.

When a discrepancy is found, the procedure packages the anomalous records as XML and sends them asynchronously via `BackOffice.SanitySend` (Service Broker). The recipient service handles alerting, logging, or escalation.

**Current status**: Most of the original 8 checks (01-04, partial) are commented out. Only 4 active checks remain (05-08):
- **05**: Credit amount does not match history sum
- **06**: Deposit (credit type 1) without a matching approved payment
- **07**: Approved payment without a matching deposit credit
- **08**: Customer's live credit does not match CustomerAllTimeAggregatedData totals

The commented-out checks (01-04) include Tradonomi/Billing account cross-checks and action-count reconciliation, which were likely superseded by other monitoring mechanisms or retired when the underlying tables changed.

This procedure is designed to be called by a SQL Server Agent job or scheduler on a regular interval (e.g., daily). It is the consumer of the `SanitySend` Service Broker delivery mechanism.

---

## 2. Business Logic

### 2.1 Check 05 - Credit Does Not Match History (ACTIVE)

**What**: Detects customers whose live Credit balance differs from the sum of their History.Credit payments (excluding IB Sync type 10).

**Rules**:
- `FROM History.Credit HCRD, Customer.Customer CCST WHERE HCRD.CID = CCST.CID AND HCRD.CreditTypeID != 10`
- `GROUP BY CCST.CID, CCST.Credit HAVING CCST.Credit != SUM(HCRD.Payment)`
- CreditTypeID=10 (IB Sync) is excluded from the sum because it represents synthetic entries not backed by real payments.
- Violation: any CID where `Customer.Credit != SUM(History.Credit.Payment)` (excluding IB Sync entries).
- Alert XML root: `AccountDifference`, contains CID, Credit (live), SumInHistory.

### 2.2 Check 06 - Deposit Without Payment (ACTIVE)

**What**: Finds History.Credit deposit records (CreditTypeID=1) that have no corresponding approved Billing.Payment.

**Rules**:
- `FROM History.Credit HCRD WHERE NOT EXISTS (SELECT * FROM Billing.Payment BPAY WHERE HCRD.PaymentID = BPAY.PaymentID AND BPAY.PaymentStatusID = 2) AND CreditTypeID = 1`
- PaymentStatusID=2 = Approved/Completed payment.
- Violation: a deposit was credited to a customer account with no approved payment record to back it.
- Alert XML root: `AccountDifference`, contains CID, Credit.

### 2.3 Check 07 - Payment Without Deposit (ACTIVE)

**What**: Finds approved Billing.Payment records that have no corresponding History.Credit deposit.

**Rules**:
- `FROM Billing.Payment BPAY WHERE NOT EXISTS (SELECT * FROM History.Credit HCRD WHERE HCRD.PaymentID = BPAY.PaymentID AND CreditTypeID = 1) AND BPAY.PaymentStatusID = 2`
- Inverse of Check 06: payment processed but no credit applied to the customer balance.
- Alert XML root: `AccountDifference`, contains CID, Amount/100 AS Credit.

### 2.4 Check 08 - Total Aggregation Does Not Match Credit (ACTIVE)

**What**: Validates that the sum of all aggregated balance components in BackOffice.CustomerAllTimeAggregatedData equals the customer's live Credit.

**Rules**:
- Aggregated total = `TotalProfit + TotalDeposit + TotalBonus + TotalCashoutRequest + TotalReverseCashout + TotalCompensation + TotalChampWin`
- Violation: `CCST.Credit != aggregated total`
- Alert XML root: `AccountDifference`, contains CID, Credit (live), TotalCredit (aggregated sum).

### 2.5 Commented-Out Checks (INACTIVE)

| # | Description | Why Commented Out |
|---|-------------|------------------|
| 01 | Tradonomi customer without Billing Account | Billing account schema changed; IB providers (IsIB=1) were an exception |
| 02 | Billing Account without Tradonomi Customer | Legacy cross-schema alignment; now handled elsewhere |
| 03 | Billing credit does not match Tradonomi credit | Credit*100 comparison - currency unit mismatch logic |
| 04 | Action count in Billing History vs Tradonomi History | Complex CreditTypeID/AccountUpdateTypeID mapping became unreliable |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no input parameters. Returns 0 (RETURN 0) on success.

Output: No result set returned to caller. Violations are dispatched asynchronously via Service Broker (SanitySend).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Check 05 | History.Credit | Reader | Sums Payment grouped by CID, excludes CreditTypeID=10 |
| Check 05 | Customer.Customer | Reader | Source of live Credit balance |
| Check 06 | History.Credit | Reader | Finds CreditTypeID=1 deposits without payment |
| Check 06 | Billing.Payment | Reader | Checks for approved payment (PaymentStatusID=2) via NOT EXISTS |
| Check 07 | Billing.Payment | Reader | Finds approved payments without deposit credits |
| Check 07 | History.Credit | Reader | Checks for matching CreditTypeID=1 via NOT EXISTS |
| Check 08 | Customer.Customer | Reader | Source of live Credit balance |
| Check 08 | BackOffice.CustomerAllTimeAggregatedData | Reader | Source of aggregated balance components |
| Alert delivery | BackOffice.SanitySend | Callee | Called for each check that finds violations |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Called from SQL Server Agent scheduled job or BackOffice monitoring scheduler.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.SanityCheck (procedure)
+-- History.Credit (table) [SELECT - checks 05, 06, 07]
+-- Customer.Customer (table) [SELECT - checks 05, 08]
+-- Billing.Payment (table) [SELECT - checks 06, 07]
+-- BackOffice.CustomerAllTimeAggregatedData (table) [SELECT - check 08]
+-- BackOffice.SanitySend (procedure) [EXEC - alert delivery for each violation]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | SELECT - sums payments by CID, finds orphaned deposit records |
| Customer.Customer | Table | SELECT - retrieves live Credit balance for comparison |
| Billing.Payment | Table | SELECT - validates payment existence and status |
| BackOffice.CustomerAllTimeAggregatedData | Table | SELECT - aggregated balance sum components (check 08) |
| BackOffice.SanitySend | Stored Procedure | EXEC - sends Service Broker alert for each detected violation |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CreditTypeID != 10 exclusion | Business Rule | IB Sync entries (type 10) are excluded from the credit-vs-history sum to avoid false positives. |
| PaymentStatusID = 2 filter | Business Rule | Only approved/completed payments are checked for deposit matching. |
| Service Broker dependency | Infrastructure | Violations are delivered via SanitySend which requires Service Broker to be enabled. |
| Commented checks | Design | Checks 01-04 are disabled; removed or replaced functionality should not be re-enabled without investigation. |

---

## 8. Sample Queries

### 8.1 Run all active integrity checks

```sql
EXEC BackOffice.SanityCheck;
-- Returns 0. Violations (if any) sent asynchronously via Service Broker.
```

### 8.2 Run check 05 directly (credit vs history) without sending an alert

```sql
SELECT CCST.CID, CCST.Credit, SUM(HCRD.Payment) AS SumInHistory
FROM History.Credit HCRD WITH (NOLOCK)
JOIN Customer.Customer CCST WITH (NOLOCK) ON HCRD.CID = CCST.CID
WHERE HCRD.CreditTypeID != 10
GROUP BY CCST.CID, CCST.Credit
HAVING CCST.Credit != SUM(HCRD.Payment)
ORDER BY CCST.CID;
```

### 8.3 Run check 08 directly (aggregation vs credit)

```sql
SELECT CCST.CID, CCST.Credit,
    BCAD.TotalProfit + BCAD.TotalDeposit + BCAD.TotalBonus + BCAD.TotalCashoutRequest
    + BCAD.TotalReverseCashout + BCAD.TotalCompensation + BCAD.TotalChampWin AS TotalCredit
FROM Customer.Customer CCST WITH (NOLOCK)
JOIN BackOffice.CustomerAllTimeAggregatedData BCAD WITH (NOLOCK) ON CCST.CID = BCAD.CID
WHERE CCST.Credit != BCAD.TotalProfit + BCAD.TotalDeposit + BCAD.TotalBonus
    + BCAD.TotalCashoutRequest + BCAD.TotalReverseCashout
    + BCAD.TotalCompensation + BCAD.TotalChampWin;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 8/10, Logic: 10/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.SanityCheck | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.SanityCheck.sql*
