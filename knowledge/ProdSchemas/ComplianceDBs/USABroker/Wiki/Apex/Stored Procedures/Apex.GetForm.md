# Apex.GetForm

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetForm.sql`  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetForm` retrieves the definition of a named regulatory or onboarding form at a specific version. Forms are JSON documents that define the structure, fields, and validation rules presented to users during the Apex account-opening workflow. By specifying both `FormName` and `Version`, callers retrieve the exact form snapshot rendered or validated at a given point in time.

This procedure is called by the front-end serving layer and by back-end validation services to obtain the canonical form definition, its hash (used for integrity checking), and its full JSON body for rendering or processing.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@FormName` | `varchar(250)` | No | The logical name of the form (e.g., `"OptionsAgreement"`). |
| `@Version` | `int` | No | The version number of the form to retrieve. |

---

## 3. Result Sets

**Result Set 1 – Form Definition**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `ID` | `Apex.Form` | Surrogate primary key of the form record. |
| `FormName` | `Apex.Form` | The logical form name. |
| `Hash` | `Apex.Form` | A hash string used to detect if the form body has changed. |
| `JsonBody` | `Apex.Form` | The full JSON definition of the form (nvarchar(max)). |
| `Version` | `Apex.Form` | The version number (echoed for confirmation). |

Returns 0 rows if no matching `FormName` + `Version` combination exists.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `Form` | `Apex` | SELECT | Read with `NOLOCK`; compound key lookup on `FormName` + `Version`. |

---

## 5. Logic Flow

1. `NOLOCK` read on `Apex.Form`.
2. Filters by `FormName = @FormName AND Version = @Version` (compound equality).
3. Returns all five columns of the matching row.

No conditional logic, joins, or aggregates. This is a versioned dictionary lookup.

---

## 6. Error Handling

No explicit error handling. An empty result set is returned when the form/version combination does not exist.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.Form` | Table | Only data source |
| `Apex.SaveForm` | Stored Procedure | Companion writer; upserts the form definition read here |
| `Apex.GetLatestForms` | Stored Procedure | Companion reader; returns the latest version of each distinct form name |

---

## 8. Usage Notes

- When the desired version is not known in advance, use `Apex.GetLatestForms` to discover the highest version ID per form name, then call `Apex.GetForm` with that version.
- The `Hash` column allows callers to detect whether a locally cached form definition is still current without re-reading the full `JsonBody`.
- `JsonBody` is `nvarchar(max)` and may be very large; avoid reading it in high-frequency loops.
- The `NOLOCK` hint is acceptable here because form definitions are effectively immutable once published at a given version number.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetForm.sql` | Quality Score: 8.5/10*
