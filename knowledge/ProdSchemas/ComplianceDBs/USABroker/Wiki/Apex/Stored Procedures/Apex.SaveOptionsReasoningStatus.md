# Apex.SaveOptionsReasoningStatus

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveOptionsReasoningStatus.sql`  
**Author:** Oleksandr Litvinov  
**Created:** 2022-05-05  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveOptionsReasoningStatus` records or updates the reasoning-workflow status for a customer's options account. The reasoning workflow is the process by which a customer provides justification for their options access — particularly when their appropriateness test result alone is insufficient to approve them, requiring a more detailed review. The procedure links the `Options` record to the specific reasoning form (`ReasoningFormID`) and records the current workflow status (`ReasoningStatusID`).

It is called by the options reasoning service when a reasoning form is initiated, when the customer submits their answers, and when compliance reviews the submission.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID. |
| `@ReasoningStatusID` | `int` | No | Current status of the reasoning workflow (e.g., pending, submitted, approved). |
| `@ReasoningFormID` | `uniqueidentifier` | No | GUID of the reasoning form associated with this options profile. |
| `@ApplicationName` | `nvarchar(50)` | No | Service name performing the update. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `Options` | `Apex` | SELECT (NOLOCK EXISTS check) + UPDATE or INSERT | Creates the row on first write with zero-valued other fields. |

---

## 5. Logic Flow

1. `IF EXISTS (SELECT 1 FROM Apex.Options WITH (NOLOCK) WHERE GCID = @GCID)`:
   - **True:** UPDATE `ReasoningStatusID`, `ReasoningFormID`, `ApplicationName` using `ISNULL(@param, existing_value)`.
   - **False:** INSERT with reasoning fields and all other fields defaulted to `0`.

---

## 6. Error Handling

No explicit error handling. SQL Server exceptions propagate.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.Options` | Table | Options profile store |
| `Apex.OptionsReasoningForm` | Table | Reasoning form header (ReasoningFormID foreign key target) |
| `Apex.GetOptions` | Stored Procedure | Reads `ReasoningStatusID` and `ReasoningFormID` written here |
| `Apex.GetOptionsReasoningFormQuestionsAnswers` | Stored Procedure | Reads the form content linked via `ReasoningFormID` |
| `Apex.CreateOptionsReasoningFormQuestion` | Stored Procedure | Creates the `OptionsReasoningForm` row referenced by `ReasoningFormID` |

---

## 8. Usage Notes

- `ReasoningFormID` must reference an existing row in `Apex.OptionsReasoningForm`; create the form header first via `Apex.CreateOptionsReasoningFormQuestion` before calling this procedure.
- The NOLOCK hint on the EXISTS check is consistent with `SaveOptionsAppropriateness` but inconsistent with `SaveOptionsEligibility` — this is a minor inconsistency in the codebase. Under high concurrency, a race condition here could lead to a duplicate insert attempt, which would fail on a unique constraint if one exists on `GCID`.
- `ReasoningStatusID` values represent states in the reasoning workflow state machine; consult the application specification for valid transitions.
- `ISNULL(@ReasoningFormID, ReasoningFormID)` in the UPDATE clause means passing NULL preserves the existing form ID, allowing status-only updates without needing to re-supply the form GUID.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveOptionsReasoningStatus.sql` | Quality Score: 8.5/10*
