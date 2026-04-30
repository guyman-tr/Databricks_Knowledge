# Apex.SaveMailingAddress

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveMailingAddress.sql`  
**Author:** Victor Shatokhin  
**Created:** 2021-05-14  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveMailingAddress` creates or updates the mailing address for a customer. The mailing address is separate from the primary residential address in `Apex.UserData` and is used for correspondence that must be routed to a different location — such as a PO box, a business address, or a third-party mailing agent.

The procedure uses a MERGE with field-level change detection, meaning a write only occurs when at least one address field has actually changed — preventing unnecessary write amplification and avoiding spurious "last modified" timestamp updates.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID. |
| `@CountryID` | `int` | No | Numeric country ID for the mailing country. |
| `@Address` | `nvarchar(255)` | No | Street address line. |
| `@City` | `nvarchar(50)` | No | City name. |
| `@Zip` | `nvarchar(50)` | No | Postal / ZIP code. |
| `@BuildingNumber` | `nvarchar(30)` | No | Building or apartment number. |
| `@RegionID` | `int` | No | Region / state / province ID. |
| `@SubRegionID` | `int` | No | Sub-region ID for finer geographic classification. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `UserDataMailingAddress` | `Apex` | MERGE (UPDATE / INSERT) | Change-detection on all seven address fields. |

---

## 5. Logic Flow

MERGE on `TARGET.GCID = Source.GCID`:

- **WHEN MATCHED AND** (any of the seven address fields differ — using `ISNULL` to treat NULL as 0 or empty string for comparison):
  - UPDATE all fields using `ISNULL(@param, TARGET.field)` to preserve existing values when NULL is passed.
- **WHEN NOT MATCHED BY TARGET:** INSERT all eight columns.

The change-detection condition uses `ISNULL` normalisation:
- Numeric IDs compared as `ISNULL(x, 0) <> ISNULL(y, 0)`.
- String fields compared as `ISNULL(x, '') <> ISNULL(y, '')`.

---

## 6. Error Handling

No explicit error handling. MERGE exceptions propagate to the caller.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.UserDataMailingAddress` | Table | Mailing address store |
| `Apex.GetMailingAddress` | Stored Procedure | Reads the address written here |

---

## 8. Usage Notes

- The ISNULL default values in the UPDATE clause (`ISNULL(@param, TARGET.field)`) mean that passing NULL for any parameter preserves the existing value. This enables partial-update call patterns.
- However, there is a subtlety: if you genuinely want to clear a field to NULL, this procedure cannot do so as written. Callers that need to null-out fields would need a different mechanism.
- `CountryID`, `RegionID`, and `SubRegionID` must be valid reference-data IDs; the procedure does not validate them against lookup tables.
- The MERGE avoids double-writes when address data is unchanged, which is important for systems that track "last modified" timestamps at the table level.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveMailingAddress.sql` | Quality Score: 8.5/10*
