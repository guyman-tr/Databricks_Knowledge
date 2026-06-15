---
object_fqn: main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 71
row_count: null
generated_at: '2026-05-19T12:12:56Z'
upstreams:
- fiktivo.dbo.tblaff_Affiliates
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md
  source_database: fiktivo
  source_schema: dbo
  source_table: tblaff_Affiliates
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/dbo/tblaff_Affiliates
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 71
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_fiktivo_dbo_tblaff_affiliates

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.dbo.tblaff_Affiliates`). 71 of 71 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 71 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Jun 09 11:14:10 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.dbo.tblaff_Affiliates` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md`.

- Lake path: `Bronze/fiktivo/dbo/tblaff_Affiliates`
- Copy strategy: `Override`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `dbo.tblaff_Affiliates`
- 71 of 71 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AffiliateID | INT | YES | Primary key. The unique identifier for each affiliate in the system. Referenced by virtually every other table via AffiliateID columns. NOT FOR REPLICATION identity. NC PK (clustered index is multi-column) (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 1 | UserID | INT | YES | Links to dbo.tblaff_User for admin portal user management. Default 0 indicates no linked admin user. Used by triggers and management procedures (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 2 | AffiliatesGroupsID | INT | YES | Organizational group assignment. References dbo.tblaff_AffiliatesGroups.AffiliatesGroupsID [done]. Default 2 is the standard/default group. Groups control manager assignments and reporting segmentation (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 3 | LoginName | STRING | YES | Affiliate portal login username. MASKED with default() for dynamic data masking. Has dedicated NC index for login lookups (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 4 | LoginPassword | STRING | YES | Affiliate portal password. MASKED with default() for dynamic data masking. Stored as plaintext/hash depending on era of creation (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 5 | Phrase | STRING | YES | Security phrase for account recovery or verification. Legacy field from original affiliate system (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 6 | Contact | STRING | YES | Primary contact person name for the affiliate. For corporate affiliates, this is the business contact (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 7 | Email | STRING | YES | Affiliate's email address. Has dedicated NC index. Used for notifications, password resets, and communication (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 8 | TaxID | STRING | YES | Tax identification number for the affiliate. Required for payment processing and regulatory reporting in some jurisdictions (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 9 | SocialSecurity | STRING | YES | Social security or national insurance number. Required for US-based affiliates for IRS W-9 reporting (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 10 | CompanyName | STRING | YES | Legal company name for corporate affiliates. MASKED with default(). Used in payment processing and compliance documentation (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 11 | CompanyAddress | STRING | YES | Business address of the affiliate. MASKED with default(). Required for payment and compliance (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 12 | Country | STRING | YES | Country name as free text. Legacy field - CountryID (column 54) is the normalized version used by newer code (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 13 | City | STRING | YES | City of the affiliate's business address (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 14 | State | STRING | YES | State/province of the affiliate's business address (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 15 | Zip | STRING | YES | Postal/ZIP code of the affiliate's business address (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 16 | Telephone | STRING | YES | Primary telephone number. Legacy field - PhoneCountryID + PhoneNumber are the structured replacement (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 17 | Fax | STRING | YES | Fax number. Legacy communication field (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 18 | WebSiteURL | STRING | YES | URL of the affiliate's website. Used for compliance review and traffic source verification (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 19 | WebSiteTitle | STRING | YES | Title/name of the affiliate's website (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 20 | Comments | STRING | YES | Free-text notes about the affiliate. Used by admins for internal annotations (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 21 | AccountStatus | INT | YES | Affiliate account lifecycle state: 0=Inactive/Pending (default), 1=Active, 2=Suspended, 4=Under Review, 5=Rejected. Controls portal access and commission eligibility (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 22 | SendEmailNotification | BOOLEAN | YES | Controls whether the affiliate receives automated email notifications (commission reports, announcements). 1=receive emails, 0=no emails (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 23 | DateCreated | TIMESTAMP | YES | Timestamp of affiliate account creation. Set automatically on INSERT. Oldest records date to 2007-07-01 (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 24 | AcceptedAgreement | BOOLEAN | YES | Whether the affiliate has accepted the affiliate program terms and conditions. 1=accepted, 0=not yet accepted. Required before commissions can be paid (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 25 | AffiliateTypeID | INT | YES | Commission plan type. References dbo.tblaff_AffiliateTypes.AffiliateTypeID [done]. Determines commission rates, CPA slabs, and payment terms (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 26 | VATNumber | STRING | YES | EU VAT registration number. Required for European affiliates for proper invoicing and tax compliance (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 27 | AffiliateCustom1 | STRING | YES | Custom field 1. Configurable per deployment for additional affiliate metadata. Sometimes used for last name or additional contact info (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 28 | AffiliateCustom2 | STRING | YES | Custom field 2. Configurable per deployment (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 29 | AffiliateCustom3 | STRING | YES | Custom field 3. Configurable per deployment (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 30 | AffiliateCustom4 | STRING | YES | Custom field 4. Configurable per deployment (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 31 | AffiliateCustom5 | STRING | YES | Custom field 5. Configurable per deployment (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 32 | PaymentDetailsID | LONG | YES | Primary payment method. References dbo.tblaff_PaymentDetails [done]. Links to banking/payment info for commission disbursement. Has NC index (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 33 | IBAffiliate | LONG | YES | Introducing Broker flag/parent ID. 0=not an IB, >0=this affiliate is an IB (value may indicate parent IB structure) (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 34 | Reports_Tiers_Summary | BOOLEAN | YES | Controls whether the affiliate can see tier summary reports in the portal. 1=visible, 0=hidden (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 35 | Reports_Tiers_Details | BOOLEAN | YES | Controls whether the affiliate can see detailed tier reports in the portal. 1=visible, 0=hidden (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 36 | IBCountries | STRING | YES | Comma-separated or JSON list of country IDs where this IB affiliate can operate. NULL means no geographic restriction (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 37 | ManagerID_Demo | LONG | YES | Demo account manager ID assigned to this affiliate. Default 36. Used for demo/sandbox environment tracking (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 38 | ManagerID_Real | LONG | YES | Real/production account manager ID assigned to this affiliate. Default 45. Determines which manager oversees this affiliate relationship (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 39 | MarketingExpenseID | LONG | YES | Marketing expense category. References dbo.tblaff_MarketingExpense [done]. Default 1. Categorizes the affiliate's marketing cost allocation (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 40 | IBProviderID | LONG | YES | The provider/partner ID within the IB hierarchy. Default 1. For IB sub-affiliates, identifies their parent IB (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 41 | IBLabelID | LONG | YES | Label/brand identifier within the IB structure. Default 0. Supports white-label IB configurations (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 42 | HideExceptIBCRM | BOOLEAN | YES | Visibility flag. 1=this affiliate is hidden from standard admin views, only visible in IB CRM tools. 0=visible everywhere (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 43 | CanShowCashier | BOOLEAN | YES | Controls whether the affiliate can access cashier/payment features in the portal. 1=cashier visible, 0=hidden (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 44 | CommunicationLangID | INT | YES | Preferred communication language for emails and notifications. Default 0. References a language lookup (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 45 | CountImpressions | BOOLEAN | YES | Controls whether banner impressions are tracked for this affiliate. 1=track impressions, 0=clicks only (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 46 | CountClicks | BOOLEAN | YES | Controls whether clicks are tracked for this affiliate. 1=track clicks (default), 0=no click tracking (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 47 | PrefferedCurrencyID | INT | YES | Affiliate's preferred payment currency. References Dictionary.Currency (1=USD, 2=EUR, 3=GBP, 4=CAD, 5=AUD, 38=RMB) (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 48 | PaymentDetails2ID | LONG | YES | Secondary payment method. References dbo.tblaff_PaymentDetails [done]. NULL if only one payment method configured (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 49 | PaymentDetails3ID | LONG | YES | Tertiary payment method. References dbo.tblaff_PaymentDetails [done]. NULL if fewer than three payment methods configured (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 50 | PaymentDetailsDefault | INT | YES | Indicates which payment method is active for disbursement. 1=primary (PaymentDetailsID), 2=secondary, 12=specific method (most common at 93%) (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 51 | BirthDayDate | TIMESTAMP | YES | Affiliate's date of birth. Required for individual affiliates in some jurisdictions for KYC compliance (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 52 | CountryID | INT | YES | Normalized country reference. FK to dbo.tblaff_Country.CountryID [done]. Default 0. The authoritative country field (replaces legacy Country text field) (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 53 | IdentificationTypeID | INT | YES | Type of government ID submitted. FK to Dictionary.IdentificationType: 1=Passport, 2=ID Card, 3=NI Number, etc. Part of KYC compliance (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 54 | IdentificationNumber | STRING | YES | The actual ID document number corresponding to IdentificationTypeID. Stored for KYC verification records (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 55 | NeedsResetPassword | BOOLEAN | YES | Forces password change on next login. 1=must reset, NULL/0=normal login. Set by admins for security events (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 56 | GCID | INT | YES | Global Customer ID linking this affiliate to the main trading platform's customer system. Has filtered NC index (WHERE GCID IS NOT NULL). Enables cross-platform identity resolution (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 57 | AccountTypeID | INT | YES | Entity type classification: 0=Legacy/unclassified (181), 1=Individual (43,513), 2=Corporate (12). Determines required compliance fields (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 58 | EntityName | STRING | YES | Legal entity name for corporate affiliates (AccountTypeID=2). The registered company name for KYP documentation (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 59 | IncorporationNumber | STRING | YES | Company registration/incorporation number for corporate affiliates. Required for KYP compliance (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 60 | IncorporationDate | TIMESTAMP | YES | Date the corporate entity was incorporated. Part of KYP due diligence (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 61 | LeiNumber | STRING | YES | Legal Entity Identifier (LEI) - a 20-character alphanumeric code required for corporate entities under MiFID II and other financial regulations (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 62 | ContactPersonFullName | STRING | YES | Full name of the authorized contact person for corporate affiliates. MASKED with default() (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 63 | CreationSourceID | INT | YES | How the affiliate account was created. FK to Dictionary.CreationSource: 1=Local (admin), 2=Azure (AD sync), 3=Test. NULL for legacy accounts (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 64 | AzureObjectId | STRING | YES | Azure Active Directory object identifier for SSO-provisioned affiliates. Has unique filtered NC index (WHERE NOT NULL). Enables SSO login and identity sync (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 65 | Trace | STRING | YES | Computed JSON column capturing session context: HostName, AppName, SUserName, SPID, DBName, ObjectName. Audit trail for who modified the record (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 66 | PhoneCountryID | INT | YES | International dialing code/country for the affiliate's phone number. Structured replacement for the legacy Telephone field (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 67 | PhoneNumber | STRING | YES | Affiliate's phone number (without country code). Paired with PhoneCountryID for the full international number (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 68 | StreetNumber | STRING | YES | Street/building number component of the affiliate's address. Added to support structured address formats (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 69 | LoginName_LOWER | STRING | YES | Computed column: lower(LoginName). Provides case-insensitive login name lookups via NC index without collation overhead (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |
| 70 | CalculateCommission | INT | YES | Commission calculation method flag: 0=standard calculation (99.8%), 1=custom/override calculation (96 accounts). Controls which commission engine processes this affiliate's earnings (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.dbo.tblaff_Affiliates` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.dbo.tblaff_Affiliates
        │
        ▼
main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates   ←── this object
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=0 runtime=0 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 5. Sample Queries & Common JOINs

### 5.1 Sample queries

> Sample queries are not auto-generated in this pack; refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage.

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered from upstream JOINs in `.lineage.md`) | — | — |

### 5.3 Gotchas

- See `.review-needed.md` for parser warnings, UNVERIFIED columns, and any Tier-4 sample-only candidates.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| AffiliateID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| UserID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| AffiliatesGroupsID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| LoginName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| LoginPassword | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| Phrase | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| Contact | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| Email | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| TaxID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| SocialSecurity | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| CompanyName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| CompanyAddress | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| Country | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| City | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| State | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| Zip | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| Telephone | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| Fax | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| WebSiteURL | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| WebSiteTitle | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| Comments | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| AccountStatus | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| SendEmailNotification | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| DateCreated | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| AcceptedAgreement | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| AffiliateTypeID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| VATNumber | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| AffiliateCustom1 | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| AffiliateCustom2 | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| AffiliateCustom3 | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| AffiliateCustom4 | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| AffiliateCustom5 | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| PaymentDetailsID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| IBAffiliate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| Reports_Tiers_Summary | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| Reports_Tiers_Details | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| IBCountries | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| ManagerID_Demo | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| ManagerID_Real | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| MarketingExpenseID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| IBProviderID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| IBLabelID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| HideExceptIBCRM | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| CanShowCashier | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| CommunicationLangID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| CountImpressions | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| CountClicks | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| PrefferedCurrencyID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| PaymentDetails2ID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| PaymentDetails3ID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| PaymentDetailsDefault | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| BirthDayDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| CountryID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| IdentificationTypeID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| IdentificationNumber | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| NeedsResetPassword | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| GCID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| AccountTypeID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| EntityName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| IncorporationNumber | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| IncorporationDate | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| LeiNumber | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| ContactPersonFullName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| CreationSourceID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| AzureObjectId | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| Trace | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| PhoneCountryID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| PhoneNumber | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| StreetNumber | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| LoginName_LOWER | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |
| CalculateCommission | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_Affiliates) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 71 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 71/71 | Source: bronze_tier1_inheritance*
