# UserAttribution.GetUserAttributes

> Returns attribute assignments for a given GCID, with an optional filter by AttributeGroupID. Reads from UserAttribution.UserAttributes.

| Property | Value |
|----------|-------|
| **Schema** | UserAttribution |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (required), @AttributeGroupID (optional) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

UserAttribution.GetUserAttributes retrieves the set of attributes currently assigned to a user. It is the primary read path for user attribution data, called during downstream processing that needs to know a user's classification (e.g., acquisition source, risk segment). The optional @AttributeGroupID parameter allows callers to request only a specific logical category of attributes rather than the entire attribution profile.

---

## 2. Business Logic

### 2.1 Optional Group Filter

**What**: Returns all attributes or only attributes within a specific group.

**Columns/Parameters Involved**: `@GCID`, `@AttributeGroupID`

**Rules**:
- @GCID is required — always filters to a single user
- @AttributeGroupID is optional (NULL = return all groups)
- When @AttributeGroupID is provided, adds WHERE AttributeGroupID = @AttributeGroupID
- Uses NOLOCK for non-blocking reads
- Returns rows from the current (active) version — no historical rows

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO (param) | - | CODE-BACKED | Required. The customer whose attributes to retrieve. |
| 2 | @AttributeGroupID | int | YES (param) | NULL | CODE-BACKED | Optional. When provided, restricts results to attributes in this group. NULL returns all groups. |

Output: ID, GCID, AttributeID, AttributeGroupID from UserAttribution.UserAttributes for the specified user (and optional group).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | UserAttribution.UserAttributes | SELECT FROM | Source of attribute assignment data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by application layer during user processing.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
UserAttribution.GetUserAttributes (procedure)
  +-- UserAttribution.UserAttributes (table)
        +-- Dictionary.Attribute (table) [implicit]
        +-- Dictionary.AttributeGroup (table) [implicit]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| UserAttribution.UserAttributes | Table | SELECT FROM with GCID (and optional AttributeGroupID) filter |

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

### 8.1 Get all attributes for a user
```sql
EXEC UserAttribution.GetUserAttributes @GCID = 12345
```

### 8.2 Get attributes for a user filtered by group
```sql
EXEC UserAttribution.GetUserAttributes @GCID = 12345, @AttributeGroupID = 3
```

### 8.3 Direct equivalent query
```sql
SELECT ID, GCID, AttributeID, AttributeGroupID
FROM UserAttribution.UserAttributes WITH (NOLOCK)
WHERE GCID = 12345
-- AND AttributeGroupID = 3  -- add when group filter needed
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: UserAttribution.GetUserAttributes | Type: Stored Procedure | Source: UserApiDB/UserApiDB/UserAttribution/Stored Procedures/UserAttribution.GetUserAttributes.sql*
