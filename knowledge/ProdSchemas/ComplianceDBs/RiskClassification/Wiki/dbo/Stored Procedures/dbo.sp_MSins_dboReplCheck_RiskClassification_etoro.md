# dbo.sp_MSins_dboReplCheck_RiskClassification_etoro

> Auto-generated transactional replication stored procedure that applies INSERT operations from the publication to the subscriber table dbo.ReplCheck_RiskClassification_etoro.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Replication INSERT agent |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`sp_MSins_dboReplCheck_RiskClassification_etoro` is an auto-generated stored procedure created by SQL Server transactional replication. It is part of the Distribution Agent mechanism that applies INSERT operations from the publisher to the subscriber copy of the `dbo.ReplCheck_RiskClassification_etoro` table.

This procedure is not maintained manually. It is created and managed by the replication infrastructure and should not be modified directly.

---

## 2. Business Logic

The procedure performs a straightforward INSERT operation into the target table:

1. INSERT INTO `dbo.ReplCheck_RiskClassification_etoro` (`ID`, `LastUpdated`) VALUES (`@c1`, `@c2`)

No conflict detection is needed for INSERT operations in the standard replication pattern.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| Parameter | Data Type | Direction | Description |
|-----------|-----------|-----------|-------------|
| @c1 | INT | IN | Value for column ID |
| @c2 | DATETIME | IN | Value for column LastUpdated |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Object | Type | Relationship |
|--------|------|--------------|
| dbo.ReplCheck_RiskClassification_etoro | Table | Target table for INSERT operation |

### 5.2 Referenced By (other objects point to this)

Called by the SQL Server Distribution Agent during replication synchronization.

---

## 6. Dependencies

### 6.0 Dependency Chain

This procedure depends on the target replication table.

### 6.1 Objects This Depends On

| Object | Type |
|--------|------|
| dbo.ReplCheck_RiskClassification_etoro | Table |

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

### 8.1 Execute the replication INSERT
```sql
EXEC dbo.sp_MSins_dboReplCheck_RiskClassification_etoro @c1 = 1, @c2 = '2026-01-01 00:00:00'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 7.0/10 (Elements: 8.0/10, Logic: 8.0/10, Relationships: 6.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.sp_MSins_dboReplCheck_RiskClassification_etoro | Type: Stored Procedure | Source: RiskClassification/dbo/Stored Procedures/dbo.sp_MSins_dboReplCheck_RiskClassification_etoro.sql*
