# Customer.DeleteRiskClassificationUpdatedUsers

> Removes processed entries from the RiskClassificationUpdatedUsers work queue table using a list of GCIDs.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcids IdList (input TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.DeleteRiskClassificationUpdatedUsers cleans up the work queue after risk classification changes have been processed by downstream systems. It takes a TVP (table-valued parameter) of GCIDs and removes those entries from Customer.RiskClassificationUpdatedUsers.

---

## 2. Business Logic

No complex business logic. Bulk DELETE using TVP join.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcids | IdList READONLY (IN) | NO | - | CODE-BACKED | Table-valued parameter containing GCIDs to remove from the work queue. Uses dbo.IdList type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.RiskClassificationUpdatedUsers | DELETE FROM | Removes processed queue entries |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.DeleteRiskClassificationUpdatedUsers (procedure)
  +-- Customer.RiskClassificationUpdatedUsers (table) [done]
  +-- dbo.IdList (UDT, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.RiskClassificationUpdatedUsers | Table | DELETE FROM |
| dbo.IdList | UDT | Parameter type |

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

### 8.1 Delete processed entries
```sql
DECLARE @ids dbo.IdList
INSERT INTO @ids (Id) VALUES (12345), (67890)
EXEC Customer.DeleteRiskClassificationUpdatedUsers @gcids = @ids
```

### 8.2 Process and clean up pattern
```sql
DECLARE @ids dbo.IdList
INSERT INTO @ids SELECT GCID FROM Customer.RiskClassificationUpdatedUsers WITH (NOLOCK)
-- Process the GCIDs...
EXEC Customer.DeleteRiskClassificationUpdatedUsers @gcids = @ids
```

### 8.3 Verify cleanup
```sql
SELECT COUNT(*) AS Remaining FROM Customer.RiskClassificationUpdatedUsers WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.DeleteRiskClassificationUpdatedUsers | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.DeleteRiskClassificationUpdatedUsers.sql*
