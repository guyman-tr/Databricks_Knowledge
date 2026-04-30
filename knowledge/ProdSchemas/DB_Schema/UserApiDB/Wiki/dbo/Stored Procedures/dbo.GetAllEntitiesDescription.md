# dbo.GetAllEntitiesDescription

> Returns descriptions for all entity types (questions, extended fields, compliance requirements) for gap analysis and compliance dashboards.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input params |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.GetAllEntitiesDescription returns a unified list of entities with descriptions for compliance gap analysis. Combines KYC questions (EntityTypeId=1), extended user fields (EntityTypeId=2), and compliance requirements from the Compliance_Requirements synonym. Used by back-office compliance dashboards.

---

## 2. Business Logic

### 2.1 Multi-Source UNION

**What**: Three-way UNION combining different entity types with a common schema.

**Rules**:
- EntityTypeId=1: KYC Questions (RequirementID=4)
- EntityTypeId=2: Extended User Fields (RequirementID=4)
- EntityTypeId=NULL: Compliance Requirements (RequirementID from source)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters. Output: RequirementID, EntityTypeId, EntityId, Name.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.Questions | SELECT FROM | Question descriptions |
| - | Dictionary.ExtendedUserField | SELECT FROM | Field descriptions |
| - | dbo.Compliance_Requirements | SELECT FROM (synonym) | Compliance requirements |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAllEntitiesDescription (procedure)
  +-- KYC.Questions (table) [done]
  +-- Dictionary.ExtendedUserField (table) [done]
  +-- dbo.Compliance_Requirements (synonym)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.Questions | Table | SELECT FROM |
| Dictionary.ExtendedUserField | Table | SELECT FROM |
| dbo.Compliance_Requirements | Synonym | SELECT FROM |

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

### 8.1 Get all entities
```sql
EXEC dbo.GetAllEntitiesDescription
```

### 8.2 Filter by entity type
```sql
CREATE TABLE #Entities (RequirementID INT, EntityTypeId INT, EntityId INT, Name NVARCHAR(250))
INSERT INTO #Entities EXEC dbo.GetAllEntitiesDescription
SELECT * FROM #Entities WHERE EntityTypeId = 1 -- Questions only
DROP TABLE #Entities
```

### 8.3 Count by type
```sql
CREATE TABLE #E (RequirementID INT, EntityTypeId INT, EntityId INT, Name NVARCHAR(250))
INSERT INTO #E EXEC dbo.GetAllEntitiesDescription
SELECT EntityTypeId, COUNT(*) FROM #E GROUP BY EntityTypeId
DROP TABLE #E
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: dbo.GetAllEntitiesDescription | Type: Stored Procedure | Source: UserApiDB/UserApiDB/dbo/Stored Procedures/dbo.GetAllEntitiesDescription.sql*
