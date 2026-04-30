# BackOffice.GetCustomerByCIDVerification

> Returns a verification-focused subset of customer profile data (~40 fields) for KYC and identity-check workflows, without the financial calculations present in GetCustomerByCID.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - single customer lookup; returns TOP 1 with OPTION(Recompile) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides the customer data needed specifically for BackOffice verification and KYC (Know Your Customer) workflows. It returns the customer's identity details, registration data, account status flags, and verification/risk metadata - but unlike `GetCustomerByCID`, it does not calculate equity, unrealized PnL, or lifetime financial aggregates.

The simplified scope makes it faster and safer to call in verification-only contexts where the full financial calculation of `GetCustomerByCID` is unnecessary or too expensive. It is also the target of the `GetCustomerByCIDVerificationNotSafe` wrapper, which runs the query under `dbo` context to allow callers without direct BackOffice schema permissions.

Key additions over time:
- **April 2020 (COMOP-614, 774)**: Email field added - previously restricted from this SP for PII protection reasons
- **February 2026 (Merab Agniashvili)**: `OnboardingRiskClassificationID` added from BackOffice.Customer

Note: The `RiskStatusID` column appears twice in the SELECT (columns ~20 and ~27) - this is a historical duplicate artifact.

---

## 2. Business Logic

### 2.1 CountryIDByLastLoginIP via History.LoginArch

**What**: Resolves the country from the customer's most recent login IP, queried inline from History.LoginArch.

**Columns/Parameters Involved**: `CountryIDByLastLoginIP`, `History.LoginArch`, `Internal.GetCountryIDByIP`

**Rules**:
- Subquery finds MAX(LoginID) from History.LoginArch WHERE CID=@CID
- JOINs back to get the IP of that login
- Applies `Internal.GetCountryIDByIP(IP)` to resolve to a country ID
- ISNULL defaults to 0 if no login record found
- Same pattern as GetCustomerByCID

### 2.2 Age Calculation

**What**: Simple year-difference calculation without the birthday-not-yet-occurred correction from GetCustomerByCID.

**Columns/Parameters Involved**: `Age`, `CCST.BirthDate`

**Rules**:
- `IsNull(DateDiff(yy, CCST.BirthDate, GetDate()), 0) As Age`
- Unlike GetCustomerByCID, this does NOT apply the OA1 correction for the case where the birthday has not yet occurred this year
- May show age as 1 year too high for customers whose birthday falls later in the current year (the bug documented in RD-2585)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| **Input Parameters** | | | | | | |
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID to look up. Returns TOP 1 from Customer.Customer WHERE CID=@CID. |
| **Output Columns** | | | | | | |
| 2 | AccountClosedStatusID | INT | NO | 1 | CODE-BACKED | Account closure status. ISNULL(CCST.AccountStatusID, 1). Default 1 = account active/open. |
| 3 | AccountTypeID | INT | YES | - | CODE-BACKED | Account type (individual, corporate, etc.). From BackOffice.Customer.AccountTypeID. |
| 4 | Address | NVARCHAR | YES | - | CODE-BACKED | Customer street address. |
| 5 | BuildingNumber | NVARCHAR | YES | - | CODE-BACKED | Customer building/apartment number. |
| 6 | Age | INT | NO | 0 | CODE-BACKED | Approximate age in years: DateDiff(yy, BirthDate, GetDate()). Note: may be 1 year too high if birthday not yet occurred this year (birthday correction not applied here; see GetCustomerByCID). |
| 7 | BirthDate | DATE | YES | - | CODE-BACKED | Customer date of birth. |
| 8 | CID | INT | NO | - | CODE-BACKED | Customer ID. PK of Customer.Customer. |
| 9 | City | NVARCHAR | YES | - | CODE-BACKED | Customer city of residence. |
| 10 | Cleared | BIT | YES | - | CODE-BACKED | Account cleared flag. From BackOffice.Customer.Cleared. |
| 11 | Comment | NVARCHAR | YES | - | CODE-BACKED | Internal BackOffice comments. From Customer.Customer.Comments. |
| 12 | CountryIDByIP | INT | YES | - | CODE-BACKED | Country ID resolved from registration IP. From Customer.Customer.CountryIDByIP. |
| 13 | CountryID | INT | YES | - | CODE-BACKED | Customer's declared country of residence ID. |
| 14 | CountryIDByLastLoginIP | INT | NO | 0 | CODE-BACKED | Country ID resolved from the most recent login IP, via History.LoginArch and Internal.GetCountryIDByIP. 0 if no login record. |
| 15 | DocumentStatusID | INT | NO | 0 | CODE-BACKED | Document verification status ID. ISNULL(BCST.DocumentStatusID, 0). |
| 16 | FirstName | NVARCHAR | NO | - | CODE-BACKED | Customer first name. |
| 17 | MiddleName | NVARCHAR | YES | - | CODE-BACKED | Customer middle name. |
| 18 | FirstAndMiddleName | NVARCHAR | NO | - | CODE-BACKED | Computed: Customer.Customer.FirstName + ISNULL(' ' + MiddleName, ''). |
| 19 | Gender | INT | YES | - | CODE-BACKED | Gender code. |
| 20 | IsReal | BIT | NO | - | CODE-BACKED | 1 = real money account; 0 = demo account. |
| 21 | LastName | NVARCHAR | NO | - | CODE-BACKED | Customer last name. |
| 22 | ManagerID | INT | YES | - | CODE-BACKED | BackOffice manager assigned to this account. From BackOffice.Customer.ManagerID. |
| 23 | OriginalCID | INT | YES | - | CODE-BACKED | Original CID before account migration or merge. |
| 24 | OriginalProviderID | INT | YES | - | CODE-BACKED | Original acquisition provider ID. |
| 25 | PhoneVerificationID | INT | NO | 0 | CODE-BACKED | Phone verification status. ISNULL(BCST.PhoneVerifiedID, 0). 0 = unverified. |
| 26 | PendingClosureStatusID | INT | NO | 1 | CODE-BACKED | Pending account closure pipeline status. ISNULL(CCST.PendingClosureStatusID, 1). |
| 27 | PendingManagerID | INT | YES | - | CODE-BACKED | FTD (first-time deposit) pool manager awaiting assignment. From BackOffice.Customer.FTDPoolManagerID. |
| 28 | PlayerLevelID | INT | YES | - | CODE-BACKED | Customer tier level ID. FK to Dictionary.PlayerLevel. |
| 29 | PlayerStatusID | INT | YES | - | CODE-BACKED | Customer trading status ID. FK to Dictionary.PlayerStatus. |
| 30 | ProviderID | INT | YES | - | CODE-BACKED | Current acquisition provider ID. |
| 31 | RegistrationDate | DATETIME | NO | - | CODE-BACKED | Date/time the customer registered. From Customer.Customer.Registered. |
| 32 | RegistrationIP | VARCHAR | YES | - | CODE-BACKED | IP address at registration time. From Customer.Customer.IP. |
| 33 | RiskStatusID | INT | YES | - | CODE-BACKED | AML/risk status of the account. From BackOffice.Customer.RiskStatusID. Note: this column appears twice in the SELECT (duplicate artifact). |
| 34 | TradeLevelID | INT | YES | - | CODE-BACKED | Trading level assignment. |
| 35 | UserName | NVARCHAR | NO | - | CODE-BACKED | Customer eToro login username. |
| 36 | VerificationLevelID | INT | YES | - | CODE-BACKED | Current KYC verification level. From BackOffice.Customer.VerificationLevelID. |
| 37 | WorldCheckStatusID | INT | YES | - | CODE-BACKED | World-Check (sanctions/PEP screening) result. From BackOffice.Customer.WorldCheckID. |
| 38 | Zip | NVARCHAR | YES | - | CODE-BACKED | Customer postal/zip code. |
| 39 | GCID | INT | NO | 0 | CODE-BACKED | Global Customer ID. ISNULL(CCST.GCID, 0). |
| 40 | Citizenship | INT | YES | - | CODE-BACKED | Citizenship country ID. From Customer.Customer.CitizenshipCountryID. Note: present here but commented out in GetCustomerByCID. |
| 41 | StateID | INT | YES | - | CODE-BACKED | Customer state/province ID. |
| 42 | Email | NVARCHAR | YES | - | CODE-BACKED | Customer email address. Added April 2020 (COMOP-614, 774) after previously being restricted from this SP. |
| 43 | OnboardingRiskClassificationID | INT | YES | - | CODE-BACKED | Risk classification assigned during onboarding. From BackOffice.Customer.OnboardingRiskClassificationID. Added February 2026. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Primary Source | Identity, registration, and personal fields |
| @CID | BackOffice.Customer | Primary Source | BO administrative state: verification, risk, manager |
| CID | History.LoginArch | Subquery | Subquery to resolve most recent login IP to country ID |
| IP | Internal.GetCountryIDByIP | Scalar function | Resolves login IP to country ID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetCustomerByCIDVerificationNotSafe | EXEC call | Wrapper / Permission elevation | Calls this procedure under EXECUTE AS 'dbo' to allow callers without BackOffice schema permissions. Created Dec 2017 (case 49860). |
| BackOffice application (BO) | N/A | Application call | Called for verification-only workflows where full financial data from GetCustomerByCID is not needed |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCustomerByCIDVerification (procedure)
|- Customer.Customer (identity + platform fields)
|- BackOffice.Customer (BO administrative state)
|- History.LoginArch (last login IP -> country subquery)
+-- Internal.GetCountryIDByIP (scalar function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | Primary source for identity, registration, and personal fields |
| BackOffice.Customer | Table | BO-specific state: verification level, document status, manager, risk |
| History.LoginArch | Table | Subquery to find most recent login IP for CountryIDByLastLoginIP |
| Internal.GetCountryIDByIP | Scalar Function | Resolves login IP to country ID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCustomerByCIDVerificationNotSafe | Stored Procedure | Wrapper that calls this SP under dbo execution context |
| BackOffice application (BO) | External application | Verification and KYC workflow data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- `OPTION(Recompile)`: Forces plan recompilation each execution to avoid parameter sniffing issues.
- `SELECT TOP 1`: Defensive guard; Customer.Customer should have exactly one row per CID.
- `WITH(NOLOCK)`: Applied to both source tables; accepts potentially stale reads for performance.

---

## 8. Sample Queries

### 8.1 Get verification data for a customer

```sql
EXEC BackOffice.GetCustomerByCIDVerification @CID = 12345678;
```

### 8.2 Call via the permission-elevated wrapper

```sql
-- For callers without direct BackOffice schema permissions:
EXEC BackOffice.GetCustomerByCIDVerificationNotSafe @CID = 12345678;
```

### 8.3 Direct base-table verification query

```sql
SELECT
    c.CID, c.FirstName, c.LastName, c.Email, c.BirthDate,
    c.CountryID, c.IsReal, c.Registered,
    bc.VerificationLevelID, bc.DocumentStatusID,
    bc.RiskStatusID, bc.WorldCheckID,
    bc.OnboardingRiskClassificationID
FROM Customer.Customer c WITH(NOLOCK)
LEFT JOIN BackOffice.Customer bc WITH(NOLOCK) ON bc.CID = c.CID
WHERE c.CID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

No Confluence or Jira records found specifically for this procedure. Context: email was added via COMOP-614 and COMOP-774 (April 2020), likely from a compliance initiative requiring email to be visible in the verification workflow. The NotSafe wrapper was created Dec 2017 (case 49860) to resolve a permission escalation pattern.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 42 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10, 11 executed; 9B skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCustomerByCIDVerification | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCustomerByCIDVerification.sql*
