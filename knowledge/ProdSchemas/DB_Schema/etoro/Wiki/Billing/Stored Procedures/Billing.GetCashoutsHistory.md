# Billing.GetCashoutsHistory

> Returns a paginated slice of legacy cashout records from Billing.Cashout for a specific customer within a date range, with total count returned via an OUTPUT parameter.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID, @DateFrom, @DateTo, @From, @To |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetCashoutsHistory` retrieves a paginated page of cashout (withdrawal) records from the legacy `Billing.Cashout` table for a given customer over a date range. It is a legacy procedure — `Billing.Cashout` contains 5,931 rows from 2007-2008 only; modern withdrawals are tracked in `Billing.Withdraw`. This procedure would have been used by the BackOffice or admin tools to browse a customer's old withdrawal history.

The procedure implements a two-result pattern common in classic pagination: it first returns a count of all matching records via the `@NumberOfPayments OUTPUT` parameter, then returns the requested page of results. The caller knows both the total count (for rendering pagination controls) and the page data in a single stored procedure call.

Pagination is zero-based: `Position IDENTITY(0,1)` starts at 0. To request the first 10 records, the caller passes `@From=0, @To=9`. To get the next 10, `@From=10, @To=19`.

---

## 2. Business Logic

### 2.1 Paginated Result Pattern with OUTPUT Count

**What**: Loads all matching records into a local table variable, sets the total count via OUTPUT, then returns the requested page.

**Columns/Parameters Involved**: `@From`, `@To`, `@NumberOfPayments`, `Position`

**Rules**:
- All matching Billing.Cashout rows for @CID within [@DateFrom, @DateTo] are loaded into @Results (inclusive BETWEEN)
- `Position` column uses `IDENTITY(0,1)` - zero-based sequential row number assigned in INSERT order (which inherits the underlying Billing.Cashout sort)
- `SELECT @NumberOfPayments = COUNT(*) FROM @Results` - total matching rows, returned to caller before paging
- `SELECT * FROM @Results WHERE Position BETWEEN @From AND @To` - page extraction
- No ORDER BY on the main INSERT means Position assignment order follows the storage order of Billing.Cashout (by CashoutID ascending implicitly)

### 2.2 Legacy Cashout Source

**What**: Reads exclusively from Billing.Cashout, the pre-2009 withdrawal table.

**Columns/Parameters Involved**: All columns from Billing.Cashout

**Rules**:
- Billing.Cashout is frozen at 5,931 rows with data from 2007-08-27 to 2008-10-26 — no new rows are inserted
- Modern withdrawals (post-2008) use Billing.Withdraw; this SP only surfaces historical legacy cashouts
- `Amount` is stored as INTEGER (not MONEY/DECIMAL) - in the legacy Cashout table, amounts were stored as integer cents or smallest currency units
- `ExchangeRate` is DECIMAL(16,8) but was NULL for all sampled rows (most legacy cashouts were USD-denominated)
- `IPAddress` is stored as NUMERIC (a packed integer representation of the IPv4 address)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | VERIFIED | Customer ID to retrieve cashout history for. Filters Billing.Cashout by CID. |
| 2 | @DateFrom | datetime | NO | - | VERIFIED | Start of the date range filter (inclusive). Compared against Billing.Cashout.RequestDate. |
| 3 | @DateTo | datetime | NO | - | VERIFIED | End of the date range filter (inclusive). Compared against Billing.Cashout.RequestDate using BETWEEN. |
| 4 | @From | int | NO | - | VERIFIED | Zero-based start position for pagination. First page starts at 0. Records with Position >= @From are included. |
| 5 | @To | int | NO | - | VERIFIED | Zero-based end position for pagination (inclusive). First page of 10 ends at 9. |
| 6 | @NumberOfPayments | int OUTPUT | NO | - | VERIFIED | OUTPUT parameter. Set to COUNT(*) of all matching records before paging. Caller uses this for total count / pagination controls. |

**Return Columns (from @Results table variable):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Position | int | NO | - | VERIFIED | Zero-based row sequence number (IDENTITY 0,1). Used internally for BETWEEN paging. Exposed in result set. |
| 2 | CashoutID | int | NO | - | VERIFIED | Unique identifier of the legacy cashout record. Max value is 6,029 (all data from 2007-2008). References Billing.Cashout.CashoutID. |
| 3 | FundingTypeID | int | NO | - | VERIFIED | Payment method used for the withdrawal. References Dictionary.FundingType. Legacy records show FundingTypeIDs 3 and 4 (early Forex payment methods). |
| 4 | CashoutStatusID | int | YES | - | VERIFIED | Status of the cashout at time of record. References Billing.CashoutStatus or similar lookup. Observed values: 1 (Pending?), 4 (Processed/Approved?). |
| 5 | CurrencyID | int | NO | - | VERIFIED | Currency of the cashout amount. References Dictionary.Currency. CurrencyID=1 = USD in all sampled rows. |
| 6 | CID | int | NO | - | VERIFIED | Customer ID - same as @CID filter. Included in the result set for client-side verification. |
| 7 | RequestDate | datetime | NO | - | VERIFIED | Date and time the customer requested the cashout. Used in the date range filter. |
| 8 | Amount | int | NO | - | VERIFIED | Cashout amount stored as integer (likely cents/smallest unit). Legacy storage format - sampled values: 6800, 20000, 4900. |
| 9 | ExchangeRate | decimal(16,8) | YES | - | VERIFIED | Currency exchange rate at time of cashout. NULL for most legacy records (most were USD-denominated). |
| 10 | IPAddress | numeric | YES | - | VERIFIED | Customer's IP address stored as packed integer (IPv4 numeric representation). |
| 11 | Attention | bit | YES | - | VERIFIED | Flag indicating the cashout requires manual attention or review. |
| 12 | Remark | varchar(500) | YES | - | VERIFIED | Free-text notes or remarks on the cashout record. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID, date range filter | Billing.Cashout | Read | Source of all cashout records. Legacy table; frozen at 2007-2008 data. |
| FundingTypeID | Dictionary.FundingType | Lookup (implicit) | Payment method used for the legacy cashout. |
| CurrencyID | Dictionary.Currency | Lookup (implicit) | Currency denomination of the cashout amount. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BILLING_MANAGER (role) | EXECUTE permission | Permission | Billing manager access to legacy cashout history. |
| PROD\BIadmins (role) | VIEW DEFINITION permission | Permission | BI admin access for schema inspection only (not execute). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCashoutsHistory (procedure)
└── Billing.Cashout (table) - legacy, 5,931 rows, 2007-2008
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Cashout | Table | SELECT CashoutID, FundingTypeID, CashoutStatusID, CurrencyID, CID, RequestDate, Amount, ExchangeRate, IPAddress, Attention, Remark WHERE CID=@CID AND RequestDate BETWEEN @DateFrom AND @DateTo. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BILLING_MANAGER (role) | Permission | Legacy cashout history browsing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get first page of cashout history for a customer
```sql
DECLARE @Total INT
EXEC Billing.GetCashoutsHistory
  @CID = 12345,
  @DateFrom = '2007-01-01',
  @DateTo = '2008-12-31',
  @From = 0,
  @To = 9,
  @NumberOfPayments = @Total OUTPUT
SELECT @Total AS TotalMatchingRecords
-- Returns: first 10 records (0-9) and total count in @Total
```

### 8.2 Direct query replicating the SP logic
```sql
SELECT CashoutID, FundingTypeID, CashoutStatusID, CurrencyID,
       CID, RequestDate, Amount, ExchangeRate, IPAddress, Attention, Remark
FROM Billing.Cashout WITH (NOLOCK)
WHERE CID = 12345
  AND RequestDate BETWEEN '2007-01-01' AND '2008-12-31'
ORDER BY CashoutID
```

### 8.3 Count all legacy cashouts in the table
```sql
SELECT COUNT(*) AS TotalRows,
       MIN(RequestDate) AS FirstCashout,
       MAX(RequestDate) AS LastCashout
FROM Billing.Cashout WITH (NOLOCK)
-- Returns: 5931 rows, 2007-08-27 to 2008-10-26
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetCashoutsHistory | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCashoutsHistory.sql*
