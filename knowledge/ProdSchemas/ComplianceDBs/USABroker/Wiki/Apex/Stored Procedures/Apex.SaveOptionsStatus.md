# Apex.SaveOptionsStatus

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveOptionsStatus.sql`  
**Author:** Oleksandr Litvinov  
**Created:** 2022-05-05  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.SaveOptionsStatus` records or updates the Apex Clearing-facing options account status for a customer. This includes the status code that Apex assigned to the options account, the Apex-assigned options account identifier (`OptionsApexID`), a control identifier used for status-event correlation (`OptionsStatusControlID`), and the originating application. This information is populated when Apex responds to an options account application and is updated when Apex sends status-change events.

It is called by the Apex event-processing service when a status change notification is received from Apex Clearing, and by the options application submission service when recording the initial account ID assigned by Apex.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID. |
| `@OptionsStatusID` | `int` | No | Options account status code from Apex Clearing. |
| `@OptionsApexID` | `nvarchar(50)` | No | Apex-assigned options account identifier. |
| `@OptionsStatusControlID` | `int` | No | Control ID for correlating Apex status-change events. |
| `@ApplicationName` | `nvarchar(50)` | No | Name of the service performing the update. |

---

## 3. Result Sets

None. Write-only procedure.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `Options` | `Apex` | SELECT (EXISTS check) + UPDATE or INSERT | Creates the row on first write with zero-valued other fields. |

---

## 5. Logic Flow

1. `IF EXISTS (SELECT 1 FROM Apex.Options WHERE GCID = @GCID)`:
   - **True:** UPDATE status fields: `OptionsStatusID`, `OptionsApexID`, `OptionsStatusControlID`, `ApplicationName` — using `ISNULL(@param, existing_value)` for nullable preservation.
   - **False:** INSERT with status fields set and all other appropriateness/eligibility fields defaulted to `0`.

---

## 6. Error Handling

No explicit error handling. SQL Server exceptions propagate.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.Options` | Table | Options profile store |
| `Apex.GetOptions` | Stored Procedure | Reads the row written here (by GCID) |
| `Apex.GetOptionsByOptionsApexId` | Stored Procedure | Reverse-lookup by `OptionsApexID` populated here |
| `Apex.SaveOptionsAppropriateness` | Stored Procedure | Writes appropriateness fields to the same row |
| `Apex.SaveOptionsEligibility` | Stored Procedure | Writes eligibility fields to the same row |

---

## 8. Usage Notes

- `OptionsApexID` written here is the key used by `Apex.GetOptionsByOptionsApexId` for reverse lookup. Ensure this value is always the exact string received from Apex Clearing.
- `OptionsStatusControlID` is used by the event-processing layer to verify that a received status event corresponds to the correct submission cycle, preventing out-of-order event processing.
- When this procedure creates a new `Options` row (INSERT path), appropriateness and eligibility fields are initialised to `0`. The full profile is built by calling all four `SaveOptions*` procedures.
- The INSERT path for this procedure is unusual in production — typically `SaveOptionsAppropriateness` or `SaveOptionsEligibility` creates the row first. The INSERT here serves as a safety net.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.SaveOptionsStatus.sql` | Quality Score: 8.5/10*
