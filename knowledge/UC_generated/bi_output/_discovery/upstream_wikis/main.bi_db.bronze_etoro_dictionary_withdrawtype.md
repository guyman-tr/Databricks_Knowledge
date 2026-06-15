# Dictionary.WithdrawType

> Lookup table defining the three classifications of withdrawal requests — Default (standard cashout), Transfer (internal account transfer), or ApprovedForClosure (final withdrawal during account closure) — controlling how the withdrawal is processed and routed.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | WithdrawTypeID (INT, manually assigned) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 clustered (PK on WithdrawTypeID) |

---

## 1. Business Meaning

Dictionary.WithdrawType classifies withdrawal requests into three categories based on their purpose and processing path. A standard customer-initiated cashout follows the normal approval and processing workflow. An internal transfer moves funds between accounts within eToro (e.g., from trading to crypto wallet). A closure withdrawal is processed as part of the account closure workflow, bypassing certain approval steps.

Without this table, the system could not distinguish between routine withdrawals, internal transfers, and closure-related fund disbursements. Each type has different processing rules — closure withdrawals may bypass normal approval thresholds, internal transfers skip external payment processing entirely, and standard withdrawals go through full compliance and approval checks.

The table is referenced by Billing.Withdraw (the core withdrawal table) and consumed by 15+ procedures across BackOffice and Billing: withdrawal request creation (Billing.WithdrawalService_WithdrawRequestAdd), cashout queue management (BackOffice.GetCashOutRequests, GetCashOutRequests_Main), withdrawal processing (Billing.WithdrawToFundingProcess, UpsertWithdraw), reporting (BackOffice.GetProcessedWithdrawPCIVersion, GetWithdrawProcessEmailParams, GetWithdrawalsByCID), and rollback handling (Billing.AddCashoutRollback).

---

## 2. Business Logic

### 2.1 Withdrawal Classification and Processing Paths

**What**: Three distinct withdrawal types determine how funds leave (or move within) the platform.

**Columns/Parameters Involved**: `WithdrawTypeID`, `WithdrawType`, `Description`

**Rules**:
- ID 0 (Default) — standard customer-initiated withdrawal. Goes through full compliance checks, approval workflow (potentially multi-group), and external payment processing to the customer's registered payment method
- ID 1 (Transfer) — internal money movement between eToro accounts. No external payment processing needed; funds move instantly within the platform. Description: "Internal Transfer"
- ID 2 (ApprovedForClosure) — withdrawal processed as part of account closure. May bypass certain approval thresholds since the account is being closed by compliance/operations. Description: "Approved for closure"
- The type is set at withdrawal creation time (Billing.WithdrawalService_WithdrawRequestAdd) and remains fixed throughout the lifecycle
- Reporting procedures filter by type to separate genuine cashouts from internal transfers and closure-related disbursements

**Diagram**:
```
Withdrawal Processing Paths:
  ┌─────────────────┐     Full compliance     ┌─────────────────┐
  │ 0 = Default     │ ──► + approval checks ──► External payment │
  │ (Standard)      │     + payment routing    │ (card/wire/PP)  │
  └─────────────────┘                          └─────────────────┘

  ┌─────────────────┐     No external payment  ┌─────────────────┐
  │ 1 = Transfer    │ ──► Instant internal  ──► │ Internal ledger │
  │ (Internal)      │     account movement     │ credit/debit    │
  └─────────────────┘                          └─────────────────┘

  ┌─────────────────┐     Reduced approvals    ┌─────────────────┐
  │ 2 = Closure     │ ──► Account closure   ──► External payment │
  │ (ApprovedFor    │     workflow              │ (final payout)  │
  │  Closure)       │                          └─────────────────┘
  └─────────────────┘
```

---

## 3. Data Overview

| WithdrawTypeID | WithdrawType | Description | Meaning |
|---|---|---|---|
| 0 | Default | (empty) | Standard customer-initiated withdrawal — the most common type. Subject to full compliance verification, multi-group approval workflow, and external payment routing. Covers all regular cashout requests from the platform. |
| 1 | Transfer | Internal Transfer | Internal fund movement between eToro accounts — no external payment processing. Used when moving money between a customer's trading account and crypto wallet, or between sub-accounts. Instant settlement. |
| 2 | ApprovedForClosure | Approved for closure | Final withdrawal during account closure — operations/compliance has approved the account for closure and this withdrawal disburses the remaining balance. May bypass standard approval thresholds since the closure decision already includes compliance sign-off. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawTypeID | int | NO | - | CODE-BACKED | Unique identifier for the withdrawal classification: 0=Default (standard cashout), 1=Transfer (internal), 2=ApprovedForClosure (closure disbursement). Stored on Billing.Withdraw and checked by 15+ procedures to determine processing path, approval requirements, and reporting categorization. |
| 2 | WithdrawType | varchar(20) | NO | - | CODE-BACKED | Short code name for the type: "Default", "Transfer", "ApprovedForClosure". Used as a programmatic identifier in application code and API responses. |
| 3 | Description | varchar(50) | YES | - | CODE-BACKED | Human-readable description of the type. Empty for Default (0), "Internal Transfer" for Transfer (1), "Approved for closure" for ApprovedForClosure (2). Used in BackOffice UI and reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Withdraw | WithdrawTypeID | Implicit | Each withdrawal record carries a type classification |
| History.WithdrawAction | WithdrawTypeID | Implicit | Historical archive of withdrawal action records |
| Billing.WithdrawalService_WithdrawRequestAdd | @WithdrawTypeID | Reader | Sets the type during withdrawal request creation |
| BackOffice.GetCashOutRequests | WithdrawTypeID | Reader | Filters cashout queue by type |
| BackOffice.GetCashOutRequests_Main | WithdrawTypeID | Reader | Main cashout queue procedure |
| Billing.WithdrawToFundingProcess | WithdrawTypeID | Reader | Routes processing by type |
| Billing.UpsertWithdraw | WithdrawTypeID | Reader | Stores type during withdrawal updates |
| BackOffice.GetProcessedWithdrawPCIVersion | WithdrawTypeID | Reader | Includes type in processed withdrawal reports |
| BackOffice.GetWithdrawalsByCID | WithdrawTypeID | Reader | Customer withdrawal history with type |
| Billing.GetRejectedWithdrawsByRejectDate | WithdrawTypeID | Reader | Rejection reports by type |
| Billing.AddCashoutRollback | WithdrawTypeID | Reader | Rollback handling by type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.WithdrawType (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Stores WithdrawTypeID per withdrawal |
| Billing.WithdrawalService_WithdrawRequestAdd | Stored Procedure | Sets type at creation |
| BackOffice.GetCashOutRequests | Stored Procedure | Filters by type |
| Billing.WithdrawToFundingProcess | Stored Procedure | Routes by type |
| Billing.UpsertWithdraw | Stored Procedure | Stores type |
| BackOffice.GetProcessedWithdrawPCIVersion | Stored Procedure | Reports by type |
| Billing.AddCashoutRollback | Stored Procedure | Handles rollbacks by type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WithdrawTypeID | CLUSTERED | WithdrawTypeID ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all withdrawal types
```sql
SELECT  WithdrawTypeID,
        WithdrawType AS TypeCode,
        Description
FROM    [Dictionary].[WithdrawType] WITH (NOLOCK)
ORDER BY WithdrawTypeID;
```

### 8.2 Count withdrawals by type
```sql
SELECT  wt.WithdrawType AS TypeCode,
        wt.Description,
        COUNT(*) AS WithdrawalCount
FROM    [Billing].[Withdraw] w WITH (NOLOCK)
JOIN    [Dictionary].[WithdrawType] wt WITH (NOLOCK)
        ON wt.WithdrawTypeID = w.WithdrawTypeID
GROUP BY wt.WithdrawType, wt.Description
ORDER BY WithdrawalCount DESC;
```

### 8.3 Find closure-related withdrawals
```sql
SELECT  w.WithdrawID,
        w.CustomerID,
        w.Amount,
        wt.Description
FROM    [Billing].[Withdraw] w WITH (NOLOCK)
JOIN    [Dictionary].[WithdrawType] wt WITH (NOLOCK)
        ON wt.WithdrawTypeID = w.WithdrawTypeID
WHERE   w.WithdrawTypeID = 2 -- ApprovedForClosure
ORDER BY w.WithdrawID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 15 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.WithdrawType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.WithdrawType.sql*
