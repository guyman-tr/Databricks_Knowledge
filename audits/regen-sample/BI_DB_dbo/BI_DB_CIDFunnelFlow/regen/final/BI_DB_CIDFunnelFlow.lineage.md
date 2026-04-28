# Lineage: BI_DB_dbo.BI_DB_CIDFunnelFlow

## Source Objects

| Source Object | Type | Schema | Role |
|--------------|------|--------|------|
| DWH_dbo.Dim_Customer | Table | DWH_dbo | Primary source — customer attributes (registration, verification, compliance, deposit history) |
| DWH_dbo.Dim_Funnel | Table | DWH_dbo | Lookup — funnel name resolution via FunnelFromID |
| DWH_dbo.Dim_Platform | Table | DWH_dbo | Lookup — platform label via Dim_Funnel.PlatformID |
| DWH_dbo.Dim_Affiliate | Table | DWH_dbo | Lookup — affiliate-to-subchannel mapping via AffiliateID |
| DWH_dbo.Dim_Channel | Table | DWH_dbo | Lookup — channel/subchannel classification via Dim_Affiliate.SubChannelID |
| DWH_dbo.Dim_Country | Table | DWH_dbo | Lookup — country name and marketing region via CountryID |
| DWH_dbo.Dim_State_and_Province | Table | DWH_dbo | Lookup — US state name via RegionByIP_ID (only when CountryID=219) |
| DWH_dbo.Dim_Regulation | Table | DWH_dbo | Lookup — regulation name via RegulationID and DesignatedRegulationID |
| DWH_dbo.Dim_ScreeningStatus | Table | DWH_dbo | Lookup — screening status name (PEP) via ScreeningStatusID |
| DWH_dbo.Fact_SnapshotCustomer | Table | DWH_dbo | First designated regulation date resolution via DateRangeID → Dim_Range |
| DWH_dbo.Dim_Range | Table | DWH_dbo | Date range decoding for Fact_SnapshotCustomer DateRangeID |
| DWH_dbo.Fact_BillingDeposit | Table | DWH_dbo | Deposit attempt detection (PaymentStatusID=2 approved deposits) |
| BI_DB_dbo.BI_DB_UsageTracking_SF | Table | BI_DB_dbo | Salesforce CRM contact activity (IsContacted, PhoneContacted, EmailContacted, etc.) |
| BI_DB_dbo.SP_CIDFunnelFlow | Stored Procedure | BI_DB_dbo | Writer SP — TRUNCATE + INSERT, @Date parameter |

## Column Lineage

| Target Column | Source Object | Source Column | Transform | Tier |
|--------------|--------------|---------------|-----------|------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | Passthrough | Tier 1 — Customer.CustomerStatic |
| Date | DWH_dbo.Dim_Customer | RegisteredReal | CAST(RegisteredReal AS date) | Tier 2 — SP_CIDFunnelFlow |
| Region | DWH_dbo.Dim_Country | Region | Dim-lookup passthrough via Dim_Customer.CountryID | Tier 1 — Dictionary.MarketingRegion |
| Country | DWH_dbo.Dim_Country | Name | Dim-lookup passthrough via Dim_Customer.CountryID | Tier 1 — Dictionary.Country |
| State | DWH_dbo.Dim_State_and_Province | Name | Conditional dim-lookup: only when CountryID=219 (US); NULL otherwise | Tier 2 — SP_CIDFunnelFlow |
| Channel | DWH_dbo.Dim_Channel | Channel | Dim-lookup chain: Dim_Customer.AffiliateID → Dim_Affiliate.SubChannelID → Dim_Channel.Channel | Tier 2 — SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse |
| SubChannel | DWH_dbo.Dim_Channel | SubChannel | Dim-lookup chain: Dim_Customer.AffiliateID → Dim_Affiliate.SubChannelID → Dim_Channel.SubChannel | Tier 2 — SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse |
| Funnel | DWH_dbo.Dim_Funnel | Name | Dim-lookup passthrough via Dim_Customer.FunnelFromID | Tier 1 — Dictionary.Funnel |
| DesignatedRegulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup via first DesignatedRegulationID from Fact_SnapshotCustomer history | Tier 1 — Dictionary.Regulation |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup passthrough via Dim_Customer.RegulationID | Tier 1 — Dictionary.Regulation |
| AffiliateID | DWH_dbo.Dim_Customer | AffiliateID | Passthrough | Tier 1 — Customer.CustomerStatic |
| FunnelFrom | DWH_dbo.Dim_Funnel | Name | Dim-lookup passthrough via Dim_Customer.FunnelFromID | Tier 1 — Dictionary.Funnel |
| Platform | DWH_dbo.Dim_Platform | Platform | Dim-lookup chain: Dim_Customer.FunnelFromID → Dim_Funnel.PlatformID → Dim_Platform.Platform | Tier 1 — Dictionary.Platform |
| REG | DWH_dbo.Dim_Customer | RegisteredReal | CASE WHEN RegisteredReal > '19000101' THEN 1 ELSE 0 END (always 1 due to WHERE filter) | Tier 2 — SP_CIDFunnelFlow |
| EmailVerification | DWH_dbo.Dim_Customer | IsEmailVerified | MAX(IsEmailVerified) | Tier 2 — SP_CIDFunnelFlow |
| V1 | DWH_dbo.Dim_Customer | VerificationLevelID | CASE WHEN VerificationLevelID >= 1 THEN 1 ELSE 0 END | Tier 2 — SP_CIDFunnelFlow |
| V2 | DWH_dbo.Dim_Customer | VerificationLevelID | CASE WHEN VerificationLevelID >= 2 THEN 1 ELSE 0 END | Tier 2 — SP_CIDFunnelFlow |
| V3 | DWH_dbo.Dim_Customer | VerificationLevelID | CASE WHEN VerificationLevelID = 3 THEN 1 ELSE 0 END | Tier 2 — SP_CIDFunnelFlow |
| EV | DWH_dbo.Dim_Customer | EvMatchStatus | CASE WHEN EvMatchStatus = 2 THEN 1 ELSE 0 END | Tier 2 — SP_CIDFunnelFlow |
| SendToEV | DWH_dbo.Dim_Customer | EvMatchStatus | CASE WHEN EvMatchStatus IN (1,2,3) THEN 1 ELSE 0 END | Tier 2 — SP_CIDFunnelFlow |
| PEP | DWH_dbo.Dim_ScreeningStatus | Name | Dim-lookup passthrough via Dim_Customer.ScreeningStatusID | Tier 1 — ScreeningService.Dictionary.ScreeningStatus |
| ProofOfAddress | DWH_dbo.Dim_Customer | IsAddressProof, IsAddressProofExpiryDate | CASE WHEN IsAddressProof=1 AND ExpiryDate >= @Date THEN 1 ELSE 0 END; MAX(ISNULL(...,0)) | Tier 2 — SP_CIDFunnelFlow |
| ProofOfIdentity | DWH_dbo.Dim_Customer | IsIDProof, IsIDProofExpiryDate | CASE WHEN IsIDProof=1 AND ExpiryDate >= @Date THEN 1 ELSE 0 END; MAX(ISNULL(...,0)) | Tier 2 — SP_CIDFunnelFlow |
| PhoneVerified | DWH_dbo.Dim_Customer | PhoneVerifiedID | CASE WHEN PhoneVerifiedID IN (1,2) THEN 1 ELSE 0 END; MAX(ISNULL(...,0)) | Tier 2 — SP_CIDFunnelFlow |
| POA_POI | DWH_dbo.Dim_Customer | IsIDProof, IsAddressProof | CASE WHEN IsIDProof > 0 AND IsAddressProof > 0 THEN 1 ELSE 0 END | Tier 2 — SP_CIDFunnelFlow |
| POA_POI_Phone | (not populated) | — | Column exists in DDL but is NOT in the SP INSERT column list; always NULL | Tier 3 — DDL only, not populated |
| DepositAttempt | DWH_dbo.Fact_BillingDeposit | CID, PaymentStatusID | CASE WHEN CID exists in Fact_BillingDeposit WITH PaymentStatusID=2 THEN 1 ELSE 0 END | Tier 2 — SP_CIDFunnelFlow |
| FTD | DWH_dbo.Dim_Customer | FirstDepositDate | CASE WHEN FirstDepositDate > '19000101' THEN 1 ELSE 0 END | Tier 2 — SP_CIDFunnelFlow |
| IsContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | CreatedDate_SF | CASE WHEN any SF action before FTD (or after registration if no FTD) THEN 1 ELSE 0 END | Tier 2 — SP_CIDFunnelFlow |
| PhoneContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName, CreatedDate_SF | CASE WHEN ActionName='Contacted__c' before FTD THEN 1 ELSE 0 END | Tier 2 — SP_CIDFunnelFlow |
| EmailContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName, CreatedDate_SF | CASE WHEN ActionName='Outbound_Email__c' before FTD THEN 1 ELSE 0 END | Tier 2 — SP_CIDFunnelFlow |
| PhoneContactedSucceed | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName, CreatedDate_SF | CASE WHEN ActionName='Phone_Call_Succeed__c' before FTD THEN 1 ELSE 0 END | Tier 2 — SP_CIDFunnelFlow |
| EmailContactedSucceed | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName, CreatedDate_SF | CASE WHEN ActionName='Completed_Contact_Email__c' before FTD THEN 1 ELSE 0 END | Tier 2 — SP_CIDFunnelFlow |
| ConvOver96H | DWH_dbo.Dim_Customer | RegisteredReal, FirstDepositDate | CASE WHEN DATEDIFF(hh, RegisteredReal, FirstDepositDate) > 96 THEN 1 ELSE 0 END | Tier 2 — SP_CIDFunnelFlow |
| PendingVerification | DWH_dbo.Dim_Customer | PlayerStatusID, VerificationLevelID | CASE WHEN PlayerStatusID=13 AND VerificationLevelID != 3 THEN 1 ELSE 0 END | Tier 2 — SP_CIDFunnelFlow |
| ReportDateID | DWH_dbo.Dim_Customer | RegisteredReal | CONVERT(VARCHAR(8), CAST(RegisteredReal AS date), 112) — YYYYMMDD string | Tier 2 — SP_CIDFunnelFlow |
| UpdateDate | (ETL-computed) | — | GETDATE() at SP execution time | Tier 2 — SP_CIDFunnelFlow |
