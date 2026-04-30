# History.DepositStep

> Synonym providing local-schema access to DB_Logs.History.DepositStep - the step-level execution log table for the deposit processing workflow in the DB_Logs database.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | Alias: DB_Logs.History.DepositStep |
| **Partition** | N/A (resolves to target in DB_Logs) |
| **Indexes** | N/A (resolves to target in DB_Logs) |

---

## 1. Business Meaning

`History.DepositStep` is a cross-database synonym that makes `DB_Logs.History.DepositStep` accessible within the etoro database's History schema without requiring a fully-qualified three-part name. The target object is a table in the `DB_Logs` database that tracks individual step outcomes in the deposit processing workflow.

From the usage in `History.AddDepositStepLog`, the underlying table stores step-by-step execution logs for deposit transaction processing: each row represents one step in the deposit pipeline (e.g., a specific payment gateway interaction, validation, or notification). Columns observed in procedure INSERT/SELECT usage include: StepID (IDENTITY, output), DepositID, InitiateRequest, Step (step name), StepStatus (Pass/Fail text), StepRetries, Error, Created, Comment, CorrelationID.

This synonym pattern (in etoro DB pointing to DB_Logs) separates high-volume operational logs from the main database to reduce I/O and storage pressure on the primary etoro DB. The DB_Logs database is dedicated to log storage.

---

## 2. Business Logic

### 2.1 Cross-Database Synonym for Log Storage Separation

**What**: Redirects all queries against History.DepositStep to DB_Logs.History.DepositStep transparently.

**Columns/Parameters Involved**: N/A (synonym is a pure alias)

**Rules**:
- All INSERT, SELECT, UPDATE, DELETE on History.DepositStep execute against DB_Logs.History.DepositStep
- The etoro DB MCP user does not have access to DB_Logs (access requires appropriate cross-DB permissions)
- Primary writer: History.AddDepositStepLog
- The underlying table's StepStatus column accepts text values ('Pass', 'Fail') rather than integer codes

### 2.2 Connection to Billing.Deposit DRStatusID Updates

**What**: History.AddDepositStepLog (which writes through this synonym) also updates Billing.Deposit.DRStatusID as a side effect.

**Rules**:
- When StepStatus='Fail' and TransactionID != 0: Billing.Deposit.DRStatusID is set to 1 (Pending)
- When StepStatus='Pass' and previous status was 'Fail': Billing.Deposit.DRStatusID is set to 3 (Completed)
- This means writing a deposit step log is not just an audit operation - it drives deposit recovery state

---

## 3. Data Overview

N/A for Synonym (target table is in DB_Logs; MCP access not available).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym) | - | - | - | CODE-BACKED | Synonym resolves to DB_Logs.History.DepositStep. All structural details (columns, types, indexes, constraints) belong to the target table in DB_Logs. Target columns inferred from History.AddDepositStepLog usage: StepID, DepositID, InitiateRequest, Step, StepStatus, StepRetries, Error, Created, Comment, CorrelationID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | DB_Logs.History.DepositStep | Synonym | All operations on History.DepositStep are redirected to this target in DB_Logs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.AddDepositStepLog | INSERT, SELECT | Writer/Reader | Primary writer - inserts deposit processing step outcomes and reads prior step status for recovery detection |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.DepositStep (synonym)
└── DB_Logs.History.DepositStep (table - external database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| DB_Logs.History.DepositStep | Table (external DB) | Synonym target - all operations resolve to this table |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.AddDepositStepLog | Procedure | Writes deposit step log entries and reads prior step status via this synonym |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym. Indexes defined on DB_Logs.History.DepositStep.

### 7.2 Constraints

N/A for Synonym. Constraints defined on DB_Logs.History.DepositStep.

---

## 8. Sample Queries

### 8.1 Query deposit step history via synonym (requires cross-DB permission)

```sql
SELECT TOP 20
    StepID,
    DepositID,
    Step,
    StepStatus,
    StepRetries,
    Error,
    Created,
    CorrelationID
FROM History.DepositStep WITH (NOLOCK)
ORDER BY StepID DESC
```

### 8.2 Find all steps for a specific deposit transaction

```sql
SELECT
    StepID,
    Step,
    StepStatus,
    StepRetries,
    Error,
    Created
FROM History.DepositStep WITH (NOLOCK)
WHERE DepositID = 12345
ORDER BY Created ASC
```

### 8.3 Find failed deposit steps needing investigation

```sql
SELECT TOP 20
    StepID,
    DepositID,
    Step,
    StepRetries,
    Error,
    Created,
    CorrelationID
FROM History.DepositStep WITH (NOLOCK)
WHERE StepStatus = 'Fail'
ORDER BY Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/6 applicable (synonym - structure from target DB not accessible)*
*Sources: Atlassian: 0 Confluence + 0 Jira | App Code: 1 repo searched / 0 files | Corrections: 0 applied*
*Object: History.DepositStep | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.DepositStep.sql*
