# Dictionary.State

**Schema:** Dictionary
**Table:** State
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.State` is the central state-machine reference table for the USABroker Apex account lifecycle. It enumerates every discrete state that a user's brokerage account workflow can occupy, from the moment a new account creation is initiated through to final closure or rejection. Each row represents a named waypoint in the workflow engine; the `ApexStateID` is stored in `Apex.State` to record which step each user currently occupies.

The state machine covers four major workflow tracks:

1. **Account Creation** (IDs 1–19, 36–39): from initial state setup through Sketch CIP checks, Apex API submission, appeals, affiliated-person review, and final trading notification or rejection.
2. **Sketch Investigation** (IDs 20–35): the identity-verification sub-workflow for both new account creation and account update requests, including indeterminate resolution, appeal, and post-appeal states.
3. **Account Update** (IDs 11–19, 27–35, 37–40): the parallel track for modifications to existing accounts, mirroring the creation flow with update-specific state names.
4. **Account Closure** (IDs 41–45): the clean-up, API submission, polling, completion, and rejection states for account close requests.

States 46–47 (`VisaAppovalRequired` and `ManualAppealRequired`) represent special-case holds that require specific compliance actions before the workflow can continue.

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| ApexStateID | int | NOT NULL | Yes | Stable numeric identifier for the workflow state; referenced by `Apex.State.ApexStateID`. |
| Name | nvarchar(150) | NOT NULL | No | CamelCase descriptive name for the workflow state; used in logs, dashboards, and alerting rules. |

**Constraints:**
- `PK_State_1` — clustered primary key on `ApexStateID`

---

## 3. Data Overview

47 rows as of 2026-04-14.

| ApexStateID | Name | Meaning |
|---|---|---|
| 1 | CreateState | The initial state when a new account workflow is instantiated; the system is preparing to collect user data. |
| 2 | CollectUserData | The workflow is waiting for the user to complete and submit all required account-opening fields and forms. |
| 3 | SendCreateAccountRequest | The system has assembled the complete account payload and is submitting the create-account request to the Apex API. |
| 4 | PullCreateAccountRequest | The system is polling the Apex API to retrieve the status of a previously submitted account creation request. |
| 5 | WaitForFailingUserDataUpdateAfterCreateAccountRequest | A create-account request was submitted but resulted in a validation failure; the workflow is waiting for corrected user data before retrying. |
| 6 | WaitForUserDataUpdate | The workflow is paused pending an update to the user's profile data (e.g., the user must correct a field flagged by Apex). |
| 7 | NotifyTradingCompleted | The account creation was accepted by Apex; the trading system has been notified that the account is ready for trading. |
| 8 | Observation | The workflow has reached a monitoring state; the account is under observation, typically pending a compliance review outcome. |
| 9 | CreateAccountRejected | Apex has rejected the account creation request; the workflow has reached a terminal rejection state for new accounts. |
| 10 | InitiateAutoAppeal | An automatic appeal of a Sketch CIP rejection has been initiated; the system is submitting an appeal on the user's behalf. |
| 11 | CollectUserDataForAccountUpdate | The workflow is waiting for the user to submit updated information needed to process an account modification request. |
| 12 | SendUpdateAccountRequest | The system is submitting the account update payload to the Apex API. |
| 13 | WaitForUserDataUpdateForAccountUpdate | The update workflow is paused waiting for the user to provide corrected or additional data. |
| 14 | WaitForFailingUserDataUpdateAfterUpdateAccountRequest | An update request failed validation at Apex; the workflow is waiting for corrected data before resubmitting. |
| 15 | PullUpdateAccountRequest | The system is polling Apex for the status of a previously submitted account update request. |
| 16 | NotifyTradingUpdateAccountRejected | The update request was rejected by Apex; the trading system is being notified of the rejection. |
| 17 | UpdateAccountRejected | Apex has definitively rejected the account update request; terminal rejection state for update workflows. |
| 18 | InitiateAutoAppealForUpdate | An automatic appeal is being initiated for a Sketch rejection encountered during an account update workflow. |
| 19 | ManualUpdateRequired | Apex has flagged the update as requiring manual processing; a compliance agent must intervene. |
| 20 | GetSketchInvestigationState | The system is querying Sketch for the current status of an open CIP investigation (account creation context). |
| 21 | SketchInvestigationRejected | Sketch has returned a definitive rejection for the CIP investigation in an account creation flow. |
| 22 | SketchInvestigationResolved | The Sketch CIP investigation has been resolved favourably; the account creation workflow can continue. |
| 23 | ResolveSketchIndeterminateState | The workflow is actively working to resolve an indeterminate Sketch CIP result (e.g., awaiting additional documents or manual review). |
| 24 | AppealRejectedSketchInvestigation | The system has submitted a formal appeal of a rejected Sketch CIP investigation in the account creation flow. |
| 25 | GetSketchInvestigationStateAfterAppeal | The system is querying Sketch for the investigation status after an appeal has been submitted. |
| 26 | SketchInvestigationRejectedAfterAppeal | Sketch has upheld its rejection even after the appeal; the account creation cannot proceed automatically. |
| 27 | GetSketchInvestigationStateForUpdateAccount | The system is querying Sketch for CIP investigation status in an account update workflow context. |
| 28 | SketchInvestigationRejectedForUpdateAccount | Sketch has returned a definitive rejection for the CIP investigation in an account update flow. |
| 29 | SketchInvestigationResolvedForUpdateAccount | The Sketch CIP investigation has been resolved favourably in an account update workflow. |
| 30 | ResolveSketchIndeterminateStateForUpdateAccount | The workflow is resolving an indeterminate Sketch result in the context of an account update. |
| 31 | AppealRejectedSketchInvestigationForUpdateAccount | A formal appeal of a rejected Sketch investigation has been submitted for an account update workflow. |
| 32 | GetSketchInvestigationStateAfterAppealForUpdateAccount | The system is polling Sketch for investigation status after an appeal in the account update flow. |
| 33 | SketchInvestigationRejectedAfterAppealForUpdateAccount | Sketch has upheld its rejection on appeal in the account update workflow; the update cannot proceed. |
| 34 | SketchInvestigationError | An unexpected error occurred when communicating with Sketch during an account creation investigation. |
| 35 | SketchInvestigationErrorForUpdateAccount | An unexpected error occurred when communicating with Sketch during an account update investigation. |
| 36 | AffiliatedApprovalRequired | The applicant is identified as affiliated with a broker-dealer or exchange; approval from the affiliated entity is required to continue account creation. |
| 37 | AffiliatedApprovalRequiredForAccountUpdate | An affiliated-entity approval is required before an account update can be processed. |
| 38 | RestrictAccount | The workflow is in the process of placing a restriction on the user's account (e.g., due to a compliance flag). |
| 39 | AccountRestricted | The account restriction has been applied; the account is now in a restricted trading state. |
| 40 | NotifyTradingAfterAccountUpdate | The account update was accepted by Apex; the trading system is being notified that updated account data is live. |
| 41 | CloseAccountCleanupData | The account closure workflow has started; the system is performing pre-closure data cleanup tasks. |
| 42 | SendCloseAccountRequest | The system is submitting the account closure request to the Apex API. |
| 43 | PullCloseAccountRequest | The system is polling Apex for the status of a previously submitted account closure request. |
| 44 | CloseAccountRequestCompleted | The Apex account closure request was accepted; the account has been successfully closed. |
| 45 | CloseAccountRequestRejected | Apex has rejected the account closure request; manual intervention is required. |
| 46 | VisaAppovalRequired | The applicant holds a visa status that requires specific compliance approval before the account can be opened or updated. Note: the state name contains a typo (`Appoval` instead of `Approval`). |
| 47 | ManualAppealRequired | An automated appeal could not be processed; a compliance agent must manually initiate and manage the appeal process. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.State | ApexStateID | Records the current workflow state for each user's account lifecycle. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Count users by current workflow state
SELECT s.Name AS WorkflowState,
       COUNT(*) AS UserCount
FROM   Apex.State ast WITH (NOLOCK)
JOIN   Dictionary.State s WITH (NOLOCK)
       ON ast.ApexStateID = s.ApexStateID
GROUP  BY s.Name
ORDER  BY UserCount DESC;
```

```sql
-- Find all users in a terminal rejection state
SELECT ast.*
FROM   Apex.State ast WITH (NOLOCK)
WHERE  ast.ApexStateID IN (9, 17, 26, 33, 45); -- all rejection terminal states
```

```sql
-- Find all users awaiting Sketch investigation resolution
SELECT ast.*
FROM   Apex.State ast WITH (NOLOCK)
WHERE  ast.ApexStateID IN (20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35);
```

---

## 6. Data Quality Notes

- State ID 46 (`VisaAppovalRequired`) contains a typo — `Appoval` should be `Approval`. This is an existing defect in the data; correcting it would require a coordinated application code change.
- The state space is large (47 entries) and reflects the branching complexity of the Apex integration; any new Apex API capability or compliance requirement will likely require new states.
- The Create and Update tracks are largely parallel (IDs 3–19 vs. 11–19 and 27–35); this symmetry is intentional and should be preserved when adding new states.
- Terminal states (where the workflow stops) are: 7 (success), 9 (create rejected), 17 (update rejected), 26 and 33 (sketch rejected after appeal), 39 (restricted), 44 (close completed), 45 (close rejected).
- `nvarchar(150)` accommodates the longer descriptive state names.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 47 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.State | Table | The primary state-tracking table; stores each user's current position in the account lifecycle state machine. |
| Dictionary.ModifyType | Table | The modify type (Create / Update / Close) determines which track of the state machine applies. |
| Dictionary.SketchInvestigationReasonType | Table | Sketch investigation outcomes (Indeterminate / Reject) drive branching within the Sketch-related states (IDs 20–35). |
| Dictionary.ApexValidationError | Table | Validation errors returned by Apex trigger transitions to states such as ID 5 and ID 14. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
