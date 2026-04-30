# Apex.SaveUserProgramEnrolment

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveUserProgramEnrolment.sql`  
**Author:** Victor Shatokhin  
**Created:** 2022-03-08  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveUserProgramEnrolment` creates or updates a customer's enrolment record for a specific brokerage programme (e.g., FPSL, a dividend reinvestment programme, or another optional service). The composite MERGE key of `GCID + UserProgramID` allows a single customer to have separate enrolment records for multiple programmes, each with its own status.

It is called by the programme-enrolment service when a customer's participation status in any registered programme changes — including initial sign-up, approval, activation, suspension, or withdrawal.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID. |
| `@UserProgramEnrolmentStatusID` | `int` | No | Current enrolment status code for the programme. |
| `@UserProgramID` | `int` | No | ID identifying the specific programme. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `UserProgramEnrolment` | `Apex` | MERGE (INSERT / conditional UPDATE) | Composite MERGE key: `GCID + UserProgramID`. Change-detection on enrolment status only. |

---

## 5. Logic Flow

MERGE on `Target.GCID = Source.GCID AND Target.UserProgramID = Source.UserProgramID`:

- **WHEN MATCHED AND** `UserProgramEnrolmentStatusID` differs (ISNULL normalisation):
  - UPDATE `UserProgramEnrolmentStatusID` using `ISNULL(@UserProgramEnrolmentStatusID, Target.UserProgramEnrolmentStatusID)`.
- **WHEN NOT MATCHED BY TARGET:** INSERT `(GCID, UserProgramEnrolmentStatusID, UserProgramID)`.

The composite key design supports multi-programme enrolments per customer without row collisions.

---

## 6. Error Handling

No explicit error handling. MERGE exceptions propagate.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.UserProgramEnrolment` | Table | Programme enrolment store |
| `Apex.SaveUserFpslEnrolment` | Stored Procedure | FPSL-specific enrolment writer (uses `UserFpslEnrolment` table, separate from this table) |

---

## 8. Usage Notes

- Each `(GCID, UserProgramID)` pair represents one programme membership. A customer enrolled in two programmes will have two rows.
- `UserProgramID` references a programme definition table; consult the programme registry for valid IDs.
- `UserProgramEnrolmentStatusID` represents lifecycle states such as `Applied`, `Active`, `Suspended`, `Withdrawn`; valid transitions are enforced by the application layer, not the database.
- `ISNULL(@UserProgramEnrolmentStatusID, Target.UserProgramEnrolmentStatusID)` in the UPDATE means passing NULL preserves the current status — though in practice, callers should always supply an explicit status.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveUserProgramEnrolment.sql` | Quality Score: 8.5/10*
