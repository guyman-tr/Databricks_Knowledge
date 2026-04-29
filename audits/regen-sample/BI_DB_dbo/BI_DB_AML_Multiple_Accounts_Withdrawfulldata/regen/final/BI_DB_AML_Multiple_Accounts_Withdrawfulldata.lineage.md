# Lineage — BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Withdrawfulldata

## Source Objects

| # | Source Object | Schema | Type | Role | Resolved Wiki |
|---|--------------|--------|------|------|---------------|
| 1 | Fact_BillingWithdraw | DWH_dbo | Table | Identifies FundingIDs shared by 2+ customers for withdrawals; provides FundingID per CID | DWH_dbo/Tables/Fact_BillingWithdraw.md |
| 2 | Dim_Customer | DWH_dbo | Table | Customer demographics, status, compliance, and identity attributes (filtered: IsValidCustomer=1, IsDepositor=1, VerificationLevelID>=2) | DWH_dbo/Tables/Dim_Customer.md |
| 3 | Dim_Country | DWH_dbo | Table | Resolves CountryID to country Name | DWH_dbo/Tables/Dim_Country.md |
| 4 | Dim_Regulation | DWH_dbo | Table | Resolves RegulationID to regulation Name | DWH_dbo/Tables/Dim_Regulation.md |
| 5 | Dim_PlayerStatus | DWH_dbo | Table | Resolves PlayerStatusID to status Name | DWH_dbo/Tables/Dim_PlayerStatus.md |
| 6 | Dim_PlayerLevel | DWH_dbo | Table | Resolves PlayerLevelID to club Name | DWH_dbo/Tables/Dim_PlayerLevel.md |
| 7 | Dim_PhoneVerified | DWH_dbo | Table | Resolves PhoneVerifiedID to PhoneVerifiedName | DWH_dbo/Tables/Dim_PhoneVerified.md |
| 8 | Dim_PlayerStatusReasons | DWH_dbo | Table | Resolves PlayerStatusReasonID to reason Name | DWH_dbo/Tables/Dim_PlayerStatusReasons.md |
| 9 | Dim_PlayerStatusSubReasons | DWH_dbo | Table | Resolves PlayerStatusSubReasonID to sub-reason Name | DWH_dbo/Tables/Dim_PlayerStatusSubReasons.md |
| 10 | Dim_EvMatchStatus | DWH_dbo | Table | Resolves EvMatchStatus to EvMatchStatusName | DWH_dbo/Tables/Dim_EvMatchStatus.md |
| 11 | eMoney_Dim_Account | eMoney_dbo | Table | Provides AccountProgram for customers with valid eToro Money accounts | eMoney_dbo/Tables/eMoney_Dim_Account.md |
| 12 | V_Liabilities | DWH_dbo | View | Provides Liabilities, RealizedEquity, PositionPnL, and ActualNWA for TotalEquity computation | DWH_dbo/Views/V_Liabilities.md |
| 13 | External_AlertServiceDB_Alert_Alert | BI_DB_dbo | External Table | Most recent risk alert per CID (ROW_NUMBER PARTITION BY CID ORDER BY ModificationDate DESC, RN=1) | -- (unresolved) |
| 14 | External_AlertServiceDB_Configuration_AlertTemplate | BI_DB_dbo | External Table | Links Alert to AlertType, Category, TriggerType | -- (unresolved) |
| 15 | External_AlertServiceDB_Dictionary_AlertType | BI_DB_dbo | External Table | Alert type Name and Description | -- (unresolved) |
| 16 | External_AlertServiceDB_Dictionary_Category | BI_DB_dbo | External Table | Alert category Name | -- (unresolved) |
| 17 | External_AlertServiceDB_Dictionary_TriggerType | BI_DB_dbo | External Table | Alert trigger type Name | -- (unresolved) |
| 18 | External_AlertServiceDB_Configuration_AlertStatus | BI_DB_dbo | External Table | Links Alert StatusID to StatusType and StatusReason | -- (unresolved) |
| 19 | External_AlertServiceDB_Dictionary_StatusType | BI_DB_dbo | External Table | Alert status type Name | -- (unresolved) |
| 20 | External_AlertServiceDB_Dictionary_StatusReason | BI_DB_dbo | External Table | Alert status reason Name | -- (unresolved) |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|-----------|---------------|---------------|-----------|------|
| 1 | FundingID | Fact_BillingWithdraw | FundingID | Passthrough (DISTINCT from withdrawal fact for shared-FID customers) | Tier 1 -- Billing.Withdraw |
| 2 | CID | Dim_Customer | RealCID | Rename: RealCID -> CID | Tier 1 -- Customer.CustomerStatic |
| 3 | GCID | Dim_Customer | GCID | Passthrough | Tier 1 -- Customer.CustomerStatic |
| 4 | UserName | Dim_Customer | UserName | Passthrough | Tier 1 -- Customer.CustomerStatic |
| 5 | BirthDate | Dim_Customer | BirthDate | CAST(dc.BirthDate AS DATE) -- time component discarded | Tier 1 -- Customer.CustomerStatic |
| 6 | PhoneVerifiedName | Dim_PhoneVerified | PhoneVerifiedName | Dim-lookup passthrough via Dim_Customer.PhoneVerifiedID | Tier 1 -- Dictionary.PhoneVerified |
| 7 | RegisteredReal | Dim_Customer | RegisteredReal | Passthrough | Tier 1 -- Customer.CustomerStatic |
| 8 | FirstDepositDate | Dim_Customer | FirstDepositDate | Passthrough (DWH-computed in SP_Dim_Customer) | Tier 2 -- SP_Dim_Customer |
| 9 | VerificationLevelID | Dim_Customer | VerificationLevelID | Passthrough | Tier 1 -- BackOffice.Customer |
| 10 | Country | Dim_Country | Name | Dim-lookup passthrough via Dim_Customer.CountryID = Dim_Country.DWHCountryID | Tier 1 -- Dictionary.Country |
| 11 | Regulation | Dim_Regulation | Name | Dim-lookup passthrough via Dim_Customer.RegulationID = Dim_Regulation.DWHRegulationID | Tier 1 -- Dictionary.Regulation |
| 12 | PlayerStatus | Dim_PlayerStatus | Name | Dim-lookup passthrough via Dim_Customer.PlayerStatusID | Tier 1 -- Dictionary.PlayerStatus |
| 13 | PlayerStatusReason | Dim_PlayerStatusReasons | Name | Dim-lookup passthrough via Dim_Customer.PlayerStatusReasonID | Tier 1 -- Dictionary.PlayerStatusReasons |
| 14 | PlayerStatusSubReasonName | Dim_PlayerStatusSubReasons | PlayerStatusSubReasonName | Dim-lookup passthrough via Dim_Customer.PlayerStatusSubReasonID | Tier 1 -- Dictionary.PlayerStatusSubReasons |
| 15 | Club | Dim_PlayerLevel | Name | Dim-lookup passthrough via Dim_Customer.PlayerLevelID | Tier 1 -- Dictionary.PlayerLevel |
| 16 | AffiliateID | Dim_Customer | AffiliateID | Passthrough | Tier 1 -- Customer.CustomerStatic |
| 17 | City | Dim_Customer | City | Passthrough | Tier 1 -- Customer.CustomerStatic |
| 18 | Zip | Dim_Customer | Zip | Passthrough | Tier 1 -- Customer.CustomerStatic |
| 19 | BuildingNumber | Dim_Customer | BuildingNumber | Passthrough | Tier 1 -- Customer.CustomerStatic |
| 20 | Gender | Dim_Customer | Gender | Passthrough | Tier 1 -- Customer.CustomerStatic |
| 21 | EvMatchStatusName | Dim_EvMatchStatus | EvMatchStatusName | Dim-lookup passthrough via Dim_Customer.EvMatchStatus | Tier 2 -- SP_AML_Multiple_Accounts, via Dim_EvMatchStatus |
| 22 | HasWallet | Dim_Customer | HasWallet | Passthrough | Tier 1 -- BackOffice.Customer |
| 23 | AccountProgram | eMoney_Dim_Account | AccountProgram | Passthrough (filtered: IsValidETM=1, IsTestAccount=0) | Tier 2 -- SP_eMoney_Dim_Account |
| 24 | Liabilities | V_Liabilities | Liabilities | Passthrough (joined on CID and @DateID) | Tier 2 -- V_Liabilities (computed) |
| 25 | RealizedEquity | V_Liabilities | RealizedEquity | Passthrough | Tier 1 -- Fact_SnapshotEquity |
| 26 | PositionPnL | V_Liabilities | PositionPnL | Passthrough | Tier 1 -- Fact_CustomerUnrealized_PnL |
| 27 | TotalEquity | V_Liabilities | Liabilities + ActualNWA | ISNULL(vl.Liabilities, 0) + ISNULL(vl.ActualNWA, 0) | Tier 2 -- SP_AML_Multiple_Accounts |
| 28 | AlertID | External_AlertServiceDB_Alert_Alert | Id | Rename: Id -> AlertID. Most recent alert per CID (ROW_NUMBER, RN=1) | Tier 3 -- AlertServiceDB (no upstream wiki) |
| 29 | CreationDate | External_AlertServiceDB_Alert_Alert | CreationDate | Passthrough (most recent alert per CID) | Tier 3 -- AlertServiceDB (no upstream wiki) |
| 30 | ModificationDate | External_AlertServiceDB_Alert_Alert | ModificationDate | Passthrough (most recent alert per CID) | Tier 3 -- AlertServiceDB (no upstream wiki) |
| 31 | AlertType | External_AlertServiceDB_Dictionary_AlertType | Name | Dim-lookup via TemplateID -> AlertTemplate -> AlertTypeID | Tier 3 -- AlertServiceDB (no upstream wiki) |
| 32 | AlertTypeDescription | External_AlertServiceDB_Dictionary_AlertType | Description | Dim-lookup via TemplateID -> AlertTemplate -> AlertTypeID | Tier 3 -- AlertServiceDB (no upstream wiki) |
| 33 | CategoryName | External_AlertServiceDB_Dictionary_Category | Name | Dim-lookup via TemplateID -> AlertTemplate -> CategoryID | Tier 3 -- AlertServiceDB (no upstream wiki) |
| 34 | TriggerType | External_AlertServiceDB_Dictionary_TriggerType | Name | Dim-lookup via TemplateID -> AlertTemplate -> TriggerType | Tier 3 -- AlertServiceDB (no upstream wiki) |
| 35 | StatusType | External_AlertServiceDB_Dictionary_StatusType | Name | Dim-lookup via StatusID -> AlertStatus -> StatusTypeID | Tier 3 -- AlertServiceDB (no upstream wiki) |
| 36 | StatusReason | External_AlertServiceDB_Dictionary_StatusReason | Name | Dim-lookup via StatusID -> AlertStatus -> StatusReasonID | Tier 3 -- AlertServiceDB (no upstream wiki) |
| 37 | UpdateDate | -- | -- | ETL-computed: GETDATE() at INSERT time | Tier 2 -- SP_AML_Multiple_Accounts |
