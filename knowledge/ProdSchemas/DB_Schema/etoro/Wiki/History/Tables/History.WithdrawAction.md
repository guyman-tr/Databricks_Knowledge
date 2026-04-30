# History.WithdrawAction

> Immutable audit log of every status change in the withdrawal (cashout) lifecycle - each row records one state transition for a withdrawal request, capturing who acted, what status was set, the financial details, and when it occurred.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | WithdrawActionID (INT, IDENTITY, NONCLUSTERED PK) |
| **Partition** | No - stored on [HISTORY] filegroup |
| **Indexes** | 2 active (NONCLUSTERED PK on WithdrawActionID, NC on ModificationDate+CashoutStatusID INCLUDE WithdrawID) |

---

## 1. Business Meaning

History.WithdrawAction is the audit trail for eToro's withdrawal/cashout process. Every time a withdrawal request changes status - from submission through approval, processing, and final settlement or cancellation - a new row is inserted here. This creates an append-only timeline of every action taken on every withdrawal, preserving the full history of who did what and when.

With 6.1 million rows spanning 2014 to present, this is one of the most important compliance and operational tables in the History schema. It is used by operations teams for withdrawal investigations, by finance for reconciliation, and by compliance for regulatory reporting on money movement.

Data flows in from multiple Billing and BackOffice procedures (CashoutRequestUpdate, WithdrawRequestAdd, WithdrawToFundingUpdate, WithdrawRequestApprove, etc.) whenever they modify a Billing.Withdraw record. Newer procedures use Billing.UpsertWithdraw which now handles the History.WithdrawAction insert internally - older procedures insert directly. The commented-out INSERT blocks in newer procedures confirm this architectural migration.

---

## 2. Business Logic

### 2.1 Withdrawal Lifecycle via Status Audit Trail

**What**: Each row represents one status snapshot of a withdrawal - reading all rows for a WithdrawID in order gives the complete withdrawal lifecycle.

**Columns/Parameters Involved**: `WithdrawID`, `CashoutStatusID`, `ModificationDate`, `ManagerID`, `Comment`

**Rules**:
- Multiple rows per WithdrawID are normal - one per status transition
- Status progression (typical path): 1=Pending -> 2=InProcess -> 3=Processed (or 4=Canceled / 7=Rejected)
- CashoutStatusID distribution: Pending (44%), InProcess (31%), Canceled (18%), Processed (5%), Partially Processed (0.5%)
- ManagerID = 0 means automated/system action; ManagerID = NULL means no manager involved; ManagerID > 0 means back-office manager action
- Comment provides human-readable reason: "Initiated by user request", "Automation - Manual Approval", etc.
- The most recent row for a WithdrawID reflects the current state of the withdrawal

**Diagram**:
```
Withdrawal lifecycle (one WithdrawID, multiple rows):

WithdrawActionID=100  CashoutStatusID=1  Pending     ModDate=T+0   ManagerID=NULL
WithdrawActionID=101  CashoutStatusID=2  InProcess   ModDate=T+5m  ManagerID=0 (automated)
WithdrawActionID=102  CashoutStatusID=3  Processed   ModDate=T+1h  ManagerID=0 (automated)

Failed withdrawal:
WithdrawActionID=200  CashoutStatusID=1  Pending     ModDate=T+0
WithdrawActionID=201  CashoutStatusID=4  Canceled    ModDate=T+2m  Comment="Initiated by user request"
```

### 2.2 CashoutStatus Values

**What**: CashoutStatusID defines which stage of the withdrawal process this action record captures.

**Columns/Parameters Involved**: `CashoutStatusID`

**Rules**:
| ID | Name | IsFinal | IsFinishedNoMoney | Business Meaning |
|----|------|---------|------------------|------------------|
| 1 | Pending | - | No | Request submitted, awaiting review/processing |
| 2 | InProcess | - | No | Picked up for processing by billing/payment system |
| 3 | Processed | Yes | No | Money successfully sent to customer |
| 4 | Canceled | Yes | Yes | Canceled (no money sent) |
| 5 | Partially Processed | Yes | No | Part of the withdrawal amount was processed |
| 7 | Rejected | Yes | Yes | Rejected (e.g., compliance, KYC, insufficient funds) |
| 8 | RejectedByProvider | Yes | No | Rejected by the external payment provider |
| 9 | PendingByProvider | - | No | Sent to provider but awaiting their confirmation |
| 10 | SentToProvider | - | No | Submitted to external payment provider |
| 11 | SentToBilling | - | No | Routed to billing system |
| 12 | ReceivedByBilling | - | No | Billing system confirmed receipt |
| 13 | Failed | Yes | No | Technical failure |
| 14 | Pending Review | - | No | Under compliance/manual review |
| 15 | Under Review | - | No | Active compliance review in progress |
| 16 | Reversed | No | No | Withdrawal reversed (funds returned to account) |
| 17 | Partially Reversed | No | No | Partial reversal of a processed withdrawal |

### 2.3 Approved Flag

**What**: Tracks manager approval state at the time each action was recorded.

**Columns/Parameters Involved**: `Approved`, `ManagerID`

**Rules**:
- Approved=true + ManagerID > 0: back-office manager explicitly approved this withdrawal step
- Approved=false + ManagerID=0: automated system action (no approval needed)
- Most records are Approved=false (automation-driven pipeline)
- When Approved=true, Comment often contains "Automation - Manual Approval"

---

## 3. Data Overview

| WithdrawActionID | WithdrawID | CashoutStatusID | ManagerID | Amount | Fee | Comment | Meaning |
|---|---|---|---|---|---|---|---|
| 6174871 | 1740281 | 1 (Pending) | NULL | 35.69 | 0 | NULL | Auto-submitted crypto/stock withdrawal (FundingTypeID=33, ExTransactionID present) - initial pending state, no manager |
| 6174870 | 1740280 | 4 (Canceled) | 0 | 25 | 5 | Initiated by user request | Customer-initiated cancellation of a $25 wire withdrawal (FundingTypeID=2), $5 fee waived on cancel |
| 6174869 | 1740280 | 1 (Pending) | 0 | 25 | 5 | NULL | Same WithdrawID as above - the initial pending state before customer canceled |
| 6174867 | 1740278 | 2 (InProcess) | 0 | 145 | 5 | Automation - Manual Approval | Automated approval of a $145 bank wire withdrawal - Approved=true shows manual override by automation |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawActionID | INT IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-incrementing surrogate PK. IDENTITY NOT FOR REPLICATION. Sequential within each withdrawal's action history. NONCLUSTERED PK on HISTORY filegroup. |
| 2 | WithdrawID | INT | NO | - | CODE-BACKED | The withdrawal request this action belongs to. FK to Billing.Withdraw(WithdrawID). Multiple rows per WithdrawID form the complete lifecycle. Included in the NC index on ModificationDate for efficient joins. |
| 3 | CashoutStatusID | INT | NO | - | CODE-BACKED | The cashout status recorded at this action. FK to Dictionary.CashoutStatus. See Section 2.2 for full value map. Leading indicator of which lifecycle stage this row captures. |
| 4 | ManagerID | INT | YES | NULL | CODE-BACKED | Back-office manager who performed this action. FK to BackOffice.Manager. NULL = no manager involved (fully automated). 0 = automated system action. > 0 = specific manager's action (approve, reject, set commission). |
| 5 | Commission | MONEY | NO | 0 | CODE-BACKED | Commission amount captured at this action step. Defaults to 0. Set by BackOffice.WithdrawRequestSetCommission when a manager assigns a commission to the withdrawal. |
| 6 | Approved | BIT | NO | - | CODE-BACKED | Whether this action represents an approval decision: 1=approved, 0=not approved. Approved=1 with ManagerID=0 indicates automated approval. Used with BackOffice.WithdrawRequestApprove. |
| 7 | ModificationDate | DATETIME | NO | - | CODE-BACKED | UTC timestamp when this action was recorded. Leading column of NC index IDX_HistoryWithdrawAction_ModificationDate - supports time-range queries for reconciliation and reporting. |
| 8 | Comment | NVARCHAR(255) | YES | NULL | CODE-BACKED | Human-readable description of this action. Common values: "Initiated by user request", "Automation - Manual Approval". Set by the calling procedure or manager note. |
| 9 | SessionID | BIGINT | YES | NULL | CODE-BACKED | Customer session identifier at the time of the withdrawal action. NULL for automated/system actions. Provides traceability back to the specific user session. |
| 10 | CashoutReasonID | INT | YES | NULL | CODE-BACKED | Reason category for this cashout action. Default value 16 = "Requested by User" (95.8% of rows). Larger values (12, 18, 19) indicate system-generated or special-case reasons. |
| 11 | ClientPersonalID | VARCHAR(255) | YES | NULL | CODE-BACKED | Customer personal identification document reference captured at withdrawal time (e.g., for KYC compliance). Added in 2019 (ticket 10864). Typically NULL for automated flows. |
| 12 | FundingID | INT | YES | NULL | CODE-BACKED | References the funding method (payment instrument) used for this withdrawal. Links to the customer's stored payment method record. |
| 13 | FundingTypeID | INT | YES | NULL | CODE-BACKED | Type of funding/payment method: 1=bank transfer, 2=credit card, 33=crypto/stock redemption (inferred from data). Determines the payment processing pathway. |
| 14 | Amount | MONEY | YES | NULL | CODE-BACKED | Withdrawal amount in the withdrawal's currency at time of this action. May differ from the original request amount for partial/reversed withdrawals. |
| 15 | CurrencyID | INT | YES | NULL | CODE-BACKED | Currency of the withdrawal amount. 1=USD in dominant records. References Dictionary/currency lookup. |
| 16 | Fee | MONEY | YES | NULL | CODE-BACKED | Withdrawal fee charged at time of this action. 0 = fee-free withdrawal (e.g., automatic stock/crypto redemption). Common value: $5 for bank wire withdrawals. |
| 17 | AccountCurrencyID | INT | YES | NULL | CODE-BACKED | Customer account currency at time of action. 1=USD, 2=other currency (observed in data). Used for currency conversion when account currency differs from withdrawal currency. |
| 18 | ExTransactionID | VARCHAR(500) | YES | NULL | CODE-BACKED | External payment provider transaction reference number. Populated for auto-processed withdrawals (e.g., crypto/stock redemptions via FundingTypeID=33). NULL for manual/bank wire flows pending external processing. |
| 19 | WithdrawTypeID | INT | YES | NULL | CODE-BACKED | Type classification of the withdrawal: 0=unclassified, 1=automatic/direct (e.g., stock redemption). NULL for certain flow types. Application-defined enum. |
| 20 | FlowID | INT | YES | NULL | CODE-BACKED | Processing flow identifier: 0=legacy/unset, 2=automatic stock/crypto redemption flow. NULL for older records or manual processes. Determines which processing pipeline handles the withdrawal. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw | FK (FK_BWDR_HWDA) | The withdrawal request this action belongs to. Core FK linking action history to the withdrawal record. |
| CashoutStatusID | Dictionary.CashoutStatus | FK (FK_DCHS_HWDA) | The status captured at this action - defines the lifecycle stage. |
| ManagerID | BackOffice.Manager | FK (FK_BMNG_HWDA) | Back-office manager who performed this action (when non-NULL and non-zero). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.CashoutRequestUpdate | WithdrawID | Writer (INSERT) | Primary active writer - inserts action rows on every withdrawal status update |
| Billing.WithdrawToFundingUpdate | WithdrawID | Writer (INSERT) | Inserts action rows during withdraw-to-funding processing |
| Billing.WithdrawToFundingReject | WithdrawID | Writer (INSERT) | Inserts action on rejection of funding-linked withdrawal |
| BackOffice.WithdrawRequestApprove | WithdrawID | Writer (INSERT) | Inserts action when manager approves a withdrawal |
| BackOffice.WithdrawRequestSetCommission | WithdrawID | Writer (INSERT) | Inserts action(s) when commission is set/changed |
| dbo.InProcessCashouts_FromDate | WithdrawID | Reader | Queries in-process cashouts for DWH/reconciliation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.WithdrawAction (table)
  (leaf - no code-level DDL dependencies)
  FKs to: Billing.Withdraw, Dictionary.CashoutStatus, BackOffice.Manager
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | FK target for WithdrawID (FK_BWDR_HWDA) |
| Dictionary.CashoutStatus | Table | FK target for CashoutStatusID (FK_DCHS_HWDA) |
| BackOffice.Manager | Table | FK target for ManagerID (FK_BMNG_HWDA) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.CashoutRequestUpdate | Stored Procedure | Primary WRITER |
| Billing.WithdrawToFundingUpdate | Stored Procedure | WRITER |
| Billing.WithdrawToFundingReject | Stored Procedure | WRITER |
| BackOffice.WithdrawRequestApprove | Stored Procedure | WRITER |
| BackOffice.WithdrawRequestSetCommission | Stored Procedure | WRITER |
| dbo.InProcessCashouts_FromDate | Stored Procedure | READER (DWH reconciliation) |
| dbo.InProcessCashouts_FromDate_ForDWH | Stored Procedure | READER |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HWDA | NONCLUSTERED PK | WithdrawActionID ASC | - | - | Active (FILLFACTOR=90) |
| IDX_HistoryWithdrawAction_ModificationDate | NONCLUSTERED | ModificationDate ASC, CashoutStatusID ASC | WithdrawID | - | Active (FILLFACTOR=90, PAGE compression) |

Note: NC PK with FILLFACTOR=90 for insert headroom. The ModificationDate index supports time-range queries filtered by status (e.g., "show me all Pending cashouts in the last 24 hours"). WithdrawID as INCLUDE avoids key lookups for most common query patterns.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_BWDR_HWDA | FOREIGN KEY | WithdrawID -> Billing.Withdraw(WithdrawID) |
| FK_DCHS_HWDA | FOREIGN KEY | CashoutStatusID -> Dictionary.CashoutStatus(CashoutStatusID) |
| FK_BMNG_HWDA | FOREIGN KEY | ManagerID -> BackOffice.Manager(ManagerID) |
| HWDA_COMMISSION | DEFAULT | Commission = 0 |

---

## 8. Sample Queries

### 8.1 Full lifecycle audit for a specific withdrawal
```sql
SELECT
    wa.WithdrawActionID,
    wa.CashoutStatusID,
    cs.Name AS StatusName,
    wa.ManagerID,
    wa.Approved,
    wa.Amount,
    wa.Fee,
    wa.Comment,
    wa.ModificationDate
FROM History.WithdrawAction wa WITH (NOLOCK)
INNER JOIN Dictionary.CashoutStatus cs WITH (NOLOCK)
    ON wa.CashoutStatusID = cs.CashoutStatusID
WHERE wa.WithdrawID = 1740280
ORDER BY wa.ModificationDate;
```

### 8.2 Find withdrawals currently stuck in Pending status
```sql
SELECT TOP 100
    wa.WithdrawID,
    wa.Amount,
    wa.FundingTypeID,
    wa.ModificationDate,
    wa.Comment
FROM History.WithdrawAction wa WITH (NOLOCK)
WHERE wa.CashoutStatusID = 1
    AND wa.ModificationDate >= DATEADD(HOUR, -24, GETUTCDATE())
ORDER BY wa.ModificationDate;
```

### 8.3 Manager activity report - withdrawals approved by managers today
```sql
SELECT
    wa.ManagerID,
    COUNT(*) AS ApprovalsCount,
    SUM(wa.Amount) AS TotalAmount
FROM History.WithdrawAction wa WITH (NOLOCK)
WHERE wa.Approved = 1
    AND wa.ManagerID > 0
    AND wa.ModificationDate >= CAST(GETUTCDATE() AS DATE)
GROUP BY wa.ManagerID
ORDER BY ApprovalsCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 20 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.WithdrawAction | Type: Table | Source: etoro/etoro/History/Tables/History.WithdrawAction.sql*
