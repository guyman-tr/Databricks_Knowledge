# dbo.sp_MSupd_DictionaryRegulation

> Auto-generated transactional replication stored procedure that applies UPDATE operations from the publication to the subscriber table Dictionary.Regulation.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Replication UPDATE agent |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`sp_MSupd_DictionaryRegulation` is an auto-generated stored procedure created by SQL Server transactional replication. It is part of the Distribution Agent mechanism that applies UPDATE operations from the publisher to the subscriber copy of the `Dictionary.Regulation` table.

This procedure is not maintained manually. It is created and managed by the replication infrastructure and should not be modified directly.

---

## 2. Business Logic

The procedure uses a bitmap-based column-level update pattern to apply only the columns that changed at the publisher:

- Bit 1 (0x01) = ID column
- Bit 2 (0x02) = Name column
- Bit 4 (0x04) = IsUSA column
- Bit 8 (0x08) = JurisdictionName column

The procedure has two main branches:

1. **Primary key column changed** (bit 1 set): Updates the row including the ID column, matching on the old primary key value `@pkc1`. Selectively includes Name, IsUSA, and JurisdictionName based on their respective bitmap bits.
2. **Primary key column not changed** (bit 1 not set): Updates only the non-PK columns that changed (Name, IsUSA, JurisdictionName) based on bitmap bits, matching on `@pkc1`.

If `@@rowcount = 0` after the UPDATE, calls `sp_MSreplraiserror` with error number 20598 to signal a conflict (the row to update was not found on the subscriber).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| Parameter | Data Type | Direction | Description |
|-----------|-----------|-----------|-------------|
| @c1 | INT | IN | New value for column ID |
| @c2 | VARCHAR(50) | IN | New value for column Name |
| @c3 | TINYINT | IN | New value for column IsUSA |
| @c4 | VARCHAR(30) | IN | New value for column JurisdictionName |
| @pkc1 | INT | IN | Primary key value (ID) of the row to update |
| @bitmap | BINARY(1) | IN | Bitmap indicating which columns changed |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Object | Type | Relationship |
|--------|------|--------------|
| Dictionary.Regulation | Table | Target table for UPDATE operation |

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

### 8.1 Execute the replication UPDATE (all columns changed)
```sql
EXEC dbo.sp_MSupd_DictionaryRegulation
    @c1 = 1,
    @c2 = 'UpdatedName',
    @c3 = 0,
    @c4 = 'UpdatedJurisdiction',
    @pkc1 = 1,
    @bitmap = 0x0F
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.0/10 (Elements: 8.0/10, Logic: 8.0/10, Relationships: 6.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_MSupd_DictionaryRegulation | Type: Stored Procedure | Source: RiskClassification/dbo/Stored Procedures/dbo.sp_MSupd_DictionaryRegulation.sql*
