# Customer.RiskClassificationInfo (UDT)

> Table-valued parameter type for bulk updating user risk classification assignments.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | GCID (user identifier column) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.RiskClassificationInfo is a minimal TVP type carrying just GCID and RiskClassificationId for bulk risk classification updates. Used by Customer.UpdateManyRiskClassificationInfo to batch-update risk classification assignments across multiple users, typically during periodic risk reassessment cycles.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Data transport type.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | CODE-BACKED | Global Customer ID - unique user identifier. |
| 2 | RiskClassificationId | int | YES | - | CODE-BACKED | Risk classification tier for the user. Used in compliance risk assessment workflows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.UpdateManyRiskClassificationInfo | Parameter | Parameter Type | TVP for bulk risk classification updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.UpdateManyRiskClassificationInfo | Stored Procedure | Uses as READONLY parameter type |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Bulk risk classification update
```sql
DECLARE @Updates Customer.RiskClassificationInfo
INSERT INTO @Updates (GCID, RiskClassificationId) VALUES (12345, 2), (67890, 3)
EXEC Customer.UpdateManyRiskClassificationInfo @BulkUpdateTable = @Updates
```

### 8.2 Populate from query
```sql
DECLARE @Updates Customer.RiskClassificationInfo
INSERT INTO @Updates SELECT GCID, 1 FROM Customer.RiskClassificationUpdatedUsers WITH (NOLOCK)
```

### 8.3 Inspect
```sql
DECLARE @Data Customer.RiskClassificationInfo
INSERT INTO @Data VALUES (1, 2)
SELECT * FROM @Data
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Object: Customer.RiskClassificationInfo | Type: User Defined Type | Source: UserApiDB/UserApiDB/Customer/User Defined Types/Customer.RiskClassificationInfo.sql*
