# Apex.SaveUserData

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveUserData.sql`  
**Author:** Serhii Poltava  
**Created:** 2019-09-06  
**Last Updated:** 2021-08-31  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveUserData` is the **primary write path for a customer's KYC (Know Your Customer) and account profile data**. It stores the comprehensive personal, contact, address, compliance-disclosure, and approval information required to open and maintain a brokerage account with Apex Clearing. This is one of the most important procedures in the schema, as it is the source of truth for the information submitted to Apex during account creation and all subsequent update events.

The procedure is called by the user-data synchronisation service whenever the customer's profile changes in the upstream system, and during initial onboarding when the account is first created.

---

## 2. Parameters

| Parameter | Type | Nullable | Default | Description |
|-----------|------|----------|---------|-------------|
| `@GCID` | `int` | No | — | Global Customer ID (merge key). |
| `@CID` | `int` | No | — | Internal Customer ID. |
| `@AccountTypeID` | `int` | No | — | Account type code. |
| `@CustomerTypeID` | `int` | No | — | Customer type code. |
| `@FirstName` | `nvarchar(50)` | No | — | First name. |
| `@LastName` | `nvarchar(50)` | No | — | Last name. |
| `@MiddleName` | `nvarchar(50)` | No | — | Middle name. |
| `@DateOfBirth` | `date` | No | — | Date of birth. |
| `@NationalPin` | `varchar(128)` | No | — | National identification number (SSN, TIN, etc.). |
| `@CitizenshipCountryID` | `int` | No | — | Citizenship country. |
| `@PermanentResident` | `bit` | No | — | Permanent resident flag. |
| `@PhoneNumber` | `varchar(30)` | No | — | Phone number. |
| `@PhoneNumberTypeID` | `int` | No | — | Phone type. |
| `@Email` | `varchar(50)` | No | — | Email address. |
| `@Address` | `nvarchar(100)` | No | — | Street address. |
| `@BuildingNumber` | `nvarchar(30)` | No | — | Building / apartment number. |
| `@City` | `nvarchar(50)` | No | — | City. |
| `@ProvinceID` | `int` | No | — | Province / state / region ID. |
| `@Zip` | `nvarchar(50)` | No | — | Postal code. |
| `@CountryID` | `int` | No | — | Country of residence. |
| `@POBCountryID` | `int` | No | — | Place of birth country. |
| `@IsControlPerson` | `bit` | No | — | FINRA control person disclosure flag. |
| `@DisclosureCompanySymbols` | `nvarchar(255)` | No | — | Company symbols for control person disclosure. |
| `@IsAffiliatedExchangeOrFINRA` | `bit` | No | — | Exchange/FINRA affiliation flag. |
| `@DisclosureFirmName` | `nvarchar(255)` | No | — | Affiliated firm name for disclosure. |
| `@IsPoliticallyExposed` | `bit` | No | — | Politically exposed person (PEP) flag. |
| `@PepAdditionalData` | `nvarchar(255)` | No | — | Additional PEP information. |
| `@ApproverName` | `varchar(128)` | No | — | Name of approving staff member. |
| `@ApprovedByDate` | `datetime2(7)` | No | — | Approval timestamp. |
| `@Created` | `datetime2(7)` | Yes | `NULL` | Record creation timestamp; defaults to `GETUTCDATE()` if NULL on INSERT. |
| `@VisaType` | `nvarchar(255)` | Yes | `NULL` | Visa type for non-citizen customers. |
| `@VisaExpirationDate` | `datetime2(7)` | Yes | `NULL` | Visa expiration date. |
| `@UsVisaHolder` | `bit` | Yes | `NULL` | Flag indicating US visa holder status. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `UserData` | `Apex` | SELECT (EXISTS) + UPDATE or INSERT | Classic IF EXISTS upsert; all 32 non-key columns are written on UPDATE. |

---

## 5. Logic Flow

1. `IF EXISTS (SELECT 1 FROM Apex.UserData WHERE GCID = @GCID)`:
   - **True:** Full UPDATE of all 31 non-GCID columns (every call overwrites the entire row).
   - **False:** INSERT all 32 columns; `Created` defaults to `ISNULL(@Created, GETUTCDATE())`.

Unlike MERGE-based procedures, there is **no change-detection** — every call to the UPDATE path writes all columns regardless of whether data changed.

---

## 6. Error Handling

No explicit error handling. SQL Server exceptions propagate.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.UserData` | Table | Primary KYC data store |
| `Apex.GetApexDataAndState` | Stored Procedure | Reads `ApproverName`, `ApprovedByDate`, `Created` from this table |
| `Apex.SaveUserDataApproveInfo` | Stored Procedure | Targeted update for approval fields only; prefer over full SaveUserData for approval-only changes |

---

## 8. Usage Notes

- This procedure performs a **full row overwrite** on UPDATE — all 31 columns are written even if only one changed. For high-frequency updates, this generates more write I/O than a MERGE with change-detection. Consider whether `SaveUserDataApproveInfo` or a more targeted update is appropriate for approval-only changes.
- `@Created` is only used on INSERT; it is ignored on UPDATE. This preserves the original creation timestamp across subsequent saves.
- `@NationalPin` is 128 characters — it may store a hashed or encrypted SSN/TIN value. Confirm data handling policies before logging or displaying this field.
- Compliance disclosure fields (`@IsControlPerson`, `@IsAffiliatedExchangeOrFINRA`, `@IsPoliticallyExposed`) are critical regulatory fields; ensure accurate values are passed with every update to prevent stale disclosure data.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveUserData.sql` | Quality Score: 8.5/10*
