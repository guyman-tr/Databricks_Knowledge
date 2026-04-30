# Trade.GetExtetendedCustomerDataByGCID

> Returns extended customer personal data (name, address, city, state, zip, username) by Global Customer ID. Note: procedure name has a typo ("Extetended" instead of "Extended").

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | CID (customer identifier) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns extended personal data for a customer identified by Global Customer ID (GCID). It answers "what is this customer's name, address, and username?" for workflows that need human-readable customer information for display, correspondence, or compliance. Without it, callers would need to join Customer.CustomerStatic and Dictionary.State themselves and select the relevant columns. It exists to provide a single-parameter lookup for customer profile data across schemas. The procedure is called when a UI or service needs to display or validate customer address and identity info by GCID. Data flows from Customer.CustomerStatic (customer core) and Dictionary.State (state name lookup) into a single-row result with aliased columns (e.g., Address as Street).

---

## 2. Business Logic

### 2.1 GCID Lookup and Address Assembly

**What**: Fetch customer row by GCID and resolve StateID to state name for address display.

**Columns/Parameters Involved**: `@GCID`, `c.CID`, `c.StateID`, `s.Name`

**Rules**:
- Filter Customer.CustomerStatic by c.GCID = @GCID.
- JOIN to Dictionary.State on c.StateID = s.StateID to get state name.
- Output columns: CID, FirstName, LastName, BuildingNumber, Street (aliased from Address), City, State (aliased from s.Name), Zip, UserName.
- At most one row per GCID (GCID is a unique customer identifier).

**Diagram**:
```
@GCID --> Customer.CustomerStatic (c) --> c.GCID = @GCID
                     |
                     JOIN Dictionary.State (s) ON c.StateID = s.StateID
                     |
                     v
        CID, FirstName, LastName, BuildingNumber, Street, City, State, Zip, UserName
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | - | - | CODE-BACKED | Global Customer ID. Unique identifier for the customer. Caller provides this to fetch extended profile. |
| 2 | CID | INT | - | - | CODE-BACKED | Output. Customer identifier from CustomerStatic. |
| 3 | FirstName | - | - | - | CODE-BACKED | Output. Customer first name. |
| 4 | LastName | - | - | - | CODE-BACKED | Output. Customer last name. |
| 5 | BuildingNumber | - | - | - | CODE-BACKED | Output. Building or street number component of address. |
| 6 | Street | - | - | - | CODE-BACKED | Output. Aliased from c.Address. Street name or full street line. |
| 7 | City | - | - | - | CODE-BACKED | Output. Customer city. |
| 8 | State | - | - | - | CODE-BACKED | Output. Aliased from s.Name. State or region name from Dictionary.State. |
| 9 | Zip | - | - | - | CODE-BACKED | Output. Postal or zip code. |
| 10 | UserName | - | - | - | CODE-BACKED | Output. Customer username. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| c | Customer.CustomerStatic | Table | Source of customer data. Filtered by GCID. |
| c.StateID | Dictionary.State | Lookup | Resolves StateID to state name. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetExtetendedCustomerDataByGCID (procedure)
├── Customer.CustomerStatic (table)
└── Dictionary.State (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FROM, WHERE c.GCID = @GCID. Source of customer profile. |
| Dictionary.State | Table | JOIN on StateID. Source of state name. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Not analyzed in this phase | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

### 7.3 Query Hints

| Hint | Usage |
|------|-------|
| NOLOCK | Applied to Customer.CustomerStatic for read-only consistency. |

---

## 8. Sample Queries

### 8.1 Get extended customer data by GCID

```sql
EXEC Trade.GetExtetendedCustomerDataByGCID @GCID = 12345;
```

### 8.2 Equivalent inline query for verification

```sql
DECLARE @GCID INT = 12345;

SELECT c.CID, c.FirstName, c.LastName, c.BuildingNumber,
       c.Address AS Street, c.City, s.Name AS State, c.Zip, c.UserName
FROM Customer.CustomerStatic c WITH (NOLOCK)
JOIN Dictionary.State s WITH (NOLOCK) ON c.StateID = s.StateID
WHERE c.GCID = @GCID;
```

### 8.3 Use result to populate an address block

```sql
DECLARE @GCID INT = 12345;

CREATE TABLE #Cust (CID INT, FirstName NVARCHAR(255), LastName NVARCHAR(255), BuildingNumber NVARCHAR(50),
    Street NVARCHAR(255), City NVARCHAR(100), State NVARCHAR(100), Zip NVARCHAR(20), UserName NVARCHAR(255));
INSERT INTO #Cust EXEC Trade.GetExtetendedCustomerDataByGCID @GCID;

SELECT CONCAT(FirstName, ' ', LastName) AS FullName,
       CONCAT(BuildingNumber, ' ', Street, ', ', City, ', ', State, ' ', Zip) AS FullAddress,
       UserName
FROM #Cust;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetExtetendedCustomerDataByGCID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetExtetendedCustomerDataByGCID.sql*
