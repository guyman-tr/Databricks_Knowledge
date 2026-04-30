# Apex.GetTrustedContact

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetTrustedContact.sql`  
**Author:** Serhii Poltava  
**Created:** 2019-09-06  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetTrustedContact` retrieves the trusted contact person designated by a brokerage customer. FINRA Rule 4512 requires broker-dealers to make reasonable efforts to obtain the name and contact information of a trusted contact person for each retail account. This trusted contact is someone the broker can reach if there are concerns about the customer's account activity, suspected financial exploitation, or the customer's capacity to make financial decisions.

This procedure is called by account-management services when displaying the trusted contact to customers, by compliance workflows that need to verify the trusted contact has been collected, and by the Apex integration layer when submitting complete account data.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID of the customer whose trusted contact information is requested. |

---

## 3. Result Sets

**Result Set 1 – Trusted Contact Person**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `GCID` | `Apex.UserDataTrustedContact` | Global Customer ID (echoed). |
| `FirstName` | `Apex.UserDataTrustedContact` | Trusted contact's first name. |
| `LastName` | `Apex.UserDataTrustedContact` | Trusted contact's last name. |
| `PhoneNumber` | `Apex.UserDataTrustedContact` | Phone number for the trusted contact. |
| `PhoneNumberTypeID` | `Apex.UserDataTrustedContact` | Type code for the phone number (e.g., mobile, home). |
| `Email` | `Apex.UserDataTrustedContact` | Email address for the trusted contact. |

Returns 0 rows if no trusted contact has been designated for the given GCID.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `UserDataTrustedContact` | `Apex` | SELECT | No locking hints; single-row lookup by GCID. |

---

## 5. Logic Flow

1. Simple `SELECT` from `Apex.UserDataTrustedContact`.
2. Filters by `GCID = @GCID`.
3. Returns all six columns.

No joins, aggregates, or conditional logic.

---

## 6. Error Handling

No explicit error handling. An empty result set indicates the customer has not yet provided a trusted contact, which is a regulatory deficiency that should be flagged.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.UserDataTrustedContact` | Table | Only data source |
| `Apex.SaveTrustedContact` | Stored Procedure | Companion writer; MERGE upsert for the record returned here |

---

## 8. Usage Notes

- FINRA Rule 4512 requires trusted contact information for retail accounts; compliance checks should treat an empty result as a required-but-missing field, not as "optional."
- `PhoneNumberTypeID` is a reference-code integer; resolve it against the phone-type lookup table for display.
- No `NOLOCK` is used, consistent with reading personally-identifiable information where committed data is important.
- The trusted contact is a separate person from the account holder; do not confuse with the customer's own contact details in `Apex.UserData`.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetTrustedContact.sql` | Quality Score: 8.5/10*
