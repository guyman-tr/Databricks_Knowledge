# Customer.DelAddress

> Deletes a specific address record for a user by GCID and address type (e.g., mailing address for W-8BEN tax form).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID + @AddressTypeID (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.DelAddress removes a specific address record from the Customer_Address table (dbo). Users may have multiple addresses of different types (residential, mailing/W-8BEN). This procedure deletes a specific address type for a user, supporting scenarios like removing an outdated mailing address used for tax form submission.

---

## 2. Business Logic

No complex business logic. Single DELETE with GCID + AddressTypeID filter.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int (IN) | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @AddressTypeID | int (IN) | NO | - | CODE-BACKED | Type of address to delete (e.g., residential, mailing/W-8BEN). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer_Address (dbo) | DELETE FROM | Removes address record |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.DelAddress (procedure)
  +-- Customer_Address (dbo table, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer_Address | dbo table | DELETE FROM |

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

### 8.1 Delete mailing address
```sql
EXEC Customer.DelAddress @GCID = 12345, @AddressTypeID = 2
```

### 8.2 Delete primary address
```sql
EXEC Customer.DelAddress @GCID = 12345, @AddressTypeID = 1
```

### 8.3 Verify deletion
```sql
EXEC Customer.DelAddress @GCID = 12345, @AddressTypeID = 2
SELECT * FROM Customer_Address WITH (NOLOCK) WHERE GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.DelAddress | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.DelAddress.sql*
