# History.UserAttributes

> System versioning history table for user attribute assignments (interest/activity attributes per user with temporal tracking).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK (clustered on ValidTo,ValidFrom) |
| **Partition** | No |
| **Indexes** | 1 (clustered on ValidTo,ValidFrom) |

---

## 1. Business Meaning

History.UserAttributes stores previous versions of user attribute assignments from its source table. Each row records which attribute (from Dictionary.Attribute) was assigned to a user, with what value, in which attribute group, during a specific validity period. Supports temporal analytics on user interest/segmentation changes.

---

## 2. Business Logic

Automatically managed by SQL Server system versioning.

---

## 3. Data Overview

N/A - system-managed history.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | - | CODE-BACKED | Original row ID from source table. |
| 2 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | AttributeID | int | NO | - | CODE-BACKED | Attribute assigned. See [Attribute](_glossary.md#attribute). 1=Stocks, 2=Crypto, 3=Copy Trader, etc. |
| 4 | AttributeValue | nvarchar(255) | NO | - | CODE-BACKED | Value of the attribute assignment. |
| 5 | AttributeGroupID | int | NO | - | CODE-BACKED | Group context. See [Attribute Group](_glossary.md#attribute-group). 1=Funnel. |
| 6 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Assignment version start. |
| 7 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Assignment version end. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

System versioning pair with its source table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

System versioning pair.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_UserAttributes | CLUSTERED | ValidTo, ValidFrom | - | - | Active (PAGE compressed) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Attribute history for a user
```sql
SELECT AttributeID, AttributeValue, ValidFrom, ValidTo FROM History.UserAttributes WITH (NOLOCK) WHERE GCID = @GCID ORDER BY ValidFrom
```

### 8.2 With attribute names
```sql
SELECT a.Name AS Attribute, h.AttributeValue, h.ValidFrom, h.ValidTo
FROM History.UserAttributes h WITH (NOLOCK)
JOIN Dictionary.Attribute a WITH (NOLOCK) ON h.AttributeID = a.AttributeID WHERE h.GCID = @GCID ORDER BY h.ValidFrom
```

### 8.3 Count changes per user
```sql
SELECT GCID, COUNT(*) AS ChangeCount FROM History.UserAttributes WITH (NOLOCK) GROUP BY GCID HAVING COUNT(*) > 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.UserAttributes | Type: Table | Source: UserApiDB/UserApiDB/History/Tables/History.UserAttributes.sql*
