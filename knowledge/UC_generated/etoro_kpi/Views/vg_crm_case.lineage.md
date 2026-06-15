# Column Lineage: main.etoro_kpi.vg_crm_case

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi.vg_crm_case` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi\_discovery\source_code\vg_crm_case.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi\_discovery\column_lineage\vg_crm_case.json` (rows: 57, mismatches: 8) |
| **Primary upstream** | `main.crm.silver_crm_case` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_output.bi_output_vg_case_event` | JOIN / referenced | ✓ `knowledge\UC_generated\bi_output\Views\bi_output_vg_case_event.md` |
| `main.crm.silver_crm_case` | Primary (FROM) | ✗ `(no wiki found)` |
| `main.crm.gold_crm_case_tiny_for_genie` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.crm.gold_crm_bot_eligible_chats` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.crm.gold_crm_case_deescalation` | JOIN / referenced | ✗ `(no wiki found)` |
| `main.crm.gold_crm_web_chat_sessions` | JOIN / referenced | ✗ `(no wiki found)` |

## Lineage Chain

```
main.crm.silver_crm_case   ←── primary upstream
  + main.crm.gold_crm_web_chat_sessions   (JOIN)
  + main.crm.gold_crm_bot_eligible_chats   (JOIN)
  + main.crm.gold_crm_case_deescalation   (JOIN)
  + main.bi_output.bi_output_vg_case_event   (JOIN)
  + main.crm.gold_crm_case_tiny_for_genie   (JOIN)
        │
        ▼
main.etoro_kpi.vg_crm_case   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `CaseID` | `main.crm.silver_crm_case` | `Id` | `rename` | — | Id AS CaseID |
| 2 | `CID` | `main.crm.silver_crm_case` | `CID__c` | `rename` | — | CID__c AS CID |
| 3 | `CreatedDate` | `main.crm.silver_crm_case` | `CreatedDate` | `passthrough` | — | CreatedDate |
| 4 | `CaseNumber` | `main.crm.silver_crm_case` | `CaseNumber` | `passthrough` | — | CaseNumber |
| 5 | `Status` | `main.crm.silver_crm_case` | `Status` | `passthrough` | — | Status |
| 6 | `Origin` | `main.crm.silver_crm_case` | `Origin` | `passthrough` | — | Origin |
| 7 | `Subject` | `main.crm.silver_crm_case` | `Subject` | `passthrough` | — | Subject |
| 8 | `Priority` | `main.crm.silver_crm_case` | `Priority` | `passthrough` | — | Priority |
| 9 | `OwnerId` | `main.crm.silver_crm_case` | `OwnerId` | `passthrough` | — | OwnerId |
| 10 | `CaseOwnerTitle` | `main.crm.silver_crm_case` | `Case_Owner_Title__c` | `rename` | — | Case_Owner_Title__c AS CaseOwnerTitle |
| 11 | `IsSolved` | `main.crm.silver_crm_case` | `Solved__c` | `rename` | — | Solved__c AS IsSolved |
| 12 | `ClosedDate` | `main.crm.silver_crm_case` | `ClosedDate` | `passthrough` | — | ClosedDate |
| 13 | `IsClosedOnCreate` | `main.crm.silver_crm_case` | `IsClosedOnCreate` | `passthrough` | — | IsClosedOnCreate |
| 14 | `ServiceLanguage` | `main.crm.silver_crm_case` | `Service_Language__c` | `rename` | — | Service_Language__c AS ServiceLanguage |
| 15 | `Product` | `main.crm.silver_crm_case` | `Product__c` | `rename` | — | Product__c AS Product |
| 16 | `Category` | `main.crm.silver_crm_case` | `Category__c` | `rename` | — | Category__c AS Category |
| 17 | `CaseType` | `main.crm.silver_crm_case` | `Type__c` | `rename` | — | Type__c AS CaseType |
| 18 | `SubType` | `main.crm.silver_crm_case` | `Sub_Type__c` | `rename` | — | Sub_Type__c AS SubType |
| 19 | `SubType2` | `main.crm.silver_crm_case` | `Sub_Type_2__c` | `rename` | — | Sub_Type_2__c AS SubType2 |
| 20 | `WithdrawalID` | `main.crm.silver_crm_case` | `Withdrawal_ID__c` | `rename` | — | Withdrawal_ID__c AS WithdrawalID |
| 21 | `DepositID` | `main.crm.silver_crm_case` | `Deposit_ID__c` | `rename` | — | Deposit_ID__c AS DepositID |
| 22 | `PositionID` | `main.crm.silver_crm_case` | `Position_ID__c` | `rename` | — | Position_ID__c AS PositionID |
| 23 | `MirrorID` | `main.crm.silver_crm_case` | `Mirror_ID__c` | `rename` | — | Mirror_ID__c AS MirrorID |
| 24 | `Phase` | `main.crm.silver_crm_case` | `Phase__c` | `rename` | — | Phase__c AS Phase |
| 25 | `IsOfficialComplaint` | `main.crm.silver_crm_case` | `Official_Complaint__c` | `rename` | — | Official_Complaint__c AS IsOfficialComplaint |
| 26 | `IsReOpened` | `main.crm.silver_crm_case` | `Re_Opened__c` | `rename` | — | Re_Opened__c AS IsReOpened |
| 27 | `CaseCreatedByRole` | `main.crm.silver_crm_case` | `Case_Created_By_Role__c` | `rename` | — | Case_Created_By_Role__c AS CaseCreatedByRole |
| 28 | `IncomingEmailCount` | `main.crm.silver_crm_case` | `Number_of_Incoming_Email_Messages__c` | `rename` | — | Number_of_Incoming_Email_Messages__c AS IncomingEmailCount |
| 29 | `OutboundEmailCount` | `main.crm.silver_crm_case` | `Number_of_Outbound_Email_Messages__c` | `rename` | — | Number_of_Outbound_Email_Messages__c AS OutboundEmailCount |
| 30 | `InternalCommentCount` | `main.crm.silver_crm_case` | `Number_of_Internal_Case_Comments__c` | `rename` | — | Number_of_Internal_Case_Comments__c AS InternalCommentCount |
| 31 | `FirstResponseDateTime` | `main.crm.silver_crm_case` | `X1st_Response_Date_Time__c` | `rename` | — | X1st_Response_Date_Time__c AS FirstResponseDateTime |
| 32 | `TimeToFirstResponse` | `main.crm.silver_crm_case` | `Time_to_1st_Response__c` | `rename` | — | Time_to_1st_Response__c AS TimeToFirstResponse |
| 33 | `ResolutionTimeFromFirstResponse` | `main.crm.silver_crm_case` | `Resolution_Time_From_1st_Response__c` | `rename` | — | Resolution_Time_From_1st_Response__c AS ResolutionTimeFromFirstResponse |
| 34 | `TotalTimeToResolve` | `main.crm.silver_crm_case` | `Total_time_to_Resolve_reports__c` | `rename` | — | Total_time_to_Resolve_reports__c AS TotalTimeToResolve |
| 35 | `TouchCount` | `main.crm.silver_crm_case` | `Number_of_touches__c` | `rename` | — | Number_of_touches__c AS TouchCount |
| 36 | `TechnicalRefund` | `main.crm.silver_crm_case` | `Technical_Refund__c` | `rename` | — | Technical_Refund__c AS TechnicalRefund |
| 37 | `OwnerSubRole` | `main.crm.silver_crm_case` | `Owner_Sub_Role__c` | `rename` | — | Owner_Sub_Role__c AS OwnerSubRole |
| 38 | `JiraID` | `main.crm.silver_crm_case` | `Jira_ID__c` | `rename` | — | Jira_ID__c AS JiraID |
| 39 | `GoodwillGesture` | `main.crm.silver_crm_case` | `Goodwill_Gesture__c` | `rename` | — | Goodwill_Gesture__c AS GoodwillGesture |
| 40 | `AMLState` | `main.crm.silver_crm_case` | `AML_State__c` | `rename` | — | AML_State__c AS AMLState |
| 41 | `QCSurvey` | `main.crm.silver_crm_case` | `QC_Survey__c` | `rename` | — | QC_Survey__c AS QCSurvey |
| 42 | `CaseSkillSet` | `main.crm.silver_crm_case` | `CaseSkillSet__c` | `rename` | — | CaseSkillSet__c AS CaseSkillSet |
| 43 | `Regulation` | `main.crm.silver_crm_case` | `Regulation_on_Creation__c` | `rename` | — | Regulation_on_Creation__c AS Regulation |
| 44 | `ClubLevel` | `main.crm.silver_crm_case` | `Club_Level_on_Creation__c` | `rename` | — | Club_Level_on_Creation__c AS ClubLevel |
| 45 | `EscalatedBy` | `main.crm.silver_crm_case` | `Escalated_By__c` | `rename` | — | Escalated_By__c AS EscalatedBy |
| 46 | `EscalationDate` | `main.crm.silver_crm_case` | `Escalation_Date__c` | `rename` | — | Escalation_Date__c AS EscalationDate |
| 47 | `IsEscalated` | `main.crm.silver_crm_case` | `—` | `case` | — | CASE WHEN COALESCE(Escalation_Date__c, '1900-01-01T01:01:01.000+00:00') < '2025-01-01T01:01:01.000+00:00' AND NOT Origin IN ('Email', 'Manua |
| 48 | `EscalationStatus` | `main.crm.silver_crm_case` | `Escalation_Status__c` | `rename` | — | Escalation_Status__c AS EscalationStatus |
| 49 | `FinalEscalationResponseDate` | `main.crm.silver_crm_case` | `Final_Escalation_Response_Date__c` | `rename` | — | Final_Escalation_Response_Date__c AS FinalEscalationResponseDate |
| 50 | `CS_OPS` | `main.crm.silver_crm_case` | `—` | `case` | — | CASE WHEN Owner_Sub_Role__c IN ('Escalation - eToro', 'Technical - eToro', 'Tier 1 - eToro', 'Tier 2 - eToro', 'Tier 3 - eToro') THEN 'CS' E |
| 51 | `IsDeflected` | `—` | `—` | `case` | — | CASE WHEN def.CaseId IS NULL THEN 0 ELSE 1 END AS IsDeflected |
| 52 | `IsDeEscalated` | `—` | `—` | `case` | — | CASE WHEN q1.CaseId IS NULL THEN 0 ELSE 1 END AS IsDeEscalated |
| 53 | `ClosedBy` | `main.crm.silver_crm_case` | `Closed_By__c` | `rename` | — | Closed_By__c AS ClosedBy |
| 54 | `EventID` | `—` | `EventID` | `join_enriched` | — | slv.EventID |
| 55 | `DoneBy` | `—` | `DoneBy` | `join_enriched` | — | slv.DoneBy |
| 56 | `Touches` | `—` | `Touches` | `join_enriched` | — | slv.Touches |
| 57 | `SolvedDate` | `—` | `FromDate` | `join_enriched` | — | slv.FromDate AS SolvedDate |

## Cross-check vs system.access.column_lineage

- Total target columns: **57**
- OK: **49**, WARN: **0**, ERROR: **8**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `IsEscalated` | — | `main.crm.silver_crm_case.case_owner_title__c`, `main.crm.silver_crm_case.escalation_date__c`, `main.crm.silver_crm_case.origin` | ERROR |
| `CS_OPS` | — | `main.crm.silver_crm_case.owner_sub_role__c` | ERROR |
| `IsDeflected` | — | `main.crm.gold_crm_case_tiny_for_genie.case_id_18__c` | ERROR |
| `IsDeEscalated` | — | `main.crm.gold_crm_case_deescalation.caseid` | ERROR |
| `EventID` | — | `main.bi_output.bi_output_vg_case_event.eventid` | ERROR |
| `DoneBy` | — | `main.bi_output.bi_output_vg_case_event.doneby` | ERROR |
| `Touches` | — | `main.bi_output.bi_output_vg_case_event.touches` | ERROR |
| `SolvedDate` | — | `main.bi_output.bi_output_vg_case_event.fromdate` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **8**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN DeEscalation AS q1 ON c.Id = q1.CaseId
- `LEFT JOIN` — LEFT JOIN deflection AS def ON c.Id = def.CaseId
- `LEFT JOIN` — LEFT JOIN Solved AS slv ON c.Id = slv.CaseId
- `LEFT JOIN` — LEFT JOIN (SELECT CaseId, SessionId FROM main.crm.gold_crm_web_chat_sessions WHERE CreatedDate >= CURRENT_DATE - INTERVAL '12' MONTHS AND CAST(CreatedDate AS DATE) <> '2025-05-28') AS wcs ON c.Case_Id_18__c = wcs.CaseId
- `LEFT JOIN` — LEFT JOIN (SELECT Id, CaseId FROM main.crm.gold_crm_bot_eligible_chats WHERE CreatedDate >= CURRENT_DATE - INTERVAL '12' MONTHS) AS bec ON c.Case_Id_18__c = bec.CaseId
