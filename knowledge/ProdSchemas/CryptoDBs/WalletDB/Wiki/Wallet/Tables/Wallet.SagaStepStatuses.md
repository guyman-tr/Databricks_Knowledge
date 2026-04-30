# Wallet.SagaStepStatuses

> Event-sourced status history for individual saga steps, tracking each execution attempt and status transition of atomic operations within distributed transaction workflows.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table tracks status transitions for individual saga steps from `Wallet.SagaSteps`. Each row records when a step moved to a new status (Start -> Done, or Start -> Failed -> Retry -> Done). FK to Dictionary.StepStatusTypes. See [Step Status Type](../../_glossary.md#step-status-type): 1=Start, 2=Failed, 3=Retry, 4=Done.

---

## 2. Business Logic

No complex logic. Status event log for step-level execution tracking.

---

## 3. Data Overview

N/A for status event table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing event identifier. |
| 2 | SagaStepId | bigint | NO | - | CODE-BACKED | Parent saga step. Implicit reference to Wallet.SagaSteps.Id. |
| 3 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of this status transition. |
| 4 | StepStatusTypeId | tinyint | NO | - | VERIFIED | Step status: 1=Start, 2=Failed, 3=Retry, 4=Done. See [Step Status Type](../../_glossary.md#step-status-type). FK to Dictionary.StepStatusTypes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| StepStatusTypeId | Dictionary.StepStatusTypes | FK | Step status value |
| SagaStepId | Wallet.SagaSteps | Implicit | Parent step |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertSagaStepStatus | - | Writer | Appends status events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.SagaStepStatuses (table)
├── Wallet.SagaSteps (table)
│     └── Wallet.SagaRuns (table)
└── Dictionary.StepStatusTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.StepStatusTypes | Table | FK target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertSagaStepStatus | Stored Procedure | Inserts status events |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaStepStatuses | CLUSTERED PK | Id ASC | - | - | Active |
| IX_...SagaStepId_Created | NC | SagaStepId, Created DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_...Created | DEFAULT | getutcdate() |
| FK_...StepStatusTypeId | FK | -> Dictionary.StepStatusTypes.Id |

---

## 8. Sample Queries

### 8.1 Status history for a step
```sql
SELECT sss.StepStatusTypeId, sst.Name AS Status, sss.Created
FROM Wallet.SagaStepStatuses sss WITH (NOLOCK)
JOIN Dictionary.StepStatusTypes sst WITH (NOLOCK) ON sss.StepStatusTypeId = sst.Id
WHERE sss.SagaStepId = 12345 ORDER BY sss.Id
```

### 8.2 Steps with retries
```sql
SELECT SagaStepId, COUNT(*) AS StatusEvents FROM Wallet.SagaStepStatuses WITH (NOLOCK)
WHERE StepStatusTypeId = 3 GROUP BY SagaStepId
```

### 8.3 Recent step failures
```sql
SELECT TOP 20 SagaStepId, Created FROM Wallet.SagaStepStatuses WITH (NOLOCK)
WHERE StepStatusTypeId = 2 ORDER BY Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.SagaStepStatuses | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.SagaStepStatuses.sql*
