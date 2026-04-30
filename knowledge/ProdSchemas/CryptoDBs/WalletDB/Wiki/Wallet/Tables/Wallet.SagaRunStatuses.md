# Wallet.SagaRunStatuses

> Event-sourced status history for saga runs, tracking each lifecycle transition of distributed transaction workflows from start through completion, rollback, or failure.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table tracks the lifecycle of each saga run from `Wallet.SagaRuns`. Each row records a status transition: 1=Start, 2=Rollback, 3=Completed, 4=Failed. See [Saga Status Type](../../_glossary.md#saga-status-type). FK to Dictionary.SagaStatusTypes.

---

## 2. Business Logic

No complex logic. Status event log for saga lifecycle tracking.

---

## 3. Data Overview

N/A for status event table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing event identifier. |
| 2 | SagaRunId | bigint | NO | - | CODE-BACKED | Parent saga run. Implicit reference to Wallet.SagaRuns.Id. No explicit FK constraint. |
| 3 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of this status transition. |
| 4 | SagaStatusTypeId | tinyint | NO | - | VERIFIED | Saga status: 1=Start, 2=Rollback, 3=Completed, 4=Failed. See [Saga Status Type](../../_glossary.md#saga-status-type). FK to Dictionary.SagaStatusTypes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SagaStatusTypeId | Dictionary.SagaStatusTypes | FK | Saga status value |
| SagaRunId | Wallet.SagaRuns | Implicit | Parent saga run |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertSagaRunStatus | - | Writer | Appends status events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.SagaRunStatuses (table)
└── Dictionary.SagaStatusTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.SagaStatusTypes | Table | FK target for SagaStatusTypeId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertSagaRunStatus | Stored Procedure | Inserts status events |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_SagaRunStatuses | CLUSTERED PK | Id ASC | - | - | Active |
| IX_...SagaRunId_Created | NC | SagaRunId, Created DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_...Created | DEFAULT | getutcdate() |
| FK_...SagaStatusTypeId | FK | -> Dictionary.SagaStatusTypes.Id |

---

## 8. Sample Queries

### 8.1 Status history for a saga
```sql
SELECT srs.SagaStatusTypeId, sst.Name AS Status, srs.Created
FROM Wallet.SagaRunStatuses srs WITH (NOLOCK)
JOIN Dictionary.SagaStatusTypes sst WITH (NOLOCK) ON srs.SagaStatusTypeId = sst.Id
WHERE srs.SagaRunId = 163847 ORDER BY srs.Id
```

### 8.2 Failed sagas
```sql
SELECT SagaRunId, Created FROM Wallet.SagaRunStatuses WITH (NOLOCK)
WHERE SagaStatusTypeId = 4 ORDER BY Created DESC
```

### 8.3 Saga outcome distribution
```sql
SELECT sst.Name, COUNT(*) AS Cnt FROM Wallet.SagaRunStatuses srs WITH (NOLOCK)
JOIN Dictionary.SagaStatusTypes sst WITH (NOLOCK) ON srs.SagaStatusTypeId = sst.Id
GROUP BY sst.Name ORDER BY Cnt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.SagaRunStatuses | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.SagaRunStatuses.sql*
