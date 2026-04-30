# Customer.DeleteAdditionalCitizenship

> Deletes a user's additional citizenship record from the system-versioned table.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.DeleteAdditionalCitizenship removes a user's secondary citizenship record. Since Customer.AdditionalCitizenship is system-versioned, the deleted row is automatically preserved in History.AdditionalCitizenship for audit purposes.

---

## 2. Business Logic

No complex business logic. Single DELETE by GCID.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int (IN) | NO | - | CODE-BACKED | Global Customer ID whose additional citizenship to delete. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.AdditionalCitizenship | DELETE FROM | Removes citizenship record (auto-archived via system versioning) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.DeleteAdditionalCitizenship (procedure)
  +-- Customer.AdditionalCitizenship (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.AdditionalCitizenship | Table | DELETE FROM |

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

### 8.1 Delete additional citizenship
```sql
EXEC Customer.DeleteAdditionalCitizenship @GCID = 12345
```

### 8.2 Verify deletion with history
```sql
EXEC Customer.DeleteAdditionalCitizenship @GCID = 12345
SELECT * FROM Customer.AdditionalCitizenship FOR SYSTEM_TIME ALL WHERE GCID = 12345
```

### 8.3 Check if citizenship exists before deleting
```sql
IF EXISTS (SELECT 1 FROM Customer.AdditionalCitizenship WITH (NOLOCK) WHERE GCID = @GCID)
  EXEC Customer.DeleteAdditionalCitizenship @GCID = @GCID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.DeleteAdditionalCitizenship | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.DeleteAdditionalCitizenship.sql*
