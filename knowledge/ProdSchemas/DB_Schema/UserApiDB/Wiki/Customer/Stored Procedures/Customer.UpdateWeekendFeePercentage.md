# Customer.UpdateWeekendFeePercentage

> Updates a customer's weekend fee percentage in dbo.Real_CustomerStatic - a per-customer override for weekend holding fees.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE dbo.Real_CustomerStatic SET WeekendFeePrecentage |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateWeekendFeePercentage sets a customer-specific weekend fee percentage override. Weekend fees are charged on CFD positions held over the weekend. This procedure allows the platform to assign different weekend fee rates to individual customers (e.g., for VIP accounts, promotional offers, or regulatory requirements). Created by Serhii Poltava (Feb 2024).

Note: The database column is named `WeekendFeePrecentage` (typo preserved from the original schema - "Precentage" instead of "Percentage").

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple single-column UPDATE by CID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | int | NO | - | CODE-BACKED | Customer ID (CID, not GCID). |
| 2 | @weekendFeePercentage | tinyint | NO | - | CODE-BACKED | Weekend fee percentage to set (0-255). Applied as the customer's override rate for weekend position holding fees. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @cid | dbo.Real_CustomerStatic | UPDATE | Sets WeekendFeePrecentage column |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Weekend fee configuration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateWeekendFeePercentage (procedure)
+-- dbo.Real_CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_CustomerStatic | Table | UPDATE |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Fee calculation service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Set weekend fee
```sql
EXEC Customer.UpdateWeekendFeePercentage @cid=100001, @weekendFeePercentage=5
```

### 8.2 Read back via aggregated info
```sql
-- Weekend fee is returned as WeekendFeePercentage in GetPrivateAggregatedInfo
-- (aliased from WeekendFeePrecentage)
```

### 8.3 Direct check
```sql
SELECT WeekendFeePrecentage FROM dbo.Real_CustomerStatic WITH (NOLOCK) WHERE CID = 100001
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateWeekendFeePercentage | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateWeekendFeePercentage.sql*
