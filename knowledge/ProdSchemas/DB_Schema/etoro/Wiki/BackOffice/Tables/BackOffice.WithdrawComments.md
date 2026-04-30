# BackOffice.WithdrawComments

> Simple one-to-one text comment store for withdrawal requests, holding a single free-text comment per WithdrawID. Currently empty - likely superseded by the Comment column in WithdrawApproval.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_BOWDRC: WithdrawID (NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (nonclustered PK) |

---

## 1. Business Meaning

`BackOffice.WithdrawComments` was designed to store a single free-text comment per withdrawal request (Billing.Withdraw). The table has a nonclustered PK on `WithdrawID`, making it a 1:1 extension table for `Billing.Withdraw` - one optional comment per withdrawal.

The table is currently empty (0 rows in live data) and has only one known SP reference: `BackOffice.UpdateWithdrawComment`. This strongly suggests the table was created for a feature that either never launched at scale, or was quickly superseded by the `Comment` column added directly to `BackOffice.WithdrawApproval`. The `WithdrawApproval.Comment` column (NOT NULL, varchar(max)) captures per-group comments on every approval decision, making a separate comments extension table redundant.

The `text` column type (deprecated in modern SQL Server, should be `varchar(max)`) and the nonclustered-only PK are additional indicators of an older, lightly-used design.

---

## 2. Business Logic

### 2.1 Withdrawal Comment Storage

**What**: Stores a single text comment per withdrawal request (1:1 with Billing.Withdraw).

**Columns/Parameters Involved**: `WithdrawID`, `Comment`

**Rules**:
- One row per WithdrawID (enforced by PK).
- Comment is `text` type (NULL allowed) - stores a free-text note about the withdrawal.
- Written by `BackOffice.UpdateWithdrawComment` SP (UPSERT or UPDATE pattern inferred).
- No foreign key constraint to Billing.Withdraw (the relationship is logical, not enforced by DDL).
- Table is currently empty - no active usage.

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| Row count | 0 (empty) |
| Status | Empty/inactive - no operational data |
| Likely superseded by | BackOffice.WithdrawApproval.Comment column |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | int | NO | - | CODE-BACKED | PK. Identifies the withdrawal request this comment belongs to. Logical FK to Billing.Withdraw.WithdrawID (no DDL constraint). One row per withdrawal. |
| 2 | Comment | text | YES | - | CODE-BACKED | Free-text comment about the withdrawal request. `text` is a deprecated SQL Server type (equivalent to varchar(max)). Nullable - comment may not be set. Currently no rows exist in this table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw.WithdrawID | Implicit (no DDL FK) | The withdrawal request this comment belongs to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.UpdateWithdrawComment | UPDATE/INSERT | Writer | Sets the comment for a withdrawal |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no code-level dependencies (no DDL foreign keys).

### 6.1 Objects This Depends On

No formal dependencies (no FK constraints defined).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.UpdateWithdrawComment | Stored Procedure | Writes comments to this table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BOWDRC | NONCLUSTERED PK | WithdrawID ASC (FILLFACTOR=90) | - | - | Active |

### 7.2 Constraints

No FK constraints. PK only.

Note: `text` column type is deprecated in SQL Server. The physical data is stored off-page (TEXTIMAGE filegroup). This is a technical debt indicator.

---

## 8. Sample Queries

### 8.1 Get comment for a specific withdrawal

```sql
SELECT WithdrawID, Comment
FROM BackOffice.WithdrawComments WITH (NOLOCK)
WHERE WithdrawID = 99999;
```

### 8.2 Check if any comments exist

```sql
SELECT COUNT(WithdrawID) AS CommentCount
FROM BackOffice.WithdrawComments WITH (NOLOCK);
-- Returns 0 - table is currently empty
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 8/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Live Data, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.WithdrawComments | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.WithdrawComments.sql*
