# dbo.GetUnpaidCommissions

> Accepts a table of affiliate IDs and a date range, then returns unpaid commission counts and amounts across eight commission types (first positions, sales, bonuses, chargebacks, CPA, leads, registrations, copy traders, eCost) using a UNION ALL with ORDER BY and OPTION(RECOMPILE).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Noga Rozen (updated 2022-07-22, removed Clicks) |
| **Created** | Unknown |

---

## 1. Business Meaning

Before a payment run is processed, the affiliate management system needs a comprehensive view of outstanding unpaid commissions for a set of affiliates across a date range. This procedure provides that view, returning one row per affiliate-tier-commission-type combination showing the count of qualifying events and the total unpaid commission amount.

The result set is used to populate pre-payment summary screens, validate payment amounts, and support finance reconciliation. By accepting a table-valued parameter of affiliate IDs, the procedure supports both individual affiliate balance reviews and bulk pre-payment scans across large cohorts.

The Clicks commission type was removed in July 2022 (the UNION ALL branch is commented out in the source code). eCost was added as an additional union branch.

---

## 2. Business Logic

### 2.1 Date Range with Precision Adjustment

**What**: Applies default values and a precision correction for the @dateTo boundary.

**Columns/Parameters Involved**: `@dateFrom`, `@dateTo`

**Rules**:
- @dateFrom defaults to '1999-01-01' if NULL
- @dateTo defaults to GETDATE() if NULL
- When @dateTo is provided, 2 milliseconds are subtracted: DATEADD(ms, -2, @dateTo). This compensates for precision loss between CLR DateTime and SQL DateTime when converting from application layer to SQL Server

### 2.2 Temporary Table with Index

**What**: Copies the input affiliate IDs to a temp table and creates an index for join performance.

**Columns/Parameters Involved**: `#AffiliateIDs`

**Rules**:
- SELECT ID INTO #AffiliateIDs FROM @AffiliateIDs copies the TVP to a temp table
- CREATE INDEX #idx ON #AffiliateIDs (ID) improves JOIN performance for the eight UNION ALL branches

### 2.3 First Positions (Commission Type: "First Positions")

**What**: Counts and sums unpaid first-position commissions within the date range.

**Rules**:
- fp.AffiliateFirstPositionAccepted != 0 and fp.Valid != 0 required
- comm.Paid = 0; date range applied on fp.ORDER_DATE

### 2.4 Sales (Commission Type: "Sales" -- includes sales, bonuses, and chargebacks)

**What**: Three separate branches unified under the "Sales" commission type label.

**Rules**:
- Sales: AffiliateSaleAccepted != 0, Valid != 0, Paid = 0, ISNULL(Optional1,'0') = '0' (excludes adjustment-type sales)
- Bonuses: AffiliateBonusAccepted != 0, Valid != 0, Paid = 0
- Chargebacks: AffiliateChargebackAccepted != 0, Valid != 0, Paid = 0
- All three use ORDER_DATE for date filtering and are labelled 'Sales' in the Commission Type column

### 2.5 CPA (Commission Type: "CPA")

**What**: Counts and sums unpaid CPA deposit commissions.

**Rules**:
- cpa.AffiliateDepositAccepted != 0, cpa.Valid != 0, comm.Paid = 0
- Date filter on cpa.ORDER_DATE

### 2.6 Leads (Commission Type: "Leads")

**What**: Counts and sums unpaid lead commissions.

**Rules**:
- lead.AffiliateSaleAccepted != 0, lead.Valid != 0, comm.Paid = 0
- Date filter on lead.ORDER_DATE

### 2.7 Registrations (Commission Type: "Registrations")

**What**: Counts and sums unpaid registration commissions.

**Rules**:
- No Accepted/Valid filter specified in this branch; Paid = 0 is the only data quality filter
- Date filter on reg.ORDER_DATE

### 2.8 Copy Traders (Commission Type: "CopysTraders")

**What**: Counts and sums unpaid copy trader commissions.

**Rules**:
- comm.Paid = 0; date filter on ct.ORDER_DATE
- Note: the Commission Type label in the source code is 'CopysTraders' (typo -- extra "s")

### 2.9 eCost (Commission Type: "eCost")

**What**: Counts and sums unpaid eCost commissions.

**Rules**:
- comm.Paid = 0; date filter on ec.ORDER_DATE

### 2.10 Removed: Clicks

The Clicks branch (joining tblaff_Clicks_Commissions to tblaff_Clicks on ClickDateTime) was removed in July 2022 per Noga Rozen's update. The commented-out code is retained in the source for historical reference.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @AffiliateIDs | IN | dbo.IDTableType (READONLY) | (required) | Table-valued parameter containing the list of affiliate IDs for which to retrieve unpaid commissions. |
| 2 | @dateFrom | IN | datetime | NULL | Start of the date range. Defaults to '1999-01-01' when NULL. |
| 3 | @dateTo | IN | datetime | NULL | End of the date range. Defaults to GETDATE() when NULL. When provided, 2ms is subtracted to handle CLR-to-SQL precision loss. |

---

## 5. Relationships

### 5.1 Tables Written

| Table | Operation | Notes |
|-------|-----------|-------|
| #AffiliateIDs (temp table) | CREATE / INSERT / DROP (implicit) | Copy of the TVP input with an index for join performance |

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_FirstPositions | SELECT (JOIN) | First position events |
| dbo.tblaff_FirstPositions_Commissions | SELECT (JOIN) | First position commission amounts |
| dbo.tblaff_Sales | SELECT (JOIN) | Sales events |
| dbo.tblaff_Sales_Commissions | SELECT (JOIN) | Sales commission amounts |
| dbo.tblaff_Bonuses | SELECT (JOIN) | Bonus events |
| dbo.tblaff_Bonuses_Commissions | SELECT (JOIN) | Bonus commission amounts |
| dbo.tblaff_Chargebacks | SELECT (JOIN) | Chargeback events |
| dbo.tblaff_Chargebacks_Commissions | SELECT (JOIN) | Chargeback commission amounts |
| dbo.tblaff_CPA | SELECT (JOIN) | CPA deposit events |
| dbo.tblaff_CPA_Commissions | SELECT (JOIN) | CPA commission amounts |
| dbo.tblaff_Leads | SELECT (JOIN) | Lead events |
| dbo.tblaff_Leads_Commissions | SELECT (JOIN) | Lead commission amounts |
| dbo.tblaff_Registrations | SELECT (JOIN) | Registration events |
| dbo.tblaff_Registrations_Commissions | SELECT (JOIN) | Registration commission amounts |
| dbo.tblaff_CopyTraders | SELECT (JOIN) | Copy trader events |
| dbo.tblaff_CopyTraders_Commissions | SELECT (JOIN) | Copy trader commission amounts |
| dbo.tblaff_eCost | SELECT (JOIN) | eCost events |
| dbo.tblaff_eCost_Commissions | SELECT (JOIN) | eCost commission amounts |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| AffiliateID | Commission table | The affiliate receiving the commission |
| Tier | Commission table | Commission tier (1-5) |
| InstanceCount | COUNT() | Number of qualifying events for this affiliate/tier/type combination |
| Commission | SUM() | Total unpaid commission amount for this combination |
| Commission Type | Literal string | One of: 'First Positions', 'Sales', 'CPA', 'Leads', 'Registrations', 'CopysTraders', 'eCost' |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetUnpaidCommissions (stored procedure)
+-- dbo.IDTableType (user-defined table type) [TVP input]
+-- dbo.tblaff_FirstPositions / tblaff_FirstPositions_Commissions (tables)
+-- dbo.tblaff_Sales / tblaff_Sales_Commissions (tables)
+-- dbo.tblaff_Bonuses / tblaff_Bonuses_Commissions (tables)
+-- dbo.tblaff_Chargebacks / tblaff_Chargebacks_Commissions (tables)
+-- dbo.tblaff_CPA / tblaff_CPA_Commissions (tables)
+-- dbo.tblaff_Leads / tblaff_Leads_Commissions (tables)
+-- dbo.tblaff_Registrations / tblaff_Registrations_Commissions (tables)
+-- dbo.tblaff_CopyTraders / tblaff_CopyTraders_Commissions (tables)
+-- dbo.tblaff_eCost / tblaff_eCost_Commissions (tables)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.IDTableType | User-Defined Table Type | Defines the TVP input shape |
| dbo.tblaff_FirstPositions + _Commissions | Tables | First position commission data |
| dbo.tblaff_Sales + _Commissions | Tables | Sales commission data |
| dbo.tblaff_Bonuses + _Commissions | Tables | Bonus commission data |
| dbo.tblaff_Chargebacks + _Commissions | Tables | Chargeback commission data |
| dbo.tblaff_CPA + _Commissions | Tables | CPA commission data |
| dbo.tblaff_Leads + _Commissions | Tables | Lead commission data |
| dbo.tblaff_Registrations + _Commissions | Tables | Registration commission data |
| dbo.tblaff_CopyTraders + _Commissions | Tables | Copy trader commission data |
| dbo.tblaff_eCost + _Commissions | Tables | eCost commission data |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Pre-payment summary service | Application | Calls this procedure to retrieve outstanding unpaid commissions before processing a payment run |
| Finance reconciliation tool | Application | Uses this procedure to validate expected payment amounts per affiliate and commission type |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- No SET NOCOUNT ON; callers receive rowcount messages
- WITH (NOLOCK) applied to all joined tables
- OPTION (RECOMPILE) at the end of the query forces a fresh execution plan for each call, preventing plan reuse issues caused by parameter sniffing across the wide variety of affiliate cohort sizes
- ORDER BY AffiliateID ASC, Tier ASC, 'Commission Type' ASC (note: ordering on the literal string column alias is used for convenience)
- Clicks were removed in July 2022; the commented-out UNION ALL branch is retained as documentation
- The "CopysTraders" Commission Type label contains a typo (extra "s"); existing consumers should match this exact string
- The 2ms precision adjustment on @dateTo: DATEADD(ms, -2, @dateTo) compensates for CLR DateTime (.NET) to SQL DateTime truncation/rounding differences

---

## 8. Sample Queries

### 8.1 Get all unpaid commissions for a set of affiliates (all time)

```sql
DECLARE @AffIDs dbo.IDTableType;
INSERT INTO @AffIDs VALUES (1001), (1002), (1003);
EXEC dbo.GetUnpaidCommissions @AffiliateIDs = @AffIDs;
```

### 8.2 Get unpaid commissions for a specific date range

```sql
DECLARE @AffIDs dbo.IDTableType;
INSERT INTO @AffIDs VALUES (1001);
EXEC dbo.GetUnpaidCommissions
    @AffiliateIDs = @AffIDs,
    @dateFrom     = '2025-01-01',
    @dateTo       = '2025-03-31';
```

### 8.3 Verify unpaid CPA commissions for one affiliate

```sql
SELECT comm.AffiliateID, comm.Tier, COUNT(*) AS Events, SUM(comm.Commission) AS Total
FROM dbo.tblaff_CPA_Commissions comm WITH (NOLOCK)
JOIN dbo.tblaff_CPA cpa WITH (NOLOCK) ON comm.DepositID = cpa.DepositID
WHERE comm.AffiliateID = 1001
  AND comm.Paid = 0
  AND cpa.AffiliateDepositAccepted <> 0
  AND cpa.Valid <> 0
  AND cpa.ORDER_DATE BETWEEN '2025-01-01' AND '2025-03-31'
GROUP BY comm.AffiliateID, comm.Tier;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Code comment: "Noga Rozen, 22/7/2022 Remove Clicks" documents the removal of the Clicks commission type from the UNION ALL.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10*
*Object: dbo.GetUnpaidCommissions | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetUnpaidCommissions.sql*
