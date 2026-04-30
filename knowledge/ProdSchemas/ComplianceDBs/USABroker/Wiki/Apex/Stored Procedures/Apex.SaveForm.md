# Apex.SaveForm

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveForm.sql`  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveForm` creates or replaces a versioned form definition in the Apex form library. Forms are JSON documents that define the structure, fields, and validation rules for regulatory and onboarding questionnaires. By pairing `FormName` with a `Version` number, the procedure supports immutable versioning: a new version of a form is a new row, while an existing version can be updated in place (e.g., to correct a hash or JSON body without changing the version number).

After writing, the procedure returns the form's database `ID` so the caller can reference it in downstream operations without a separate lookup.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@FormName` | `varchar(250)` | No | The logical form name (e.g., `"OptionsAgreement"`). |
| `@Hash` | `varchar(250)` | No | Integrity hash of the JSON body; used for change detection. |
| `@JsonBody` | `nvarchar(max)` | No | The full JSON form definition. |
| `@Version` | `int` | No | The version number for this form definition. |

---

## 3. Result Sets

**Result Set 1 – Form ID**

| Column | Description |
|--------|-------------|
| `ID` | The database surrogate key of the inserted or updated form record. |

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `Form` | `Apex` | SELECT (EXISTS) + UPDATE or INSERT | OUTPUT clause used to capture the ID in both branches. |

---

## 5. Logic Flow

1. Declares a table variable `@ExistingID` to capture the `ID` from the OUTPUT clause.
2. `IF EXISTS (SELECT 1 FROM Apex.Form WHERE FormName = @FormName AND Version = @Version)`:
   - **True:** `UPDATE Form SET Hash, FormName, JsonBody, Version ... OUTPUT deleted.ID INTO @ExistingID WHERE FormName = @FormName AND Version = @Version`.
   - **False:** `INSERT INTO Form (FormName, Hash, JsonBody, Version) OUTPUT inserted.ID INTO @ExistingID VALUES (...)`.
3. `SELECT ID FROM @ExistingID` — returns the form's database ID.

Note: The UPDATE uses `OUTPUT deleted.ID` (the ID before the update — but since `ID` is an identity column and not updated, this is the same as the current `ID`).

---

## 6. Error Handling

No explicit error handling. SQL Server standard exceptions propagate. A `JsonBody` exceeding available storage would raise a system error.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.Form` | Table | Form definition store |
| `Apex.GetForm` | Stored Procedure | Reads the form by FormName + Version |
| `Apex.GetLatestForms` | Stored Procedure | Reads the latest version of each form |

---

## 8. Usage Notes

- The returned `ID` is useful for caching and cross-referencing; callers should store it rather than performing a secondary lookup.
- Updating an existing `FormName` + `Version` combination is intentional for correcting hash or body errors. If semantic changes to a form require a new version, increment `@Version` instead.
- `JsonBody` is `nvarchar(max)` and can be very large; monitor for storage and memory impacts in high-churn environments.
- Unlike the MERGE-based Save procedures, this uses IF EXISTS / UPDATE ELSE INSERT — which has the same theoretical TOCTOU race for concurrent inserts of the same new form version. In practice, form creation is low-frequency.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveForm.sql` | Quality Score: 8.5/10*
