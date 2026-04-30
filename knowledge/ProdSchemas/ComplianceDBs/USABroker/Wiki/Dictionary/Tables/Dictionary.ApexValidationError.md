# Dictionary.ApexValidationError

**Schema:** Dictionary
**Table:** ApexValidationError
**Database:** USABroker
**Last Reviewed:** 2026-04-14

---

## 1. Business Meaning

`Dictionary.ApexValidationError` is a static reference table that enumerates every distinct error condition the Apex integration layer can surface when a user account creation or update request fails validation. Each row provides a stable numeric identifier and a camelCase name that the application layer maps to a user-facing message or a compliance workflow branch.

The table exists because the Apex platform (the US broker-dealer account management system) returns structured error codes rather than free-text descriptions. Storing those codes in this lookup table decouples the raw numeric value stored in `Apex.UserValidationErrors` from the human-readable label, enabling consistent reporting and alerting without hardcoding strings in application code.

Operationally, the error codes fall into several categories: general API/schema problems (IDs 1–2), personal data validation failures (4–7, 22, 25, 34), form integrity errors (8–11, 20–21), account type / agreement mismatches (12–19), regulatory and compliance holds (38–39, 42–45, 48), and identity-verification failures from the Sketch CIP pipeline (43–50).

---

## 2. Table Elements

| Column | Data Type | Nullable | PK | Description |
|---|---|---|---|---|
| ApexValidationErrorID | int | NOT NULL | Yes | Stable numeric identifier assigned by Apex; referenced by `Apex.UserValidationErrors.ApexValidationErrorID`. |
| Name | nvarchar(150) | NOT NULL | No | CamelCase error code name as returned by the Apex API; used as the programmatic handle in application logic and reporting. |

**Constraints:**
- `PK_ApexValiddationError` — clustered primary key on `ApexValidationErrorID`

---

## 3. Data Overview

50 rows as of 2026-04-14.

| ApexValidationErrorID | Name | Meaning |
|---|---|---|
| 1 | GeneralApiError | An unclassified error was returned from the Apex API — a catch-all when no more specific code applies. |
| 2 | GeneralValidationError | A request failed general validation at Apex without a more specific reason being identified. |
| 3 | UpdateNotSuitable | The requested account update is not permissible for the current state of that account. |
| 4 | FirstNameError | The first name provided does not satisfy Apex's format or allowed-character rules. |
| 5 | LastNameError | The last name provided does not satisfy Apex's format or allowed-character rules. |
| 6 | AddressError | The address submitted (home or mailing) failed Apex's address validation check. |
| 7 | PhoneError | The phone number submitted failed Apex's basic format validation. |
| 8 | FormVersionMismatch | The version of the submitted Apex form does not match the currently accepted version. |
| 9 | FormVersionNotWhiteListed | The form version sent is not on the list of versions Apex permits for submission. |
| 10 | FormSchemaHashWrong | The hash of the form schema does not match the expected value, indicating a tampered or stale schema. |
| 11 | FormHashWrongInvalidHashAlgorithm | The form hash was computed with an algorithm that Apex does not recognise or accept. |
| 12 | AccountIsRequired | An account identifier must be provided but was absent from the request payload. |
| 13 | NotValidAccountForAccountRequest | The account ID supplied is not valid or not eligible for the requested operation. |
| 14 | OneJointAgreementNeeded | Exactly one joint account agreement document must be included for a joint account request. |
| 15 | ForeignDueDiligenceFormShouldBeProvided | A foreign due-diligence form is mandatory but was missing from the submission. |
| 16 | ExactlyOneIraAdoptionAgreementIsRequiredToCreateIraAccount | Creating an IRA account requires exactly one IRA adoption agreement — not zero, not two. |
| 17 | AnIraAgreementShouldOnlyBeProvidedWithAnIraAccount | An IRA agreement was included in a request that is not for an IRA account type. |
| 18 | AJointAgreementShouldOnlyBeProvidedWithJointAccount | A joint agreement document was supplied for an account that is not a joint account. |
| 19 | OneNewAccountFormPossible | Only one new-account form may be submitted per request; multiple forms were detected. |
| 20 | FormNotAllowed | The specific form type submitted is not permitted for this request or account type. |
| 21 | OneFormShouldBeProvided | The request requires exactly one form to be provided but none or multiple were found. |
| 22 | PhoneTooShort | The phone number submitted is shorter than the minimum required length. |
| 23 | EmploymentStatusIsRequired | The employment status field is mandatory for this account type but was not supplied. |
| 24 | EmployerIsRequired | Employer details are mandatory (e.g., when employment status indicates employment) but were absent. |
| 25 | SsnIsMustForUsa | A US Social Security Number is required for US-based account holders but was not provided. |
| 26 | EnumNotFound | A submitted enumerated field value does not exist in the Apex reference data. |
| 27 | ObjectHasMissingRequiredProperties | A JSON object in the request payload is missing one or more required properties per the schema. |
| 28 | InputForCountryAlpha3IsInvalidSeeIso3166Alpha3 | The country code provided is not a valid ISO 3166-1 alpha-3 code. |
| 29 | InputMustBeAsciiPrintable | A text field contains characters outside the ASCII printable range, which Apex does not accept. |
| 30 | InputNotAllowedByTheSchema | A field value was present that the Apex schema explicitly forbids. |
| 31 | PostOfficeBoxNotAllowedForHomeAddress | A P.O. Box was supplied as the home/residential address, which Apex disallows. |
| 32 | PercentageForPrimaryBeneficiaries | The beneficiary percentage allocations do not sum correctly or violate Apex's beneficiary rules. |
| 33 | StateIdFromForUsIsRequired | A US state-issued ID form is required for this request but was not included. |
| 34 | GivenNameInvalid | The given name contains characters or a format that Apex deems invalid. |
| 35 | HomeAddressError | The home address failed a deeper validation check beyond the general AddressError (ID 6). |
| 36 | WrongCombinationOfZipCityAndState | The ZIP code, city, and state combination supplied does not correspond to a valid US location. |
| 37 | NationalPinIsEmpty | The national identification PIN field was expected but submitted as empty. |
| 38 | AffiliatedApprovalRequired | The applicant is affiliated with a broker-dealer or exchange; manual approval is required before proceeding. |
| 39 | ManualProcessingRequired | Apex has flagged this application for manual compliance review rather than straight-through processing. |
| 40 | DisclosureFirmNameError | The name of the firm in the disclosure documents is invalid or does not match expectations. |
| 41 | MailingAddressError | The mailing address submitted failed Apex's address validation check. |
| 42 | UserIsNotPermanentResident | The applicant does not hold US permanent residency and cannot be processed under the current rules. |
| 43 | CipCheckRejectedBySketch | The Customer Identification Program (CIP) check run via Sketch returned a hard rejection. |
| 44 | AddressCouldNotBeVerified | The Sketch CIP pipeline was unable to verify the address against its reference data. |
| 45 | SsnCouldNotBeVerified | The Social Security Number could not be matched or verified through the Sketch identity service. |
| 46 | LastNameCouldNotBeVerified | Sketch's identity verification service could not confirm the last name against its records. |
| 47 | FirstNameCouldNotBeVerified | Sketch's identity verification service could not confirm the first name against its records. |
| 48 | ApplicantProfileContainsHighRiskFraudWarning | Sketch flagged the applicant's profile with a high-risk fraud indicator, triggering compliance review. |
| 49 | DateOfBirthCouldNotBeVerified | The date of birth submitted could not be verified through the Sketch CIP service. |
| 50 | CannotAutoAcceptForDeceased | Sketch's records indicate the applicant is deceased; the system cannot auto-accept such applications. |

---

## 4. Relationships

### Referenced by (Foreign Keys into this table)

| Referencing Table | Referencing Column | Notes |
|---|---|---|
| Apex.UserValidationErrors | ApexValidationErrorID | Each validation error event recorded against a user's account creation or update attempt references one code from this table. |

### References to other tables

This table has no foreign key dependencies; it is a terminal reference (lookup-only) table.

---

## 5. Common Query Patterns

```sql
-- Find the most frequent validation errors logged against user account requests
SELECT d.Name,
       COUNT(*) AS ErrorCount
FROM   Apex.UserValidationErrors uv WITH (NOLOCK)
JOIN   Dictionary.ApexValidationError d WITH (NOLOCK)
       ON uv.ApexValidationErrorID = d.ApexValidationErrorID
GROUP  BY d.Name
ORDER  BY ErrorCount DESC;
```

```sql
-- Retrieve all Sketch-related CIP failure events
SELECT uv.*
FROM   Apex.UserValidationErrors uv WITH (NOLOCK)
JOIN   Dictionary.ApexValidationError d WITH (NOLOCK)
       ON uv.ApexValidationErrorID = d.ApexValidationErrorID
WHERE  d.ApexValidationErrorID BETWEEN 43 AND 50;
```

---

## 6. Data Quality Notes

- The table is append-only in practice; IDs are assigned by the Apex platform and must not be renumbered.
- The primary key constraint name contains a typo (`PK_ApexValiddationError` — double 'd') that should be noted if the constraint is ever rebuilt.
- `Name` uses `nvarchar(150)`, which is wider than most other Dictionary tables (typically 50); this accommodates verbose error codes such as ID 16.
- There is no `IsActive` or soft-delete column; deprecated codes should be documented here rather than deleted.

---

## 7. Change History

| Date | Change |
|---|---|
| 2026-04-14 | Initial documentation created; 50 rows verified against live data. |

---

## 8. Related Objects

| Object | Type | Relationship |
|---|---|---|
| Apex.UserValidationErrors | Table | Fact table that stores each occurrence of a validation error, keyed to this dictionary. |
| Dictionary.OptionsStatus | Table | Sibling dictionary table within the same schema. |
| Dictionary.EligibilityStatus | Table | Sibling dictionary table within the same schema. |

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Documentation generated 2026-04-14 — USABroker · Dictionary schema*
