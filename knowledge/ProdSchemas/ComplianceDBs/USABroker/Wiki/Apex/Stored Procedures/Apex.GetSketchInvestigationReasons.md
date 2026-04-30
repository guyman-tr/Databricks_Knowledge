# Apex.GetSketchInvestigationReasons

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetSketchInvestigationReasons.sql`  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetSketchInvestigationReasons` returns the full catalogue of active reasons why a compliance sketch investigation was raised. These reason codes and descriptions are the reference data used when compliance officers, automated systems, or Apex Clearing flag an account for investigation. Only active reasons (`Active = 1`) are returned, ensuring retired reason codes are not presented in UI dropdowns or used in new investigation records.

This procedure is called by the compliance workflow UI to populate reason-selection dropdowns, by the investigation-creation service to validate submitted reason codes, and by reporting tools to decode reason IDs stored in investigation records.

---

## 2. Parameters

None. Returns the full active reason catalogue.

---

## 3. Result Sets

**Result Set 1 – Active Sketch Investigation Reasons**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `ID` | `Apex.SketchInvestigationReason` | Surrogate primary key of the reason record. |
| `ReasonTypeID` | `Apex.SketchInvestigationReason` | Numeric type grouping (e.g., identity-related, financial, regulatory). |
| `ReasonCode` | `Apex.SketchInvestigationReason` | Short alphanumeric code used in API payloads and integrations. |
| `ReasonDescription` | `Apex.SketchInvestigationReason` | Human-readable description of the investigation reason. |
| `ReasonConstant` | `Apex.SketchInvestigationReason` | Application-code constant string for programmatic matching. |
| `CanAutoAppeal` | `Apex.SketchInvestigationReason` | Flag indicating whether the system can automatically submit an appeal for this reason. |
| `Active` | `Apex.SketchInvestigationReason` | Always 1 in this result set (filter applied). |

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `SketchInvestigationReason` | `Apex` | SELECT | Read with `NOLOCK`; filtered to `Active = 1`. |

---

## 5. Logic Flow

1. `NOLOCK` read on `Apex.SketchInvestigationReason`.
2. Filters by `Active = 1` to return only current, valid reason codes.
3. Returns all seven columns for each active reason.

Reference-data read with no joins, aggregates, or parameters.

---

## 6. Error Handling

No explicit error handling. Returns an empty result set if no active reasons are configured (a configuration error).

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.SketchInvestigationReason` | Table | Only data source |
| `Apex.SaveSketchInvestigationDoNotAppealReason` | Stored Procedure | Uses `ReasonConstant` and `ReasonTypeID` from this catalogue |

---

## 8. Usage Notes

- `CanAutoAppeal = 1` indicates the system may automatically file an appeal without compliance-officer intervention; `CanAutoAppeal = 0` requires manual review.
- `ReasonConstant` is used by application code for hard-coded matching logic; do not change existing constants without a coordinated code deployment.
- The `Active` column allows soft-deletion of retired reasons without removing historical data from investigation records.
- This is a low-change reference table; consider caching the result in the application layer to reduce database round-trips.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetSketchInvestigationReasons.sql` | Quality Score: 8.5/10*
