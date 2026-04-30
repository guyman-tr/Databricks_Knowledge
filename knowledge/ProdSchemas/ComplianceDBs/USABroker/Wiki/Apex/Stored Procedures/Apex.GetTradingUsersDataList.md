# Apex.GetTradingUsersDataList

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetTradingUsersDataList.sql`  
**Ticket:** COAKV-3067 (Oleksandr Pavlov, 2021-08-04)  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetTradingUsersDataList` is the bulk variant of `Apex.GetTradingUserData`. It accepts a table-valued parameter (TVP) containing a set of GCIDs and returns the Apex Clearing trading profiles for all of them in a single database call. This is used by batch-processing pipelines, reconciliation services, and export jobs that need to fetch trading data for many customers at once without issuing one round-trip per customer.

The use of a typed TVP (`Apex.GCIDs`) provides efficient set-based processing and avoids the performance and maintainability issues of dynamic SQL or comma-delimited string parameters.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@gcids` | `Apex.GCIDs` (TVP) | No | Table-valued parameter containing the set of GCIDs to retrieve. Must be passed as `READONLY`. |

---

## 3. Result Sets

**Result Set 1 – Trading Profiles for Requested GCIDs**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `CID` | `Apex.TradingUserData` | Internal Customer ID. |
| `GCID` | `Apex.TradingUserData` | Global Customer ID (identifies which input GCID this row satisfies). |
| `GivenName` | `Apex.TradingUserData` | Customer's given name. |
| `FamilyName` | `Apex.TradingUserData` | Customer's family name. |
| `LegalName` | `Apex.TradingUserData` | Customer's full legal name. |
| `Country` | `Apex.TradingUserData` | ISO 3-letter country code. |
| `State` | `Apex.TradingUserData` | 2-letter US state code. |
| `City` | `Apex.TradingUserData` | City name. |
| `PostalCode` | `Apex.TradingUserData` | Postal / ZIP code. |
| `StreetAddress1` | `Apex.TradingUserData` | Primary street address. |
| `StreetAddress2` | `Apex.TradingUserData` | Secondary street address. |
| `StreetAddress3` | `Apex.TradingUserData` | Tertiary street address. |
| `ApexID` | `Apex.TradingUserData` | Apex-assigned brokerage account ID. |
| `FDID` | `Apex.TradingUserData` | FINRA Large Trader ID. |

GCIDs in the TVP with no matching `TradingUserData` row are silently omitted from the result set.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `TradingUserData` | `Apex` | SELECT | No locking hints; set-based filter via `IN (SELECT GCID FROM @gcids)`. |

---

## 5. Logic Flow

1. Simple `SELECT` from `Apex.TradingUserData`.
2. Filters with `WHERE GCID IN (SELECT GCID FROM @gcids)` to return only the requested customers.
3. Returns all 14 columns for each matching row.

Set-based single-pass query; no loops, cursors, or aggregates.

---

## 6. Error Handling

No explicit error handling. The TVP is declared `READONLY`, so SQL Server enforces that the caller cannot modify it. An empty TVP input yields an empty result set.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.TradingUserData` | Table | Only data source |
| `Apex.GCIDs` | User-Defined Table Type | TVP type accepted by this procedure |
| `Apex.GetTradingUserData` | Stored Procedure | Single-GCID variant |
| `Apex.SaveTradingUserData` | Stored Procedure | Companion writer |

---

## 8. Usage Notes

- The `Apex.GCIDs` TVP type must be defined in the database before this procedure can be called; it is a single-column table type with a `GCID int` column.
- Callers in .NET should use `SqlParameter` with `SqlDbType.Structured` and set `TypeName = "Apex.GCIDs"` to pass the TVP.
- The column set is identical to `Apex.GetTradingUserData`; the same data reader / DTO can be reused.
- For very large input sets (thousands of GCIDs), consider batching the TVP to avoid excessive memory allocation on the SQL Server side.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetTradingUsersDataList.sql` | Quality Score: 8.5/10*
