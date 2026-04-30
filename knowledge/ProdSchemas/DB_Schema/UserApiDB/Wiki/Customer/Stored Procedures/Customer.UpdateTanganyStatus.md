# Customer.UpdateTanganyStatus

> Updates the Tangany (crypto custody) status for a customer in Customer.CustomerIdentification.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE CustomerIdentification SET TanganyStatusID + UpdateDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateTanganyStatus changes a customer's Tangany crypto custody wallet status. Created by Serhii Poltava (Nov 2023). Companion to UpdateDltStatus (which updates the DLT status in the same table).

---

## 2. Business Logic

No complex logic. Simple status + timestamp update.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @Status | tinyint | NO | - | CODE-BACKED | New Tangany status. FK to Dictionary.TanganyStatus. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.CustomerIdentification | UPDATE | TanganyStatusID + UpdateDate |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Tangany status changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateTanganyStatus (procedure)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | UPDATE |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Crypto custody service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update Tangany status
```sql
EXEC Customer.UpdateTanganyStatus @GCID=12345, @Status=2
```

### 8.2 Read back
```sql
EXEC Customer.GetTanganyData @GCID=12345
```

### 8.3 Direct check
```sql
SELECT TanganyStatusID, UpdateDate FROM Customer.CustomerIdentification WITH (NOLOCK) WHERE GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateTanganyStatus | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateTanganyStatus.sql*
