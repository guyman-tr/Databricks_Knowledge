# Wallet.ManualApproveTransaction

> Staging table for transactions flagged for manual approval by the operations team, holding the correlation ID and full request payload pending human review before processing proceeds.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

This table acts as a manual approval queue for wallet transactions that cannot be automatically processed and require human sign-off before execution. When the wallet system determines that a transaction needs operations team review - due to risk flags, unusual activity, compliance escalation, or exception handling - the transaction's correlation ID and its full data payload are inserted here, pausing the processing pipeline until an operator acts.

The table is currently empty (0 rows), indicating either that no transactions are currently pending approval or that the manual approval workflow is invoked infrequently and transactions move through quickly. The simple three-column design reflects this table's role as a transient staging area rather than a permanent record store: rows are expected to be inserted, reviewed, approved or rejected, and then deleted (or marked) as part of the workflow.

The `Data` column (nvarchar 3000) carries the full serialised transaction payload - sufficient context for an operations user to evaluate and approve the transaction without needing to join to other tables. This self-contained design allows the approval interface to display all relevant information from a single row.

---

## 2. Business Logic

### 2.1 Manual Approval Workflow

**What**: Transactions flagged for human review are staged here until an operator approves or rejects them.

**Columns/Parameters Involved**: `CorrelationId`, `Data`

**Rules**:
- A row is inserted when the system decides a transaction requires manual intervention
- The `CorrelationId` uniquely identifies the originating transaction across all wallet tables
- `Data` contains the full serialised transaction context (JSON or structured text, max 3000 characters) that the approver needs to make a decision
- After an operator approves, the transaction is released back into the processing pipeline using the CorrelationId
- After an operator rejects, the transaction is cancelled and the row is removed from this table
- No formal status column exists - the presence of a row implies "pending approval"; absence implies "resolved"

---

## 3. Data Overview

| Id | CorrelationId | Data | Meaning |
|---|---|---|---|
| (empty) | - | - | Table currently has 0 rows - no transactions pending manual approval at this time |

*Note: Table is empty. Sample rows are illustrative of the expected structure.*

| Id | CorrelationId | Data | Meaning (illustrative) |
|---|---|---|---|
| 1 | A1B2C3D4-... | {"gcid":12345,"cryptoId":1,"amount":"1.5",...} | BTC send flagged for manual review - high-value transaction requiring ops sign-off |
| 2 | E5F6G7H8-... | {"gcid":67890,"cryptoId":3,"amount":"10.0",...} | ETH withdrawal pending approval - unusual destination address detected |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Provides a stable identifier for the pending approval record, used by the approval UI or stored procedures to reference specific rows. |
| 2 | CorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Request correlation ID of the transaction awaiting approval. Links to Wallet.Requests and to the originating service request chain. The operations team uses this to look up full transaction context across systems. |
| 3 | Data | nvarchar(3000) | YES | - | CODE-BACKED | Serialised representation of the transaction payload (JSON or structured string format, max 3000 characters). Provides the approving operator with all information needed to make a decision without joining to other tables. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CorrelationId | Wallet.Requests | Implicit (via CorrelationId) | Links to the transaction request awaiting approval |

### 5.2 Referenced By (other objects point to this)

This object has no known referencing objects.

---

## 6. Dependencies

### 6.0 Dependency Chain

Wallet.Requests → (implicit via CorrelationId) → Wallet.ManualApproveTransaction

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table (implicit) | CorrelationId references the originating request |

### 6.2 Objects That Depend On This

No known dependents.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ManualApproveTransaction | CLUSTERED PK | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (none beyond PK) | - | No FK constraints, no unique constraints, no default values defined. |

---

## 8. Sample Queries

### 8.1 List all transactions currently pending manual approval
```sql
SELECT Id, CorrelationId, Data
FROM Wallet.ManualApproveTransaction WITH (NOLOCK)
ORDER BY Id ASC
```

### 8.2 Look up a specific pending approval by correlation ID
```sql
SELECT Id, CorrelationId, Data
FROM Wallet.ManualApproveTransaction WITH (NOLOCK)
WHERE CorrelationId = 'A1B2C3D4-0000-0000-0000-000000000000'
```

### 8.3 Count of pending approvals (should be 0 in normal operation)
```sql
SELECT COUNT(*) AS PendingApprovals
FROM Wallet.ManualApproveTransaction WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 6.5/10 (Elements: 7/10, Logic: 6/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.ManualApproveTransaction | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.ManualApproveTransaction.sql*
