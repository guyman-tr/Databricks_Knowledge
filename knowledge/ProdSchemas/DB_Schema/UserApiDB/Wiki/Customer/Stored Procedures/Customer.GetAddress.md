# Customer.GetAddress

> Returns all addresses for a user from the Customer_Address table, including address type, region, and temporal validity.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetAddress retrieves all address records for a user from the Customer_Address dbo table. A user may have multiple address types (residential, mailing/W-8BEN). Returns address details including country, region, sub-region, street, city, zip, building number, and temporal validity (BeginTime/EndTime for system versioning).

---

## 2. Business Logic

No complex business logic. Single SELECT with NOLOCK.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int (IN) | NO | - | CODE-BACKED | Global Customer ID. |

Output columns: GCID, AddressTypeID, CountryID, RegionID, SubRegionID, Address, City, Zip, BuildingNumber, BeginTime, EndTime.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer_Address (dbo) | SELECT FROM | Reads address records |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetAddress (procedure)
  +-- Customer_Address (dbo table, external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer_Address | dbo table | SELECT FROM |

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

### 8.1 Get addresses
```sql
EXEC Customer.GetAddress @GCID = 12345
```

### 8.2 Direct query with country name
```sql
SELECT a.*, c.Name AS Country FROM Customer_Address a WITH (NOLOCK) JOIN Dictionary.Country c WITH (NOLOCK) ON a.CountryID = c.CountryID WHERE a.GCID = 12345
```

### 8.3 Current addresses only
```sql
SELECT * FROM Customer_Address WITH (NOLOCK) WHERE GCID = 12345 AND EndTime > GETUTCDATE()
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetAddress | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetAddress.sql*
