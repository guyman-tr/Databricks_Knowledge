# Trade.BSLBlackList

> Registry of customer accounts subject to BSL (Bonus Stop Loss) margin call checks, with audit trail of who added them and why.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | CID (PK, CLUSTERED) |
| **Partition** | No (PRIMARY, PAGE compressed) |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

This table identifies which customer accounts should be **included** in BSL (Bonus Stop Loss) margin call checks. BSL is the automated system that monitors customer equity relative to their bonus credit, sending warnings when equity drops and liquidating positions when it falls below a threshold percentage.

In the original BSL design (`Trade.CheckBSL`), only customers with a row in this table were checked for margin calls. The table also serves as an audit log, recording who added the customer (UserName), when (Occurred), and from what process (ProcName). An optional DepositID links the entry to the deposit that triggered the blacklisting.

The table is currently empty (0 rows). The newer BSL implementation (`Trade.InsertBSLMessagesIntoQueue`) hardcodes `IsInBlackList = 1` for all users, bypassing this table entirely and checking all customers with open non-settled positions. This suggests the blacklist approach was deprecated in favor of universal BSL checking, though the table is retained in the schema.

---

## 2. Business Logic

### 2.1 BSL Eligibility Control (Legacy)

**What**: Originally gated which customers were subject to margin call monitoring.

**Columns/Parameters Involved**: `CID`, `ProcName`, `UserName`

**Rules**:
- In `Trade.CheckBSL`: JOIN to BSLBlackList meant only blacklisted CIDs were checked
- In `Trade.InsertBSLMessagesIntoQueue`: hardcoded `IsInBlackList = 1` bypasses this table
- Addition was audited: `Occurred` defaults to GETUTCDATE(), `UserName` defaults to SUSER_SNAME(), `ProcName` defaults to 'manual'
- `TmpInsertUsersToBSLBlackListTable` was used for bulk insertion

### 2.2 Audit Trail Defaults

**What**: Built-in audit trail via DEFAULT constraints.

**Columns/Parameters Involved**: `Occurred`, `UserName`, `ProcName`

**Rules**:
- `Occurred` = GETUTCDATE() captures when the entry was created
- `UserName` = SUSER_SNAME() captures the SQL login of the session
- `ProcName` = 'manual' indicates manual insertion unless overridden by automated process

---

## 3. Data Overview

Table is empty (0 rows). The BSL system has evolved to check all eligible customers regardless of blacklist membership.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer identifier. One entry per customer (PK). The customer this BSL eligibility entry applies to. Implicit FK to Customer.CustomerStatic. |
| 2 | Occurred | datetime | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp when this customer was added to the BSL blacklist. Auto-populated via DEFAULT constraint. |
| 3 | UserName | varchar(60) | NO | SUSER_SNAME() | CODE-BACKED | SQL login name of the session that inserted this row. Auto-populated via DEFAULT. For manual operations, contains the DBA's login; for automated, contains the service account. |
| 4 | ProcName | varchar(80) | NO | 'manual' | CODE-BACKED | Name of the stored procedure or process that added this entry. Defaults to 'manual' for ad-hoc insertions; overridden by automated processes. |
| 5 | DepositID | int | YES | - | NAME-INFERRED | Optional reference to the deposit that triggered the customer being added to BSL monitoring. NULL for entries not linked to a specific deposit event. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit FK | Customer account subject to BSL checks |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CheckBSL | CID | READER (JOIN) | Legacy BSL check procedure JOINs to this table to filter eligible customers |
| Trade.TmpInsertUsersToBSLBlackListTable | CID | WRITER | Bulk insertion of customers into BSL blacklist |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CheckBSL | Stored Procedure | READER - JOINs to check BSL for blacklisted customers only |
| Trade.TmpInsertUsersToBSLBlackListTable | Stored Procedure | WRITER - bulk inserts customers |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeBSLBlackList | CLUSTERED PK | CID ASC | - | - | Active (FILLFACTOR=95, PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_TradeBSLBlackListOccurred | DEFAULT | GETUTCDATE() - auto-captures insertion timestamp |
| DF_TradeBSLBlackListUserName | DEFAULT | SUSER_SNAME() - auto-captures SQL login for audit |
| DF_TradeBSLBlackListProcName | DEFAULT | 'manual' - default source unless overridden by automation |

---

## 8. Sample Queries

### 8.1 Check if a specific customer is in the BSL blacklist
```sql
SELECT  CID, Occurred, UserName, ProcName, DepositID
FROM    Trade.BSLBlackList WITH (NOLOCK)
WHERE   CID = @CID
```

### 8.2 View recent additions to the blacklist
```sql
SELECT  CID, Occurred, UserName, ProcName, DepositID
FROM    Trade.BSLBlackList WITH (NOLOCK)
ORDER BY Occurred DESC
```

### 8.3 Count entries by source process
```sql
SELECT  ProcName, COUNT(*) AS EntryCount
FROM    Trade.BSLBlackList WITH (NOLOCK)
GROUP BY ProcName
ORDER BY EntryCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| AI Generated: BSL (Bonus Stop Loss) Service Design Overview and Technical Details | Confluence | BSL is the margin call system that monitors customer equity vs bonus thresholds |

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.2/10 (Elements: 9.0/10, Logic: 7/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.BSLBlackList | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.BSLBlackList.sql*
