# dbo.FiatAccountStatuses

> Event-sourced status history table tracking all lifecycle state changes (Active, Suspended, Deleted) for fiat accounts.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (+ PK) |

---

## 1. Business Meaning

FiatAccountStatuses records every status change event for a fiat account. Each row represents a point-in-time status transition - when an account becomes Active, is Suspended, or is Deleted. This event-sourced pattern preserves the complete status history for audit, compliance, and support purposes.

This table exists because account status changes are critical compliance events. Regulators and support teams need to know when an account was suspended, why (traceable via the operation that triggered it), and when it was reactivated. A simple "current status" column on FiatAccount would lose this history.

Data is created by dbo.AddFiatAccountAtatus (note: typo in SP name preserved from source) when the operational system reports a status change.

---

## 2. Business Logic

### 2.1 Account Status Lifecycle

**What**: Event-sourced account status tracking with the latest record representing current state.

**Columns/Parameters Involved**: `AccountId`, `StatusType`, `Created`

**Rules**:
- StatusType maps to Dictionary.AccountStatuses: 0=Active, 1=Suspended, 2=Deleted. See [Account Status](../../_glossary.md#account-status).
- The latest record (by Created or Id) for an AccountId is the current status
- New accounts start with StatusType=0 (Active)
- Multiple status changes may occur (Active -> Suspended -> Active)

---

## 3. Data Overview

| Id | AccountId | StatusType | Created | Meaning |
|---|---|---|---|---|
| 2135493 | 2135575 | 0 | 2026-04-14 13:51 | Account 2135575 set to Active (new account) |
| 2135492 | 2135574 | 0 | 2026-04-14 13:51 | Account 2135574 set to Active (new account) |
| 2135491 | 2135573 | 0 | 2026-04-14 13:50 | Account 2135573 set to Active (new account) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | AccountId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatAccount.Id. The account whose status changed. |
| 3 | StatusType | int | NO | - | CODE-BACKED | Account status: 0=Active, 1=Suspended, 2=Deleted. See [Account Status](../../_glossary.md#account-status). (Dictionary.AccountStatuses) |
| 4 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this status change was recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AccountId | dbo.FiatAccount | FK | The account whose status changed |
| StatusType | Dictionary.AccountStatuses | Implicit | Status value lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddFiatAccountAtatus | INSERT | Writer | Records account status changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.FiatAccountStatuses (table)
└── dbo.FiatAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatAccount | Table | FK from AccountId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddFiatAccountAtatus | Stored Procedure | Writes status records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FiatAccountStatuses | CLUSTERED | Id ASC | - | - | Active |
| IX_FiatAccountStatuses_AccountId | NONCLUSTERED | AccountId ASC | - | - | Active |
| IX_FiatAccountStatuses_Created | NONCLUSTERED | Created ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_FiatAccountStatuses_AccountId_FiatAccount_Id | FK | AccountId -> dbo.FiatAccount.Id |

---

## 8. Sample Queries

### 8.1 Get current status for an account
```sql
SELECT TOP 1 StatusType, Created
FROM dbo.FiatAccountStatuses WITH (NOLOCK)
WHERE AccountId = 2135575
ORDER BY Created DESC;
```

### 8.2 Get full status history for an account
```sql
SELECT s.Id, s.StatusType, ds.Name AS StatusName, s.Created
FROM dbo.FiatAccountStatuses s WITH (NOLOCK)
JOIN Dictionary.AccountStatuses ds WITH (NOLOCK) ON ds.Id = s.StatusType
WHERE s.AccountId = 2135575
ORDER BY s.Created;
```

### 8.3 Find recently suspended accounts
```sql
SELECT s.AccountId, a.Gcid, s.Created
FROM dbo.FiatAccountStatuses s WITH (NOLOCK)
JOIN dbo.FiatAccount a WITH (NOLOCK) ON a.Id = s.AccountId
WHERE s.StatusType = 1 AND s.Created >= DATEADD(DAY, -1, GETUTCDATE())
ORDER BY s.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.FiatAccountStatuses | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.FiatAccountStatuses.sql*
