# Apex.GetMailingAddress

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetMailingAddress.sql`  
**Author:** Victor Shatokhin  
**Created:** 2021-05-14  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetMailingAddress` retrieves the mailing address on file for a given customer. The mailing address is used when the customer's correspondence address differs from their primary residential address — for example, customers who receive brokerage statements and regulatory notices at a PO box or a secondary address rather than their home address.

This procedure is called by account-management services, compliance workflows, and communication systems that need the current mailing address for document delivery, KYC checks, or submission to Apex Clearing.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID of the user whose mailing address is requested. |

---

## 3. Result Sets

**Result Set 1 – Mailing Address**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `GCID` | `Apex.UserDataMailingAddress` | Global Customer ID (echoed). |
| `CountryID` | `Apex.UserDataMailingAddress` | Numeric ID of the mailing country. |
| `Address` | `Apex.UserDataMailingAddress` | Street address line (up to 255 characters). |
| `City` | `Apex.UserDataMailingAddress` | City name. |
| `Zip` | `Apex.UserDataMailingAddress` | Postal / ZIP code. |
| `BuildingNumber` | `Apex.UserDataMailingAddress` | Building or apartment number (up to 30 characters). |
| `RegionID` | `Apex.UserDataMailingAddress` | Numeric region / state / province ID. |
| `SubRegionID` | `Apex.UserDataMailingAddress` | Numeric sub-region ID for finer geographic classification. |

Returns 0 rows if no mailing address has been registered for the given GCID.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `UserDataMailingAddress` | `Apex` | SELECT | No locking hint; single-row lookup by GCID. |

---

## 5. Logic Flow

1. Simple `SELECT` from `Apex.UserDataMailingAddress`.
2. Filters by `GCID = @GCID`.
3. Returns all eight columns.

No joins, aggregates, or conditional branching.

---

## 6. Error Handling

No explicit error handling. An empty result set indicates no mailing address has been stored for the user.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.UserDataMailingAddress` | Table | Only data source |
| `Apex.SaveMailingAddress` | Stored Procedure | Companion writer; upserts the row returned here |

---

## 8. Usage Notes

- No `NOLOCK` hint is used on this read; this is intentional to ensure callers receive committed address data, particularly important for regulatory submissions.
- `CountryID`, `RegionID`, and `SubRegionID` are foreign keys to a reference-data dictionary. Callers must resolve these IDs to human-readable values if displaying to end users.
- An empty result set means the user relies on their primary address (from `Apex.UserData`) for all correspondence; this is a valid state.
- Use `Apex.SaveMailingAddress` to create or update the mailing address; it performs a change-detection MERGE to avoid unnecessary writes.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetMailingAddress.sql` | Quality Score: 8.5/10*
