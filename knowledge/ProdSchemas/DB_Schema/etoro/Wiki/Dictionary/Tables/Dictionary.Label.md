# Dictionary.Label

> Lookup table defining 25 platform labels (white-label brands) — eToro, RetailFX, eToroUSA, and partner brands — with associated website URLs and cashier logo assets for multi-brand customer experience.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | LabelID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.Label defines the platform brands (labels) under which eToro operates its trading platform. eToro has historically offered its platform as a white-label solution to partner brands (RetailFX, JCLyons, ICMarkets, etc.) and operates regional variants (eToroUSA, eToroRussia, eToroChina). Each label has its own branding — website URL and cashier logo — allowing the same platform infrastructure to serve multiple brands with distinct customer-facing identities.

This table exists because eToro's multi-brand architecture requires brand-aware behavior throughout the platform. When a customer registers, they are assigned a LabelID that determines their brand experience: which logo appears in the cashier/payment flow, which website URL is used in emails, and which brand-specific rules apply. Even internal functions (eToro-Partners, Dealing) have label entries for system classification.

The LabelID is referenced extensively across the codebase — in customer registration (Customer.RegisterIB), withdrawal processing (BackOffice.GetWithdrawRequests, GetUnapprovedWithdrawRequests), billing (Billing.GetRollbackedPaymentOrdersReport), reporting (BackOffice.GetRegistrationReport, GetRiskExposureReport), and email generation (Customer views for mail campaigns).

---

## 2. Business Logic

### 2.1 Brand Classification

**What**: Labels categorize platform instances into primary brand, regional variants, white-label partners, and internal/system brands.

**Columns/Parameters Involved**: `LabelID`, `Name`, `URL`, `CashierLogoURL`

**Rules**:
- **Primary brand (0, 1, 9)**: eToro main platform — LabelIDs 0, 1, and 9 all map to "eToro" with the same logo/URL. Multiple IDs likely represent different internal contexts (default, legacy, alternate).
- **Regional variants (14, 29, 31)**: eToroUSA, eToroRussia, eToroChina — same core product but region-specific regulatory and UI adaptations.
- **White-label partners (2, 10-26)**: RetailFX, JCLyons, ICMarkets, Euroforex, etc. — external companies that licensed eToro's platform technology. Many are likely historical/inactive.
- **Internal/System (27, 30)**: eToro-Partners (affiliate system), Dealing (internal trading desk). No customer-facing URL or logo.
- Labels with NULL URL or CashierLogoURL are either deprecated or internal-only brands.

### 2.2 Cashier Branding

**What**: Each label's cashier logo URL controls the branding displayed during payment flows.

**Columns/Parameters Involved**: `CashierLogoURL`

**Rules**:
- Logo URLs point to the eToro CDN (etoro-cdn.etorostatic.com/cashier/cashier/images/master/logos/)
- The logo appears in the payment/cashier interface when customers make deposits or withdrawals
- Labels without a CashierLogoURL (NULL) use the default eToro branding or are not customer-facing

---

## 3. Data Overview

| LabelID | Name | URL | Meaning |
|---|---|---|---|
| 0 | eToro | http://www.etoro.com | Default eToro platform label. Primary brand used for the majority of customers globally. All standard platform features and branding apply. |
| 2 | RetailFX | http://www.retailfx.com | White-label partner brand — RetailFX was one of eToro's early B2B partners providing the trading platform under their own brand to their customer base. |
| 14 | eToroUSA | http://www.etorousa.com/ | US-specific variant of the eToro platform. Operates under US regulatory requirements (SEC/FINRA) with different product offerings than the global platform. |
| 27 | eToro-Partners | (none) | Internal label for the affiliate/partner management system. Not customer-facing — used to classify partner-related operations and transactions in the system. |
| 30 | Dealing | (none) | Internal trading desk label. Used by eToro's proprietary trading operations. No customer-facing URL — purely an internal classification for dealing desk activities. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LabelID | int | NO | - | VERIFIED | Primary key identifying the platform brand/label. 0/1/9=eToro (primary), 2=RetailFX, 10-26=white-label partners, 14=eToroUSA, 27=Partners, 29=eToroRussia, 30=Dealing, 31=eToroChina. Stored in customer records and referenced across billing, reporting, and registration procedures. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Brand name displayed in BackOffice interfaces, reports, and internal systems. Multiple LabelIDs can share the same Name (e.g., 0, 1, 9 all = "eToro"). |
| 3 | URL | varchar(300) | YES | - | VERIFIED | Brand's primary website URL. Used in customer-facing emails, notifications, and redirect links. NULL for internal/system labels (Partners, Dealing) that have no website. |
| 4 | CashierLogoURL | varchar(300) | YES | - | VERIFIED | CDN URL for the brand's logo displayed in the cashier/payment interface. Points to eToro's CDN (etoro-cdn.etorostatic.com). NULL for internal labels. Determines the visual branding during deposit and withdrawal flows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.RegisterIB | LabelID | Parameter | Assigns label during IB (Introducing Broker) registration |
| Customer.SetLabel | LabelID | Parameter | Updates a customer's label assignment |
| BackOffice.GetWithdrawRequests | LabelID | Lookup | Resolves brand name in withdrawal reports |
| BackOffice.GetRegistrationReport | LabelID | Lookup | Resolves brand in registration reporting |
| BackOffice.BillingDepositsPCIVersion | LabelID | Lookup | Resolves brand in billing deposit reports |
| BackOffice.GetRiskExposureReportPCIVersion | LabelID | Lookup | Resolves brand in risk exposure reports |
| Customer.GetRealCustomersShortVersionForMail | LabelID | Lookup | Filters/resolves brand in email campaigns |
| Customer.GetDemoCustomersShortVersionForMail | LabelID | Lookup | Filters/resolves brand in demo email campaigns |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.RegisterIB | Stored Procedure | Writes — assigns label at registration |
| Customer.SetLabel | Stored Procedure | Writes — updates customer label |
| BackOffice.GetWithdrawRequests | Stored Procedure | Reads — resolves brand in reports |
| BackOffice.GetRegistrationReport | Stored Procedure | Reads — registration reporting |
| BackOffice.BillingDepositsPCIVersion | Stored Procedure | Reads — billing reports |
| BackOffice.GetRiskExposureReportPCIVersion | Stored Procedure | Reads — risk exposure reports |
| Customer.GetRealCustomersShortVersionForMail | View | Reads — email campaign filtering |
| Billing.GetRollbackedPaymentOrdersReport | Stored Procedure | Reads — rollback reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCLB | CLUSTERED PK | LabelID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DCLB | PRIMARY KEY | Unique label/brand identifier |

---

## 8. Sample Queries

### 8.1 List all platform labels
```sql
SELECT  LabelID,
        Name,
        URL,
        CashierLogoURL
FROM    [Dictionary].[Label] WITH (NOLOCK)
ORDER BY LabelID;
```

### 8.2 Find active customer-facing labels
```sql
SELECT  LabelID,
        Name,
        URL
FROM    [Dictionary].[Label] WITH (NOLOCK)
WHERE   URL IS NOT NULL
ORDER BY Name;
```

### 8.3 Count customers per label
```sql
SELECT  l.Name AS Brand,
        l.LabelID,
        COUNT(*) AS CustomerCount
FROM    [Customer].[CustomerStatic] cs WITH (NOLOCK)
JOIN    [Dictionary].[Label] l WITH (NOLOCK)
        ON cs.LabelID = l.LabelID
GROUP BY l.Name, l.LabelID
ORDER BY CustomerCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.Label | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.Label.sql*
