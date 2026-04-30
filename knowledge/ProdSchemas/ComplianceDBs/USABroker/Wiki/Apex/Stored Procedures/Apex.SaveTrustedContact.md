# Apex.SaveTrustedContact

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveTrustedContact.sql`  
**Author:** Serhii Poltava  
**Created:** 2019-09-06  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveTrustedContact` creates or updates the trusted contact person designated for a brokerage account. Per FINRA Rule 4512, broker-dealers must make reasonable efforts to obtain trusted contact information for retail accounts. This procedure is the write path for that data — called when a customer designates or updates their trusted contact during account opening or via the account management flow.

The MERGE with field-level change detection ensures that the trusted contact row is only written when information has actually changed, preventing unnecessary audit-trail entries.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID (merge key). |
| `@FirstName` | `nvarchar(50)` | No | Trusted contact's first name. |
| `@LastName` | `nvarchar(50)` | No | Trusted contact's last name. |
| `@PhoneNumber` | `varchar(30)` | No | Phone number. |
| `@PhoneNumberTypeID` | `int` | No | Phone number type code (mobile, home, etc.). |
| `@Email` | `varchar(50)` | No | Email address. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `UserDataTrustedContact` | `Apex` | MERGE (INSERT / conditional UPDATE) | Change-detection on all five contact fields. |

---

## 5. Logic Flow

MERGE on `Target.GCID = Source.GCID`:

- **WHEN MATCHED AND** any of the five fields differ (using `ISNULL` normalisation):
  - UPDATE all five fields with `ISNULL(@param, Target.field)` — preserves existing value when NULL is passed.
- **WHEN NOT MATCHED BY TARGET:** INSERT all six columns.

Change-detection uses:
- Strings: `ISNULL(x, '') <> ISNULL(y, '')`.
- Phone number type: `ISNULL(x, 0) <> ISNULL(y, 0)`.

---

## 6. Error Handling

No explicit error handling. MERGE exceptions propagate.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.UserDataTrustedContact` | Table | Trusted contact store |
| `Apex.GetTrustedContact` | Stored Procedure | Reads the record written here |

---

## 8. Usage Notes

- The `ISNULL(@param, Target.field)` UPDATE pattern means passing NULL for any field preserves the existing value. This supports partial-update call patterns where only changed fields are known.
- A customer can have at most one trusted contact per GCID (enforced by the MERGE key). To remove a trusted contact entirely, use `Apex.DeleteTrustedContact`.
- `@PhoneNumberTypeID` references a phone-type lookup table; ensure the value is valid before calling.
- `@Email` is typed `varchar(50)`, which may truncate longer email addresses; monitor for truncation errors in environments with long email domains.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveTrustedContact.sql` | Quality Score: 8.5/10*
