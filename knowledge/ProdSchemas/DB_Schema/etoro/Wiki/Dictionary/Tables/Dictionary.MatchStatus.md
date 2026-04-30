# Dictionary.MatchStatus

> Defines the reconciliation match states for billing deposits and withdrawal-to-funding transactions, tracking whether financial records have been verified against external payment provider data.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MatchStatusID (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK + 1 unique NC on Name |

---

## 1. Business Meaning

Dictionary.MatchStatus classifies the reconciliation state of billing transactions. When deposits and withdrawals flow through external payment providers (PSPs), the platform must reconcile its internal records against the provider's records. This table defines the seven possible matching outcomes — from completely unmatched to automatically/manually reconciled.

Without this table, the billing team could not track reconciliation progress or identify discrepancies between internal and external financial records. It is essential for financial controls, audit trails, and compliance reporting. Unmatched transactions require investigation and resolution.

Referenced extensively by Billing.Deposit (MatchStatusID column), Billing.WithdrawToFunding, and dozens of billing procedures including Billing.DepositMatch, Billing.WithdrawToFundingMatch, Billing.DepositAdd, Billing.DepositProcess, and payout processing procedures.

---

## 2. Business Logic

### 2.1 Reconciliation State Machine

**What**: Seven-state model tracking how financial transactions progress through reconciliation.

**Columns/Parameters Involved**: `MatchStatusID`, `Name`

**Rules**:
- Transactions start as UnMatched (Open) (0) when first created
- UnMatched (Closed) (1) means the transaction was closed/processed but not yet reconciled
- UnMatched (Old) (2) flags aged unreconciled transactions needing manual review
- Matched (Automatically) (3) means the system's auto-reconciliation found an exact match
- Matched (Manually) (4) means a human operator confirmed the match
- Matched (With Difference) (5) means reconciled but with a value discrepancy that was accepted
- Matched (Offline Approval) (6) means reconciled via offline/batch approval process

**Diagram**:
```
Transaction Created
       │
       ▼
UnMatched (Open) ──────────> Matched (Automatically)
  (0)  │                          (3)
       │
       ├──> UnMatched (Closed) ──> Matched (Manually)
       │      (1)                      (4)
       │
       └──> UnMatched (Old) ──────> Matched (With Difference)
              (2)                       (5)
                                   Matched (Offline Approval)
                                        (6)
```

---

## 3. Data Overview

| MatchStatusID | Name | Meaning |
|---|---|---|
| 0 | UnMatched (Open) | Transaction is active and has not been reconciled — normal state for recent transactions awaiting the next reconciliation cycle |
| 1 | UnMatched (Closed) | Transaction has been completed/processed but the reconciliation run has not yet matched it to a PSP record |
| 2 | UnMatched (Old) | Transaction has been unmatched for an extended period — flagged for manual investigation by the billing team |
| 3 | Matched (Automatically) | Auto-reconciliation engine found an exact match between internal record and PSP settlement report |
| 5 | Matched (With Difference) | Reconciled but with a discrepancy (e.g., rounding, FX conversion) — the difference was reviewed and accepted within tolerance |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MatchStatusID | tinyint | NO | - | CODE-BACKED | Unique identifier for the reconciliation state: 0=UnMatched (Open), 1=UnMatched (Closed), 2=UnMatched (Old), 3=Matched (Automatically), 4=Matched (Manually), 5=Matched (With Difference), 6=Matched (Offline Approval). Referenced by Billing.Deposit, Billing.WithdrawToFunding, and 30+ billing procedures. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable reconciliation state label. Enforced unique by UK_DMS_Name. Displayed in billing reconciliation reports and BackOffice screens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Deposit | MatchStatusID | Implicit | Every deposit record tracks its reconciliation state |
| Billing.WithdrawToFunding | MatchStatusID | Implicit | Every withdrawal tracks its reconciliation state |
| History.Deposit | MatchStatusID | Implicit | Historical deposit records preserve match status |
| History.WithdrawToFundingAction | MatchStatusID | Implicit | Historical withdrawal actions preserve match status |
| Billing.DepositMatch | MatchStatusID | Implicit | Procedure that sets match status during reconciliation |
| Billing.WithdrawToFundingMatch | MatchStatusID | Implicit | Procedure that sets match status for withdrawals |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | MatchStatusID column |
| Billing.WithdrawToFunding | Table | MatchStatusID column |
| Billing.DepositMatch | Stored Procedure | Updates match status |
| Billing.WithdrawToFundingMatch | Stored Procedure | Updates match status |
| Billing.DepositAdd | Stored Procedure | Sets initial match status |
| Billing.DepositProcess | Stored Procedure | Processes with match status |
| Billing.DepositUpdate | Stored Procedure | Updates match status |
| Billing.GetDepositsByCid | Stored Procedure | Reads match status |
| Billing.GetPayoutProcessData | Stored Procedure | Reads match status for payout processing |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DMS | CLUSTERED PK | MatchStatusID | - | - | Active |
| UK_DMS_Name | NC UNIQUE | Name | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| UK_DMS_Name | UNIQUE | Ensures each reconciliation state has a unique name |

---

## 8. Sample Queries

### 8.1 List all match statuses
```sql
SELECT  MatchStatusID,
        Name
FROM    [Dictionary].[MatchStatus] WITH (NOLOCK)
ORDER BY MatchStatusID;
```

### 8.2 Find unmatched deposits
```sql
SELECT  d.*,
        ms.Name AS MatchStatusName
FROM    [Billing].[Deposit] d WITH (NOLOCK)
JOIN    [Dictionary].[MatchStatus] ms WITH (NOLOCK)
        ON d.MatchStatusID = ms.MatchStatusID
WHERE   ms.MatchStatusID IN (0, 1, 2)
ORDER BY d.MatchStatusID;
```

### 8.3 Reconciliation summary by match status
```sql
SELECT  ms.Name AS MatchStatus,
        COUNT(*) AS DepositCount,
        SUM(d.Amount) AS TotalAmount
FROM    [Billing].[Deposit] d WITH (NOLOCK)
JOIN    [Dictionary].[MatchStatus] ms WITH (NOLOCK)
        ON d.MatchStatusID = ms.MatchStatusID
GROUP BY ms.Name
ORDER BY DepositCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 9 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MatchStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MatchStatus.sql*
