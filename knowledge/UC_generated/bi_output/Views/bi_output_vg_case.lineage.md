# Column Lineage: main.bi_output.bi_output_vg_case

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_output_vg_case` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_output_vg_case.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_output_vg_case.json` (rows: 50, mismatches: 3) |
| **Primary upstream** | `main.crm.silver_crm_case` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.crm.silver_crm_case` | Primary (FROM) | ✗ `(no wiki found)` |

## Lineage Chain

```
main.crm.silver_crm_case   ←── primary upstream
        │
        ▼
main.bi_output.bi_output_vg_case   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CaseNumber` | `main.crm.silver_crm_case` | `CaseNumber` | `passthrough` | — | CaseNumber AS CaseNumber |
| 2 | `CaseID` | `main.crm.silver_crm_case` | `Id` | `rename` | — | Id AS CaseID |
| 3 | `CreatedDate` | `main.crm.silver_crm_case` | `CreatedDate` | `passthrough` | — | CreatedDate AS CreatedDate |
| 4 | `CreatedById` | `main.crm.silver_crm_case` | `CreatedById` | `passthrough` | — | CreatedById AS CreatedById |
| 5 | `LastModifiedDate` | `main.crm.silver_crm_case` | `LastModifiedDate` | `passthrough` | — | LastModifiedDate AS LastModifiedDate |
| 6 | `LastModifiedByID` | `main.crm.silver_crm_case` | `LastModifiedById` | `rename` | — | LastModifiedById AS LastModifiedByID |
| 7 | `OwnerID` | `main.crm.silver_crm_case` | `OwnerId` | `rename` | — | OwnerId AS OwnerID |
| 8 | `OwnerCSDesk` | `main.crm.silver_crm_case` | `Owner_CS_Desk__c` | `rename` | — | Owner_CS_Desk__c AS OwnerCSDesk |
| 9 | `OwnerSubRole` | `main.crm.silver_crm_case` | `Owner_Sub_Role__c` | `rename` | — | Owner_Sub_Role__c AS OwnerSubRole |
| 10 | `OwnerTeam` | `main.crm.silver_crm_case` | `Owner_Team__c` | `rename` | — | Owner_Team__c AS OwnerTeam |
| 11 | `AccountID` | `main.crm.silver_crm_case` | `AccountId` | `rename` | — | AccountId AS AccountID |
| 12 | `RealCID` | `main.crm.silver_crm_case` | `CID__c` | `rename` | — | CID__c AS RealCID |
| 13 | `Origin` | `main.crm.silver_crm_case` | `Origin` | `passthrough` | — | Origin AS Origin |
| 14 | `CurrentStatus` | `main.crm.silver_crm_case` | `Status` | `rename` | — | Status AS CurrentStatus |
| 15 | `Priority` | `main.crm.silver_crm_case` | `Priority` | `passthrough` | — | Priority AS Priority |
| 16 | `Subject` | `main.crm.silver_crm_case` | `Subject` | `passthrough` | — | Subject AS Subject |
| 17 | `Description` | `main.crm.silver_crm_case` | `Description` | `passthrough` | — | Description AS Description |
| 18 | `IsClosedOnCreate` | `main.crm.silver_crm_case` | `IsClosedOnCreate` | `passthrough` | — | IsClosedOnCreate AS IsClosedOnCreate |
| 19 | `Product` | `main.crm.silver_crm_case` | `Product__c` | `rename` | — | Product__c AS Product |
| 20 | `CASS_Impact` | `main.crm.silver_crm_case` | `CASS_Impact__c` | `rename` | — | CASS_Impact__c AS CASS_Impact |
| 21 | `AML_status` | `main.crm.silver_crm_case` | `AML_Status__c` | `rename` | — | AML_Status__c AS AML_status |
| 22 | `Type` | `main.crm.silver_crm_case` | `Type__c` | `rename` | — | Type__c AS Type |
| 23 | `SubType` | `main.crm.silver_crm_case` | `Sub_Type__c` | `rename` | — | Sub_Type__c AS SubType |
| 24 | `SubType2` | `main.crm.silver_crm_case` | `Sub_Type_2__c` | `rename` | — | Sub_Type_2__c AS SubType2 |
| 25 | `NumberOfTouches` | `main.crm.silver_crm_case` | `Number_of_touches__c` | `rename` | — | Number_of_touches__c AS NumberOfTouches |
| 26 | `NumberOfOutboundEmailMessages` | `main.crm.silver_crm_case` | `Number_of_Outbound_Email_Messages__c` | `rename` | — | Number_of_Outbound_Email_Messages__c AS NumberOfOutboundEmailMessages |
| 27 | `NumberOfIncomingEmailMessages` | `main.crm.silver_crm_case` | `Number_of_Incoming_Email_Messages__c` | `rename` | — | Number_of_Incoming_Email_Messages__c AS NumberOfIncomingEmailMessages |
| 28 | `NumberOfInternalCaseComments` | `main.crm.silver_crm_case` | `Number_of_Internal_Case_Comments__c` | `rename` | — | Number_of_Internal_Case_Comments__c AS NumberOfInternalCaseComments |
| 29 | `IsReopened` | `main.crm.silver_crm_case` | `Re_Opened__c` | `rename` | — | Re_Opened__c AS IsReopened |
| 30 | `IsPP_Report` | `main.crm.silver_crm_case` | `PP_Report__c` | `rename` | — | PP_Report__c AS IsPP_Report |
| 31 | `IsPlatform` | `main.crm.silver_crm_case` | `Platform__c` | `rename` | — | Platform__c AS IsPlatform |
| 32 | `Phase` | `main.crm.silver_crm_case` | `Phase__c` | `rename` | — | Phase__c AS Phase |
| 33 | `DepositID` | `main.crm.silver_crm_case` | `Deposit_ID__c` | `rename` | — | Deposit_ID__c AS DepositID |
| 34 | `WithdrawalID` | `main.crm.silver_crm_case` | `Withdrawal_ID__c` | `rename` | — | Withdrawal_ID__c AS WithdrawalID |
| 35 | `ServiceLanguage` | `main.crm.silver_crm_case` | `Service_Language__c` | `rename` | — | Service_Language__c AS ServiceLanguage |
| 36 | `IsDuplicate` | `main.crm.silver_crm_case` | `—` | `case` | — | CASE WHEN Duplicate__c = TRUE AND Origin = 'Chat' AND Status = 'Closed' THEN 1 ELSE 0 END AS IsDuplicate |
| 37 | `IsOneTouch` | `main.crm.silver_crm_case` | `One_Touch__c` | `rename` | — | One_Touch__c AS IsOneTouch |
| 38 | `ClosedByAutomation` | `main.crm.silver_crm_case` | `Closed_by_Automation__c` | `rename` | — | Closed_by_Automation__c AS ClosedByAutomation |
| 39 | `UpdatedByAutomaticProcess` | `main.crm.silver_crm_case` | `Updated_by_automatic_process__c` | `rename` | — | Updated_by_automatic_process__c AS UpdatedByAutomaticProcess |
| 40 | `InternalCase` | `main.crm.silver_crm_case` | `Internal_Case__c` | `rename` | — | Internal_Case__c AS InternalCase |
| 41 | `EscalatedBy` | `main.crm.silver_crm_case` | `Escalated_By__c` | `rename` | — | Escalated_By__c AS EscalatedBy |
| 42 | `EscalationStatus` | `main.crm.silver_crm_case` | `Escalation_Status__c` | `rename` | — | Escalation_Status__c AS EscalationStatus |
| 43 | `EscalationDate` | `main.crm.silver_crm_case` | `Escalation_Date__c` | `rename` | — | Escalation_Date__c AS EscalationDate |
| 44 | `EscalatedByBot` | `main.crm.silver_crm_case` | `Escalated_By_Bot__c` | `rename` | — | Escalated_By_Bot__c AS EscalatedByBot |
| 45 | `FinalEscalationResponseDate` | `main.crm.silver_crm_case` | `Final_Escalation_Response_Date__c` | `rename` | — | Final_Escalation_Response_Date__c AS FinalEscalationResponseDate |
| 46 | `IsEscalated` | `main.crm.silver_crm_case` | `IsEscalated` | `passthrough` | — | IsEscalated AS IsEscalated |
| 47 | `ElapsedTimeFromEscalation` | `main.crm.silver_crm_case` | `Elapsed_Time_From_Escalation__c` | `rename` | — | Elapsed_Time_From_Escalation__c AS ElapsedTimeFromEscalation |
| 48 | `FirstResponseDateTime` | `main.crm.silver_crm_case` | `—` | `case` | — | CASE WHEN Origin IN ('Chat', 'Chatbot') THEN CreatedDate ELSE X1st_Response_Date_Time__c END AS FirstResponseDateTime |
| 49 | `ClosedDate` | `main.crm.silver_crm_case` | `ClosedDate` | `passthrough` | — | ClosedDate |
| 50 | `ChatSkill` | `main.crm.silver_crm_case` | `—` | `case` | — | CASE WHEN Original_Skillset__c LIKE '%US%' THEN 'US' WHEN Original_Skillset__c LIKE '%General Support%' THEN '1.General Support' WHEN Origin |

## Cross-check vs system.access.column_lineage

- Total target columns: **50**
- OK: **47**, WARN: **0**, ERROR: **3**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `IsDuplicate` | — | `main.crm.silver_crm_case.duplicate__c`, `main.crm.silver_crm_case.origin`, `main.crm.silver_crm_case.status` | ERROR |
| `FirstResponseDateTime` | — | `main.crm.silver_crm_case.createddate`, `main.crm.silver_crm_case.origin`, `main.crm.silver_crm_case.x1st_response_date_time__c` | ERROR |
| `ChatSkill` | — | `main.crm.silver_crm_case.original_skillset__c` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **3**
