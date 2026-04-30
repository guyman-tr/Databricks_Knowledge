# dbo.GetEntityDescriptionByEntityTypeId

> Returns entity descriptions for specific entity type+ID pairs from a TVP, supporting questions (1), extended fields (2), and compliance workflows (5).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Tvp EntityDescriptionTVP (input) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.GetEntityDescriptionByEntityTypeId resolves entity IDs to names for specific entity types. Takes a TVP of (EntityTypeId, EntityId) pairs and returns names by joining to the appropriate source: EntityTypeId=1 -> KYC.Questions (English, LanguageId=1), EntityTypeId=2 -> Dictionary.ExtendedUserField, EntityTypeId=5 -> Compliance_WorkFlow.

---

## 2. Business Logic

Three-way UNION with TVP JOIN, each branch filtered by EntityTypeId.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Tvp | EntityDescriptionTVP READONLY (IN) | NO | - | CODE-BACKED | TVP with EntityTypeId + EntityId pairs to resolve. |

Output: EntityTypeId, EntityId, Name.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.Questions | JOIN | EntityTypeId=1 |
| - | Dictionary.ExtendedUserField | JOIN | EntityTypeId=2 |
| - | dbo.Compliance_WorkFlow | JOIN (synonym) | EntityTypeId=5 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetEntityDescriptionByEntityTypeId (procedure)
  +-- dbo.EntityDescriptionTVP (UDT) [done]
  +-- KYC.Questions (table) [done]
  +-- Dictionary.ExtendedUserField (table) [done]
  +-- dbo.Compliance_WorkFlow (synonym)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.EntityDescriptionTVP | UDT | Parameter type |
| KYC.Questions | Table | JOIN |
| Dictionary.ExtendedUserField | Table | JOIN |
| dbo.Compliance_WorkFlow | Synonym | JOIN |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Resolve entities
```sql
DECLARE @tvp dbo.EntityDescriptionTVP
INSERT INTO @tvp VALUES (1, 3), (2, 6), (5, 1)
EXEC dbo.GetEntityDescriptionByEntityTypeId @Tvp = @tvp
```

### 8.2 Questions only
```sql
DECLARE @tvp dbo.EntityDescriptionTVP
INSERT INTO @tvp VALUES (1, 1), (1, 2), (1, 3)
EXEC dbo.GetEntityDescriptionByEntityTypeId @Tvp = @tvp
```

### 8.3 Mixed types
```sql
DECLARE @tvp dbo.EntityDescriptionTVP
INSERT INTO @tvp VALUES (1, 5), (2, 7)
EXEC dbo.GetEntityDescriptionByEntityTypeId @Tvp = @tvp
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: dbo.GetEntityDescriptionByEntityTypeId | Type: Stored Procedure | Source: UserApiDB/UserApiDB/dbo/Stored Procedures/dbo.GetEntityDescriptionByEntityTypeId.sql*
