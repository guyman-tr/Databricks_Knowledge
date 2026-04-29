# BI_DB_dbo.BI_DB_ProfessionalCustomers

> 85,899-row monthly snapshot of MiFID II Professional/Elective Professional customer approvals from June 2020 to present, tracking 4,070 distinct customers with their account manager, approval date ranges, and trading activity status -- sourced from Fact_SnapshotCustomer MifidCategorizationID transitions and External_BI_OUTPUT_Customer_ProfessionalCustomers application data via SP_ProfessionalCustomers.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: External_BI_OUTPUT_Customer_ProfessionalCustomers (lake parquet), DWH_dbo.Fact_SnapshotCustomer (MiFID categorization), DWH_dbo.Dim_Manager, DWH_dbo.Dim_Position via SP_ProfessionalCustomers |
| **Refresh** | Monthly (DELETE+INSERT by StartOfMonth DateID) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_ProfessionalCustomers` is a monthly point-in-time report tracking every eToro customer who has been approved as a MiFID II Professional or Elective Professional client (MifidCategorizationID IN 2=Professional, 3=Elective Professional). The table captures the lifecycle of professional status: when a customer was approved, whether they are still actively trading, and who their account manager is.

The ETL runs monthly via `SP_ProfessionalCustomers` (Tom Boksenbojm, 2020-08-12; migrated to Synapse 2023-06-17). For each month, it:
1. Identifies all customers who have ever had MifidCategorizationID IN (2,3) in Fact_SnapshotCustomer
2. Computes state transitions using LAG/LEAD window functions: 'Approved' when a customer first enters Professional status, 'Cancelled' when they leave
3. Filters to only **Approved** rows (WHERE ActionType = 'Approved')
4. Checks trading activity in the last 2 months via Dim_Position to flag IsActive

Each row represents one customer's approved professional status as of a specific month (DateID = start of month). The same customer can appear in multiple months. 85,899 rows spanning 70 monthly snapshots (June 2020 - April 2026), 4,070 distinct customers.

**Note**: The `Desk` column is defined in the DDL but NOT populated by the current SP (the INSERT is commented out). Historical data exists for ~82% of rows but is stale and should not be relied upon.

---

## 2. Business Logic

### 2.1 MiFID II Professional Status Transitions

**What**: The SP uses LAG/LEAD window functions over Fact_SnapshotCustomer's MifidCategorizationID to detect when a customer enters or exits Professional status.

**Columns Involved**: `ActionType`, `FromDate`, `ToDate`, `RealCID`

**Rules**:
- 'Approved': When current MifidCategorizationID IN (2,3) AND previous was NOT IN (2,3) -- customer newly became Professional
- 'Cancelled': When current MifidCategorizationID NOT IN (2,3) AND previous was IN (2,3) -- customer lost Professional status
- Only 'Approved' rows are inserted (WHERE filter in final INSERT)
- FromDate = the date the Approved transition occurred
- ToDate = LEAD(FullDate) over the RealCID partition, defaulting to 9999-12-31 (open-ended = still Professional)

### 2.2 Trading Activity Flag (IsActive)

**What**: Determines if the professional customer has traded recently.

**Columns Involved**: `IsActive`

**Rules**:
- IsActive = 1 if the customer has at least one non-partial-close position opened in the last 2 full months (from @StartActiveDate to @Date)
- IsActive = 0 otherwise
- Source: DWH_dbo.Dim_Position filtered by OpenDateID range and IsPartialCloseChild = 0
- As of latest data: 32.5% active, 67.5% inactive

### 2.3 Desk Column Deprecation

**What**: The Desk column was originally planned to source from ThirdParty_Fivetran.Fivetran.gsheets.customer_managers but was commented out.

**Rules**:
- Column remains in DDL as nvarchar(256) NULL
- Current SP does not populate it (INSERT column list has `--,[Desk]`)
- Historical data present for rows before the change (14 distinct desk values: German, French, Italian, UK, ROW, Spanish, Eastern Europe, Arabic, Australia, IB, Russia, Chinese, Netherlands)
- 15,257 rows have blank/NULL Desk (18%)
- Do NOT use Desk for current analysis

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN** distribution -- no colocation benefit; suitable for full-table scans
- **Clustered Index on DateID** -- always filter by DateID for efficient range scans
- Each monthly snapshot is identified by DateID = YYYYMMDD of the first day of month (e.g., 20260401)

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current professional customers | `WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_ProfessionalCustomers)` |
| Active professional customers | Add `AND IsActive = 1` |
| Professional customer growth over time | `GROUP BY DateID` with `COUNT(DISTINCT RealCID)` |
| When a customer became Professional | Filter by RealCID, check `FromDate` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID = RealCID | Customer demographics, country, regulation |
| BI_DB_dbo.BI_DB_ProfessionalCustomersPending | RealCID = RealCID AND DateID = DateID | Cross-reference approved vs. pending applications |
| BI_DB_dbo.BI_DB_ProfessionalCustomersDocuments | RealCID = CID | Document submissions for professional applications |

### 3.4 Gotchas

- **Desk is stale**: Column exists but is NOT populated by the current SP. Do not use for analysis.
- **ActionType is always 'Approved'**: The SP computes both 'Approved' and 'Cancelled' but only inserts 'Approved' rows. You cannot track cancellations from this table alone.
- **Monthly granularity only**: One snapshot per month (start of month). Daily changes are not captured.
- **ToDate = 9999-12-31**: Means the customer is still Professional as of that snapshot. It does NOT mean they are currently Professional.
- **Blank Desk values**: 15,257 rows have empty string Desk (not NULL). Use `WHERE Desk <> ''` if filtering on Desk.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki (production source documentation) |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data patterns |
| Tier 4 | Best available knowledge, limited confidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Start-of-month date for this snapshot. Computed as DATEADD(MONTH,DATEDIFF(MONTH,0,@Date),0). One snapshot per month from June 2020. (Tier 2 — SP_ProfessionalCustomers) |
| 2 | DateID | int | YES | Integer representation of Date in YYYYMMDD format (e.g., 20260401). Clustered index key. Used for monthly DELETE+INSERT partitioning. (Tier 2 — SP_ProfessionalCustomers) |
| 3 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 4 | AM | varchar(101) | NO | Account manager full name (FirstName + ' ' + LastName from Dim_Manager via Fact_SnapshotCustomer.AccountManagerID). Assigned manager at the time of the snapshot. (Tier 2 — SP_ProfessionalCustomers) |
| 5 | Desk | nvarchar(256) | YES | Sales/support desk assignment. NOT POPULATED by current SP (INSERT commented out). Historical data present for ~82% of rows with 14 distinct desks (German, French, Italian, UK, ROW, Spanish, Eastern Europe, Arabic, Australia, IB, Russia, Chinese, Netherlands). Stale -- do not use. (Tier 2 — SP_ProfessionalCustomers, deprecated) |
| 6 | ActionType | varchar(9) | YES | Professional status transition type. Only 'Approved' in data (Cancelled rows filtered out by WHERE clause). Derived from MifidCategorizationID transitions using LAG window function. (Tier 2 — SP_ProfessionalCustomers) |
| 7 | IsActive | int | NO | Trading activity flag: 1 = customer opened at least one non-partial-close position in the last 2 months, 0 = no recent trading. 32.5% active, 67.5% inactive. (Tier 2 — SP_ProfessionalCustomers) |
| 8 | FromDate | date | NO | Date when the customer's MiFID categorization first entered Professional (2) or Elective Professional (3) status. Derived from Fact_SnapshotCustomer date range via Dim_Date/Dim_Range. (Tier 2 — SP_ProfessionalCustomers) |
| 9 | ToDate | date | NO | Date when the customer's next status change occurred, or 9999-12-31 if still Professional. Computed via LEAD(FullDate) OVER (PARTITION BY RealCID ORDER BY FullDate). (Tier 2 — SP_ProfessionalCustomers) |
| 10 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by the ETL pipeline (GETDATE()). (Tier 2 — SP_ProfessionalCustomers) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Date | ETL | @StartOfMonth | DATEADD computation |
| DateID | ETL | @StartOfMonthINT | CAST(CONVERT(CHAR(8),date,112) AS INT) |
| RealCID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough (via #Approved filter on MifidCategorizationID) |
| AM | DWH_dbo.Dim_Manager | FirstName, LastName | Concatenation: FirstName + ' ' + LastName |
| Desk | _Not populated_ | — | Commented out in current SP |
| ActionType | DWH_dbo.Fact_SnapshotCustomer | MifidCategorizationID | CASE transition logic via LAG window |
| IsActive | DWH_dbo.Dim_Position | CID | CASE WHEN EXISTS open position in last 2 months |
| FromDate | DWH_dbo.Dim_Date | FullDate | Derived from MifidCategorization transition date |
| ToDate | ETL | — | LEAD window function, default 9999-12-31 |
| UpdateDate | ETL | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
External_BI_OUTPUT_Customer_ProfessionalCustomers (lake parquet: BI_OUTPUT/Customer/ProfessionalCustomers)
  |-- GCID-based application data (ApplicationDate, SelectedCriteria)
  v
DWH_dbo.Dim_Customer (GCID → RealCID resolution)
  v
DWH_dbo.Fact_SnapshotCustomer (MifidCategorizationID history, SCD Type 2)
  |-- LAG/LEAD window functions for state transitions
  |-- JOIN Dim_Range → Dim_Date for date resolution
  |-- JOIN Dim_Manager for AM name
  |-- LEFT JOIN Dim_Position for IsActive check (last 2 months)
  v
SP_ProfessionalCustomers @Date (monthly, Tom Boksenbojm 2020)
  |-- DELETE WHERE DateID = @StartOfMonthINT
  |-- INSERT approved professional customers
  v
BI_DB_dbo.BI_DB_ProfessionalCustomers (85,899 rows, ROUND_ROBIN)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension via RealCID |
| AM | DWH_dbo.Dim_Manager | Account manager name (derived from FirstName + LastName) |

### 6.2 Referenced By (other objects point to this)

No known consumers in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Current Active Professional Customers

```sql
SELECT RealCID, AM, FromDate, IsActive
FROM BI_DB_dbo.BI_DB_ProfessionalCustomers
WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_dbo.BI_DB_ProfessionalCustomers)
  AND IsActive = 1
ORDER BY FromDate
```

### 7.2 Professional Customer Growth by Month

```sql
SELECT DateID, COUNT(DISTINCT RealCID) AS total_professional,
       SUM(IsActive) AS active_count
FROM BI_DB_dbo.BI_DB_ProfessionalCustomers
GROUP BY DateID
ORDER BY DateID
```

### 7.3 Longest-Standing Professional Customers

```sql
SELECT TOP 20 RealCID, AM, FromDate, 
       DATEDIFF(DAY, FromDate, GETDATE()) AS days_professional
FROM BI_DB_dbo.BI_DB_ProfessionalCustomers
WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_dbo.BI_DB_ProfessionalCustomers)
  AND ToDate = '9999-12-31'
ORDER BY FromDate ASC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 1 T1, 8 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_ProfessionalCustomers | Type: Table | Production Source: Multi-source via SP_ProfessionalCustomers*
