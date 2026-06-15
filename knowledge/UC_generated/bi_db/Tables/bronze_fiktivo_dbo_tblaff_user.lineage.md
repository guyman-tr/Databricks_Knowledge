# Column Lineage: main.bi_db.bronze_fiktivo_dbo_tblaff_user

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_dbo_tblaff_user` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-05-19 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/bronze_fiktivo_dbo_tblaff_user.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `UserID` | `—` | `—` | `runtime_lineage` |
| 2 | `AffiliatesGroups` | `—` | `—` | `runtime_lineage` |
| 3 | `Name` | `—` | `—` | `runtime_lineage` |
| 4 | `EmailAddress` | `—` | `—` | `runtime_lineage` |
| 5 | `LoginName` | `—` | `—` | `runtime_lineage` |
| 6 | `LoginPassword` | `—` | `—` | `runtime_lineage` |
| 7 | `AffiliateTypes_ViewAll` | `—` | `—` | `runtime_lineage` |
| 8 | `AffiliateTypes_Edit` | `—` | `—` | `runtime_lineage` |
| 9 | `AffiliateTypes_AddNew` | `—` | `—` | `runtime_lineage` |
| 10 | `AffiliateTypes_Delete` | `—` | `—` | `runtime_lineage` |
| 11 | `Affiliates_ViewAll` | `—` | `—` | `runtime_lineage` |
| 12 | `Affiliates_Edit` | `—` | `—` | `runtime_lineage` |
| 13 | `Affiliates_AddNew` | `—` | `—` | `runtime_lineage` |
| 14 | `Affiliates_Delete` | `—` | `—` | `runtime_lineage` |
| 15 | `Affiliates_ViewTiers` | `—` | `—` | `runtime_lineage` |
| 16 | `Affiliates_Import` | `—` | `—` | `runtime_lineage` |
| 17 | `Categories_ViewAll` | `—` | `—` | `runtime_lineage` |
| 18 | `Categories_Edit` | `—` | `—` | `runtime_lineage` |
| 19 | `Categories_AddNew` | `—` | `—` | `runtime_lineage` |
| 20 | `Categories_Delete` | `—` | `—` | `runtime_lineage` |
| 21 | `Banners_ViewAll` | `—` | `—` | `runtime_lineage` |
| 22 | `Banners_Edit` | `—` | `—` | `runtime_lineage` |
| 23 | `Banners_AddNew` | `—` | `—` | `runtime_lineage` |
| 24 | `Banners_Delete` | `—` | `—` | `runtime_lineage` |
| 25 | `Banners_Import` | `—` | `—` | `runtime_lineage` |
| 26 | `Sales_ViewAll` | `—` | `—` | `runtime_lineage` |
| 27 | `Sales_Edit` | `—` | `—` | `runtime_lineage` |
| 28 | `Sales_AddNew` | `—` | `—` | `runtime_lineage` |
| 29 | `Sales_Delete` | `—` | `—` | `runtime_lineage` |
| 30 | `Sales_Import` | `—` | `—` | `runtime_lineage` |
| 31 | `RecurringSales_ViewAll` | `—` | `—` | `runtime_lineage` |
| 32 | `RecurringSales_AddNew` | `—` | `—` | `runtime_lineage` |
| 33 | `RecurringSales_Delete` | `—` | `—` | `runtime_lineage` |
| 34 | `Leads_ViewAll` | `—` | `—` | `runtime_lineage` |
| 35 | `Leads_Edit` | `—` | `—` | `runtime_lineage` |
| 36 | `Leads_AddNew` | `—` | `—` | `runtime_lineage` |
| 37 | `Leads_Delete` | `—` | `—` | `runtime_lineage` |
| 38 | `Leads_Import` | `—` | `—` | `runtime_lineage` |
| 39 | `TrackingCode` | `—` | `—` | `runtime_lineage` |
| 40 | `AffiliateSignupPage` | `—` | `—` | `runtime_lineage` |
| 41 | `SummaryReport` | `—` | `—` | `runtime_lineage` |
| 42 | `Reports_ClicksLeadsSalesSummary` | `—` | `—` | `runtime_lineage` |
| 43 | `Reports_ClicksLeadsSalesByDay` | `—` | `—` | `runtime_lineage` |
| 44 | `Reports_TrendGraphs` | `—` | `—` | `runtime_lineage` |
| 45 | `Reports_PaymentSummary` | `—` | `—` | `runtime_lineage` |
| 46 | `Reports_AffiliateList` | `—` | `—` | `runtime_lineage` |
| 47 | `Reports_SalesSummary` | `—` | `—` | `runtime_lineage` |
| 48 | `Reports_LeadSummary` | `—` | `—` | `runtime_lineage` |
| 49 | `Reports_ClickSummary` | `—` | `—` | `runtime_lineage` |
| 50 | `Reports_ImpressionsClicks` | `—` | `—` | `runtime_lineage` |
| 51 | `Reports_SaleDetail` | `—` | `—` | `runtime_lineage` |
| 52 | `Reports_LeadDetail` | `—` | `—` | `runtime_lineage` |
| 53 | `Reports_ClickDetail` | `—` | `—` | `runtime_lineage` |
| 54 | `Reports_InactiveAffiliates` | `—` | `—` | `runtime_lineage` |
| 55 | `Reports_Banners` | `—` | `—` | `runtime_lineage` |
| 56 | `Tools_PayAffiliates` | `—` | `—` | `runtime_lineage` |
| 57 | `Tools_EmailBroadcast` | `—` | `—` | `runtime_lineage` |
| 58 | `Tools_SendAcceptanceEmail` | `—` | `—` | `runtime_lineage` |
| 59 | `Tools_ExportPaymentData` | `—` | `—` | `runtime_lineage` |
| 60 | `Tools_EmailEarningsSummaries` | `—` | `—` | `runtime_lineage` |
| 61 | `Tools_EmailLinks` | `—` | `—` | `runtime_lineage` |
| 62 | `Preferences_Setup` | `—` | `—` | `runtime_lineage` |
| 63 | `Preferences_EmailMessages` | `—` | `—` | `runtime_lineage` |
| 64 | `Preferences_AffiliateConsole` | `—` | `—` | `runtime_lineage` |
| 65 | `Preferences_SpiderIPs` | `—` | `—` | `runtime_lineage` |
| 66 | `Preferences_SpiderHeaders` | `—` | `—` | `runtime_lineage` |
| 67 | `Preferences_IPBlocking` | `—` | `—` | `runtime_lineage` |
| 68 | `Announcements_ViewAll` | `—` | `—` | `runtime_lineage` |
| 69 | `Announcements_Edit` | `—` | `—` | `runtime_lineage` |
| 70 | `Announcements_AddNew` | `—` | `—` | `runtime_lineage` |
| 71 | `Announcements_Delete` | `—` | `—` | `runtime_lineage` |
| 72 | `AffiliateGroups_ViewAll` | `—` | `—` | `runtime_lineage` |
| 73 | `AffiliateGroups_Edit` | `—` | `—` | `runtime_lineage` |
| 74 | `AffiliateGroups_AddNew` | `—` | `—` | `runtime_lineage` |
| 75 | `AffiliateGroups_Delete` | `—` | `—` | `runtime_lineage` |
| 76 | `Chargebacks_ViewAll` | `—` | `—` | `runtime_lineage` |
| 77 | `Bonuses_ViewAll` | `—` | `—` | `runtime_lineage` |
| 78 | `Deposits_ViewAll` | `—` | `—` | `runtime_lineage` |
| 79 | `Registrations_ViewAll` | `—` | `—` | `runtime_lineage` |
| 80 | `Reports_DailySummary` | `—` | `—` | `runtime_lineage` |
| 81 | `Reports_DailySummaryByAffiliate` | `—` | `—` | `runtime_lineage` |
| 82 | `Reports_DownloadsReferrer` | `—` | `—` | `runtime_lineage` |
| 83 | `Reports_RegistrationSummary` | `—` | `—` | `runtime_lineage` |
| 84 | `Reports_CPASummary` | `—` | `—` | `runtime_lineage` |
| 85 | `Tools_PayAffiliatesApprove` | `—` | `—` | `runtime_lineage` |
| 86 | `Languages_ViewAll` | `—` | `—` | `runtime_lineage` |
| 87 | `Languages_Edit` | `—` | `—` | `runtime_lineage` |
| 88 | `Languages_AddNew` | `—` | `—` | `runtime_lineage` |
| 89 | `Languages_Delete` | `—` | `—` | `runtime_lineage` |
| 90 | `Brands_ViewAll` | `—` | `—` | `runtime_lineage` |
| 91 | `Brands_Edit` | `—` | `—` | `runtime_lineage` |
| 92 | `Brands_AddNew` | `—` | `—` | `runtime_lineage` |
| 93 | `Brands_Delete` | `—` | `—` | `runtime_lineage` |
| 94 | `Tools_PayAffiliatesReview` | `—` | `—` | `runtime_lineage` |
| 95 | `AffiliateManager` | `—` | `—` | `runtime_lineage` |
| 96 | `ChiefMarketingOfficer` | `—` | `—` | `runtime_lineage` |
| 97 | `AccountingManager` | `—` | `—` | `runtime_lineage` |
| 98 | `Tools_eCPL` | `—` | `—` | `runtime_lineage` |
| 99 | `Tools_eCPR` | `—` | `—` | `runtime_lineage` |
| 100 | `Chargebacks_Delete` | `—` | `—` | `runtime_lineage` |
| 101 | `Deposits_Delete` | `—` | `—` | `runtime_lineage` |
| 102 | `Registrations_Delete` | `—` | `—` | `runtime_lineage` |
| 103 | `Bonuses_Delete` | `—` | `—` | `runtime_lineage` |
| 104 | `Tools_eCost` | `—` | `—` | `runtime_lineage` |
| 105 | `Countries_ViewAll` | `—` | `—` | `runtime_lineage` |
| 106 | `Countries_Edit` | `—` | `—` | `runtime_lineage` |
| 107 | `Countries_AddNew` | `—` | `—` | `runtime_lineage` |
| 108 | `Countries_Delete` | `—` | `—` | `runtime_lineage` |
| 109 | `EMailNotifications_ViewAll` | `—` | `—` | `runtime_lineage` |
| 110 | `EMailNotifications_Edit` | `—` | `—` | `runtime_lineage` |
| 111 | `GeneratePayment` | `—` | `—` | `runtime_lineage` |
| 112 | `Tools_eCostHistoryView` | `—` | `—` | `runtime_lineage` |
| 113 | `Tools_eCostHistoryEdit` | `—` | `—` | `runtime_lineage` |
| 114 | `Tools_eCostHistoryDelete` | `—` | `—` | `runtime_lineage` |
| 115 | `Pixels_ViewAll` | `—` | `—` | `runtime_lineage` |
| 116 | `Pixels_Edit` | `—` | `—` | `runtime_lineage` |
| 117 | `Pixels_AddNew` | `—` | `—` | `runtime_lineage` |
| 118 | `Pixels_Delete` | `—` | `—` | `runtime_lineage` |
| 119 | `PhotoImagePath` | `—` | `—` | `runtime_lineage` |
| 120 | `AffiliateGroups_Edit_UserList` | `—` | `—` | `runtime_lineage` |
| 121 | `IsSystemAdministrator` | `—` | `—` | `runtime_lineage` |
| 122 | `CopyTraders_ViewAll` | `—` | `—` | `runtime_lineage` |
| 123 | `CopyTraders_Delete` | `—` | `—` | `runtime_lineage` |
| 124 | `AffiliateGroups_Move` | `—` | `—` | `runtime_lineage` |
| 125 | `Audits_View` | `—` | `—` | `runtime_lineage` |
| 126 | `EncryptedLoginPassword` | `—` | `—` | `runtime_lineage` |
| 127 | `ChangedPasswordDate` | `—` | `—` | `runtime_lineage` |
| 128 | `Countries_Move` | `—` | `—` | `runtime_lineage` |
| 129 | `IsDeleted` | `—` | `—` | `runtime_lineage` |
| 130 | `MarketingManager` | `—` | `—` | `runtime_lineage` |
| 131 | `OperationsManager` | `—` | `—` | `runtime_lineage` |
| 132 | `FinanceManager` | `—` | `—` | `runtime_lineage` |
| 133 | `Pixels_CreateGeneric` | `—` | `—` | `runtime_lineage` |
| 134 | `Trace` | `—` | `—` | `runtime_lineage` |
| 135 | `InstrumentTypes_ViewAll` | `—` | `—` | `runtime_lineage` |
| 136 | `InstrumentTypes_Edit` | `—` | `—` | `runtime_lineage` |
| 137 | `InstrumentTypes_AddNew` | `—` | `—` | `runtime_lineage` |
| 138 | `InstrumentTypes_Delete` | `—` | `—` | `runtime_lineage` |
