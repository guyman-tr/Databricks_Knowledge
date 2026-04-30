# UserAttribution.UserAttributes

> Stores user attribute assignments linking a customer to a specific attribute within an attribute group. System-versioned, PAGE compressed, with a non-clustered composite PK over GCID+AttributeID+AttributeGroupID and a separate clustered index on the IDENTITY column ID.

| Property | Value |
|----------|-------|
| **Schema** | UserAttribution |
| **Object Type** | Table |
| **Key Identifier** | ID (BIGINT IDENTITY, CLUSTERED) / GCID + AttributeID + AttributeGroupID (NC PK) |
| **Partition** | No |
| **Indexes** | 2 (CLUSTERED on ID, NC PK on GCID+AttributeID+AttributeGroupID) |

---

## 1. Business Meaning

UserAttribution.UserAttributes is the fact table recording which attributes have been assigned to each user. An attribute represents a marketing or behavioral classification (e.g., "organic signup", "referred by campaign X", "high-value segment"). The AttributeGroupID allows attributes to be organized into logical groups (e.g., "acquisition source", "risk tier").

This table is written by UserAttribution.SetUserAttribute and read by UserAttribution.GetUserAttributes. It is system-versioned with history tracked in History.UserAttributes, enabling full audit trails of how user classifications change over time.

The table uses PAGE compression to reduce storage footprint given the potentially large number of rows (one row per user-attribute combination).

---

## 2. Business Logic

### 2.1 Composite Uniqueness

**What**: Each user can have each attribute assigned only once per group.

**Columns/Parameters Involved**: `GCID`, `AttributeID`, `AttributeGroupID`

**Rules**:
- Non-clustered PK enforces uniqueness on (GCID, AttributeID, AttributeGroupID)
- A user may hold multiple attributes from the same group (different AttributeIDs)
- Upsert pattern: SetUserAttribute checks existence before INSERT vs UPDATE

### 2.2 System Versioning

**What**: Full history of attribute assignment changes.

**Rules**:
- SYSTEM_VERSIONED = ON, history table: History.UserAttributes
- Tracks when attributes were assigned, changed, or removed
- Supports compliance queries: "what attributes did user X have on date Y?"

---

## 3. Data Overview

N/A - transactional table; row count scales with active user base and number of assigned attributes per user.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint IDENTITY | NO | - | CODE-BACKED | Surrogate primary key with clustered index. Auto-incrementing; used for internal ordering and efficient range scans. |
| 2 | GCID | int | NO | - | CODE-BACKED | Part of NC PK. Global Customer ID. Identifies the user who holds this attribute. |
| 3 | AttributeID | int | NO | - | CODE-BACKED | Part of NC PK. The attribute assigned to the user. Implicit FK to Dictionary.Attribute. |
| 4 | AttributeGroupID | int | NO | - | CODE-BACKED | Part of NC PK. The attribute group this assignment belongs to. Implicit FK to Dictionary.AttributeGroup. Allows filtering by logical category. |
| 5 | SysStartTime | datetime2 | NO | - | CODE-BACKED | System-versioning period start. Managed by SQL Server. |
| 6 | SysEndTime | datetime2 | NO | - | CODE-BACKED | System-versioning period end. Managed by SQL Server (9999 = currently active). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AttributeID | Dictionary.Attribute | Implicit FK | The attribute definition |
| AttributeGroupID | Dictionary.AttributeGroup | Implicit FK | The grouping category for the attribute |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.UserAttributes | GCID, AttributeID, AttributeGroupID | System versioning | Temporal history |
| UserAttribution.GetUserAttributes | GCID | SP reads | Returns user's current attributes |
| UserAttribution.SetUserAttribute | GCID, AttributeID, AttributeGroupID | SP writes | Upserts attribute assignment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
UserAttribution.UserAttributes (table)
  +-- Dictionary.Attribute (table) [implicit]
  +-- Dictionary.AttributeGroup (table) [implicit]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Attribute | Table | Implicit FK: AttributeID |
| Dictionary.AttributeGroup | Table | Implicit FK: AttributeGroupID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.UserAttributes | Table | System-versioned history |
| UserAttribution.GetUserAttributes | Stored Procedure | Reads user attributes |
| UserAttribution.SetUserAttribute | Stored Procedure | Upserts attribute rows |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| CIX_UserAttributes_ID | CLUSTERED | ID | - | - | Active |
| PK_UserAttributes | NON-CLUSTERED PK | GCID, AttributeID, AttributeGroupID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_UserAttributes | PRIMARY KEY (NC) | GCID + AttributeID + AttributeGroupID uniqueness |
| PAGE COMPRESSION | Storage | Data pages compressed; reduces I/O for large scans |
| PERIOD FOR SYSTEM_TIME | System versioning | SysStartTime, SysEndTime managed by SQL Server |

---

## 8. Sample Queries

### 8.1 Get all attributes for a user
```sql
SELECT ua.AttributeID, a.Name AS AttributeName, ua.AttributeGroupID, ag.Name AS GroupName
FROM UserAttribution.UserAttributes ua WITH (NOLOCK)
JOIN Dictionary.Attribute a WITH (NOLOCK) ON ua.AttributeID = a.AttributeID
JOIN Dictionary.AttributeGroup ag WITH (NOLOCK) ON ua.AttributeGroupID = ag.AttributeGroupID
WHERE ua.GCID = @GCID
```

### 8.2 Find all users with a specific attribute
```sql
SELECT GCID FROM UserAttribution.UserAttributes WITH (NOLOCK)
WHERE AttributeID = @AttributeID
```

### 8.3 Attribute assignment history for a user
```sql
SELECT GCID, AttributeID, AttributeGroupID, SysStartTime, SysEndTime
FROM UserAttribution.UserAttributes FOR SYSTEM_TIME ALL
WHERE GCID = @GCID
ORDER BY SysStartTime
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: UserAttribution.UserAttributes | Type: Table | Source: UserApiDB/UserApiDB/UserAttribution/Tables/UserAttribution.UserAttributes.sql*
