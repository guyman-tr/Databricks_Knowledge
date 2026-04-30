# Apex.GetOptions

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetOptions.sql`  
**Author:** Oleksandr Litvinov  
**Created:** 2022-05-05  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetOptions` retrieves the complete options-trading profile for a customer. This includes the results of the appropriateness test (whether the customer demonstrated sufficient knowledge/experience for options trading), their eligibility status for options products, the current options account status as assigned by Apex, and reasoning-workflow fields used when the customer is requesting elevated options approval.

It is the primary read for any service that needs to make options-related decisions: front-end eligibility displays, compliance review dashboards, and the options-approval workflow engine.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID of the customer whose options profile is requested. |

---

## 3. Result Sets

**Result Set 1 – Options Profile (all fields)**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `GCID` | `Apex.Options` | Global Customer ID. |
| `AppropriatenessTestResultID` | `Apex.Options` | Result code of the options knowledge/appropriateness test. |
| `AppropriatenessProductID` | `Apex.Options` | Product scope for which the appropriateness result applies. |
| `AppropriatenessRecalculationReasonID` | `Apex.Options` | Reason code when the appropriateness result was recalculated. |
| `EligibilityStatusID` | `Apex.Options` | Overall options-trading eligibility status. |
| `EligibilityStatusReasonID` | `Apex.Options` | Reason code for the eligibility decision. |
| `OptionsStatusID` | `Apex.Options` | Current options account status at Apex Clearing. |
| `OptionsApexID` | `Apex.Options` | Apex-assigned options account identifier. |
| `ApplicationName` | `Apex.Options` | Name of the application/service that last updated this record. |
| `OptionsStatusControlID` | `Apex.Options` | Control identifier used to correlate Apex status events. |
| `ReasoningStatusID` | `Apex.Options` | Status of the reasoning/justification workflow. |
| `ReasoningFormID` | `Apex.Options` | GUID of the reasoning form associated with this options profile. |
| `AppropriatenessTestDate` | `Apex.Options` | Date the appropriateness test was last administered. |
| `StocksElegibilityStatusID` | `Apex.Options` | Eligibility status specific to stocks options. |
| `CryptoElegibilityStatusID` | `Apex.Options` | Eligibility status specific to crypto options. |

Returns 0 rows if no options record exists for the given GCID.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `Options` | `Apex` | SELECT | Read with `NOLOCK`; full-row retrieval by GCID. |

---

## 5. Logic Flow

1. `NOLOCK` read on `Apex.Options`.
2. Filters by `GCID = @GCID`.
3. Returns all 15 columns.

No joins or aggregates. Single-row point query.

---

## 6. Error Handling

No explicit error handling. Returns empty if no options record exists.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.Options` | Table | Only data source |
| `Apex.SaveOptionsAppropriateness` | Stored Procedure | Writes appropriateness fields |
| `Apex.SaveOptionsEligibility` | Stored Procedure | Writes eligibility fields |
| `Apex.SaveOptionsStatus` | Stored Procedure | Writes status fields |
| `Apex.SaveOptionsReasoningStatus` | Stored Procedure | Writes reasoning workflow fields |
| `Apex.GetOptionsByOptionsApexId` | Stored Procedure | Alternate lookup by OptionsApexID |

---

## 8. Usage Notes

- The `Options` record is created lazily — a row is inserted on the first save operation (whichever of the four Save procedures is called first), with default zero values for all other status fields.
- `StocksElegibilityStatusID` and `CryptoElegibilityStatusID` are separate from the general `EligibilityStatusID` to support product-specific eligibility rules.
- `ReasoningFormID` links to `Apex.OptionsReasoningForm`; use `Apex.GetOptionsReasoningFormQuestionsAnswers` to retrieve associated Q&A data.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetOptions.sql` | Quality Score: 8.5/10*
