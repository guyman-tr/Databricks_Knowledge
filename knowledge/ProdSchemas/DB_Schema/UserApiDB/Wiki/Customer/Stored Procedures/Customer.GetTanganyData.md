# Customer.GetTanganyData

> Retrieves Tangany (crypto custody) identification data for a customer - Tangany ID, status, and last update date.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TanganyID, TanganyStatusID, UpdateDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetTanganyData retrieves a customer's Tangany crypto custody identification record. Tangany is a third-party crypto custody provider - customers who trade cryptocurrencies may have a Tangany wallet ID and associated status. This is the companion procedure to GetDltData (which retrieves DLT/blockchain data from the same CustomerIdentification table).

Created by Serhii Poltava (October 2023).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple single-row read.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | TanganyID (output) | varchar | YES | - | CODE-BACKED | Customer's Tangany crypto custody wallet identifier. |
| 3 | TanganyStatusID (output) | int | YES | - | CODE-BACKED | Tangany wallet status. FK to Dictionary.TanganyStatus. See [Tangany Status](_glossary.md#tangany-status). |
| 4 | UpdateDate (output) | datetime | YES | - | CODE-BACKED | When the Tangany record was last updated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.CustomerIdentification | FROM | Tangany data stored in identification table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Crypto custody data retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetTanganyData (procedure)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | FROM - Tangany fields |

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

### 8.1 Get Tangany data
```sql
EXEC Customer.GetTanganyData @GCID = 12345
```

### 8.2 Direct query with status name
```sql
SELECT ci.TanganyID, ci.TanganyStatusID, ts.Name AS TanganyStatusName, ci.UpdateDate
FROM Customer.CustomerIdentification ci WITH (NOLOCK)
LEFT JOIN Dictionary.TanganyStatus ts WITH (NOLOCK) ON ci.TanganyStatusID = ts.TanganyStatusID
WHERE ci.GCID = @GCID
```

### 8.3 Compare with DLT data
```sql
-- GetTanganyData: returns TanganyID, TanganyStatusID, UpdateDate
-- GetDltData: returns DltID, DltStatusID, UpdateDate
-- Both read from Customer.CustomerIdentification
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetTanganyData | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetTanganyData.sql*
