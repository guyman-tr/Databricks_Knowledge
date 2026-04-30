# BackOffice.CustomerSafty

> Schema-bound view exposing the compliance, regulatory, and sales management columns of BackOffice.Customer while deliberately excluding personal identity data (name, email, address) for access-controlled consumption.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | CID (from BackOffice.Customer) |
| **Partition** | N/A |
| **Indexes** | Possible indexed view (SCHEMABINDING) |

---

## 1. Business Meaning

`BackOffice.CustomerSafty` (note: "Safety" is misspelled as "Safty" in the object name - this is a legacy naming artifact) is a schema-bound view over `BackOffice.Customer` that exposes 28 compliance, regulatory, and sales-management columns while excluding personal identity fields (customer name, email, date of birth, address, country, etc.) from `BackOffice.Customer`.

The view is defined `WITH SCHEMABINDING`, which means:
1. The underlying `BackOffice.Customer` table cannot be dropped or have the referenced columns altered while this view exists.
2. It is eligible to be used as an indexed view (if a unique clustered index is added).

This view acts as a data-access boundary: systems or roles with read access to `BackOffice.CustomerSafty` can query operational compliance state without being able to read PII columns like customer names. It is a separation-of-concerns pattern - compliance/sales state is "safe" to expose broadly, while personal data requires tighter access.

---

## 2. Business Logic

### 2.1 PII-Filtered Projection of BackOffice.Customer

**What**: Projects only non-PII operational fields from BackOffice.Customer.

**Columns Included**: CID, SalesStatusID, ManagerID, IsAffiliate, Cleared, Verified, FTDPoolManagerID, PreviousManagerID, FXEligibilityDate, AffiliateManagerID, CashoutFeeGroupID, ChangePassword, RiskStatusID, WorldCheckID, isEmployeeAccount, AccountTypeID, MasterAccountCID, ManagerPermitID, ThirdPartyManagerComment, GuruStatusID, RiskClassificationID, AcceptanceStatusID, VerificationLevelID, RegulationID, DocumentStatusID, PhoneVerifiedID, AcceptanceStatusChanginManagerID, GDCCheckID, RegulationChangeDate

**Columns Excluded** (PII and other columns from BackOffice.Customer): Customer name, email, date of birth, country, address, phone, national ID, and any other personal identity data not listed above.

**Rules**:
- No filter predicate - all 18.744M rows in BackOffice.Customer appear.
- No computed columns - all values are direct projections.
- SCHEMABINDING prevents underlying schema changes that would break this view.

---

## 3. Data Overview

Matches `BackOffice.Customer` row count: 18.744M rows as of 2026-03-17 (one per CID).

---

## 4. Elements

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | CID | int | CODE-BACKED | Customer ID - primary key. Matches BackOffice.Customer.CID. |
| 2 | SalesStatusID | int | CODE-BACKED | Customer's current sales stage (e.g., New Lead, Contacted, FTD). FK to Dictionary.SalesStatus. |
| 3 | ManagerID | int | CODE-BACKED | Assigned back-office sales manager. FK to BackOffice.Manager.ManagerID. |
| 4 | IsAffiliate | bit | CODE-BACKED | Whether this customer is registered as an affiliate (partner). |
| 5 | Cleared | bit | CODE-BACKED | AML cleared flag - customer has passed AML/compliance screening. |
| 6 | Verified | bit | CODE-BACKED | Legacy verification flag (distinct from VerificationLevelID). |
| 7 | FTDPoolManagerID | int | CODE-BACKED | Manager who receives first-time deposit attribution. |
| 8 | PreviousManagerID | int | CODE-BACKED | Prior sales manager before last reassignment. |
| 9 | FXEligibilityDate | datetime | CODE-BACKED | Date from which the customer is eligible for FX/forex trading. |
| 10 | AffiliateManagerID | int | CODE-BACKED | Manager associated with the customer's affiliate relationship. |
| 11 | CashoutFeeGroupID | int | CODE-BACKED | Cashout fee tier. FK to Dictionary.CashoutFeeGroup (Default, Exempt, etc.). |
| 12 | ChangePassword | bit | CODE-BACKED | Flag requiring the customer to change their password on next login. |
| 13 | RiskStatusID | int | CODE-BACKED | Back-office risk assessment status. FK to Dictionary or internal lookup. |
| 14 | WorldCheckID | varchar | CODE-BACKED | ID of the customer's WorldCheck AML screening record. |
| 15 | isEmployeeAccount | bit | CODE-BACKED | Whether this account belongs to an eToro employee. |
| 16 | AccountTypeID | int | CODE-BACKED | Account type (1=Real, 2=Demo/Virtual). 99.3% are 1. |
| 17 | MasterAccountCID | int | CODE-BACKED | CID of the master account if this is a sub-account. NULL for standalone accounts. |
| 18 | ManagerPermitID | int | CODE-BACKED | Permission group assigned to this customer's manager relationship. |
| 19 | ThirdPartyManagerComment | nvarchar | CODE-BACKED | Free-text comment from third-party manager or partner. |
| 20 | GuruStatusID | int | CODE-BACKED | Popular Investor (Guru) status tier. FK to Dictionary.GuruStatus. |
| 21 | RiskClassificationID | int | CODE-BACKED | Customer risk classification for regulatory purposes. FK to BackOffice.RiskClassification. |
| 22 | AcceptanceStatusID | int | CODE-BACKED | Status of the customer's TNC/compliance acceptance. |
| 23 | VerificationLevelID | int | CODE-BACKED | KYC verification tier achieved (0=unverified, 1=email, 2=phone, 3=fully verified). 47.1% are level 3. |
| 24 | RegulationID | int | CODE-BACKED | Regulatory entity governing this account (CySEC, FCA, ASIC, BVI, etc.). |
| 25 | DocumentStatusID | int | CODE-BACKED | Status of the customer's identity document review. FK to Dictionary.DocumentStatus. |
| 26 | PhoneVerifiedID | int | CODE-BACKED | Phone verification status record ID. |
| 27 | AcceptanceStatusChanginManagerID | int | CODE-BACKED | Manager who last changed the AcceptanceStatus. |
| 28 | GDCCheckID | int | CODE-BACKED | ID of the customer's GDC (Global Data Consortium / identity check) screening record. |
| 29 | RegulationChangeDate | datetime | CODE-BACKED | Date of most recent regulation assignment change. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | BackOffice.Customer | Base Table (SCHEMABINDING) | Direct column projection - all data from BackOffice.Customer, schema-bound |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No BackOffice SP consumers identified in SSDT repo) | - | - | Likely consumed by application services or reporting layers with restricted access. SCHEMABINDING suggests it may be used as an indexed view. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSafty (view, SCHEMABINDING)
+-- BackOffice.Customer (table - schema-bound dependency)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | Schema-bound base table - all 29 selected columns sourced from here |

### 6.2 Objects That Depend On This

No stored procedure consumers identified in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

The view is defined `WITH SCHEMABINDING`. A unique clustered index on CID could be added to make this an indexed (materialized) view. No such index has been identified in the SSDT repo.

### 7.2 Constraints

SCHEMABINDING: The underlying `BackOffice.Customer` table cannot drop or alter the 29 referenced columns while this view exists. Any structural change to BackOffice.Customer that would invalidate this view requires dropping and recreating it first.

---

## 8. Sample Queries

### 8.1 Get compliance state for a customer

```sql
SELECT CID, RegulationID, VerificationLevelID, DocumentStatusID,
       AcceptanceStatusID, RiskClassificationID, GuruStatusID,
       CashoutFeeGroupID
FROM BackOffice.CustomerSafty WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.2 Find unverified customers assigned to a manager

```sql
SELECT CID, SalesStatusID, VerificationLevelID, RegulationID
FROM BackOffice.CustomerSafty WITH (NOLOCK)
WHERE ManagerID = 1001
  AND VerificationLevelID < 3
ORDER BY CID;
```

### 8.3 Compare with full BackOffice.Customer (PII excluded)

```sql
-- CustomerSafty is a subset of BackOffice.Customer columns
-- Use for queries that do not need name/email/address/DOB
SELECT cs.CID, cs.RegulationID, cs.VerificationLevelID
FROM BackOffice.CustomerSafty cs WITH (NOLOCK)
WHERE cs.RegulationID = 5;  -- e.g., FCA regulation
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this view.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11 (DDL, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerSafty | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.CustomerSafty.sql*
