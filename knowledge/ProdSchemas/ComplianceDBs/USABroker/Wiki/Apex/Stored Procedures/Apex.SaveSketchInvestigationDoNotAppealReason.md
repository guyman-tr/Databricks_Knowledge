# Apex.SaveSketchInvestigationDoNotAppealReason

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveSketchInvestigationDoNotAppealReason.sql`  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveSketchInvestigationDoNotAppealReason` records the reason why an automated appeal was **not** filed for a compliance sketch investigation. When Apex Clearing raises an investigation flag (sketch) on a customer's account, the system evaluates whether to auto-appeal. When the system decides NOT to auto-appeal — perhaps because the reason is too complex, the customer has a history of flags, or the `CanAutoAppeal` flag on the reason is false — this procedure writes a permanent record of that decision, including the reason type, constant, and data source, for the compliance audit trail.

It is called by the investigation-processing service after it determines that an auto-appeal should not be submitted for a specific sketch.

---

## 2. Parameters

| Parameter | Type | Nullable | Default | Description |
|-----------|------|----------|---------|-------------|
| `@GCID` | `int` | No | — | Global Customer ID. |
| `@ApexID` | `varchar(8)` | No | — | Apex-assigned brokerage account ID. |
| `@SketchID` | `uniqueidentifier` | No | — | GUID of the compliance sketch this decision applies to. |
| `@ReasonTypeID` | `int` | No | — | Type code of the investigation reason (from `Apex.SketchInvestigationReason`). |
| `@ReasonConstant` | `varchar(500)` | No | — | Application constant string identifying the reason. |
| `@SketchDataSource` | `varchar(50)` | No | — | Source system that generated the sketch (e.g., "Apex", "Internal"). |
| `@ReasonDescription` | `varchar(1024)` | Yes | `NULL` | Optional free-text description of the reason for non-appeal. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `SketchInvestigationDoNotAppealReason` | `Apex` | INSERT | Append-only; no duplicate check. |

---

## 5. Logic Flow

1. Single `INSERT INTO Apex.SketchInvestigationDoNotAppealReason` with all seven columns.
2. No existence check — each call creates a new row regardless of prior entries for the same sketch.

This is a pure audit-log append; no upsert logic.

---

## 6. Error Handling

No explicit error handling. Constraint violations propagate to the caller.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.SketchInvestigationDoNotAppealReason` | Table | Audit log for non-appeal decisions |
| `Apex.SketchInvestigationReason` | Table | Reference for `ReasonTypeID` and `ReasonConstant` values |
| `Apex.GetSketchInvestigationReasons` | Stored Procedure | Retrieves the active reason catalogue used to populate `ReasonTypeID` / `ReasonConstant` |

---

## 8. Usage Notes

- This procedure is called when the system decides **not** to auto-appeal — it is not called when an appeal is filed or when manual review is initiated.
- No duplicate prevention is built in; if the same sketch generates multiple non-appeal events, multiple rows will be inserted. This is intentional for a complete audit trail.
- `@ReasonConstant` should be sourced from `Apex.GetSketchInvestigationReasons.ReasonConstant` to ensure consistency with the reference catalogue.
- `@SketchDataSource` identifies the external system that created the investigation flag, which helps operations distinguish Apex-originated sketches from internally-generated ones.
- `@ReasonDescription` is optional but should be populated when the non-appeal decision requires contextual explanation beyond the standard reason type.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveSketchInvestigationDoNotAppealReason.sql` | Quality Score: 8.5/10*
