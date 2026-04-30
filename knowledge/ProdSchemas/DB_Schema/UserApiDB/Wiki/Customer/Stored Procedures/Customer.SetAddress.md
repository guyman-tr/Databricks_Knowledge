# Customer.SetAddress

> Upserts a customer's address by type (e.g., mailing address) in dbo.Customer_Address - inserts if no record exists for the GCID+AddressTypeID combination, updates if one does.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPSERT on dbo.Customer_Address by GCID + AddressTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SetAddress saves or updates a customer's address record for a specific address type. This supports W8BEN tax form requirements (RD-12304/12501/16255, Nov 2019) where customers need a mailing address separate from their primary contact address. The address type system allows multiple addresses per customer (e.g., residential, mailing, business).

The procedure uses an IF EXISTS / UPDATE / ELSE INSERT pattern on dbo.Customer_Address, keyed by GCID + AddressTypeID.

---

## 2. Business Logic

### 2.1 UPSERT by Address Type

**What**: One address per customer per type.

**Rules**:
- IF EXISTS (GCID + AddressTypeID): UPDATE all address fields
- ELSE: INSERT new record
- Each AddressTypeID represents a different address category

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @AddressTypeID | int | NO | - | CODE-BACKED | Address type (e.g., mailing, residential). |
| 3 | @CountryID | int | NO | - | CODE-BACKED | Country. FK to Dictionary.Country. |
| 4 | @RegionID | int | NO | - | CODE-BACKED | Region. |
| 5 | @SubRegionID | int | NO | - | CODE-BACKED | Sub-region. |
| 6 | @Address | nvarchar(255) | NO | - | CODE-BACKED | Street address. |
| 7 | @City | nvarchar(50) | NO | - | CODE-BACKED | City. |
| 8 | @Zip | nvarchar(50) | NO | - | CODE-BACKED | Postal/ZIP code. |
| 9 | @BuildingNumber | nvarchar(30) | NO | - | CODE-BACKED | Building/house number. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | dbo.Customer_Address | UPSERT | Address storage by type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Address management / W8BEN |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetAddress (procedure)
+-- dbo.Customer_Address (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Customer_Address | Table | UPSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Set mailing address
```sql
EXEC Customer.SetAddress @GCID=12345, @AddressTypeID=2, @CountryID=234,
    @RegionID=1, @SubRegionID=0, @Address=N'123 Main St', @City=N'New York',
    @Zip=N'10001', @BuildingNumber=N'123'
```

### 8.2 Read address back
```sql
SELECT * FROM dbo.Customer_Address WITH (NOLOCK) WHERE GCID = 12345
```

### 8.3 Get address by type
```sql
SELECT * FROM dbo.Customer_Address WITH (NOLOCK) WHERE GCID = 12345 AND AddressTypeID = 2
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.SetAddress | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.SetAddress.sql*
