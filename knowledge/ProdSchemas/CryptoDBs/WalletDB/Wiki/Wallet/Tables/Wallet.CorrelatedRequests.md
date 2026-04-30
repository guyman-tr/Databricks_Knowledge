# Wallet.CorrelatedRequests

> Links causally related wallet requests (parent-child), tracking when one operation triggers another - primarily used for bounceback scenarios where an incoming transaction triggers a return send.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC UNIQUE + 1 clustered PK |

---

## 1. Business Meaning

This table records parent-child relationships between wallet requests. When one operation causally triggers another (e.g., a received transaction fails AML screening and triggers a bounceback send), the two requests' CorrelationIds are linked here. Currently, all 4,795 entries are type 1 (Bounceback), indicating this table is exclusively used for tracking bounceback relationships.

Without this table, the system could not trace that a specific send-back transaction was triggered by a specific incoming transaction. This linkage is essential for compliance auditing (proving a bounceback was initiated for a specific failed AML check) and for preventing duplicate bouncebacks.

Rows are created by `Wallet.TryAddCorrelatedRequest` during the bounceback flow. The unique constraint on (ParentRequestCorrelationId, ChildRequestCorrelationId) prevents duplicate linkages.

---

## 2. Business Logic

### 2.1 Bounceback Correlation

**What**: When an incoming transaction must be returned (bounced back), the parent receive request and child send-back request are linked.

**Columns/Parameters Involved**: `CorrelatedRequestsTypeId`, `ParentRequestCorrelationId`, `ChildRequestCorrelationId`

**Rules**:
- ParentRequestCorrelationId = the CorrelationId of the original incoming (receive) request
- ChildRequestCorrelationId = the CorrelationId of the triggered bounceback (send) request
- CorrelatedRequestsTypeId = 1 (Bounceback) for all current entries
- See [Correlated Request Type](../../_glossary.md#correlated-request-type). Implicit reference to Dictionary.CorrelatedRequestsTypes.
- Used to prevent duplicate bouncebacks: before initiating a bounceback, check if a child already exists for the parent

---

## 3. Data Overview

| Id | CorrelatedRequestsTypeId | ParentRequestCorrelationId | ChildRequestCorrelationId | Meaning |
|---|---|---|---|---|
| 4795 | 1 (Bounceback) | 60AB681B-... | E3749F16-... | Most recent bounceback: incoming transaction (parent) triggered a send-back (child) due to AML failure or ineligible customer |
| 4794 | 1 (Bounceback) | 02607CBC-... | D1985D5B-... | Another bounceback correlation linking a received transaction to its return send |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | CorrelatedRequestsTypeId | tinyint | NO | - | VERIFIED | Type of correlation: 1=Bounceback (only type currently used). See [Correlated Request Type](../../_glossary.md#correlated-request-type). Implicit FK to Dictionary.CorrelatedRequestsTypes. |
| 3 | ParentRequestCorrelationId | uniqueidentifier | NO | - | VERIFIED | CorrelationId of the original (parent) request that triggered the child. For bouncebacks, this is the received transaction's CorrelationId from Wallet.Requests. |
| 4 | ChildRequestCorrelationId | uniqueidentifier | NO | - | VERIFIED | CorrelationId of the triggered (child) request. For bouncebacks, this is the send-back transaction's CorrelationId from Wallet.Requests. |
| 5 | Created | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when this correlation was established. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ParentRequestCorrelationId | Wallet.Requests | Implicit (via CorrelationId) | Links to the parent request |
| ChildRequestCorrelationId | Wallet.Requests | Implicit (via CorrelationId) | Links to the child request |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.TryAddCorrelatedRequest | - | Writer | Creates correlation records |
| Wallet.GetCorrelatedRequestId | - | Reader | Looks up child CorrelationId by parent |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies (implicit reference to Wallet.Requests via CorrelationId, but no FK constraint).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TryAddCorrelatedRequest | Stored Procedure | Inserts correlations |
| Wallet.GetCorrelatedRequestId | Stored Procedure | Reads correlations |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED PK | Id ASC | - | - | Active |
| UX_CorrelatedRequests_ParentRequestCorrelationId_ChildRequestCorrelationId | NC UNIQUE | ParentRequestCorrelationId, ChildRequestCorrelationId | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF (Created) | DEFAULT | getutcdate() |

---

## 8. Sample Queries

### 8.1 Find bounceback child for a parent request
```sql
SELECT ChildRequestCorrelationId, Created
FROM Wallet.CorrelatedRequests WITH (NOLOCK)
WHERE ParentRequestCorrelationId = '60AB681B-8167-4B88-97CE-2986C57EBC7E'
```

### 8.2 Count bouncebacks over time
```sql
SELECT CAST(Created AS DATE) AS Day, COUNT(*) AS BouncebackCount
FROM Wallet.CorrelatedRequests WITH (NOLOCK)
WHERE CorrelatedRequestsTypeId = 1
GROUP BY CAST(Created AS DATE)
ORDER BY Day DESC
```

### 8.3 Trace full bounceback chain with request details
```sql
SELECT cr.ParentRequestCorrelationId, pr.RequestTypeId AS ParentType,
       cr.ChildRequestCorrelationId, chr.RequestTypeId AS ChildType, cr.Created
FROM Wallet.CorrelatedRequests cr WITH (NOLOCK)
JOIN Wallet.Requests pr WITH (NOLOCK) ON cr.ParentRequestCorrelationId = pr.CorrelationId
JOIN Wallet.Requests chr WITH (NOLOCK) ON cr.ChildRequestCorrelationId = chr.CorrelationId
ORDER BY cr.Created DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.CorrelatedRequests | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.CorrelatedRequests.sql*
