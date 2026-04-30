# Apex.GetOptionsByOptionsApexId

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetOptionsByOptionsApexId.sql`  
**Author:** Andrii Slobodian  
**Created:** 2023-01-02  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetOptionsByOptionsApexId` looks up a customer's options record using the **Apex-assigned options identifier** (`OptionsApexID`) rather than the internal `GCID`. This is needed when Apex Clearing sends back event callbacks that carry the `OptionsApexID` but not the internal customer identifier. By reversing the lookup, the integration layer can map an inbound Apex event back to the correct customer row and update state accordingly.

It is called by the event-processing pipeline when handling Apex status-change notifications for options accounts.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@OptionsApexID` | `nvarchar(50)` | No | The Apex-assigned options account identifier received from Apex Clearing. |

---

## 3. Result Sets

**Result Set 1 – Options Record by Apex ID**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `GCID` | `Apex.Options` | Internal Global Customer ID — use this to correlate back to the customer. |
| `AppropriatenessTestResultID` | `Apex.Options` | Result of the appropriateness test. |
| `AppropriatenessProductID` | `Apex.Options` | Product scope for the appropriateness result. |
| `AppropriatenessRecalculationReasonID` | `Apex.Options` | Reason if the test result was recalculated. |
| `EligibilityStatusID` | `Apex.Options` | Options eligibility status. |
| `EligibilityStatusReasonID` | `Apex.Options` | Reason code for the eligibility decision. |
| `OptionsStatusID` | `Apex.Options` | Current options account status at Apex Clearing. |
| `OptionsApexID` | `Apex.Options` | The Apex options account ID (echoed). |
| `ApplicationName` | `Apex.Options` | Last application to update this record. |
| `OptionsStatusControlID` | `Apex.Options` | Control ID for Apex status correlation. |
| `BeginTime` | `Apex.Options` | Timestamp when the options record was first created. |
| `EndTime` | `Apex.Options` | Timestamp when the options record was closed/expired, if applicable. |

Returns 0 rows if no options record exists for the given `OptionsApexID`. Returns multiple rows if more than one GCID shares the same `OptionsApexID` (a data-integrity anomaly that should not occur).

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `Options` | `Apex` | SELECT | Read with `NOLOCK`; lookup by `OptionsApexID` column. |

---

## 5. Logic Flow

1. `NOLOCK` read on `Apex.Options`.
2. Filters by `OptionsApexID = @OptionsApexID`.
3. Returns 12 columns including `BeginTime` and `EndTime` (which differ from the `Apex.GetOptions` column set — `ReasoningStatusID`, `ReasoningFormID`, `AppropriatenessTestDate`, `StocksElegibilityStatusID`, and `CryptoElegibilityStatusID` are omitted, but `BeginTime` and `EndTime` are included).

---

## 6. Error Handling

No explicit error handling. An empty result set indicates the `OptionsApexID` is not known in this database.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.Options` | Table | Only data source |
| `Apex.GetOptions` | Stored Procedure | Companion reader by GCID — returns a different column subset |
| `Apex.SaveOptionsStatus` | Stored Procedure | Populates the `OptionsApexID` field queried here |

---

## 8. Usage Notes

- This procedure is specifically designed for **inbound Apex event processing** where only `OptionsApexID` is available. Once `GCID` is retrieved from the result, switch to GCID-based procedures for all further operations.
- The column set returned is not identical to `Apex.GetOptions` — `BeginTime` and `EndTime` are included here but not in `GetOptions`; reasoning and extended eligibility columns are omitted.
- `NOLOCK` is appropriate because this is a read-only reverse-lookup for event processing and does not need to participate in a write transaction.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetOptionsByOptionsApexId.sql` | Quality Score: 8.5/10*
