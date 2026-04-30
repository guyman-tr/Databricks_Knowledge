# dbo.EntityDescriptionTVP (UDT)

> Table-valued parameter type for passing entity type/ID pairs to description lookup procedures.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | EntityTypeId + EntityId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.EntityDescriptionTVP is a TVP for passing batches of entity type and entity ID pairs to stored procedures like dbo.GetAllEntitiesDescription and dbo.GetEntityDescriptionByEntityTypeId. Enables bulk lookup of entity descriptions.

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
| 1 | EntityTypeId | int | YES | - | CODE-BACKED | Entity type classifier. |
| 2 | EntityId | int | YES | - | CODE-BACKED | Entity instance identifier within the type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.GetAllEntitiesDescription | Parameter | Parameter Type | TVP for entity description lookup |
| dbo.GetEntityDescriptionByEntityTypeId | Parameter | Parameter Type | TVP for filtered entity lookup |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.GetAllEntitiesDescription | Stored Procedure | READONLY parameter |
| dbo.GetEntityDescriptionByEntityTypeId | Stored Procedure | READONLY parameter |

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
DECLARE @Entities dbo.EntityDescriptionTVP
INSERT INTO @Entities VALUES (1, 100), (2, 200)
EXEC dbo.GetAllEntitiesDescription @Entities = @Entities
```

### 8.2 Single entity lookup
```sql
DECLARE @E dbo.EntityDescriptionTVP
INSERT INTO @E VALUES (1, 12345)
EXEC dbo.GetEntityDescriptionByEntityTypeId @EntityTypeId = 1, @Entities = @E
```

### 8.3 Inspect
```sql
DECLARE @E dbo.EntityDescriptionTVP
INSERT INTO @E VALUES (1, 1), (1, 2), (2, 1)
SELECT * FROM @E
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Object: dbo.EntityDescriptionTVP | Type: User Defined Type | Source: UserApiDB/UserApiDB/dbo/User Defined Types/dbo.EntityDescriptionTVP.sql*
