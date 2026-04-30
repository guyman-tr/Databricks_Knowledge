# UserAttribution.SetUserAttribute

> Upserts a user attribute assignment: updates the existing row if the GCID+AttributeID+AttributeGroupID combination exists, otherwise inserts a new row.

| Property | Value |
|----------|-------|
| **Schema** | UserAttribution |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID + @AttributeID + @AttributeGroupID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

UserAttribution.SetUserAttribute is the write path for user attribute assignments. It implements an upsert (IF EXISTS → UPDATE, ELSE → INSERT) pattern to idempotently assign or update an attribute for a user. Callers do not need to know whether the attribute has been previously assigned — the SP handles both cases.

This SP is called during registration (to apply funnel-derived attributes) and during subsequent re-classifications (e.g., when a user is reassigned to a different segment). The system-versioned nature of UserAttribution.UserAttributes means every upsert creates a history record automatically.

---

## 2. Business Logic

### 2.1 Upsert Pattern

**What**: Idempotent attribute assignment.

**Columns/Parameters Involved**: `@GCID`, `@AttributeID`, `@AttributeGroupID`

**Rules**:
- Checks IF EXISTS in UserAttribution.UserAttributes WHERE GCID = @GCID AND AttributeID = @AttributeID AND AttributeGroupID = @AttributeGroupID
- If row exists: UPDATE (refreshes the row; triggers a new system-versioning history entry)
- If row does not exist: INSERT new row with provided values
- No return value — callers assume success if no error is raised
- The composite NC PK guarantees no duplicate rows can exist after the insert branch

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO (param) | - | CODE-BACKED | The customer to assign the attribute to. |
| 2 | @AttributeID | int | NO (param) | - | CODE-BACKED | The attribute being assigned. Implicit FK to Dictionary.Attribute. |
| 3 | @AttributeGroupID | int | NO (param) | - | CODE-BACKED | The attribute group context for this assignment. Implicit FK to Dictionary.AttributeGroup. |

Output: none (no result set returned).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | UserAttribution.UserAttributes | IF EXISTS + UPDATE / INSERT | Upserts attribute assignment row |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by application/registration layer.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
UserAttribution.SetUserAttribute (procedure)
  +-- UserAttribution.UserAttributes (table)
        +-- Dictionary.Attribute (table) [implicit]
        +-- Dictionary.AttributeGroup (table) [implicit]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| UserAttribution.UserAttributes | Table | Checks existence, then UPDATE or INSERT |

### 6.2 Objects That Depend On This

No dependents found in SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Assign an attribute to a user
```sql
EXEC UserAttribution.SetUserAttribute @GCID = 12345, @AttributeID = 7, @AttributeGroupID = 3
```

### 8.2 Re-assign (update) an existing attribute
```sql
-- If the combination already exists, this runs the UPDATE branch
EXEC UserAttribution.SetUserAttribute @GCID = 12345, @AttributeID = 7, @AttributeGroupID = 3
```

### 8.3 Verify the assignment
```sql
SELECT GCID, AttributeID, AttributeGroupID
FROM UserAttribution.UserAttributes WITH (NOLOCK)
WHERE GCID = 12345 AND AttributeID = 7 AND AttributeGroupID = 3
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: UserAttribution.SetUserAttribute | Type: Stored Procedure | Source: UserApiDB/UserApiDB/UserAttribution/Stored Procedures/UserAttribution.SetUserAttribute.sql*
