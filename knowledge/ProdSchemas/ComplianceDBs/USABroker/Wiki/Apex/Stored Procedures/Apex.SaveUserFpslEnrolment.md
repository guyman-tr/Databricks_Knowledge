# Apex.SaveUserFpslEnrolment

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveUserFpslEnrolment.sql`  
**Author:** Victor Shatokhin  
**Created:** 2022-02-01  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveUserFpslEnrolment` creates or updates a customer's full enrolment record for the Fully Paid Securities Lending (FPSL) programme. Unlike `SaveUserFpslAppropriateness` which only manages the test result fields, this procedure additionally manages the enrolment status (`FpslEnrolmentStatusID`) — representing the customer's lifecycle position in the FPSL programme (e.g., applied, enrolled, suspended, withdrawn).

It is called by the FPSL enrolment service when a customer's programme status changes — including initial enrolment, status updates from Apex Clearing, and withdrawal processing.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID. |
| `@FpslEnrolmentStatusID` | `int` | No | Current FPSL programme enrolment status code. |
| `@AppropriatenessTestResultID` | `int` | No | Result of the FPSL appropriateness test. |
| `@AppropriatenessProductID` | `int` | No | Product scope for the appropriateness result. |
| `@AppropriatenessRecalculationReasonID` | `int` | No | Reason code if the test was recalculated. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `UserFpslEnrolment` | `Apex` | MERGE (INSERT / conditional UPDATE) | Change-detection on all four data fields. |

---

## 5. Logic Flow

MERGE on `Target.GCID = Source.GCID`:

- **WHEN MATCHED AND** any of the four fields differ (ISNULL normalisation on all four):
  - UPDATE all four fields using `ISNULL(@param, Target.field)`.
- **WHEN NOT MATCHED BY TARGET:** INSERT all five columns (GCID + 4 data fields) with the provided values.

This is the **full-write** variant vs `SaveUserFpslAppropriateness` which only writes three of the four fields.

---

## 6. Error Handling

No explicit error handling. MERGE exceptions propagate.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.UserFpslEnrolment` | Table | FPSL enrolment record — MERGE target |
| `Apex.SaveUserFpslAppropriateness` | Stored Procedure | Sibling writer for appropriateness-only updates to the same row |

---

## 8. Usage Notes

- This procedure supersedes `SaveUserFpslAppropriateness` when both the enrolment status and appropriateness data need to be updated simultaneously — use this for complete record saves.
- The change-detection condition includes `FpslEnrolmentStatusID` in addition to the three appropriateness fields, so a status-only change (with unchanged appropriateness data) will correctly trigger an UPDATE.
- `ISNULL(@param, Target.field)` means NULL inputs preserve existing values; callers can pass NULL for fields they do not intend to change.
- `FpslEnrolmentStatusID = 0` in `SaveUserFpslAppropriateness` represents the "not yet enrolled" state. Once a customer progresses through FPSL onboarding, this procedure should be called with the appropriate status code.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveUserFpslEnrolment.sql` | Quality Score: 8.5/10*
