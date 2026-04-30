# Apex.SaveUserFpslAppropriateness

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveUserFpslAppropriateness.sql`  
**Author:** Victor Shatokhin  
**Created:** 2022-02-01  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveUserFpslAppropriateness` records or updates the appropriateness test results for a customer's Fully Paid Securities Lending (FPSL) programme enrolment. FPSL is a feature that allows customers to lend their securities to institutional borrowers in exchange for income. Before enrolment, customers must pass an appropriateness assessment. This procedure stores the test outcome, the product scope, and the recalculation reason — the same three appropriateness fields used for options, applied to the FPSL context.

It is called by the FPSL onboarding service when an appropriateness assessment is completed or updated for a customer seeking FPSL participation.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID. |
| `@AppropriatenessTestResultID` | `int` | No | Result code of the FPSL appropriateness test. |
| `@AppropriatenessProductID` | `int` | No | Product scope for which the appropriateness result applies. |
| `@AppropriatenessRecalculationReasonID` | `int` | No | Reason code if the test result was recalculated. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `UserFpslEnrolment` | `Apex` | MERGE (INSERT / conditional UPDATE) | Change-detection on all three appropriateness fields; new rows seeded with `FpslEnrolmentStatusID = 0`. |

---

## 5. Logic Flow

MERGE on `Target.GCID = Source.GCID`:

- **WHEN MATCHED AND** any of the three appropriateness fields differ (ISNULL normalisation):
  - UPDATE the three appropriateness fields.
- **WHEN NOT MATCHED BY TARGET:** INSERT with `FpslEnrolmentStatusID = 0` (not yet enrolled) and the three appropriateness fields.

The enrolment status is not touched by this procedure — it is managed by `Apex.SaveUserFpslEnrolment`.

---

## 6. Error Handling

No explicit error handling. MERGE exceptions propagate.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.UserFpslEnrolment` | Table | FPSL enrolment record — MERGE target |
| `Apex.SaveUserFpslEnrolment` | Stored Procedure | Sibling writer; manages enrolment status for the same row |

---

## 8. Usage Notes

- This procedure creates the `UserFpslEnrolment` row with `FpslEnrolmentStatusID = 0` if it does not exist. This is the appropriate initial state before enrolment is confirmed.
- It does **not** update `FpslEnrolmentStatusID` — use `Apex.SaveUserFpslEnrolment` to update the enrolment status.
- The ISNULL-based change detection prevents unnecessary writes when appropriateness data is unchanged — important for a table that may be polled frequently.
- Appropriateness results for FPSL use the same ID scheme as options (`AppropriatenessTestResultID`, `AppropriatenessProductID`, `AppropriatenessRecalculationReasonID`); consult the test-result reference table for valid values in the FPSL context.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveUserFpslAppropriateness.sql` | Quality Score: 8.5/10*
