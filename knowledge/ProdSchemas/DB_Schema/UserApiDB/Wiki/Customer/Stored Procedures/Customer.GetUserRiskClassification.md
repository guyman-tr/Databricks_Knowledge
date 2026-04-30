# Customer.GetUserRiskClassification

> Returns the risk classification ID for a customer from the back-office record - used for risk-based trading limits and compliance categorization.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns RiskClassificationID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetUserRiskClassification retrieves a customer's risk classification from Real_BackOfficeCustomer. The RiskClassificationID determines the customer's risk tier, which affects trading limits, leverage caps, and regulatory treatment. This is used by the risk engine and compliance systems.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple single-value lookup.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | RiskClassificationID (output) | int | YES | - | CODE-BACKED | Customer's risk classification tier from Real_BackOfficeCustomer. Determines trading limits and regulatory treatment. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | dbo.Real_Customer | JOIN | GCID to CID |
| CID | dbo.Real_BackOfficeCustomer | JOIN | Risk classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Risk engine / compliance |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetUserRiskClassification (procedure)
+-- dbo.Real_BackOfficeCustomer (table)
+-- dbo.Real_Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_BackOfficeCustomer | Table | FROM - risk classification |
| dbo.Real_Customer | Table | JOIN - GCID to CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get risk classification
```sql
EXEC Customer.GetUserRiskClassification @gcid = 12345
```

### 8.2 Direct query
```sql
SELECT bc.RiskClassificationID
FROM dbo.Real_BackOfficeCustomer bc WITH (NOLOCK)
JOIN dbo.Real_Customer rc WITH (NOLOCK) ON bc.CID = rc.CID
WHERE rc.GCID = @gcid
```

### 8.3 Compare with risk classification queue
```sql
-- GetUserRiskClassification: reads current classification
-- GetRiskClassificationUpdatedUsers: reads the update queue for batch processing
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetUserRiskClassification | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetUserRiskClassification.sql*
