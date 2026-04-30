# Customer.IsEToroCountry

> Checks whether a customer (by username) belongs to the special 'eToro' virtual country in Dictionary.Country, returning the result as a BIT output parameter.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Username -> @IsEToroCountry (OUTPUT BIT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.IsEToroCountry determines whether a customer's registered country is the special 'eToro' virtual country. The 'eToro' entry in Dictionary.Country is a platform-specific country used for internal or system-type accounts that do not belong to a real geographic country (e.g., employee test accounts, system users, internal trading accounts). By checking this flag, services can distinguish these special accounts from regular retail customers.

The check is performed by username (not CID), making it useful in login flows or username-based pipelines where the CID is not yet known. The result is returned via an OUTPUT BIT parameter: 1 = eToro country, 0 = regular country.

---

## 2. Business Logic

### 2.1 eToro Virtual Country Check

**What**: Identifies whether a customer belongs to the special 'eToro' internal virtual country.

**Columns/Parameters Involved**: `@Username`, `Customer.Customer.CountryID`, `Dictionary.Country.Name`

**Rules**:
- The 'eToro' country is looked up dynamically by name from Dictionary.Country: `WHERE Name = 'eToro'`
- If the customer's CountryID matches this virtual country's ID: @IsEToroCountry = 1
- Otherwise: @IsEToroCountry = 0
- The username lookup uses Customer.Customer.UserName (exact case, not UserName_LOWER) - callers should pass the correct-case username or the check may fail

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Username | varchar(24) | NO | - | VERIFIED | Customer's username to check. Used in WHERE UserName = @Username against Customer.Customer. Case-sensitive match (not using UserName_LOWER). |
| 2 | @IsEToroCountry | bit (OUTPUT) | NO | - | VERIFIED | Output parameter: 1 = the customer's CountryID matches the 'eToro' virtual country in Dictionary.Country; 0 = regular country. Indicates whether the customer is a special internal/system account. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Username -> CountryID | Customer.Customer | Reader (EXISTS) | Fetches the customer's CountryID by username |
| 'eToro' country | Dictionary.Country | Reader (SELECT) | Looks up the CountryID for the virtual 'eToro' country by Name='eToro' |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD_BIadmins | EXECUTE permission | Caller | BI administrators use for account classification checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.IsEToroCountry (procedure)
├── Customer.Customer (view)
│     ├── Customer.CustomerStatic (table)
│     └── Customer.CustomerMoney (table)
└── Dictionary.Country (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | EXISTS check - fetches CountryID WHERE UserName = @Username |
| Dictionary.Country | Table | SELECT CountryID WHERE Name = 'eToro' - identifies the virtual country ID |

### 6.2 Objects That Depend On This

No dependents found in the codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check if a username belongs to the eToro virtual country
```sql
DECLARE @isEtoro BIT;
EXEC Customer.IsEToroCountry @Username = 'someinternaluser', @IsEToroCountry = @isEtoro OUTPUT;
SELECT @isEtoro AS IsEToroCountry;  -- 1 = eToro internal, 0 = regular customer
```

### 8.2 Direct equivalent query for debugging
```sql
SELECT CASE WHEN EXISTS (
    SELECT CountryID
    FROM Customer.Customer WITH (NOLOCK)
    WHERE UserName = 'someinternaluser'
      AND CountryID = (SELECT CountryID FROM Dictionary.Country WITH (NOLOCK) WHERE Name = 'eToro')
) THEN 1 ELSE 0 END AS IsEToroCountry;
```

### 8.3 Find the eToro virtual country ID
```sql
SELECT CountryID, Name
FROM Dictionary.Country WITH (NOLOCK)
WHERE Name = 'eToro';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.IsEToroCountry | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.IsEToroCountry.sql*
