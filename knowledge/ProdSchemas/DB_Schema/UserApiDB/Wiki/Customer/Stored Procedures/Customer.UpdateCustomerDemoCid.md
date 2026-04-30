# Customer.UpdateCustomerDemoCid

> Updates the DemoCID in Customer.CustomerIdentification - links a demo account CID to a customer's GCID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Customer.CustomerIdentification SET DemoCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateCustomerDemoCid updates the demo account CID link in Customer.CustomerIdentification. Called by InsertNewDemoCustomer after creating a demo account to link it to the customer's global identity.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple single-column UPDATE.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @DemoCid | int | NO | - | CODE-BACKED | Demo account CID to link. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.CustomerIdentification | UPDATE | Sets DemoCID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.InsertNewDemoCustomer | - | EXEC | Links demo CID after creation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateCustomerDemoCid (procedure)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | UPDATE |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.InsertNewDemoCustomer | Procedure | EXEC |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Link demo CID
```sql
EXEC Customer.UpdateCustomerDemoCid @GCID=50001, @DemoCid=200001
```

### 8.2 Verify
```sql
SELECT GCID, CID, DemoCID FROM Customer.CustomerIdentification WITH (NOLOCK) WHERE GCID = 50001
```

### 8.3 Check demo link
```sql
SELECT ci.GCID, ci.CID AS RealCID, ci.DemoCID
FROM Customer.CustomerIdentification ci WITH (NOLOCK)
WHERE ci.GCID = 50001
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateCustomerDemoCid | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateCustomerDemoCid.sql*
