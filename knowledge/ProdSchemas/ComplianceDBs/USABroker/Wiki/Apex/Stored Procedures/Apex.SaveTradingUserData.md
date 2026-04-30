# Apex.SaveTradingUserData

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveTradingUserData.sql`  
**Author:** Oleksandr Litvinov  
**Created:** 2021-07-28  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveTradingUserData` creates or updates the Apex Clearing-facing trading profile for a customer. This record contains the personal and address data formatted for submission to Apex's account management API, along with the FINRA Large Trader ID (`FDID`) and the Apex account identifier. The procedure uses MERGE with field-level change detection to avoid unnecessary writes when the profile has not changed.

It is called by the account-synchronisation service whenever a customer's personal or address data changes and needs to be reflected in the Apex trading profile, and during initial onboarding when the trading profile is first established.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@CID` | `int` | No | Internal Customer ID. |
| `@GCID` | `int` | No | Global Customer ID (merge key). |
| `@ApexID` | `varchar(8)` | No | Apex-assigned brokerage account ID. |
| `@FDID` | `varchar(20)` | No | FINRA Large Trader ID. |
| `@GivenName` | `nvarchar(50)` | No | Customer's given (first) name. |
| `@FamilyName` | `nvarchar(50)` | No | Customer's family (last) name. |
| `@LegalName` | `nvarchar(150)` | No | Customer's full legal name. |
| `@Country` | `nvarchar(3)` | No | ISO 3-letter country code. |
| `@State` | `nvarchar(2)` | No | US state code. |
| `@City` | `nvarchar(50)` | No | City name. |
| `@PostalCode` | `nvarchar(50)` | No | Postal / ZIP code. |
| `@StreetAddress1` | `nvarchar(50)` | No | Primary street address. |
| `@StreetAddress2` | `nvarchar(50)` | No | Secondary street address. |
| `@StreetAddress3` | `nvarchar(50)` | No | Tertiary street address. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `TradingUserData` | `Apex` | MERGE (INSERT / conditional UPDATE) | Change-detection on 13 of 14 fields; GCID is the merge key. |

---

## 5. Logic Flow

MERGE on `TARGET.GCID = Source.GCID`:

- **WHEN MATCHED AND** any of 13 fields differ (using `ISNULL` normalisation): UPDATE all fields.
  - **Note:** `StreetAddress2` and `StreetAddress3` use direct assignment (`= @StreetAddress2`) in the UPDATE, not `ISNULL()` — meaning they can be explicitly set to NULL, unlike the other fields which preserve existing values when NULL is passed.
- **WHEN NOT MATCHED BY TARGET:** INSERT all 14 columns.

---

## 6. Error Handling

No explicit error handling. MERGE exceptions propagate.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.TradingUserData` | Table | Trading profile store |
| `Apex.GetTradingUserData` | Stored Procedure | Reads the profile written here (single GCID) |
| `Apex.GetTradingUsersDataList` | Stored Procedure | Reads profiles written here (bulk TVP) |

---

## 8. Usage Notes

- **`StreetAddress2` and `StreetAddress3` behave differently from other fields:** they use direct assignment in the UPDATE (not `ISNULL`), so passing NULL for these fields will set them to NULL in the database. This is intentional — secondary address lines should be clearable.
- `FDID` may be `NULL` or empty for customers below the FINRA large-trader threshold, but the parameter is typed as `NOT NULL` in the procedure — pass an empty string if not applicable.
- The MERGE key is `GCID` (one trading profile per customer). If a customer is re-opened with a new `ApexID`, the existing row will be updated.
- The change-detection condition checks 13 fields; the `GCID` itself is the key and is not in the change-detection list.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveTradingUserData.sql` | Quality Score: 8.5/10*
