# Dictionary.CashoutStatus

> Lookup table defining the 17-state lifecycle of withdrawal (cashout) requests, tracking from submission through processing to completion or rejection.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CashoutStatusID (INT, NONCLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 2 active (PK nonclustered + unique on Name) |

---

## 1. Business Meaning

Dictionary.CashoutStatus tracks the lifecycle of every withdrawal request on the eToro platform. From the moment a user requests a cashout through compliance review, billing processing, provider settlement, and potential reversal — each step has a distinct status.

This table is critical to financial operations and compliance. Withdrawal processing involves multiple systems (billing, payment providers, compliance review) and each transition must be auditable. The IsFinalStatus flag distinguishes terminal states from intermediate ones, preventing reprocessing of completed requests. The IsFinishedWithoutMoneyTransfer flag identifies rejections where no funds moved, which is important for reconciliation.

CashoutStatusID is stored in withdrawal request records and updated as the request progresses through the pipeline. It is read by BackOffice cashout procedures, Billing payout processors, and compliance review workflows.

---

## 2. Business Logic

### 2.1 Cashout Lifecycle State Machine

**What**: Withdrawal requests flow through defined states with clear terminal conditions.

**Columns/Parameters Involved**: `CashoutStatusID`, `IsFinishedWithoutMoneyTransfer`, `IsFinalStatus`

**Rules**:
- **Initial states**: Pending (1), Pending Review (14), Under Review (15)
- **Processing states**: InProcess (2), SentToBilling (11), ReceivedByBilling (12), SentToProvider (10), PendingByProvider (9)
- **Success terminal**: Processed (3), Payment Sent (6), Partially Processed (5)
- **Failure terminal**: Canceled (4), Rejected (7), RejectedByProvider (8), Failed (13)
- **Reversal states**: Reversed (16), Partially Reversed (17) — money returned after initial processing
- IsFinishedWithoutMoneyTransfer=1: Canceled (4), Rejected (7) — no funds left the system

**Diagram**:
```
[1: Pending] ──► [14: Pending Review] ──► [15: Under Review]
     │                                          │
     ▼                                          ▼
[2: InProcess] ──► [11: SentToBilling] ──► [12: ReceivedByBilling]
                                                │
                                                ▼
                                         [10: SentToProvider]
                                                │
                              ┌─────────────────┼────────────────┐
                              ▼                 ▼                ▼
                    [9: PendingByProvider] [3: Processed✓]  [8: RejectedByProvider✓]
                              │           [6: PaymentSent]
                              ▼
                        [3: Processed✓]

Terminal (✓): 3, 4, 5, 7, 8, 13
Reversal: 16 (full), 17 (partial)
```

---

## 3. Data Overview

| CashoutStatusID | Name | IsFinalStatus | Meaning |
|---|---|---|---|
| 1 | Pending | NULL | Withdrawal submitted by user, waiting to enter the processing pipeline. First touchpoint — compliance rules may route to review before processing. |
| 3 | Processed | 1 | Successfully completed — funds have been sent to the payment provider and confirmed. Terminal state. The money has left eToro's accounts. |
| 7 | Rejected | 1 | Denied by compliance or business rules before any money moved. Common reasons: insufficient equity, compliance block, AML flag. User is notified with reason. |
| 15 | Under Review | NULL | Actively being examined by the compliance team for AML/fraud concerns. May take days. User sees "under review" in their withdrawal history. |
| 16 | Reversed | 0 | Previously processed withdrawal was returned — the provider reversed the payment. Funds go back to the user's eToro balance. Often due to incorrect bank details. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CashoutStatusID | int | NO | - | VERIFIED | Primary key identifying the withdrawal lifecycle state. 1=Pending, 2=InProcess, 3=Processed, 4=Canceled, 5=Partially Processed, 6=Payment Sent, 7=Rejected, 8=RejectedByProvider, 9=PendingByProvider, 10=SentToProvider, 11=SentToBilling, 12=ReceivedByBilling, 13=Failed, 14=Pending Review, 15=Under Review, 16=Reversed, 17=Partially Reversed. See [Cashout Status](_glossary.md#cashout-status). (Dictionary.CashoutStatus) |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable status label. UNIQUE constraint. Used in back-office withdrawal management UI and user-facing withdrawal history. |
| 3 | IsFinishedWithoutMoneyTransfer | tinyint | NO | (0) | CODE-BACKED | Whether this status represents a termination where NO funds left the system. 1 for Canceled (4) and Rejected (7) — important for reconciliation because the withdrawal entry exists but no actual payment was made. 0 for all other statuses. |
| 4 | IsFinalStatus | tinyint | YES | (0) | CODE-BACKED | Whether this is a terminal state (no further transitions expected). 1 for Processed, Canceled, Partially Processed, Rejected, RejectedByProvider, Failed. NULL for intermediate states. Used by monitoring to identify stuck withdrawals (intermediate status for too long = alert). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing cashout tables | CashoutStatusID | Implicit Lookup | Tracks withdrawal status |
| BackOffice.GetCashOutRequests_Main | CashoutStatusID | Read | Back-office withdrawal management |
| Billing payout procedures | CashoutStatusID | Read/Write | Status transitions during processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing cashout tables | Table | Stores CashoutStatusID per withdrawal |
| BackOffice cashout procedures | Stored Procedure | Manage and report on withdrawals |
| Billing payout processors | Stored Procedure | Transition withdrawal status |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCSS | NC PK | CashoutStatusID ASC | - | - | Active |
| DCSS_NAME | NC UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DCSS | PRIMARY KEY (NC) | Unique cashout status identifier — nonclustered |
| DCSS_NAME | UNIQUE | No duplicate status names |
| DF_DictionaryCashoutStatusIsFinshedWithoutMoneyTransfer | DEFAULT | IsFinishedWithoutMoneyTransfer defaults to 0 |
| DF_DictionaryCashoutStatus_IsFinalStatus | DEFAULT | IsFinalStatus defaults to 0 |

---

## 8. Sample Queries

### 8.1 List all statuses with terminal/money flags
```sql
SELECT CashoutStatusID, Name, IsFinishedWithoutMoneyTransfer, IsFinalStatus
FROM [Dictionary].[CashoutStatus] WITH (NOLOCK) ORDER BY CashoutStatusID;
```

### 8.2 Find pending withdrawals under review
```sql
SELECT c.*, cs.Name AS StatusName
FROM [Billing].[Cashout] c WITH (NOLOCK)
JOIN [Dictionary].[CashoutStatus] cs WITH (NOLOCK) ON c.CashoutStatusID = cs.CashoutStatusID
WHERE c.CashoutStatusID IN (14, 15) ORDER BY c.RequestDate;
```

### 8.3 Count withdrawals by final status
```sql
SELECT cs.Name, COUNT(*) AS WithdrawalCount
FROM [Billing].[Cashout] c WITH (NOLOCK)
JOIN [Dictionary].[CashoutStatus] cs WITH (NOLOCK) ON c.CashoutStatusID = cs.CashoutStatusID
WHERE cs.IsFinalStatus = 1 GROUP BY cs.Name ORDER BY WithdrawalCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.CashoutStatus.

---

*Generated: 2026-03-13 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CashoutStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CashoutStatus.sql*
