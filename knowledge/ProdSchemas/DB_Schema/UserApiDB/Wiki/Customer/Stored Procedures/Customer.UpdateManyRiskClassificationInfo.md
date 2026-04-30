# Customer.UpdateManyRiskClassificationInfo

> Bulk updates risk classification for multiple customers - validates batch size (max 2000), copies TVP to temp table, and delegates to dbo.Real_UpdateManyRiskClassificationInfo.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Batch risk classification update with 2000 row limit |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateManyRiskClassificationInfo performs a bulk risk classification update for multiple customers. It validates that the batch does not exceed 2000 records (RAISERROR if exceeded), copies the input TVP to a temp table (#BulkUpdateRiskClassificationInfo), and delegates to dbo.Real_UpdateManyRiskClassificationInfo for the actual update. The temp table approach allows the legacy procedure to read the data.

---

## 2. Business Logic

### 2.1 Batch Size Validation

**Rules**:
- If COUNT > 2000: RAISERROR 'Too many records, allowed 2000 records per batch'
- This prevents performance issues from oversized bulk operations

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @BulkUpdateTable | Customer.RiskClassificationInfo (TVP) | NO | - | CODE-BACKED | Rows with GCID + RiskClassificationId to update. Max 2000 rows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TVP | dbo.Real_UpdateManyRiskClassificationInfo | EXEC | Delegated bulk update |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Risk reclassification batch |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateManyRiskClassificationInfo (procedure)
+-- dbo.Real_UpdateManyRiskClassificationInfo (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_UpdateManyRiskClassificationInfo | Procedure | EXEC |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Risk batch processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RAISERROR | Validation | Max 2000 records per batch |

---

## 8. Sample Queries

### 8.1 Bulk update risk classification
```sql
DECLARE @bulk Customer.RiskClassificationInfo
INSERT @bulk (GCID, RiskClassificationId) VALUES (1001, 2), (1002, 3)
EXEC Customer.UpdateManyRiskClassificationInfo @BulkUpdateTable=@bulk
```

### 8.2 Check current classifications
```sql
SELECT bc.RiskClassificationID
FROM dbo.Real_BackOfficeCustomer bc WITH (NOLOCK)
JOIN dbo.Real_Customer rc WITH (NOLOCK) ON bc.CID = rc.CID
WHERE rc.GCID IN (1001, 1002)
```

### 8.3 Check update queue
```sql
-- Updated users appear in Customer.RiskClassificationUpdatedUsers
-- Read via: EXEC Customer.GetRiskClassificationUpdatedUsers @batchSize=100
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateManyRiskClassificationInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateManyRiskClassificationInfo.sql*
