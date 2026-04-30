# Apex.GetApexData

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetApexData.sql`  
**Author:** Serhii Poltava  
**Created:** 2019-10-24  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetApexData` is the primary lookup for a user's Apex brokerage account binding. Given a Global Customer ID (`GCID`), it returns the Apex-assigned account identifier (`ApexID`), the current account status (`StatusID`), and the timestamp when the Apex onboarding process began (`BeginTime`).

This procedure is called early in every workflow that needs to know whether a user already has an Apex account, what that account's external ID is, and what lifecycle state it is in. It is the canonical "does this user have an Apex account?" check within the integration layer.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID — the internal platform identifier for the user. |

---

## 3. Result Sets

**Result Set 1 – Apex Account Snapshot**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `ApexID` | `Apex.ApexData` | The external Apex-assigned account identifier (up to 8 characters). |
| `GCID` | `Apex.ApexData` | The internal Global Customer ID (echoed back for confirmation). |
| `StatusID` | `Apex.ApexData` | Numeric status code representing the Apex account lifecycle state. |
| `BeginTime` | `Apex.ApexData` | UTC timestamp when the Apex onboarding process was initiated. |

Returns 0 rows if the user has no Apex account record.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `ApexData` | `Apex` | SELECT | Read with `NOLOCK`; single-row lookup by `GCID`. |

---

## 5. Logic Flow

1. Executes a `NOLOCK` point query against `Apex.ApexData`.
2. Filters by `GCID = @GCID`.
3. Returns four columns: `ApexID`, `GCID`, `StatusID`, `BeginTime`.

No joins, aggregates, CTEs, or conditional branching. This is the simplest possible account-existence check.

---

## 6. Error Handling

No explicit error handling. SQL Server default exception propagation applies. An empty result set indicates no Apex account record exists for the given `GCID`.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.ApexData` | Table | Primary data source |
| `Apex.SaveApexData` | Stored Procedure | Companion writer; creates or updates the row returned here |
| `Apex.GetApexDataAndState` | Stored Procedure | Richer variant that JOINs `ApexData`, `State`, and `UserData` |

---

## 8. Usage Notes

- The `NOLOCK` hint prevents read locks, making this safe for high-frequency polling without blocking writers.
- `StatusID` references an external enumeration defined by the Apex Clearing integration; consult the Apex API specification for valid values.
- When no row is returned, the calling service should treat the user as "not yet enrolled" in Apex and initiate the onboarding flow.
- Prefer `Apex.GetApexDataAndState` when state machine context (ApexStateID, Comment) is also needed in the same call.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetApexData.sql` | Quality Score: 8.5/10*
