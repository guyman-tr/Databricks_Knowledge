# Customer.GetDemography

> Demographic data slice from Customer.Customer: 21 columns covering identity, classification, and contact PII (with password masked) - used for demographic reporting and analytics.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | View |
| **Key Identifier** | CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetDemography is a narrow projection from Customer.Customer (WITH NOLOCK) that selects the 21 most commonly needed demographic fields: customer identifiers (CID, ProviderID), geographic classification (CountryID, StateID, LanguageID, CurrencyID, TimeZoneID, PlayerLevelID), authentication (UserName, Password=masked), and contact/PII (BirthDate, Gender, FirstName, LastName, Address, City, Zip, Email, Phone, Fax, Mobile).

The name reflects its purpose: a "demographics" read - who the customer is, where they are, and their contact details - without financial, trading, or compliance fields. This is a safe subset for analytics, reporting, and external data export pipelines that need customer profile data but not balance or trading configuration.

Password is replaced with `'' as Password` (same masking pattern as CustomerSafty). All other columns inherit their full semantics from Customer.Customer and CustomerStatic.

---

## 2. Business Logic

No complex multi-column business logic patterns. This is a simple SELECT projection. See Customer.Customer Section 2 for base table business logic. See individual element descriptions in Section 4.

---

## 3. Data Overview

Data is a subset of Customer.Customer - same rows, 21 of 86 columns. See Customer.Customer Section 3 for representative data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer ID. From Customer.Customer. |
| 2 | ProviderID | int | NO | - | VERIFIED | Trading provider ID. From Customer.Customer. |
| 3 | CountryID | int | NO | - | VERIFIED | Country of residence. From Customer.Customer. FK to Dictionary.Country. |
| 4 | StateID | int | NO | - | VERIFIED | US state ID or 0. From Customer.Customer. |
| 5 | LanguageID | int | NO | - | VERIFIED | Platform language preference. From Customer.Customer. FK to Dictionary.Language. |
| 6 | CurrencyID | int | NO | - | VERIFIED | Account base currency. From Customer.Customer. FK to Dictionary.Currency. |
| 7 | TimeZoneID | int | NO | - | VERIFIED | Time zone. From Customer.Customer. |
| 8 | PlayerLevelID | int | NO | - | VERIFIED | Customer tier (standard/PI/VIP). From Customer.Customer. FK to Dictionary.PlayerLevel. |
| 9 | UserName | varchar(20) | NO | - | VERIFIED | Login username. From Customer.Customer. |
| 10 | Password | varchar | NO | - | VERIFIED | Always empty string ''. Masked - never returns the actual hash. |
| 11 | BirthDate | datetime | YES | - | VERIFIED | Date of birth (Dynamic Data Masking on base). From Customer.Customer. |
| 12 | Gender | char(1) | YES | - | VERIFIED | Gender: 'M', 'F', 'U'. From Customer.Customer. |
| 13 | FirstName | nvarchar(50) | YES | - | VERIFIED | First name (Dynamic Data Masking). From Customer.Customer. |
| 14 | LastName | nvarchar(50) | YES | - | VERIFIED | Last name (Dynamic Data Masking). From Customer.Customer. |
| 15 | Address | nvarchar(100) | YES | - | VERIFIED | Street address (Dynamic Data Masking). From Customer.Customer. |
| 16 | City | nvarchar(50) | YES | - | CODE-BACKED | City. From Customer.Customer. |
| 17 | Zip | nvarchar(50) | YES | - | VERIFIED | Postal code (Dynamic Data Masking). From Customer.Customer. |
| 18 | Email | varchar(50) | YES | - | VERIFIED | Email (Dynamic Data Masking). From Customer.Customer. |
| 19 | Phone | varchar(30) | YES | - | VERIFIED | Phone (Dynamic Data Masking). From Customer.Customer. |
| 20 | Fax | varchar(30) | YES | - | CODE-BACKED | Fax. From Customer.Customer. |
| 21 | Mobile | varchar(30) | YES | - | VERIFIED | Mobile (Dynamic Data Masking). From Customer.Customer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.Customer | FROM (base view, NOLOCK) | All 21 columns sourced from Customer.Customer |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetDemography (view)
└── Customer.Customer (view)
      ├── Customer.CustomerStatic (table)
      └── Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM (base view) - 21 columns selected |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None. No SCHEMABINDING declared.

---

## 8. Sample Queries

### 8.1 Get demographic data for a specific customer
```sql
SELECT CID, CountryID, StateID, LanguageID, PlayerLevelID, Gender, BirthDate
FROM Customer.GetDemography WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.2 Count customers by country and gender
```sql
SELECT CountryID, Gender, COUNT(*) AS CustomerCount
FROM Customer.GetDemography WITH (NOLOCK)
WHERE Gender IN ('M', 'F')
GROUP BY CountryID, Gender
ORDER BY CountryID, Gender;
```

### 8.3 Find customers by email (case-insensitive match)
```sql
SELECT CID, UserName, Email, CountryID, PlayerLevelID
FROM Customer.GetDemography WITH (NOLOCK)
WHERE lower(Email) = lower('user@example.com');
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 18 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,7,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (view) | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetDemography | Type: View | Source: etoro/etoro/Customer/Views/Customer.GetDemography.sql*
