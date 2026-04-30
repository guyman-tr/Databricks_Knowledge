# Billing.GetUserFor3ds

> Returns a customer's personal and address details (name, email, phone, address, zip, city, country abbreviation, ISO code) for 3D Secure (3DS) authentication payload construction during credit card deposits.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Cid; returns one row with personal + address + country data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetUserFor3ds fetches the customer profile data required to construct the 3D Secure (3DS) authentication request when processing a credit card deposit. 3DS is the additional authentication layer (e.g., Verified by Visa, Mastercard SecureCode) that requires the cardholder to authenticate with their bank before the transaction is approved.

The 3DS protocol requires the merchant to submit cardholder personal data (name, email, phone, billing address) and country identification (ISO code, country abbreviation) alongside the payment request. This procedure provides that data from the eToro customer record.

Key fields:
- **Name fields**: `FirstName`, `LastName` - cardholder identity for 3DS
- **Contact**: `Email`, `Phone` - for OTP delivery and cardholder verification
- **Address**: `Address`, `Zip`, `City` - billing address for 3DS address verification
- **Country codes**: `Abbreviation` (2/3-letter abbreviation) AS `CountryAbbreviation`, `IsoCode` - required by payment gateway in specific formats

Referenced in multiple Confluence spaces including "Routing Tool - 3DS" and "Credit card deposit flow" (MG), confirming the 3DS payment context.

---

## 2. Business Logic

### 2.1 Customer Data Fetch for 3DS Payload

**What**: Single query joining CustomerStatic to Dictionary.Country to assemble the 3DS request fields.

**Columns/Parameters Involved**: `Customer.CustomerStatic`, `Dictionary.Country`, `@Cid`

**Rules**:
- `INNER JOIN Dictionary.Country ON CustomerStatic.CountryID = Country.CountryID`
- INNER JOIN (not LEFT): if the customer has no country or country not in Dictionary.Country, no row is returned
- Returns: `FirstName`, `LastName`, `Email`, `Phone`, `Address`, `Zip`, `City`, `Abbreviation AS CountryAbbreviation`, `IsoCode`
- Source: `Customer.CustomerStatic` (not Customer.Customer) - the static profile data optimized for reads

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Cid | INT | NO | - | CODE-BACKED | Customer ID. Joins CustomerStatic to retrieve personal and address data. |
| - | FirstName | NVARCHAR | YES | - | CODE-BACKED | Customer's first name from Customer.CustomerStatic. Submitted to payment gateway as cardholder first name in 3DS request. |
| - | LastName | NVARCHAR | YES | - | CODE-BACKED | Customer's last name from Customer.CustomerStatic. Submitted as cardholder last name in 3DS request. |
| - | Email | NVARCHAR | YES | - | CODE-BACKED | Customer's email address from Customer.CustomerStatic. Used by 3DS for OTP delivery and cardholder verification. |
| - | Phone | NVARCHAR | YES | - | CODE-BACKED | Customer's phone number from Customer.CustomerStatic. Used for 3DS out-of-band authentication (SMS OTP). |
| - | Address | NVARCHAR | YES | - | CODE-BACKED | Customer's street address from Customer.CustomerStatic. Submitted as billing address in 3DS request for address verification. |
| - | Zip | NVARCHAR | YES | - | CODE-BACKED | Customer's postal/zip code from Customer.CustomerStatic. Part of billing address for 3DS. |
| - | City | NVARCHAR | YES | - | CODE-BACKED | Customer's city from Customer.CustomerStatic. Part of billing address for 3DS. |
| - | CountryAbbreviation | VARCHAR | YES | - | CODE-BACKED | Country abbreviation from Dictionary.Country.Abbreviation (aliased). 2 or 3-letter country code submitted to payment gateway in 3DS request format. |
| - | IsoCode | VARCHAR | YES | - | CODE-BACKED | Country ISO code from Dictionary.Country.IsoCode. Numeric or alpha ISO country code for 3DS compliance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, FirstName, LastName, Email, Phone, Address, Zip, City, CountryID | Customer.CustomerStatic | SELECT | Primary source of cardholder personal and address data |
| CountryID, Abbreviation, IsoCode | Dictionary.Country | INNER JOIN | Resolves country abbreviation and ISO code from the customer's CountryID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Credit card deposit service (3DS flow) | @Cid | EXEC | Fetches cardholder data to construct the 3DS authentication request before submitting to payment gateway |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetUserFor3ds (procedure)
+-- Customer.CustomerStatic (table) [personal + address data]
+-- Dictionary.Country (table) [country abbreviation + ISO code]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FirstName, LastName, Email, Phone, Address, Zip, City, CountryID for 3DS payload |
| Dictionary.Country | Table | INNER JOIN for Abbreviation (as CountryAbbreviation) and IsoCode |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Credit card 3DS authentication service | External | Cardholder data for 3DS request construction during credit card deposit flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| INNER JOIN on Country | Design | Returns no row if customer has no CountryID or CountryID not in Dictionary.Country; caller must handle empty result |
| No NOLOCK | Concurrency | No WITH (NOLOCK) hints; reads committed data - ensures accurate personal data for 3DS |
| CustomerStatic (not Customer) | Design | Uses Customer.CustomerStatic for personal data rather than Customer.Customer - optimized for profile reads |

---

## 8. Sample Queries

### 8.1 Fetch 3DS data for a customer

```sql
EXEC [Billing].[GetUserFor3ds] @Cid = 12345
-- Returns: FirstName, LastName, Email, Phone, Address, Zip, City,
--          CountryAbbreviation, IsoCode
-- Used by the credit card deposit service to build the 3DS request
```

### 8.2 Equivalent direct query

```sql
SELECT
    cu.FirstName, cu.LastName, cu.Email, cu.Phone,
    cu.[Address], cu.Zip, cu.City,
    co.Abbreviation AS CountryAbbreviation,
    co.IsoCode
FROM [Customer].[CustomerStatic] cu WITH (NOLOCK)
INNER JOIN [Dictionary].[Country] co WITH (NOLOCK) ON cu.CountryID = co.CountryID
WHERE cu.CID = 12345
```

---

## 9. Atlassian Knowledge Sources

**Confluence**:
- "Routing Tool - 3DS" (/spaces/MG) - 3DS routing logic that uses this procedure's output
- "Billing Service Database Readonly Separation" (/spaces/MG) - procedure in read-only billing service API
- "Credit card deposit flow" (/spaces/MG) - end-to-end credit card deposit flow documentation including 3DS step
- "Credit Card Migration Code Analysis" (/spaces/MG) - credit card code migration analysis

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.2/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 9.5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 4 Confluence (Routing Tool-3DS, Billing Service DB Readonly Sep, Credit card deposit flow, CC Migration) + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetUserFor3ds | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetUserFor3ds.sql*
