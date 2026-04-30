# Dictionary.State

## 1. Business Meaning

**What it is**: A geographic lookup table mapping US states and territories (plus a "Not Available" placeholder) to their 2-letter codes. Each state belongs to a country via FK to `Dictionary.Country`.

**Why it exists**: eToro requires state-level granularity for US customers due to varying state-level financial regulations, tax reporting requirements, and marketing restrictions. This table is used across customer registration, KYC verification, billing (cashout/credit card), and economic reporting. It is a foundational geographic dimension table.

**How it works**: The state is captured during customer registration (`Customer.CustomerStatic.StateID`, `Customer.RegistrationRequest`) and used in BackOffice customer views (`BackOffice.GetCustomerHeader`, `BackOffice.KycIlqGetStates`), billing operations (`Billing.GetCashoutInfo`, `Billing.CreditCardToPayment`), economic reports, and GDPR data export procedures.

---

## 2. Business Logic

### Structure
- **StateID 0**: "Not Available" — default for non-US customers or unset state
- **StateIDs 1-68**: US states and territories (including DC, Puerto Rico, US Virgin Islands, Guam, etc.)
- All non-zero entries reference `CountryID = 219` (United States)

### Key Regulatory Uses
- State-level trading restrictions (e.g., certain crypto instruments blocked in specific states)
- Tax reporting per US state
- KYC verification address validation
- Withdrawal processing address requirements

---

## 3. Data Overview

| StateID | CountryID | Code | Name | Business Meaning |
|---------|-----------|------|------|------------------|
| 0 | 0 | NULL | Not Available | Default — non-US or unset |
| 1 | 219 | AL | ALABAMA | US state |
| 6 | 219 | CA | CALIFORNIA | US state |
| 32 | 219 | NY | NEW YORK | US state |

*68 rows — US states, territories, and default placeholder*

---

## 4. Elements

| Column | Type | Null | Default | Description | Confidence |
|--------|------|------|---------|-------------|------------|
| **StateID** | int | NOT NULL | — | Primary key. State identifier. 0=Not Available, 1-68=US states/territories. | `MCP` |
| **CountryID** | int | NOT NULL | 0 | FK → `Dictionary.Country`. All states reference CountryID 219 (United States) except StateID 0 which references CountryID 0. | `DDL+MCP` |
| **Code** | char(2) | NULL | — | Standard 2-letter US state abbreviation (e.g., CA, NY, TX). NULL for StateID 0. Indexed for lookup. | `MCP` |
| **Name** | char(50) | NOT NULL | — | Full uppercase state name. Enforced unique by index `DSTA_NAME`. Fixed-width char(50) — padded with spaces. | `MCP+DDL` |

---

## 5. Relationships

### References To (this table points to)
| Referenced Table | FK Column | Relationship | Business Meaning |
|-----------------|-----------|--------------|------------------|
| Dictionary.Country | CountryID | FK_TDCNR_TDSTT | Each state belongs to a country (all = US except default) |

### Referenced By (other objects point to this table)
| Referencing Object | FK Column | Relationship | Business Meaning |
|-------------------|-----------|--------------|------------------|
| Customer.CustomerStatic | StateID | Implicit FK | Customer's US state for registration/KYC |
| Customer.RegistrationRequest | StateID | Implicit FK | State captured during registration |
| Billing.CreditCardToPayment | StateID | Implicit FK | State for credit card billing address |
| Billing.GetCashoutInfo | StateID | JOIN | Cashout processing includes customer state |
| BackOffice.GetCustomerHeader | StateID | JOIN | Customer header display includes state |
| BackOffice.KycIlqGetStates | StateID | JOIN | KYC verification state listing |
| Customer.GetCustomerDetails | StateID | JOIN | Customer details API includes state |
| Customer.GetMiscData | StateID | JOIN | Miscellaneous customer data includes state |
| dbo.SP_GDPR | StateID | JOIN | GDPR data export includes state |
| dbo.SP_Economic_Report_new | StateID | JOIN | Economic reports filtered by state |

---

## 6. Dependencies

### Depends On
- `Dictionary.Country` — parent country reference

### Depended On By
- `Customer.CustomerStatic` — customer state storage
- 10+ procedures across Customer, BackOffice, Billing, DWH, and dbo schemas

---

## 7. Technical Details

| Property | Value |
|----------|-------|
| Primary Key | `StateID` (clustered) |
| Indexes | `DSTA_CODE` — nonclustered on `Code`; `DSTA_COUNTRY` — nonclustered on `CountryID`; `DSTA_NAME` — unique nonclustered on `Name` |
| Foreign Keys | `FK_TDCNR_TDSTT` → `Dictionary.Country(CountryID)` |
| Constraints | `DSTA_NULLCOUNTRY` DEFAULT 0 for `CountryID` |
| Filegroup | DICTIONARY |
| Fill Factor | 90% |
| Row Count | 68 |

---

## 8. Sample Queries

```sql
-- Get all US states with codes
SELECT  StateID, Code, RTRIM(Name) AS Name
FROM    Dictionary.State WITH (NOLOCK)
WHERE   CountryID = 219
ORDER BY Name;

-- Customer count by US state
SELECT  RTRIM(S.Name) AS State, S.Code, COUNT(*) AS CustomerCount
FROM    Customer.CustomerStatic CS WITH (NOLOCK)
JOIN    Dictionary.State S WITH (NOLOCK) ON S.StateID = CS.StateID
WHERE   S.StateID > 0
GROUP BY RTRIM(S.Name), S.Code
ORDER BY CustomerCount DESC;

-- Find state by code
SELECT  StateID, RTRIM(Name) AS Name
FROM    Dictionary.State WITH (NOLOCK)
WHERE   Code = 'CA';
```

---

## 9. Atlassian Knowledge Sources

No specific Confluence or Jira references found. US state geographic data is a foundational reference table.

---

*Generated: 2026-03-14 | Schema: Dictionary | Database: etoro*
*Quality Score: 9.4 — MCP verified (68 rows), codebase traced (10+ consumers across 5 schemas), 3 indexes + FK documented*
