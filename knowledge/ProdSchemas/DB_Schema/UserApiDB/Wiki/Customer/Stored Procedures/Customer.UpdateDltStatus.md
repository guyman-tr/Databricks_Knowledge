# Customer.UpdateDltStatus

> Updates the DLT (blockchain) status for a customer in Customer.CustomerIdentification.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE CustomerIdentification SET DltStatusID + UpdateDate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateDltStatus changes a customer's DLT (Distributed Ledger Technology) wallet status. This is called when the blockchain wallet status changes (e.g., from Pending to Active, or to Failed). Sets UpdateDate to GETUTCDATE() automatically.

---

## 2. Business Logic

No complex logic. Simple status update with auto-timestamp.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @Status | tinyint | NO | - | CODE-BACKED | New DLT status. FK to Dictionary.DltStatus. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.CustomerIdentification | UPDATE | DltStatusID + UpdateDate |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | DLT status changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateDltStatus (procedure)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | UPDATE |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Crypto service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update DLT status
```sql
EXEC Customer.UpdateDltStatus @GCID=12345, @Status=2 -- e.g., Active
```

### 8.2 Read back
```sql
EXEC Customer.GetDltData @GCID=12345
```

### 8.3 Direct check
```sql
SELECT DltStatusID, UpdateDate FROM Customer.CustomerIdentification WITH (NOLOCK) WHERE GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateDltStatus | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateDltStatus.sql*
