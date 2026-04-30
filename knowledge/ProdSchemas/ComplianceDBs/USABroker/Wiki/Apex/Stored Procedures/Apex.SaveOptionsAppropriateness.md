# Apex.SaveOptionsAppropriateness

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveOptionsAppropriateness.sql`  
**Author:** Oleksandr Litvinov  
**Created:** 2022-05-05  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveOptionsAppropriateness` records or updates the result of an options-trading appropriateness assessment for a customer. Appropriateness testing evaluates whether a customer has sufficient knowledge and experience to trade options products. The procedure stores the test result, the product scope tested, the reason for any recalculation, the originating application, and the date the test was administered.

It is called by the options onboarding workflow whenever an appropriateness assessment is completed or re-evaluated (e.g., after the customer re-takes the questionnaire or when product-scope changes require a new assessment).

---

## 2. Parameters

| Parameter | Type | Nullable | Default | Description |
|-----------|------|----------|---------|-------------|
| `@GCID` | `int` | No | — | Global Customer ID. |
| `@AppropriatenessTestResultID` | `int` | No | — | Result code of the appropriateness test (pass/fail/pending). |
| `@AppropriatenessProductID` | `int` | No | — | ID of the product category the test was conducted for. |
| `@AppropriatenessRecalculationReasonID` | `int` | No | — | Reason code if this is a recalculation of a prior test. |
| `@ApplicationName` | `nvarchar(50)` | No | — | Name of the service/application that performed the assessment. |
| `@AppropriatenessTestDate` | `datetime` | Yes | `NULL` | Date the appropriateness test was administered. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `Options` | `Apex` | SELECT (NOLOCK EXISTS check) + UPDATE or INSERT | Creates a new `Options` row with zero-valued other fields on first write. |

---

## 5. Logic Flow

1. `IF EXISTS (SELECT 1 FROM Apex.Options WITH (NOLOCK) WHERE GCID = @GCID)`:
   - **True:** UPDATE appropriateness fields using `ISNULL(@param, existing_value)` pattern to preserve other fields.
   - **False:** INSERT a new row with appropriateness fields populated and all other status fields (EligibilityStatusID, OptionsStatusID) defaulted to `0`.
2. On INSERT, the `Options` row is initialised with zero-valued IDs for fields outside this procedure's scope — those are set by the sibling `SaveOptionsEligibility`, `SaveOptionsStatus`, and `SaveOptionsReasoningStatus` procedures.

---

## 6. Error Handling

No explicit error handling. Standard SQL Server exceptions propagate.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.Options` | Table | Options profile store |
| `Apex.GetOptions` | Stored Procedure | Reads the row written here |
| `Apex.SaveOptionsEligibility` | Stored Procedure | Writes eligibility fields to the same row |
| `Apex.SaveOptionsStatus` | Stored Procedure | Writes status fields to the same row |
| `Apex.SaveOptionsReasoningStatus` | Stored Procedure | Writes reasoning fields to the same row |

---

## 8. Usage Notes

- The INSERT initialises non-appropriateness fields to `0`. If the `Options` row was created by this procedure and then fetched via `Apex.GetOptions`, the eligibility and status fields will appear as `0` (not NULL) until their respective Save procedures are called.
- `@AppropriatenessTestDate` is nullable — pass NULL if the test date is not known at the time of writing.
- The `ISNULL(@param, existing_value)` pattern in the UPDATE means passing NULL for any parameter preserves the current value; this is an important partial-update design for the multi-procedure Options update pattern.
- `@ApplicationName` is recorded as an audit trail; it should always reflect the actual service name, not a generic placeholder.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveOptionsAppropriateness.sql` | Quality Score: 8.5/10*
