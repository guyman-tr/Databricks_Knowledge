# Apex.GetTradingUserData

**Schema:** Apex  
**Object Type:** Stored Procedure  
**Source File:** `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetTradingUserData.sql`  
**Documented:** 2026-04-14

---

## 1. Business Meaning

`Apex.GetTradingUserData` retrieves the Apex Clearing-specific trading profile for a single customer. The `TradingUserData` table holds the personal, geographic, and account-identifier fields submitted to Apex for brokerage account creation and maintenance. This includes the Apex-assigned account ID (`ApexID`), the FINRA FDID identifier, and the customer's name and address as formatted for Apex submission.

This procedure is called by account-opening services, reconciliation jobs, and compliance workflows that need the exact data payload sent to Apex (or that will be sent) — as distinct from the internal `UserData` record which may have additional internal fields.

---

## 2. Parameters

| Parameter | Type | Nullable | Description |
|-----------|------|----------|-------------|
| `@GCID` | `int` | No | Global Customer ID of the customer whose trading data is requested. |

---

## 3. Result Sets

**Result Set 1 – Apex Trading Profile**

| Column | Source Table | Description |
|--------|-------------|-------------|
| `CID` | `Apex.TradingUserData` | Internal Customer ID (CID) of the user. |
| `GCID` | `Apex.TradingUserData` | Global Customer ID (echoed). |
| `GivenName` | `Apex.TradingUserData` | Customer's given (first) name as formatted for Apex. |
| `FamilyName` | `Apex.TradingUserData` | Customer's family (last) name as formatted for Apex. |
| `LegalName` | `Apex.TradingUserData` | Customer's full legal name. |
| `Country` | `Apex.TradingUserData` | ISO 3-letter country code. |
| `State` | `Apex.TradingUserData` | 2-letter US state code (or equivalent). |
| `City` | `Apex.TradingUserData` | City name. |
| `PostalCode` | `Apex.TradingUserData` | Postal / ZIP code. |
| `StreetAddress1` | `Apex.TradingUserData` | Primary street address line. |
| `StreetAddress2` | `Apex.TradingUserData` | Secondary street address line. |
| `StreetAddress3` | `Apex.TradingUserData` | Tertiary street address line. |
| `ApexID` | `Apex.TradingUserData` | Apex-assigned brokerage account identifier. |
| `FDID` | `Apex.TradingUserData` | FINRA-assigned Large Trader ID (FDID), required for FINRA reporting. |

Returns 0 rows if no trading data record exists for the given GCID.

---

## 4. Tables Accessed

| Table | Schema | Access | Notes |
|-------|--------|--------|-------|
| `TradingUserData` | `Apex` | SELECT | No locking hints; simple point query by `GCID`. |

---

## 5. Logic Flow

1. Simple `SELECT` from `Apex.TradingUserData`.
2. Filters by `GCID = @GCID`.
3. Returns all 14 columns.

---

## 6. Error Handling

No explicit error handling. Empty result if no record exists.

---

## 7. Dependencies

| Object | Type | Relationship |
|--------|------|-------------|
| `Apex.TradingUserData` | Table | Only data source |
| `Apex.SaveTradingUserData` | Stored Procedure | Companion writer; upserts the record returned here |
| `Apex.GetTradingUsersDataList` | Stored Procedure | Bulk variant that accepts a TVP of GCIDs |

---

## 8. Usage Notes

- `FDID` is required by FINRA Large Trader rules; it may be NULL for customers who do not meet the large-trader threshold.
- Address fields (`StreetAddress1/2/3`, `City`, `State`, `PostalCode`, `Country`) represent the address as normalised for Apex submission and may differ slightly from the internal `Apex.UserData` address fields.
- Use `Apex.GetTradingUsersDataList` when bulk-fetching trading profiles for multiple customers to reduce round-trips.

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Source: `C:\Repos\ComplianceDBs\USABroker\Apex\Stored Procedures\Apex.GetTradingUserData.sql` | Quality Score: 8.5/10*
