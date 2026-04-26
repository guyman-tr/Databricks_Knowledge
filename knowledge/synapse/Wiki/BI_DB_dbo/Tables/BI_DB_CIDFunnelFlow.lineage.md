# Lineage: BI_DB_dbo.BI_DB_CIDFunnelFlow

## Object Metadata

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object** | BI_DB_CIDFunnelFlow |
| **Type** | Table |
| **Writer SP** | BI_DB_dbo.SP_CIDFunnelFlow |
| **Primary Source** | DWH_dbo.Dim_Customer (WHERE RegisteredReal >= dateadd(month,-12,@Date) AND IsValidCustomer=1) |
| **Secondary Source** | DWH_dbo.Fact_SnapshotCustomer (DesignatedRegulation RANK=1) |
| **Tertiary Source** | BI_DB_dbo.BI_DB_UsageTracking_SF (contact actions before FTD) |
| **UC Target** | _Not_Migrated |

## ETL Chain

```
DWH_dbo.Dim_Customer (WHERE RegisteredReal >= DATEADD(month,-12,@Date) AND IsValidCustomer=1)
  + DWH_dbo.Dim_Funnel, Dim_Platform (via FunnelFromID — resolved in #POP staging table)
  |-- #POP temp table (HEAP, ROUND_ROBIN) ---|
  + DWH_dbo.Fact_SnapshotCustomer + Dim_Range (earliest DesignatedRegulationID after registration)
  |-- #DesignatedRegulation / #DesignatedRegulation2 (RANK() by DateID) ---|
  + DWH_dbo.Dim_Country, Dim_State_and_Province, Dim_Channel, Dim_Affiliate
  + DWH_dbo.Dim_Funnel (re-joined for Funnel name), Dim_Regulation DR (DesignatedRegulation name)
  + DWH_dbo.Dim_Regulation DR2 (current Regulation name via RegulationID=DR2.ID)
  + DWH_dbo.Fact_BillingDeposit (DepositAttempt — PaymentStatusID=2)
  + BI_DB_dbo.BI_DB_UsageTracking_SF (contact actions before FTD date)
  + DWH_dbo.Dim_ScreeningStatus (PEP screening status name)
  |-- SP_CIDFunnelFlow @Date (TRUNCATE + INSERT GROUP BY RealCID) ---|
  v
BI_DB_dbo.BI_DB_CIDFunnelFlow (3,970,310 rows — 1 row per customer, rolling 12-month cohort)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|--------------|---------------|-----------|------|
| 1 | RealCID | DWH_dbo.Dim_Customer | RealCID | GROUP BY key — unique customer identifier | Tier 2 |
| 2 | Date | DWH_dbo.Dim_Customer | RegisteredReal | CAST(RegisteredReal AS date) — date portion of registration timestamp | Tier 2 |
| 3 | Region | DWH_dbo.Dim_Country | Region | LEFT JOIN on CountryID — geographic macro-region name | Tier 2 |
| 4 | Country | DWH_dbo.Dim_Country | Name | LEFT JOIN on CountryID — country name | Tier 2 |
| 5 | State | DWH_dbo.Dim_State_and_Province | Name | LEFT JOIN on RegionID=RegionByIP_ID — only populated when CountryID=219 (USA) per #POP CASE | Tier 2 |
| 6 | Channel | DWH_dbo.Dim_Channel | Channel | LEFT JOIN via Dim_Affiliate.SubChannelID → Dim_Channel — acquisition channel | Tier 2 |
| 7 | SubChannel | DWH_dbo.Dim_Channel | SubChannel | LEFT JOIN via Dim_Affiliate.SubChannelID → Dim_Channel — acquisition sub-channel | Tier 2 |
| 8 | Funnel | DWH_dbo.Dim_Funnel | Name | LEFT JOIN on FunnelFromID in main query — funnel name (duplicate of FunnelFrom, different GROUP BY alias) | Tier 2 |
| 9 | DesignatedRegulation | DWH_dbo.Dim_Regulation | Name | LEFT JOIN DR on #DesignatedRegulation2.DesignatedRegulationID (RANK=1 = earliest snapshot after registration date) | Tier 2 |
| 10 | Regulation | DWH_dbo.Dim_Regulation | Name | LEFT JOIN DR2 on DC.RegulationID = DR2.ID — current regulation at ETL run time | Tier 2 |
| 11 | AffiliateID | DWH_dbo.Dim_Customer | AffiliateID | Passthrough GROUP BY key | Tier 2 |
| 12 | FunnelFrom | DWH_dbo.Dim_Funnel | Name | Resolved as e.Name in #POP staging table via LEFT JOIN on FunnelFromID — funnel name pre-resolved before aggregation | Tier 2 |
| 13 | Platform | DWH_dbo.Dim_Platform | Platform | Resolved as f.Platform in #POP staging table via Dim_Funnel.PlatformID — device/platform type | Tier 2 |
| 14 | REG | DWH_dbo.Dim_Customer | RegisteredReal | MAX(CASE WHEN RegisteredReal > '19000101' THEN 1 ELSE 0 END) — always 1 for valid population (sentinel date guard) | Tier 2 |
| 15 | EmailVerification | DWH_dbo.Dim_Customer | IsEmailVerified | MAX(IsEmailVerified) — 1 if customer verified email | Tier 2 |
| 16 | V1 | DWH_dbo.Dim_Customer | VerificationLevelID | MAX(CASE WHEN VerificationLevelID >= 1 THEN 1 ELSE 0 END) — reached verification level 1 | Tier 2 |
| 17 | V2 | DWH_dbo.Dim_Customer | VerificationLevelID | MAX(CASE WHEN VerificationLevelID >= 2 THEN 1 ELSE 0 END) — reached verification level 2 | Tier 2 |
| 18 | V3 | DWH_dbo.Dim_Customer | VerificationLevelID | MAX(CASE WHEN VerificationLevelID = 3 THEN 1 ELSE 0 END) — fully verified (level 3) | Tier 2 |
| 19 | EV | DWH_dbo.Dim_Customer | EvMatchStatus | MAX(CASE WHEN EvMatchStatus = 2 THEN 1 ELSE 0 END) — electronic verification matched (status=2) | Tier 2 |
| 20 | SendToEV | DWH_dbo.Dim_Customer | EvMatchStatus | MAX(CASE WHEN EvMatchStatus IN (1,2,3) THEN 1 ELSE 0 END) — sent to eVerification (any non-null result) | Tier 2 |
| 21 | PEP | DWH_dbo.Dim_ScreeningStatus | Name | LEFT JOIN on ScreeningStatusID — politically exposed person / AML screening result | Tier 2 |
| 22 | ProofOfAddress | DWH_dbo.Dim_Customer | IsAddressProof | MAX(ISNULL(IsAddressProof, 0)) — from #POP with expiry guard: IsAddressProofExpiryDate >= @Date | Tier 2 |
| 23 | ProofOfIdentity | DWH_dbo.Dim_Customer | IsIDProof | MAX(ISNULL(IsIDProof, 0)) — from #POP with expiry guard: IsIDProofExpiryDate >= @Date | Tier 2 |
| 24 | PhoneVerified | DWH_dbo.Dim_Customer | PhoneVerifiedID | MAX(ISNULL(IsPhoneVerified, 0)) — from #POP: PhoneVerifiedID IN (1,2) → 1 else 0 | Tier 2 |
| 25 | POA_POI | DWH_dbo.Dim_Customer | IsIDProof + IsAddressProof | MAX(CASE WHEN IsIDProof > 0 AND IsAddressProof > 0 THEN 1 ELSE 0 END) — both documents present | Tier 2 |
| 26 | POA_POI_Phone | — | — | NULL — column exists in DDL but SP_CIDFunnelFlow never inserts a value; always NULL (deprecated/stub) | Tier 2 |
| 27 | DepositAttempt | DWH_dbo.Fact_BillingDeposit | CID | MAX(CASE WHEN bd.CID IS NOT NULL THEN 1 ELSE 0 END) — LEFT JOIN on PaymentStatusID=2 records | Tier 2 |
| 28 | FTD | DWH_dbo.Dim_Customer | FirstDepositDate | MAX(CASE WHEN FirstDepositDate > '19000101' THEN 1 ELSE 0 END) — 1 if customer has ever deposited (sentinel date guard) | Tier 2 |
| 29 | IsContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | CreatedDate_SF | MAX(CASE WHEN sf.CreatedDate_SF < FirstDepositDate OR (no FTD AND sf.CreatedDate_SF > RegisteredReal) THEN 1 ELSE 0 END) — any contact before FTD | Tier 2 |
| 30 | PhoneContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | MAX(CASE WHEN ActionName='Contacted__c' AND before-FTD condition THEN 1 ELSE 0 END) — phone contact attempt before FTD | Tier 2 |
| 31 | EmailContacted | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | MAX(CASE WHEN ActionName='Outbound_Email__c' AND before-FTD condition THEN 1 ELSE 0 END) — outbound email before FTD | Tier 2 |
| 32 | PhoneContactedSucceed | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | MAX(CASE WHEN ActionName='Phone_Call_Succeed__c' AND before-FTD condition THEN 1 ELSE 0 END) — successful phone call before FTD | Tier 2 |
| 33 | EmailContactedSucceed | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | MAX(CASE WHEN ActionName='Completed_Contact_Email__c' AND before-FTD condition THEN 1 ELSE 0 END) — completed email contact before FTD | Tier 2 |
| 34 | ConvOver96H | DWH_dbo.Dim_Customer | RegisteredReal + FirstDepositDate | MAX(CASE WHEN DATEDIFF(hh, RegisteredReal, FirstDepositDate) > 96 THEN 1 ELSE 0 END) — FTD occurred more than 96 hours after registration | Tier 2 |
| 35 | PendingVerification | DWH_dbo.Dim_Customer | PlayerStatusID + VerificationLevelID | MAX(CASE WHEN PlayerStatusID = 13 AND VerificationLevelID != 3 THEN 1 ELSE 0 END) — in pending verification status and not fully verified | Tier 2 |
| 36 | ReportDateID | DWH_dbo.Dim_Customer | RegisteredReal | CONVERT(VARCHAR(8), CAST(RegisteredReal AS date), 112) — YYYYMMDD of registration date (NOT ETL run date) | Tier 2 |
| 37 | UpdateDate | SP_CIDFunnelFlow | — | GETDATE() at SP execution time — ETL metadata timestamp | Tier 2 |

## Tier Summary

| Tier | Count | Notes |
|------|-------|-------|
| Tier 1 | 0 | No direct passthrough from a documented upstream production wiki |
| Tier 2 | 37 | All columns — computed milestones, dimension name resolutions, contact logic, ETL metadata |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

## Source Tables Referenced

| Source Object | Type | Role |
|---------------|------|------|
| DWH_dbo.Dim_Customer | Table | Primary — population filter, registration dates, verification state, document state |
| DWH_dbo.Fact_SnapshotCustomer | Table | DesignatedRegulationID — earliest snapshot after registration (RANK=1) |
| DWH_dbo.Dim_Range | Table | DateRangeID→FromDateID for snapshot ordering |
| DWH_dbo.Dim_Regulation | Table | Regulation name lookup (used twice: DR for DesignatedRegulation, DR2 for Regulation) |
| DWH_dbo.Dim_Country | Table | Country name + Region |
| DWH_dbo.Dim_State_and_Province | Table | US state name (CountryID=219 only) |
| DWH_dbo.Dim_Funnel | Table | Funnel name (FunnelFrom pre-resolved in #POP; Funnel resolved in main query) |
| DWH_dbo.Dim_Platform | Table | Platform name via Dim_Funnel.PlatformID |
| DWH_dbo.Dim_Affiliate | Table | SubChannelID for Channel/SubChannel resolution |
| DWH_dbo.Dim_Channel | Table | Channel + SubChannel names |
| DWH_dbo.Dim_ScreeningStatus | Table | PEP/AML screening status name |
| DWH_dbo.Fact_BillingDeposit | Table | DepositAttempt flag (PaymentStatusID=2 records) |
| BI_DB_dbo.BI_DB_UsageTracking_SF | Table | Salesforce contact action events (IsContacted, PhoneContacted, EmailContacted, etc.) |
