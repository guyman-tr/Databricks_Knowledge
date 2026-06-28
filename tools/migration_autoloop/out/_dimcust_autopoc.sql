BEGIN

DECLARE V_dateID INT;
DECLARE V_rnum INT;
DECLARE V_avtar_rn INT;

SET V_dateID = CAST(date_format(current_timestamp(), 'yyyyMMdd') AS INT);

-- ============================================================
-- STEP 1: Build #customer (Ext_Customer JOIN Ext_BOCustomer)
--         Materialized to avoid recomputation in downstream steps
-- ============================================================
CREATE OR REPLACE TABLE dwh_daily_process.migration_tables._tmp_sp_dimcust_customer AS
SELECT cc.GCID
    , cc.CID
    , cc.OriginalCID
    , cc.UserName
    , cc.FirstName
    , cc.LastName
    , cc.MiddleName
    , cc.Gender
    , cc.BirthDate
    , cc.ReferralID
    , cc.CountryID
    , cc.IP
    , cc.Phone
    , cc.Zip
    , cc.Address
    , cc.BuildingNumber
    , cc.City
    , cc.SerialID AS AffiliateID
    , cc.CampaignID
    , cc.LabelID
    , cc.LanguageID
    , cc.Email
    , cc.PlayerStatusID
    , cc.PlayerLevelID
    , cc.FunnelID
    , cc.DownloadID
    , cc.Registered
    , cc.FunnelFromID
    , cc.CommunicationLanguageID
    , cc.BannerID
    , cc.AccountStatusID
    , cc.ID
    , cc.ExternalID
    , cc.PlayerStatusReasonID
    , cc.PendingClosureStatusID
    , cc.CountryIDByIP
    , cc.SubSerialID
    , bc.VerificationLevelID
    , bc.RiskStatusID
    , bc.RiskClassificationID
    , bc.isEmployeeAccount AS EmployeeAccount
    , bc.GuruStatusID
    , bc.AccountTypeID
    , bc.RegulationID
    , bc.ManagerID AS AccountManagerID
    , bc.EvMatchStatus
    , bc.DocumentStatusID
    , bc.RegulationChangeDate
    , bc.IsCopyBlocked
    , bc.IsEDD
    , bc.MifidCategorizationID
    , bc.SuitabilityTestStatusID
    , CAST(cc.IsEmailVerified AS INT) AS IsEmailVerified
    , bc.DesignatedRegulationID
    , cc.RegionByIP_ID
    , cc.RegionID
    , COALESCE(CAST(bc.HasWallet AS INT), 0) AS HasWallet
    , CitizenshipCountryID
    , PlayerStatusSubReasonID
    , PrivacyPolicyID
    , CashoutFeeGroupID
    , CASE WHEN PlayerLevelID <> 4
            AND LabelID NOT IN (30, 26)
            AND CountryID <> 250
            THEN 1 ELSE 0 END AS IsValidCustomer
    , CASE WHEN (NOT (PlayerLevelID = 4 AND AccountTypeID <> 2)
                AND LabelID NOT IN (26, 30)
                AND NOT (CountryID = 250 AND cc.CID NOT IN (3400616,10526243,10842855,11464063,21547142,34537826)))
                THEN 1 ELSE 0 END AS IsCreditReportValidCB
    , bc.SalesForceAccountID
    , cc.POBCountryID
    , cc.WeekendFeePrecentage
FROM dwh_daily_process.migration_tables.Ext_Dim_Customer_Customer cc
JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_BOCustomer bc
    ON cc.CID = bc.CID;

-- ============================================================
-- STEP 2: Detect NEW CIDs (not in Dim_Customer yet)
-- ============================================================
CREATE OR REPLACE TABLE dwh_daily_process.migration_tables._tmp_sp_dimcust_new AS
SELECT CID
FROM dwh_daily_process.migration_tables._tmp_sp_dimcust_customer a
WHERE NOT EXISTS (SELECT NULL FROM dwh_daily_process.migration_tables.Dim_Customer WHERE RealCID = a.CID);

-- ============================================================
-- STEP 3: Detect UPDATED CIDs (changed vs current Dim_Customer)
-- ============================================================
CREATE OR REPLACE TABLE dwh_daily_process.migration_tables._tmp_sp_dimcust_update AS
SELECT a.CID
FROM dwh_daily_process.migration_tables.Dim_Customer dc
JOIN dwh_daily_process.migration_tables._tmp_sp_dimcust_customer a ON a.CID = dc.RealCID
WHERE NOT (dc.UserName <=> a.UserName)
    OR NOT (dc.FirstName <=> a.FirstName)
    OR NOT (dc.LastName <=> a.LastName)
    OR NOT (dc.MiddleName <=> a.MiddleName)
    OR NOT (dc.Gender <=> a.Gender)
    OR NOT (dc.BirthDate <=> a.BirthDate)
    OR NOT (dc.ReferralID <=> a.ReferralID)
    OR NOT (dc.CountryID <=> a.CountryID)
    OR NOT (dc.Phone <=> a.Phone)
    OR NOT (dc.Zip <=> a.Zip)
    OR NOT (dc.Address <=> a.Address)
    OR NOT (dc.BuildingNumber <=> a.BuildingNumber)
    OR NOT (dc.City <=> a.City)
    OR NOT (dc.AffiliateID <=> a.AffiliateID)
    OR NOT (dc.CampaignID <=> a.CampaignID)
    OR NOT (dc.LabelID <=> a.LabelID)
    OR NOT (dc.LanguageID <=> a.LanguageID)
    OR NOT (dc.Email <=> a.Email)
    OR NOT (dc.PlayerStatusID <=> a.PlayerStatusID)
    OR NOT (dc.PlayerLevelID <=> a.PlayerLevelID)
    OR NOT (dc.FunnelID <=> a.FunnelID)
    OR NOT (dc.DownloadID <=> a.DownloadID)
    OR NOT (dc.RegisteredReal <=> a.Registered)
    OR NOT (dc.FunnelFromID <=> a.FunnelFromID)
    OR NOT (dc.CommunicationLanguageID <=> a.CommunicationLanguageID)
    OR NOT (dc.BannerID <=> a.BannerID)
    OR NOT (dc.AccountStatusID <=> a.AccountStatusID)
    OR NOT (dc.PlayerStatusReasonID <=> a.PlayerStatusReasonID)
    OR NOT (dc.PendingClosureStatusID <=> a.PendingClosureStatusID)
    OR NOT (dc.CountryIDByIP <=> a.CountryIDByIP)
    OR NOT (dc.SubSerialID <=> a.SubSerialID)
    OR NOT (dc.VerificationLevelID <=> a.VerificationLevelID)
    OR NOT (dc.RiskStatusID <=> a.RiskStatusID)
    OR COALESCE(dc.RiskClassificationID, 200) <> COALESCE(a.RiskClassificationID, 200)
    OR NOT (dc.EmployeeAccount <=> a.EmployeeAccount)
    OR NOT (dc.GuruStatusID <=> a.GuruStatusID)
    OR NOT (dc.AccountTypeID <=> a.AccountTypeID)
    OR NOT (dc.RegulationID <=> a.RegulationID)
    OR NOT (dc.AccountManagerID <=> a.AccountManagerID)
    OR NOT (dc.EvMatchStatus <=> a.EvMatchStatus)
    OR NOT (dc.DocumentStatusID <=> a.DocumentStatusID)
    OR NOT (dc.RegulationChangeDate <=> a.RegulationChangeDate)
    OR NOT (dc.IsCopyBlocked <=> a.IsCopyBlocked)
    OR NOT (dc.IsEDD <=> a.IsEDD)
    OR NOT (dc.SuitabilityTestStatusID <=> a.SuitabilityTestStatusID)
    OR NOT (dc.MifidCategorizationID <=> a.MifidCategorizationID)
    OR NOT (CAST(dc.IsEmailVerified AS INT) <=> CAST(a.IsEmailVerified AS INT))
    OR NOT (dc.DesignatedRegulationID <=> a.DesignatedRegulationID)
    OR NOT (dc.RegionByIP_ID <=> a.RegionByIP_ID)
    OR NOT (dc.RegionID <=> a.RegionID)
    OR NOT (CAST(dc.HasWallet AS INT) <=> CAST(a.HasWallet AS INT))
    OR NOT (dc.CitizenshipCountryID <=> a.CitizenshipCountryID)
    OR NOT (dc.PlayerStatusSubReasonID <=> a.PlayerStatusSubReasonID)
    OR NOT (dc.PrivacyPolicyID <=> a.PrivacyPolicyID)
    OR NOT (dc.CashoutFeeGroupID <=> a.CashoutFeeGroupID)
    OR NOT (dc.IsValidCustomer <=> a.IsValidCustomer)
    OR NOT (dc.IsCreditReportValidCB <=> a.IsCreditReportValidCB)
    OR NOT (dc.SalesForceAccountID <=> a.SalesForceAccountID)
    OR NOT (dc.POBCountryID <=> a.POBCountryID)
    OR NOT (dc.WeekendFeePrecentage <=> a.WeekendFeePrecentage);

-- ============================================================
-- STEP 4: Build full_list (new + updated, with 2FA)
-- ============================================================
CREATE OR REPLACE TABLE dwh_daily_process.migration_tables._tmp_sp_dimcust_full_list AS
SELECT
      a.GCID, a.CID, a.OriginalCID, a.UserName, a.FirstName, a.LastName
    , a.MiddleName, a.Gender, a.BirthDate, a.ReferralID, a.CountryID, a.IP
    , a.AffiliateID, a.CampaignID, a.LabelID, a.LanguageID, a.Email, a.Phone
    , a.Zip, a.City, a.Address, a.BuildingNumber, a.VerificationLevelID
    , a.PlayerStatusID, a.FunnelID, a.DownloadID, a.Registered, a.FunnelFromID
    , a.RiskStatusID, a.RiskClassificationID, a.EmployeeAccount
    , a.CommunicationLanguageID, a.BannerID, a.GuruStatusID, a.AccountTypeID
    , a.RegulationID, a.PlayerLevelID, a.AccountStatusID, a.AccountManagerID
    , a.ID, a.ExternalID, a.PlayerStatusReasonID, a.PendingClosureStatusID
    , a.CountryIDByIP, a.SubSerialID, a.EvMatchStatus, a.DocumentStatusID
    , a.RegulationChangeDate, a.IsCopyBlocked, a.IsEDD
    , a.SuitabilityTestStatusID, a.MifidCategorizationID
    , CAST(a.IsEmailVerified AS INT) AS IsEmailVerified
    , a.IsValidCustomer
    , COALESCE(FA.`2FA`, d.`2FA`) AS `2FA`
    , a.DesignatedRegulationID, a.RegionByIP_ID, a.RegionID
    , COALESCE(CAST(a.HasWallet AS INT), 0) AS HasWallet
    , a.CitizenshipCountryID, a.PlayerStatusSubReasonID, a.PrivacyPolicyID
    , a.CashoutFeeGroupID, a.IsCreditReportValidCB, a.SalesForceAccountID
    , a.POBCountryID, a.WeekendFeePrecentage
FROM dwh_daily_process.migration_tables._tmp_sp_dimcust_customer a
LEFT JOIN dwh_daily_process.migration_tables._tmp_sp_dimcust_new b ON a.CID = b.CID
LEFT JOIN dwh_daily_process.migration_tables._tmp_sp_dimcust_update c ON a.CID = c.CID
LEFT JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_2FA FA ON a.GCID = FA.GCID
LEFT JOIN dwh_daily_process.migration_tables.Dim_Customer d ON a.GCID = d.GCID
WHERE b.CID IS NOT NULL OR c.CID IS NOT NULL;

-- ============================================================
-- STEP 5: Preserve initial indicators before re-insert
-- ============================================================
CREATE OR REPLACE TABLE dwh_daily_process.migration_tables._tmp_sp_dimcust_initial AS
SELECT
    RealCID, FirstDepositAmount, FirstDepositDate, HasAvatar, IsDepositor,
    ScreeningStatusID, SalesForceAccountID, IsAddressProof,
    IsAddressProofExpiryDate, IsIDProof, IsIDProofExpiryDate,
    WorldCheckID, WorldCheckResultsUpdated,
    CAST(TanganyID AS STRING) AS TanganyID, TanganyStatusID,
    PhoneNumber, IsPhoneVerified, PhoneVerificationDate, PhoneVerifiedID,
    EquiLendID, StocksLendingStatusID, DltID, DltStatusID,
    FTDRecoveryDate, FTDTransactionID, FTDPlatformID
FROM dwh_daily_process.migration_tables.Dim_Customer
WHERE EXISTS (SELECT NULL FROM dwh_daily_process.migration_tables._tmp_sp_dimcust_full_list WHERE CID = Dim_Customer.RealCID);

-- ============================================================
-- STEP 6: DELETE + INSERT (core dimension rebuild for changed CIDs)
-- ============================================================
DELETE FROM dwh_daily_process.migration_tables.Dim_Customer
WHERE EXISTS (SELECT NULL FROM dwh_daily_process.migration_tables._tmp_sp_dimcust_full_list WHERE CID = Dim_Customer.RealCID);

INSERT INTO dwh_daily_process.migration_tables.Dim_Customer
(GCID, RealCID, OriginalCID, UserName, FirstName, LastName, MiddleName,
 Gender, BirthDate, ReferralID, CountryID, IP, AffiliateID, CampaignID,
 LabelID, LanguageID, Email, Phone, Zip, City, Address, BuildingNumber,
 VerificationLevelID, PlayerStatusID, FunnelID, DownloadID, RegisteredReal,
 FunnelFromID, RiskStatusID, RiskClassificationID, EmployeeAccount,
 CommunicationLanguageID, BannerID, GuruStatusID, AccountTypeID, RegulationID,
 PlayerLevelID, AccountStatusID, AccountManagerID, ID, ExternalID,
 PlayerStatusReasonID, PendingClosureStatusID, CountryIDByIP, SubSerialID,
 EvMatchStatus, DocumentStatusID, RegulationChangeDate, IsCopyBlocked,
 IsEDD, SuitabilityTestStatusID, MifidCategorizationID, UpdateDate,
 IsEmailVerified, IsValidCustomer, `2FA`, DesignatedRegulationID,
 RegionByIP_ID, RegionID, HasWallet, CitizenshipCountryID,
 PlayerStatusSubReasonID, PrivacyPolicyID, CashoutFeeGroupID,
 IsCreditReportValidCB, POBCountryID, WeekendFeePrecentage,
 FirstDepositAmount, FirstDepositDate, HasAvatar, IsDepositor,
 ScreeningStatusID, SalesForceAccountID, IsAddressProof,
 IsAddressProofExpiryDate, IsIDProof, IsIDProofExpiryDate,
 WorldCheckID, WorldCheckResultsUpdated, TanganyID, TanganyStatusID,
 EquiLendID, StocksLendingStatusID, DltID, DltStatusID,
 PhoneNumber, IsPhoneVerified, PhoneVerificationDate, PhoneVerifiedID,
 FTDRecoveryDate, FTDTransactionID, FTDPlatformID)
SELECT
    a.GCID, a.CID, a.OriginalCID, a.UserName, a.FirstName, a.LastName, a.MiddleName,
    a.Gender, a.BirthDate, a.ReferralID, a.CountryID, a.IP,
    COALESCE(a.AffiliateID, 0), COALESCE(a.CampaignID, 0),
    a.LabelID, a.LanguageID, a.Email, a.Phone, a.Zip, a.City, a.Address, a.BuildingNumber,
    COALESCE(a.VerificationLevelID, 0), COALESCE(a.PlayerStatusID, 0),
    COALESCE(a.FunnelID, 0), COALESCE(a.DownloadID, 0), a.Registered,
    COALESCE(a.FunnelFromID, 0), COALESCE(a.RiskStatusID, 0),
    COALESCE(a.RiskClassificationID, 200), a.EmployeeAccount,
    COALESCE(a.CommunicationLanguageID, 0), COALESCE(a.BannerID, 0),
    COALESCE(a.GuruStatusID, 0), COALESCE(a.AccountTypeID, 0),
    COALESCE(a.RegulationID, 0), COALESCE(a.PlayerLevelID, 0),
    COALESCE(a.AccountStatusID, 0), COALESCE(a.AccountManagerID, 0),
    a.ID, a.ExternalID, a.PlayerStatusReasonID, a.PendingClosureStatusID,
    a.CountryIDByIP, a.SubSerialID, a.EvMatchStatus,
    COALESCE(a.DocumentStatusID, 0), a.RegulationChangeDate, a.IsCopyBlocked,
    a.IsEDD, a.SuitabilityTestStatusID, a.MifidCategorizationID,
    current_timestamp(),
    CAST(a.IsEmailVerified AS INT), a.IsValidCustomer, a.`2FA`,
    a.DesignatedRegulationID, a.RegionByIP_ID, a.RegionID, CAST(a.HasWallet AS INT),
    a.CitizenshipCountryID, a.PlayerStatusSubReasonID, a.PrivacyPolicyID,
    a.CashoutFeeGroupID, a.IsCreditReportValidCB,
    a.POBCountryID, a.WeekendFeePrecentage,
    -- Preserved from prior state
    b.FirstDepositAmount,
    COALESCE(b.FirstDepositDate, TIMESTAMP '1900-01-01'),
    b.HasAvatar,
    COALESCE(CAST(b.IsDepositor AS BOOLEAN), FALSE),
    b.ScreeningStatusID, b.SalesForceAccountID,
    b.IsAddressProof, b.IsAddressProofExpiryDate,
    b.IsIDProof, b.IsIDProofExpiryDate,
    b.WorldCheckID, b.WorldCheckResultsUpdated,
    b.TanganyID, b.TanganyStatusID,
    b.EquiLendID, b.StocksLendingStatusID, b.DltID, b.DltStatusID,
    b.PhoneNumber, b.IsPhoneVerified, b.PhoneVerificationDate, b.PhoneVerifiedID,
    b.FTDRecoveryDate, b.FTDTransactionID, b.FTDPlatformID
FROM dwh_daily_process.migration_tables._tmp_sp_dimcust_full_list a
LEFT JOIN dwh_daily_process.migration_tables._tmp_sp_dimcust_initial b
    ON a.CID = b.RealCID;

SET V_rnum = (SELECT count(*) FROM dwh_daily_process.migration_tables._tmp_sp_dimcust_full_list LIMIT 1);

-- ============================================================
-- STEP 7: UPDATE Avatar
-- ============================================================
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_avatar AS
SELECT RealCID, Avatars.HasAvatar
FROM dwh_daily_process.migration_tables.Dim_Customer a
JOIN (SELECT CID, 1 AS HasAvatar
      FROM (
          SELECT DISTINCT CID FROM dwh_daily_process.migration_tables.Ext_Dim_Customer_Avatars
          EXCEPT
          SELECT CID FROM dwh_daily_process.migration_tables.Ext_Dim_Customer_Avatars
          WHERE ImageURL LIKE '%default-avatars%' OR ImageURL LIKE '%avatoros%'
      ) a
) Avatars ON a.RealCID = Avatars.CID
WHERE NOT (a.HasAvatar <=> Avatars.HasAvatar);

SET V_avtar_rn = (SELECT count(*) FROM TEMP_TABLE_avatar LIMIT 1);

-- STEP 8: UPDATE FTD
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_deposit AS
SELECT DISTINCT b.RealCID AS CID,
    a.FTDDate, 1 AS IsDepositor, a.FTDAmountInUsd, a.FTDRecoveryDate, a.FTDTransactionID, a.FTDPlatformID
FROM dwh_daily_process.migration_tables.Ext_CustomerFinanceDB_Customer_FirstTimeDeposits a
JOIN dwh_daily_process.migration_tables.Dim_Customer b ON a.GCID = b.GCID
WHERE a.FTDDate < CURRENT_DATE();

MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
    SELECT *
    FROM dwh_daily_process.migration_tables.Dim_Customer A
    INNER JOIN TEMP_TABLE_deposit deposit ON A.RealCID = deposit.CID
    QUALIFY ROW_NUMBER() OVER (PARTITION BY A.RealCID ORDER BY 1) = 1
)
ON A.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
    IsDepositor = COALESCE(CAST(deposit.IsDepositor AS BOOLEAN), FALSE),
    FirstDepositDate = CASE WHEN CAST(A.FirstDepositDate AS DATE) < CAST(deposit.FTDRecoveryDate AS DATE) THEN deposit.FTDRecoveryDate ELSE COALESCE(deposit.FTDDate, TIMESTAMP '1900-01-01') END,
    FirstDepositAmount = deposit.FTDAmountInUsd,
    FTDRecoveryDate = deposit.FTDRecoveryDate,
    FTDTransactionID = deposit.FTDTransactionID,
    FTDPlatformID = deposit.FTDPlatformID,
    UpdateDate = current_timestamp();

-- STEP 9: UPDATE ScreeningStatusID
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
    SELECT *
    FROM dwh_daily_process.migration_tables.Dim_Customer A
    INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_ScreeningStatusID B ON A.RealCID = B.CID
    QUALIFY ROW_NUMBER() OVER (PARTITION BY A.RealCID ORDER BY 1) = 1
)
ON A.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
    ScreeningStatusID = B.ScreeningStatusID,
    UpdateDate = current_timestamp();

-- STEP 10: UPDATE SalesForceAccountID
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
    SELECT *
    FROM dwh_daily_process.migration_tables.Dim_Customer A
    INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_SF_ID B ON A.RealCID = B.CID
    QUALIFY ROW_NUMBER() OVER (PARTITION BY A.RealCID ORDER BY 1) = 1
)
ON A.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
    SalesForceAccountID = B.SF_ID,
    UpdateDate = current_timestamp();

-- STEP 11: UPDATE Document Proofs
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
    SELECT *
    FROM dwh_daily_process.migration_tables.Dim_Customer A
    INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_Document B ON A.RealCID = B.CID
    QUALIFY ROW_NUMBER() OVER (PARTITION BY A.RealCID ORDER BY 1) = 1
)
ON A.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
    IsAddressProof = B.IsAddressProof,
    IsAddressProofExpiryDate = B.IsAddressProofExpiryDate,
    IsIDProof = B.IsIDProof,
    IsIDProofExpiryDate = B.IsIDProofExpiryDate,
    UpdateDate = current_timestamp();

-- STEP 12: UPDATE 2FA
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
    SELECT *
    FROM dwh_daily_process.migration_tables.Dim_Customer C
    INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_2FA FA ON C.GCID = FA.GCID
    QUALIFY ROW_NUMBER() OVER (PARTITION BY C.GCID ORDER BY 1) = 1
)
ON C.GCID = A_TGT.GCID
WHEN MATCHED THEN UPDATE SET
    `2FA` = FA.`2FA`,
    UpdateDate = current_timestamp();

-- STEP 13: UPDATE SubChannelID (Affiliate)
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
    SELECT *
    FROM dwh_daily_process.migration_tables.Dim_Customer A
    INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_Affiliate B ON A.AffiliateID = B.AffiliateID
    QUALIFY ROW_NUMBER() OVER (PARTITION BY A.AffiliateID ORDER BY 1) = 1
)
ON A.AffiliateID = A_TGT.AffiliateID
WHEN MATCHED THEN UPDATE SET
    SubChannelID = B.SubChannelID,
    UpdateDate = current_timestamp();

-- STEP 14: UPDATE ApexID
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
    SELECT *
    FROM dwh_daily_process.migration_tables.Dim_Customer A
    INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_CustomerStatic B ON A.RealCID = B.CID
    QUALIFY ROW_NUMBER() OVER (PARTITION BY A.RealCID ORDER BY 1) = 1
)
ON A.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
    ApexID = B.ApexID,
    UpdateDate = current_timestamp();

-- STEP 15: UPDATE Phone
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
    SELECT *
    FROM dwh_daily_process.migration_tables.Dim_Customer A
    INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_PhoneCustomer B ON A.GCID = B.GCID
    QUALIFY ROW_NUMBER() OVER (PARTITION BY A.GCID ORDER BY 1) = 1
)
ON A.GCID = A_TGT.GCID
WHEN MATCHED THEN UPDATE SET
    PhoneNumber = B.PhoneNumber,
    IsPhoneVerified = B.IsPhoneVerified,
    PhoneVerificationDate = B.PhoneVerificationDate,
    PhoneVerifiedID = B.PhoneVerifiedID,
    UpdateDate = current_timestamp();

-- STEP 16: UPDATE Tangany
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
    SELECT *
    FROM dwh_daily_process.migration_tables.Dim_Customer A
    INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_CustomerIdentification B ON A.RealCID = B.CID
    QUALIFY ROW_NUMBER() OVER (PARTITION BY A.RealCID ORDER BY 1) = 1
)
ON A.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
    TanganyID = B.TanganyID,
    TanganyStatusID = B.TanganyStatusID,
    UpdateDate = current_timestamp();

-- STEP 17: UPDATE DLT
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
    SELECT *
    FROM dwh_daily_process.migration_tables.Dim_Customer A
    INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_CustomerIdentification B ON A.RealCID = B.CID
    QUALIFY ROW_NUMBER() OVER (PARTITION BY A.RealCID ORDER BY 1) = 1
)
ON A.RealCID = A_TGT.RealCID
WHEN MATCHED THEN UPDATE SET
    DltID = B.DltID,
    DltStatusID = B.DltStatusID,
    UpdateDate = current_timestamp();

-- STEP 18: UPDATE StocksLending
MERGE INTO dwh_daily_process.migration_tables.Dim_Customer A_TGT
USING (
    SELECT *
    FROM dwh_daily_process.migration_tables.Dim_Customer A
    INNER JOIN dwh_daily_process.migration_tables.Ext_Dim_Customer_StocksLending B ON A.GCID = B.GCID
    QUALIFY ROW_NUMBER() OVER (PARTITION BY A.GCID ORDER BY 1) = 1
)
ON A.GCID = A_TGT.GCID
WHEN MATCHED THEN UPDATE SET
    EquiLendID = B.EquiLendID,
    StocksLendingStatusID = B.StocksLendingStatusID,
    UpdateDate = current_timestamp();

-- STEP 19: Rebuild ExternalID_GCID lookup
TRUNCATE TABLE dwh_daily_process.migration_tables.Ext_Dim_Customer_ExternalID_GCID;

INSERT INTO dwh_daily_process.migration_tables.Ext_Dim_Customer_ExternalID_GCID
    (RealCID, GCID, ExternalID, UpdateDate)
SELECT RealCID, GCID, ExternalID, current_timestamp()
FROM dwh_daily_process.migration_tables.Dim_Customer;

-- STEP 20: UPDATE UserName_Lower
UPDATE dwh_daily_process.migration_tables.Dim_Customer SET UserName_Lower = LOWER(UserName);

-- ============================================================
-- CLEANUP: Drop scratch Delta tables
-- ============================================================
DROP TABLE IF EXISTS dwh_daily_process.migration_tables._tmp_sp_dimcust_customer;
DROP TABLE IF EXISTS dwh_daily_process.migration_tables._tmp_sp_dimcust_new;
DROP TABLE IF EXISTS dwh_daily_process.migration_tables._tmp_sp_dimcust_update;
DROP TABLE IF EXISTS dwh_daily_process.migration_tables._tmp_sp_dimcust_full_list;
DROP TABLE IF EXISTS dwh_daily_process.migration_tables._tmp_sp_dimcust_initial;
DROP VIEW IF EXISTS TEMP_TABLE_avatar;
DROP VIEW IF EXISTS TEMP_TABLE_deposit;

END