# dbo.UsernameList (UDT)

> Table-valued parameter type for passing lists of usernames to stored procedures for batch lookup operations.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | Username (single column) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.UsernameList enables passing batches of usernames for bulk user lookup operations. Used when resolving multiple usernames to GCIDs or other user data.

---

## 2. Business Logic

No complex business logic. Data transport type.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Username | nvarchar(50) | YES | - | CODE-BACKED | Username string for lookup. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate
```sql
DECLARE @names dbo.UsernameList
INSERT INTO @names VALUES (N'user1'), (N'user2'), (N'user3')
SELECT * FROM @names
```

### 8.2 Use for user lookup
```sql
DECLARE @names dbo.UsernameList
INSERT INTO @names VALUES (N'johndoe')
SELECT b.GCID, b.UserName FROM Customer.BasicUserInfo b WITH (NOLOCK) JOIN @names n ON b.UserName = n.Username
```

### 8.3 Populate from query
```sql
DECLARE @names dbo.UsernameList
INSERT INTO @names SELECT UserName FROM Customer.BasicUserInfo WITH (NOLOCK) WHERE PlayerLevelID = 7
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Object: dbo.UsernameList | Type: User Defined Type | Source: UserApiDB/UserApiDB/dbo/User Defined Types/dbo.UsernameList.sql*
