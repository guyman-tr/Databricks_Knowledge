# Customer.UpdateLei

> Updates a customer's Legal Entity Identifier (LEI) via dbo.Real_SetCustomerLeiDetails - resolves GCID to CID, then delegates to the legacy procedure. Returns update success flag.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | EXEC dbo.Real_SetCustomerLeiDetails |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateLei updates the Legal Entity Identifier (LEI) for corporate/institutional accounts. The LEI is a 20-character code required by MiFID II for identifying legal entities in financial transactions. The procedure resolves GCID to CID via CustomerIdentification, then delegates to dbo.Real_SetCustomerLeiDetails.

---

## 2. Business Logic

No complex logic. GCID-to-CID resolution + delegation.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @lei | nvarchar(50) | NO | - | CODE-BACKED | Legal Entity Identifier (20-char ISO 17442 code). |
| 3 | (return) | bit | - | - | CODE-BACKED | @Updated output from Real_SetCustomerLeiDetails: 1=updated, 0=not updated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.CustomerIdentification | SELECT | CID resolution |
| @cid, @lei | dbo.Real_SetCustomerLeiDetails | EXEC | Legacy LEI update |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Corporate account LEI management |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateLei (procedure)
+-- Customer.CustomerIdentification (table)
+-- dbo.Real_SetCustomerLeiDetails (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | SELECT - CID resolution |
| dbo.Real_SetCustomerLeiDetails | Procedure | EXEC |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Corporate compliance |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update LEI
```sql
EXEC Customer.UpdateLei @gcid=12345, @lei=N'529900T8BM49AURSDO55'
```

### 8.2 Verify LEI
```sql
SELECT bc.Lei FROM dbo.Real_BackOfficeCustomer bc WITH (NOLOCK)
JOIN dbo.Real_Customer rc WITH (NOLOCK) ON bc.CID = rc.CID
WHERE rc.GCID = 12345
```

### 8.3 Check if update succeeded
```sql
DECLARE @result bit
EXEC Customer.UpdateLei @gcid=12345, @lei=N'529900T8BM49AURSDO55'
-- Returns SELECT @Updated (1 or 0)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateLei | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateLei.sql*
