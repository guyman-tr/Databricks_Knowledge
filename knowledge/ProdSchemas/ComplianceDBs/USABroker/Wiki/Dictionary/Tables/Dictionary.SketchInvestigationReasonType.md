# Dictionary.SketchInvestigationReasonType

**Schema:** Dictionary
**Table:** SketchInvestigationReasonType
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.SketchInvestigationReasonType` is a static reference table that classifies the outcome type of a Sketch CIP (Customer Identification Program) investigation result. Sketch is the third-party identity-verification service that performs automated CIP checks when a user submits their account application. When Sketch cannot return a clear pass, the result falls into one of two actionable categories: `Indeterminate` (the check is inconclusive and requires further investigation or appeal) or `Reject` (the check has definitively failed and the applicant cannot be automatically accepted).

These outcome types drive the branching logic in the USABroker account-opening state machine (`Dictionary.State`). An `Indeterminate` result routes the user into an appeal or indeterminate-resolution workflow; a `Reject` result triggers the rejected-investigation pathway. The `None` sentinel covers records not yet associated with an investigation or created before reason-type tracking was introduced.

The table is referenced by two tables in the `Apex` schema: `Apex.SketchInvestigationReason` (the reasons attached to an investigation event) and `Apex.SketchInvestigationDoNotAppealReason` (the reasons recorded when a rejected investigation is explicitly marked as not to be appealed).

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| SketchInvestigationReasonTypeID | int | NOT NULL | Yes | Numeric identifier for the investigation outcome category; 0 is the sentinel for no type assigned. |
| Name | nvarchar(50) | NOT NULL | No | Short label identifying the investigation result class used in workflow routing logic. |

**Constraints:**
- `PK_SketchInvestigationReasonType` — clustered primary key on `SketchInvestigationReasonTypeID`

---

## 3. Data Overview

3 rows as of 2026-04-14.

| SketchInvestigationReasonTypeID | Name | Meaning |
|---|---|---|
| 0 | None | No investigation reason type has been assigned; used as the default sentinel for records not yet associated with a Sketch outcome. |
| 1 | Indeterminate | Sketch returned an inconclusive CIP result; the account application cannot be auto-accepted and is routed to a manual review or appeal workflow. |
| 2 | Reject | Sketch returned a definitive failure; the CIP check has rejected the applicant and the account cannot be opened without successful appeal or manual override. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.SketchInvestigationReason | ReasonTypeID | Stores the investigation outcome type for each Sketch CIP investigation event. |
| Apex.SketchInvestigationDoNotAppealReason | ReasonTypeID | Stores the reason type when a compliance decision is made not to appeal a rejected Sketch investigation. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Count Sketch investigation events by outcome type
SELECT rt.Name AS ReasonType,
       COUNT(*) AS EventCount
FROM   Apex.SketchInvestigationReason sr WITH (NOLOCK)
JOIN   Dictionary.SketchInvestigationReasonType rt WITH (NOLOCK)
       ON sr.ReasonTypeID = rt.SketchInvestigationReasonTypeID
GROUP  BY rt.Name
ORDER  BY EventCount DESC;
```

```sql
-- Find all investigations that were rejected and not appealed
SELECT dnar.*
FROM   Apex.SketchInvestigationDoNotAppealReason dnar WITH (NOLOCK)
WHERE  dnar.ReasonTypeID = 2; -- Reject
```

---

## 6. Data Quality Notes

- The distinction between `Indeterminate` (ID 1) and `Reject` (ID 2) is critical for compliance workflows: indeterminate cases may be resolved through appeal (`InitiateAutoAppeal`, State ID 10), whereas rejected cases require explicit compliance action.
- `nvarchar(50)` is used for `Name`; all values are ASCII-safe.
- The Apex state machine (`Dictionary.State`) contains multiple states corresponding to each outcome type (e.g., `SketchInvestigationRejected`, `SketchInvestigationRejectedAfterAppeal`); these states implicitly correspond to the `Reject` outcome type.
- No soft-delete column exists; historical reason types must never be deleted to preserve referential integrity of investigation records.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 3 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.SketchInvestigationReason | Table | Records the reasons and outcome type for each Sketch CIP investigation event. |
| Apex.SketchInvestigationDoNotAppealReason | Table | Records the reason when a compliance team decides not to appeal a Sketch rejection. |
| Dictionary.State | Table | The Apex workflow state machine contains dedicated states for each Sketch investigation outcome type. |
| Dictionary.ApexValidationError | Table | Error code 43 (`CipCheckRejectedBySketch`) corresponds to a Sketch Reject investigation outcome. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
