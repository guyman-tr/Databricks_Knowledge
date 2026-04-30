# History.PayoutStep

> Synonym providing local-schema access to DB_Logs.History.PayoutStep - the step-level execution log table for the payout (withdrawal-to-funding) workflow in the DB_Logs database.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | Alias: DB_Logs.History.PayoutStep |
| **Partition** | N/A (resolves to target in DB_Logs) |
| **Indexes** | N/A (resolves to target in DB_Logs) |

---

## 1. Business Meaning

`History.PayoutStep` is a cross-database synonym that makes `DB_Logs.History.PayoutStep` accessible within the etoro database's History schema. The target table tracks individual step outcomes in the payout (withdraw-to-funding) processing workflow. It is the payout-side equivalent of `History.DepositStep`.

From `History.AddPayoutStepLog` usage, the underlying table columns include: StepID (IDENTITY, output via OUTPUT clause), WithdrawToFundingID (FK to the payout transaction), InitiateRequest, Step, StepStatus, StepRetries, Error, Created, Comment, CorrelationID. The key structural difference from DepositStep is that the transaction foreign key column is named `WithdrawToFundingID` rather than `DepositID`, reflecting that payouts are tracked via WithdrawToFunding transaction IDs.

Like `History.DepositStep`, this synonym exists to separate high-volume log writes from the main etoro database into the dedicated DB_Logs database.

---

## 2. Business Logic

### 2.1 Cross-Database Synonym for Payout Log Storage

**What**: Redirects all queries against History.PayoutStep to DB_Logs.History.PayoutStep.

**Columns/Parameters Involved**: N/A (synonym is a pure alias)

**Rules**:
- All operations on History.PayoutStep execute against DB_Logs.History.PayoutStep
- Primary writer: History.AddPayoutStepLog
- StepStatus accepts text values ('Pass', 'Fail')
- Unlike DepositStep's writer, AddPayoutStepLog does NOT update Billing.Deposit - simpler insert-only pattern
- The @TransactionID parameter in AddPayoutStepLog maps to WithdrawToFundingID (unlike AddDepositStepLog which maps to DepositID)

---

## 3. Data Overview

N/A for Synonym (target table is in DB_Logs; MCP access not available).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym) | - | - | - | CODE-BACKED | Synonym resolves to DB_Logs.History.PayoutStep. Target columns inferred from History.AddPayoutStepLog usage: StepID, WithdrawToFundingID, InitiateRequest, Step, StepStatus, StepRetries, Error, Created, Comment, CorrelationID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | DB_Logs.History.PayoutStep | Synonym | All operations redirect to this target in DB_Logs |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.AddPayoutStepLog | INSERT | Writer | Inserts payout processing step outcomes via this synonym |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PayoutStep (synonym)
└── DB_Logs.History.PayoutStep (table - external database)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| DB_Logs.History.PayoutStep | Table (external DB) | Synonym target - all operations resolve to this table |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.AddPayoutStepLog | Procedure | Writes payout step log entries via this synonym |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Query payout step history via synonym (requires cross-DB permission)

```sql
SELECT TOP 20
    StepID,
    WithdrawToFundingID,
    Step,
    StepStatus,
    StepRetries,
    Error,
    Created,
    CorrelationID
FROM History.PayoutStep WITH (NOLOCK)
ORDER BY StepID DESC
```

### 8.2 Find all steps for a specific payout transaction

```sql
SELECT
    StepID,
    Step,
    StepStatus,
    StepRetries,
    Error,
    Created
FROM History.PayoutStep WITH (NOLOCK)
WHERE WithdrawToFundingID = 67890
ORDER BY Created ASC
```

### 8.3 Find failed payout steps

```sql
SELECT TOP 20
    StepID,
    WithdrawToFundingID,
    Step,
    StepRetries,
    Error,
    Created
FROM History.PayoutStep WITH (NOLOCK)
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
*Object: History.PayoutStep | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.PayoutStep.sql*
