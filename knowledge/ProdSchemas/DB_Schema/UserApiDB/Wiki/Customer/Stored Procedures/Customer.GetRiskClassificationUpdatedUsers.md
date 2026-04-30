# Customer.GetRiskClassificationUpdatedUsers

> Retrieves a batch of customers whose risk classification was recently updated - used for processing risk reclassification events.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOP @batchSize rows from RiskClassificationUpdatedUsers |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRiskClassificationUpdatedUsers retrieves a batch of customers who have had their risk classification updated. The Customer.RiskClassificationUpdatedUsers table acts as a queue - rows are inserted when a customer's risk classification changes, and this procedure reads them in batches for downstream processing (e.g., applying new trading limits, notifications, regulatory reporting).

Created by Tal Cohen (May 2024) for the risk classification update pipeline.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple batch read with configurable size.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @batchSize | int | NO | - | CODE-BACKED | Maximum number of records to return per call. Controls processing batch size. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID of the updated customer. |
| 3 | RiskClassificationId (output) | int | NO | - | CODE-BACKED | The new risk classification assigned to the customer. |
| 4 | UpdatedAt (output) | datetime | NO | - | CODE-BACKED | When the risk classification was updated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.RiskClassificationUpdatedUsers | FROM | Queue table for risk updates |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Batch processing of risk reclassifications |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRiskClassificationUpdatedUsers (procedure)
+-- Customer.RiskClassificationUpdatedUsers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.RiskClassificationUpdatedUsers | Table | FROM - batch read |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called by batch processing service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get batch of 100 updated users
```sql
EXEC Customer.GetRiskClassificationUpdatedUsers @batchSize = 100
```

### 8.2 Direct query equivalent
```sql
SELECT TOP 100 GCID, RiskClassificationId, UpdatedAt
FROM Customer.RiskClassificationUpdatedUsers WITH (NOLOCK)
```

### 8.3 Check queue depth
```sql
SELECT COUNT(*) AS QueueDepth FROM Customer.RiskClassificationUpdatedUsers WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetRiskClassificationUpdatedUsers | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetRiskClassificationUpdatedUsers.sql*
