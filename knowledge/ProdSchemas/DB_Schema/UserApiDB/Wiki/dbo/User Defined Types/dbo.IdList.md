# dbo.IdList (UDT)

> General-purpose table-valued parameter type for passing lists of integer IDs to stored procedures across the database.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | Id (single column) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.IdList is the most widely used TVP in UserApiDB. It provides a standard way to pass lists of integer IDs (typically GCIDs, CIDs, or other entity IDs) to stored procedures for bulk operations. Used by numerous procedures across Customer, KYC, and other schemas for batch lookups, deletes, and updates.

---

## 2. Business Logic

No complex business logic. Universal ID list transport type.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | YES | - | CODE-BACKED | Integer identifier. Typically a GCID, CID, or other entity ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.DeleteRiskClassificationUpdatedUsers | @gcids | Parameter Type | GCID list for batch delete |
| Multiple other procedures | Various | Parameter Type | Standard ID list parameter |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

Widely referenced across Customer, KYC, and other schema procedures.

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Standard usage pattern
```sql
DECLARE @ids dbo.IdList
INSERT INTO @ids (Id) VALUES (12345), (67890), (11111)
-- Pass to any procedure accepting IdList
```

### 8.2 Populate from query
```sql
DECLARE @ids dbo.IdList
INSERT INTO @ids SELECT GCID FROM Customer.BasicUserInfo WITH (NOLOCK) WHERE PlayerLevelID = 7
```

### 8.3 Use in JOIN
```sql
DECLARE @ids dbo.IdList
INSERT INTO @ids VALUES (1), (2), (3)
SELECT b.* FROM Customer.BasicUserInfo b WITH (NOLOCK) JOIN @ids i ON b.GCID = i.Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Object: dbo.IdList | Type: User Defined Type | Source: UserApiDB/UserApiDB/dbo/User Defined Types/dbo.IdList.sql*
