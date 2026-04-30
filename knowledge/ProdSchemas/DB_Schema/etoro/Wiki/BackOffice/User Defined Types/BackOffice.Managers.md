# BackOffice.Managers

> Single-column table-valued parameter type for passing a set of BackOffice manager IDs as a filter list to stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | User Defined Type |
| **Key Identifier** | ManagerID (nullable - no PK constraint) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.Managers` is a single-column Table-Valued Type (TVT) that holds a set of `ManagerID` values for use as a multi-value filter parameter in BackOffice stored procedures. It allows callers to pass a list of manager IDs (referencing `BackOffice.Manager.ManagerID`) in a single READONLY parameter instead of dynamic SQL or string parsing.

This type exists to enable manager-scoped queries - specifically to let a back-office user or the application request data for "their" list of assigned customers across multiple managers simultaneously. The lack of a PK or uniqueness constraint (unlike `BackOffice.IDs`) reflects that manager ID lists are typically small, pre-validated sets where deduplication overhead is unnecessary.

Data flows into this type from the back-office CRM or manager portal. A manager or supervisor inserts their assigned manager IDs and passes the list to `BackOffice.GetMyCustomers`, which filters `BackOffice.Customer.ManagerID IN (SELECT ManagerID FROM @ManagerIds)`.

---

## 2. Business Logic

### 2.1 Manager-Scoped Customer Access

**What**: Enables a manager or team lead to retrieve customers for a specific set of managers in one query, supporting team-view and supervisory access patterns.

**Columns/Parameters Involved**: `ManagerID`

**Rules**:
- `ManagerID` is nullable in the DDL, but a NULL value would match customers with no assigned manager (ManagerID IS NULL) depending on how the consuming SP handles it.
- No PK or uniqueness constraint - duplicates are silently allowed (though functionally harmless since the SP uses IN subquery).
- An empty table (no rows inserted) causes the consuming SP to return no customers, not all customers - the IN clause requires at least one matching value.

**Diagram**:
```
Caller (BO portal) passes @managerList AS BackOffice.Managers:
  [(ManagerID=101), (ManagerID=102)]
         |
         v
BackOffice.GetMyCustomers
  WHERE BC.ManagerID IN (SELECT ManagerID FROM @ManagerIds)
         |
         v
  Returns customers assigned to ManagerID 101 or 102
```

---

## 3. Data Overview

N/A for User Defined Type. This is a transient parameter container, not a persistent table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ManagerID | int | YES | - | CODE-BACKED | BackOffice manager identifier. References BackOffice.Manager.ManagerID. Used as an IN-list filter in BackOffice.GetMyCustomers to return customers assigned to specific managers. Nullable in the DDL but expected to be non-NULL in valid usage. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ManagerID | BackOffice.Manager.ManagerID | Implicit | Identifies BackOffice managers whose assigned customers should be retrieved |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetMyCustomers | @ManagerIds parameter | Schema contract | Filters BackOffice.Customer.ManagerID using IN subquery on this TVT |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetMyCustomers | Stored Procedure | READONLY parameter @ManagerIds - used in WHERE BC.ManagerID IN (SELECT ManagerID FROM @ManagerIds) to scope the customer result set to specific manager assignments |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None. ManagerID is nullable with no uniqueness enforcement.

---

## 8. Sample Queries

### 8.1 Get customers for a specific manager

```sql
DECLARE @managers BackOffice.Managers;
DECLARE @levels BackOffice.PlayerLevels;

INSERT INTO @managers VALUES (101); -- Single manager ID

-- @levels empty = all player levels
EXEC BackOffice.GetMyCustomers
    @ManagerIds = @managers,
    @RegisteredFrom = '2025-01-01',
    @RegisteredTo = '2026-03-17',
    @PlayerLevelIds = @levels;
```

### 8.2 Get customers for a team of managers

```sql
DECLARE @managers BackOffice.Managers;
DECLARE @levels BackOffice.PlayerLevels;

INSERT INTO @managers
SELECT ManagerID
FROM BackOffice.Manager WITH (NOLOCK)
WHERE TeamID = 5; -- All managers in team 5

INSERT INTO @levels VALUES (1), (2); -- Gold and Platinum levels only

EXEC BackOffice.GetMyCustomers
    @ManagerIds = @managers,
    @RegisteredFrom = '2024-01-01',
    @RegisteredTo = '2026-03-17',
    @PlayerLevelIds = @levels;
```

### 8.3 Inspect manager list before passing to procedure

```sql
DECLARE @managers BackOffice.Managers;

INSERT INTO @managers VALUES (101), (102), (103);

SELECT m.ManagerID, bm.FirstName + ' ' + bm.LastName AS ManagerName
FROM @managers m WITH (NOLOCK)
JOIN BackOffice.Manager bm WITH (NOLOCK) ON bm.ManagerID = m.ManagerID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, Procedure Ref, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.Managers | Type: User Defined Type | Source: etoro/etoro/BackOffice/User Defined Types/BackOffice.Managers.sql*
