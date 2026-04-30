# dbo.sp_MSdel_DictionaryRegulationl

> Auto-generated transactional replication stored procedure that applies DELETE operations from the publication to the subscriber table Dictionary.Regulation.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Replication DELETE agent |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`sp_MSdel_DictionaryRegulationl` is an auto-generated stored procedure created by SQL Server transactional replication. It is part of the Distribution Agent mechanism that applies DELETE operations from the publisher to the subscriber copy of the `Dictionary.Regulation` table.

Note: The trailing "l" in the procedure name is a known naming artifact from the replication auto-generation process.

This procedure is not maintained manually. It is created and managed by the replication infrastructure and should not be modified directly.

---

## 2. Business Logic

The procedure performs a simple DELETE operation against the target table using the primary key value provided:

1. DELETE FROM `Dictionary.Regulation` WHERE `ID` = `@pkc1`
2. If `@@rowcount = 0`, calls `sp_MSreplraiserror` with error number 20598 to signal a conflict (the row to delete was not found on the subscriber)

This is the standard replication conflict-detection pattern for DELETE commands.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| Parameter | Data Type | Direction | Description |
|-----------|-----------|-----------|-------------|
| @pkc1 | INT | IN | Primary key value (ID) of the row to delete |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Object | Type | Relationship |
|--------|------|--------------|
| Dictionary.Regulation | Table | Target table for DELETE operation |

### 5.2 Referenced By (other objects point to this)

Called by the SQL Server Distribution Agent during replication synchronization.

---

## 6. Dependencies

### 6.0 Dependency Chain

This procedure depends on the target replication table.

### 6.1 Objects This Depends On

| Object | Type |
|--------|------|
| Dictionary.Regulation | Table |

### 6.2 Objects That Depend On This

No dependents found. Called internally by the replication Distribution Agent.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the replication DELETE
```sql
EXEC dbo.sp_MSdel_DictionaryRegulationl @pkc1 = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.0/10 (Elements: 8.0/10, Logic: 8.0/10, Relationships: 6.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_MSdel_DictionaryRegulationl | Type: Stored Procedure | Source: RiskClassification/dbo/Stored Procedures/dbo.sp_MSdel_DictionaryRegulationl.sql*
