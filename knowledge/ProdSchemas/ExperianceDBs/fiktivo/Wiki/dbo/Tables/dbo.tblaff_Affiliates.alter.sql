-- =============================================================================
-- Databricks ALTER Script: main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates  (TABLE)
-- Generated: 2026-05-19 | scaffold_alter_for_uc_targets.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_Affiliates.md
-- Target: Unity Catalog comments (1024 char limit per comment)
-- Drift guard: pre-flight uc_comment_validator.validate_alter_sql
-- =============================================================================

-- ---- Table comment intentionally not emitted (--cols-only) ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN AffiliateID COMMENT 'Primary key. The unique identifier for each affiliate in the system. Referenced by virtually every other table via AffiliateID columns. NOT FOR REPLICATION identity. NC PK (clustered index is multi-column).';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN UserID COMMENT 'Links to dbo.tblaff_User for admin portal user management. Default 0 indicates no linked admin user. Used by triggers and management procedures.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN AffiliatesGroupsID COMMENT 'Organizational group assignment. References dbo.tblaff_AffiliatesGroups.AffiliatesGroupsID [done]. Default 2 is the standard/default group. Groups control manager assignments and reporting segmentation.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN LoginName COMMENT 'Affiliate portal login username. MASKED with default() for dynamic data masking. Has dedicated NC index for login lookups.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN LoginPassword COMMENT 'Affiliate portal password. MASKED with default() for dynamic data masking. Stored as plaintext/hash depending on era of creation.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN Phrase COMMENT 'Security phrase for account recovery or verification. Legacy field from original affiliate system.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN Contact COMMENT 'Primary contact person name for the affiliate. For corporate affiliates, this is the business contact.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN Email COMMENT 'Affiliate''s email address. Has dedicated NC index. Used for notifications, password resets, and communication.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN TaxID COMMENT 'Tax identification number for the affiliate. Required for payment processing and regulatory reporting in some jurisdictions.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN SocialSecurity COMMENT 'Social security or national insurance number. Required for US-based affiliates for IRS W-9 reporting.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN CompanyName COMMENT 'Legal company name for corporate affiliates. MASKED with default(). Used in payment processing and compliance documentation.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN CompanyAddress COMMENT 'Business address of the affiliate. MASKED with default(). Required for payment and compliance.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN Country COMMENT 'Country name as free text. Legacy field - CountryID (column 54) is the normalized version used by newer code.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN City COMMENT 'City of the affiliate''s business address.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN State COMMENT 'State/province of the affiliate''s business address.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN Zip COMMENT 'Postal/ZIP code of the affiliate''s business address.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN Telephone COMMENT 'Primary telephone number. Legacy field - PhoneCountryID + PhoneNumber are the structured replacement.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN Fax COMMENT 'Fax number. Legacy communication field.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN WebSiteURL COMMENT 'URL of the affiliate''s website. Used for compliance review and traffic source verification.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN WebSiteTitle COMMENT 'Title/name of the affiliate''s website.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN Comments COMMENT 'Free-text notes about the affiliate. Used by admins for internal annotations.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN AccountStatus COMMENT 'Affiliate account lifecycle state: 0=Inactive/Pending (default), 1=Active, 2=Suspended, 4=Under Review, 5=Rejected. Controls portal access and commission eligibility.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN SendEmailNotification COMMENT 'Controls whether the affiliate receives automated email notifications (commission reports, announcements). 1=receive emails, 0=no emails.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN DateCreated COMMENT 'Timestamp of affiliate account creation. Set automatically on INSERT. Oldest records date to 2007-07-01.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN AcceptedAgreement COMMENT 'Whether the affiliate has accepted the affiliate program terms and conditions. 1=accepted, 0=not yet accepted. Required before commissions can be paid.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN AffiliateTypeID COMMENT 'Commission plan type. References dbo.tblaff_AffiliateTypes.AffiliateTypeID [done]. Determines commission rates, CPA slabs, and payment terms.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN VATNumber COMMENT 'EU VAT registration number. Required for European affiliates for proper invoicing and tax compliance.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN AffiliateCustom1 COMMENT 'Custom field 1. Configurable per deployment for additional affiliate metadata. Sometimes used for last name or additional contact info.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN AffiliateCustom2 COMMENT 'Custom field 2. Configurable per deployment.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN AffiliateCustom3 COMMENT 'Custom field 3. Configurable per deployment.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN AffiliateCustom4 COMMENT 'Custom field 4. Configurable per deployment.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN AffiliateCustom5 COMMENT 'Custom field 5. Configurable per deployment.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN PaymentDetailsID COMMENT 'Primary payment method. References dbo.tblaff_PaymentDetails [done]. Links to banking/payment info for commission disbursement. Has NC index.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN IBAffiliate COMMENT 'Introducing Broker flag/parent ID. 0=not an IB, >0=this affiliate is an IB (value may indicate parent IB structure).';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN Reports_Tiers_Summary COMMENT 'Controls whether the affiliate can see tier summary reports in the portal. 1=visible, 0=hidden.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN Reports_Tiers_Details COMMENT 'Controls whether the affiliate can see detailed tier reports in the portal. 1=visible, 0=hidden.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN IBCountries COMMENT 'Comma-separated or JSON list of country IDs where this IB affiliate can operate. NULL means no geographic restriction.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN ManagerID_Demo COMMENT 'Demo account manager ID assigned to this affiliate. Default 36. Used for demo/sandbox environment tracking.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN ManagerID_Real COMMENT 'Real/production account manager ID assigned to this affiliate. Default 45. Determines which manager oversees this affiliate relationship.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN MarketingExpenseID COMMENT 'Marketing expense category. References dbo.tblaff_MarketingExpense [done]. Default 1. Categorizes the affiliate''s marketing cost allocation.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN IBProviderID COMMENT 'The provider/partner ID within the IB hierarchy. Default 1. For IB sub-affiliates, identifies their parent IB.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN IBLabelID COMMENT 'Label/brand identifier within the IB structure. Default 0. Supports white-label IB configurations.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN HideExceptIBCRM COMMENT 'Visibility flag. 1=this affiliate is hidden from standard admin views, only visible in IB CRM tools. 0=visible everywhere.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN CanShowCashier COMMENT 'Controls whether the affiliate can access cashier/payment features in the portal. 1=cashier visible, 0=hidden.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN CommunicationLangID COMMENT 'Preferred communication language for emails and notifications. Default 0. References a language lookup.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN CountImpressions COMMENT 'Controls whether banner impressions are tracked for this affiliate. 1=track impressions, 0=clicks only.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN CountClicks COMMENT 'Controls whether clicks are tracked for this affiliate. 1=track clicks (default), 0=no click tracking.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN PrefferedCurrencyID COMMENT 'Affiliate''s preferred payment currency. References Dictionary.Currency (1=USD, 2=EUR, 3=GBP, 4=CAD, 5=AUD, 38=RMB).';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN PaymentDetails2ID COMMENT 'Secondary payment method. References dbo.tblaff_PaymentDetails [done]. NULL if only one payment method configured.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN PaymentDetails3ID COMMENT 'Tertiary payment method. References dbo.tblaff_PaymentDetails [done]. NULL if fewer than three payment methods configured.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN PaymentDetailsDefault COMMENT 'Indicates which payment method is active for disbursement. 1=primary (PaymentDetailsID), 2=secondary, 12=specific method (most common at 93%).';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN BirthDayDate COMMENT 'Affiliate''s date of birth. Required for individual affiliates in some jurisdictions for KYC compliance.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN CountryID COMMENT 'Normalized country reference. FK to dbo.tblaff_Country.CountryID [done]. Default 0. The authoritative country field (replaces legacy Country text field).';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN IdentificationTypeID COMMENT 'Type of government ID submitted. FK to Dictionary.IdentificationType: 1=Passport, 2=ID Card, 3=NI Number, etc. Part of KYC compliance.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN IdentificationNumber COMMENT 'The actual ID document number corresponding to IdentificationTypeID. Stored for KYC verification records.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN NeedsResetPassword COMMENT 'Forces password change on next login. 1=must reset, NULL/0=normal login. Set by admins for security events.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN GCID COMMENT 'Global Customer ID linking this affiliate to the main trading platform''s customer system. Has filtered NC index (WHERE GCID IS NOT NULL). Enables cross-platform identity resolution.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN AccountTypeID COMMENT 'Entity type classification: 0=Legacy/unclassified (181), 1=Individual (43,513), 2=Corporate (12). Determines required compliance fields.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN EntityName COMMENT 'Legal entity name for corporate affiliates (AccountTypeID=2). The registered company name for KYP documentation.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN IncorporationNumber COMMENT 'Company registration/incorporation number for corporate affiliates. Required for KYP compliance.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN IncorporationDate COMMENT 'Date the corporate entity was incorporated. Part of KYP due diligence.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN LeiNumber COMMENT 'Legal Entity Identifier (LEI) - a 20-character alphanumeric code required for corporate entities under MiFID II and other financial regulations.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN ContactPersonFullName COMMENT 'Full name of the authorized contact person for corporate affiliates. MASKED with default().';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN CreationSourceID COMMENT 'How the affiliate account was created. FK to Dictionary.CreationSource: 1=Local (admin), 2=Azure (AD sync), 3=Test. NULL for legacy accounts.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN AzureObjectId COMMENT 'Azure Active Directory object identifier for SSO-provisioned affiliates. Has unique filtered NC index (WHERE NOT NULL). Enables SSO login and identity sync.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN PhoneCountryID COMMENT 'International dialing code/country for the affiliate''s phone number. Structured replacement for the legacy Telephone field.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN PhoneNumber COMMENT 'Affiliate''s phone number (without country code). Paired with PhoneCountryID for the full international number.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN StreetNumber COMMENT 'Street/building number component of the affiliate''s address. Added to support structured address formats.';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates ALTER COLUMN CalculateCommission COMMENT 'Commission calculation method flag: 0=standard calculation (99.8%), 1=custom/override calculation (96 accounts). Controls which commission engine processes this affiliate''s earnings.';

-- NOTE: PII tags intentionally NOT emitted by scaffold_alter_for_uc_targets.py.
-- Blanket-tagging every column 'pii=none' would risk silently misclassifying
-- PII-masked columns. Run the dedicated PII classifier afterwards.

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-19 13:20:20 UTC
-- Statements: 69/69 succeeded
-- ====================
