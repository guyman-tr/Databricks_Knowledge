# Dictionary Schema Overview - fiktivo

> The Dictionary schema contains 22 lookup/reference tables that define the vocabulary and classification systems used across the fiktivo affiliate management platform.

## Purpose

The Dictionary schema serves as the centralized reference data layer for the fiktivo database. Every status code, type classification, and enumeration used in affiliate management, commission processing, KYP compliance, and reporting is defined here. These tables are:

- **Small and static**: All tables have fewer than 60 rows (most have 3-20 rows)
- **Read-only at runtime**: Rows are not created or modified by application procedures
- **Referenced everywhere**: The 22 tables collectively are referenced by 100+ objects across 15+ schemas

## Business Domains

The Dictionary tables organize into six business domains:

### 1. Account & Customer Classification
- **Dictionary.AccountStatus** - Account lifecycle states (Activated, Deactivated, Terminated variants)
- **Dictionary.AccountType** - Account product types (Trading, Options, IBAN, Moneyfarm)
- **Dictionary.PlayerLevel** - Customer loyalty tiers (Bronze, Silver, Gold, V.I.P) with cashout speed and threshold criteria
- **Dictionary.ISAProduct** - UK ISA product variants (Cash, Managed, DIY) linked to Moneyfarm account type

### 2. Affiliate Commission & Credit Events
- **Dictionary.CreditType** - Financial event types (Deposit, Bonus A/B, Chargeback A/B) driving commission calculations
- **Dictionary.EventState** - 51-state event processing pipeline (Tracking, Eligibility, Commission, Deferred stages)
- **Dictionary.ServiceType** - Event categories (Credit, Registration, Sale) routing to commission pipelines
- **Dictionary.PositionAssetType** - Instrument asset classes (Forex, Stocks, Crypto, etc.) for commission segmentation
- **Dictionary.PixelTypes** - Conversion tracking events (Registration, Approved FTD, Eligible FTD) for affiliate attribution

### 3. Payment & Financial
- **Dictionary.PaymentMethods** - Commission payout channels (PayPal, Wire, eToro Account, etc.)
- **Dictionary.PaymentRowStatus** - Payment processing states (Pending, Approved, Processed, Rejected) using bitmask IDs
- **Dictionary.Currency** - Supported currencies (USD, EUR, GBP, CAD, AUD, RMB)

### 4. KYP (Know Your Partner) Compliance
- **Dictionary.KYPStatus** - KYP verification lifecycle (Unavailable through Verified)
- **Dictionary.KYPDocType** - Document types for identity verification (ID, Passport, Tax Form, etc.)
- **Dictionary.KYPMarketingMethod** - Affiliate marketing channels (PPC, SEO, Social Media, etc.)
- **Dictionary.FormOfIncorporation** - Corporate legal structures (Private, Public, Other)
- **Dictionary.NatureOfBusiness** - Corporate industry sectors (Marketing, Real Estate, Education, etc.)
- **Dictionary.IdentificationType** - Government ID document types (Passport, ID Card, SSN, etc.)

### 5. Audit & Change Tracking
- **Dictionary.Action** - DML operation types (Insert, Update, Delete) for audit logs
- **Dictionary.ChangedSections** - Business areas tracked in audit logs (20 sections from Affiliates to ISAPlan)

### 6. Geographic & Regional
- **Dictionary.MarketingRegion** - 16 marketing regions (geographic + linguistic) for affiliate segmentation
- **Dictionary.CreationSource** - Affiliate provisioning channels (Local, Azure, Test)

## Key Relationships

```
Dictionary Schema Relationship Map:

Dictionary.AccountType <-- Dictionary.ISAProduct (SubAccountTypeID -> AccountTypeID=4)

Dictionary.Action     --> dbo.AuditLog (ActionID)
Dictionary.ChangedSections --> dbo.AuditLog (SectionID)

Dictionary.EventState --> AffiliateCommission.CreditEventStateLog
Dictionary.ServiceType --> AffiliateCommission.CreditEventStateLog

Dictionary.PlayerLevel --> 14+ transactional tables (Deposits, Sales, Registrations, etc.)
Dictionary.CreditType --> AffiliateCommission.Credit, CreditEvent
Dictionary.PositionAssetType --> AffiliateConfiguration.FirstPositionAssetPlan

Dictionary.KYPStatus, FormOfIncorporation, NatureOfBusiness --> KYP.Affiliate
Dictionary.KYPDocType --> KYP.AffiliateKYPDocs
Dictionary.KYPMarketingMethod --> KYP.AffiliateKYPMarketingMethods
```

## Statistics

| Metric | Value |
|--------|-------|
| Total tables | 22 |
| Total rows (all tables) | ~200 |
| Most referenced table | Dictionary.PlayerLevel (14+ consumer tables, 30+ procedures) |
| Largest table | Dictionary.EventState (51 rows, 3 columns) |
| Tables with IDENTITY PK | 3 (Currency, PaymentMethods, PixelTypes) |
| Tables with composite PK | 1 (ISAProduct) |
| Average quality score | 8.1/10 |
| Documentation date | 2026-04-12 |

---

*Generated: 2026-04-12 | Schema: Dictionary | Database: fiktivo*
