# Customer.UpdateCustomerStaticDltID

> Updates the DltID (Data Lineage Tracking ID) field on Customer.CustomerStatic for a given GCID, linking the record to a data lineage or downstream tracking system.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID - lookup key for CustomerStatic; @DltID - the tracking identifier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateCustomerStaticDltID is a targeted setter for the DltID field on Customer.CustomerStatic. DltID is a GUID that connects the customer's static record to a data lineage or downstream tracking system (the "Dlt" prefix suggests "Data Lineage Tracking" or similar). This unique identifier may be used to correlate eToro's customer records with an external system's record for the same customer.

The procedure exists as a dedicated setter so external systems can update this tracking ID without needing to call broader update procedures. @DltID defaults to NULL, allowing callers to clear the field.

---

## 2. Business Logic

### 2.1 DltID Assignment

**Rules**:
- UPDATE Customer.CustomerStatic SET DltID = @DltID WHERE GCID = @GCID
- @DltID defaults to NULL - passing NULL clears the DltID
- SET NOCOUNT ON suppresses row-count messages

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. Lookup key for CustomerStatic WHERE GCID=@GCID. |
| 2 | @DltID | uniqueidentifier | YES | NULL | CODE-BACKED | Data Lineage Tracking GUID. Maps to CustomerStatic.DltID. NULL clears the existing tracking ID. Used to link the customer to an external data lineage or tracking system record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.CustomerStatic | Modifier | Updates DltID column via GCID lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external system) | - | - | No intra-DB callers found; called from data lineage / external tracking integration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateCustomerStaticDltID (procedure)
└── Customer.CustomerStatic (table - UPDATE)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | UPDATE target for DltID column via GCID lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No intra-DB callers found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| NULL default | Design | @DltID = NULL by default; passing NULL clears the DltID field |

---

## 8. Sample Queries

### 8.1 Assign a DltID to a customer
```sql
EXEC Customer.UpdateCustomerStaticDltID
    @GCID = 67890,
    @DltID = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.2 Clear a customer's DltID
```sql
EXEC Customer.UpdateCustomerStaticDltID @GCID = 67890, @DltID = NULL;
```

### 8.3 Find customers with a DltID assigned
```sql
SELECT GCID, CID, DltID FROM Customer.CustomerStatic WITH (NOLOCK)
WHERE DltID IS NOT NULL ORDER BY GCID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.UpdateCustomerStaticDltID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateCustomerStaticDltID.sql*
