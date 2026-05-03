-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Customer.TwoFactorVerificationDetails
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.TwoFactorVerificationDetails.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_customer_twofactorverificationdetails
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_customer_twofactorverificationdetails (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_customer_twofactorverificationdetails SET TBLPROPERTIES (
    'comment' = 'Two-factor authentication audit log: records each OTP challenge sent to a customer via SMS or voice call, tracking whether the code was successfully verified and how many entry attempts were made. Source: etoro.Customer.TwoFactorVerificationDetails on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.TwoFactorVerificationDetails.md).'
);

ALTER TABLE main.general.bronze_etoro_customer_twofactorverificationdetails SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Customer',
    'source_table' = 'TwoFactorVerificationDetails',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_customer_twofactorverificationdetails ALTER COLUMN ReferenceID COMMENT 'Application-generated GUID that uniquely identifies this 2FA challenge. NONCLUSTERED PK - used for point-lookup by the consuming application to retrieve or update a specific challenge by session ID. InsertTwoFactorVerificationDetails receives this from the caller; the application generates it before calling the SP. (Tier 1 - upstream wiki, etoro.Customer.TwoFactorVerificationDetails)';
ALTER TABLE main.general.bronze_etoro_customer_twofactorverificationdetails ALTER COLUMN GCID COMMENT 'Group Customer ID - the cross-product identity of the customer receiving the challenge. Part of the CLUSTERED index (GCID, VerificationDate DESC), enabling fast "get all/latest challenges for this customer" queries. Used by all reader procedures as the primary filter. (Tier 1 - upstream wiki, etoro.Customer.TwoFactorVerificationDetails)';
ALTER TABLE main.general.bronze_etoro_customer_twofactorverificationdetails ALTER COLUMN VerificationCode COMMENT 'The OTP code sent to the customer via SMS or voice call. Typically a 6-digit numeric string. Stored here so the verification service can compare the customer''s entered value against the original. InsertTwoFactorVerificationDetails receives this from the calling application. varchar(32) provides headroom for future code format changes. (Tier 1 - upstream wiki, etoro.Customer.TwoFactorVerificationDetails)';
ALTER TABLE main.general.bronze_etoro_customer_twofactorverificationdetails ALTER COLUMN VerificationDate COMMENT 'UTC timestamp when this challenge was created and the code dispatched to the customer. Default = getutcdate() on INSERT. Functions as the clustered index leading key (after GCID) in descending order - rows are physically sorted newest-first per customer. Used by GetLatestTwoFactorVerificationDetails to filter for non-expired codes via DATEADD(minute, -@expirationIntervalMinutes, getutcdate()). (Tier 1 - upstream wiki, etoro.Customer.TwoFactorVerificationDetails)';
ALTER TABLE main.general.bronze_etoro_customer_twofactorverificationdetails ALTER COLUMN VerifySuccessDate COMMENT 'UTC timestamp set by UpdateTwoFactorVerificationDetails when Success is flipped to 1. NULL = challenge not yet verified. Non-NULL = the exact moment the customer entered the correct code. Useful for auditing how long customers take to verify and for detecting replayed/delayed codes. (Tier 1 - upstream wiki, etoro.Customer.TwoFactorVerificationDetails)';
ALTER TABLE main.general.bronze_etoro_customer_twofactorverificationdetails ALTER COLUMN Success COMMENT 'Whether the OTP was successfully verified: 1 = customer entered correct code (UpdateTwoFactorVerificationDetails was called); 0 = challenge still open, failed, or expired. Default=0 on INSERT. GetTwoFactorVerificationFailedRequestCount counts rows WHERE Success=0 for brute-force detection. GetOTPAbusers reads Success=0 rows as the abuse signal. (Tier 1 - upstream wiki, etoro.Customer.TwoFactorVerificationDetails)';
ALTER TABLE main.general.bronze_etoro_customer_twofactorverificationdetails ALTER COLUMN VerificationTries COMMENT 'Count of incorrect entry attempts. Default=0 on INSERT. Incremented by 1 on each call to UpdateTwoFactorVerificationTries (wrong code entered). Does NOT increment on success - UpdateTwoFactorVerificationDetails sets Success=1 directly without touching VerificationTries. A high value (e.g., 3+) combined with Success=0 indicates a brute-force attempt or user error. (Tier 1 - upstream wiki, etoro.Customer.TwoFactorVerificationDetails)';
ALTER TABLE main.general.bronze_etoro_customer_twofactorverificationdetails ALTER COLUMN VerificationSendMethodTypeID COMMENT 'Delivery channel for the OTP code. FK to Dictionary.TwoFactorVerificationSendMethodType: 1=sms (text message), 2=call (automated voice call). NULL = delivery method not recorded (older rows predating this column). InsertTwoFactorVerificationDetails receives this from the caller - the application determines which channel based on user preference or fallback logic. (Tier 1 - upstream wiki, etoro.Customer.TwoFactorVerificationDetails)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
