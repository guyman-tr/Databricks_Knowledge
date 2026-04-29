# BI_DB_dbo.BI_DB_ProfessionalCustomersPending

> 200,154-row monthly snapshot of pending MiFID II professional customer applications from June 2020 to present, tracking 34,030 distinct customers who applied for professional status within the last 6 months but have not yet been approved (MifidCategorizationID IN 4=Retail Pending, 5=Pending) -- enriched with club tier, country, account manager, and days since application via SP_ProfessionalCustomers.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | External_BI_OUTPUT_Customer_ProfessionalCustomers (lake parquet) + DWH_dbo.Fact_SnapshotCustomer + Dim_Country + Dim_PlayerLevel + Dim_Manager via SP_ProfessionalCustomers |
| **Refresh** | Monthly (DELETE+INSERT by StartOfMonth DateID) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_ProfessionalCustomersPending` tracks customers who have applied for MiFID II Professional status but have not yet been approved. Each row represents a pending applicant as of a monthly snapshot, showing how long their application has been waiting and their current customer attributes.

The ETL runs monthly in the same SP as `BI_DB_ProfessionalCustomers` (`SP_ProfessionalCustomers`, Tom Boksenbojm, 2020-08-12). For each month:
1. Loads recent applications from `External_BI_OUTPUT_Customer_ProfessionalCustomers` (last 6 months, SelectedCriteria > 1)
2. Computes `DaysSinceApplication` as DATEDIFF from ApplicationDate to @Date
3. JOINs to `Fact_SnapshotCustomer` for current-state filtering: only customers with MifidCategorizationID IN (4=Retail Pending, 5=Pending) and IsValidCustomer=1
4. Resolves ClubTier (Dim_PlayerLevel), Country (Dim_Country), AM (Dim_Manager)

200,154 rows across 70 monthly snapshots. 34,030 distinct customers. DaysSinceApplication ranges from 0 to 214 (max ~7 months due to 6-month lookback + month boundary), average 106 days. ClubTier distribution: Bronze 71%, Silver 14%, Gold 10%, Platinum 3%, Platinum Plus 2%, Diamond <1%.

The companion table `BI_DB_ProfessionalCustomers` tracks customers who were eventually approved.

---

## 2. Business Logic

### 2.1 Application Lookback Window (6 Months)

**What**: Only applications from the last 6 months are considered pending.

**Columns Involved**: `DaysSinceApplication`, `Date`

**Rules**:
- @Date6Month = DATEADD(MONTH,DATEDIFF(MONTH,0,@Date)-6,0) -- 6 months before @Date
- Applications where ApplicationDate >= @Date6Month AND <= @Date AND SelectedCriteria > 1
- SelectedCriteria > 1 filters out customers who selected only 1 criterion (incomplete application)
- After 6 months, an unapproved application is no longer considered "pending" and drops out

### 2.2 MiFID Pending Status Filter

**What**: Only customers currently in a pending MiFID state are included.

**Columns Involved**: `RealCID`, `ClubTier`, `Country`, `AM`

**Rules**:
- MifidCategorizationID IN (4, 5) from Fact_SnapshotCustomer:
  - 4 = Retail Pending -- customer applied but review is in progress
  - 5 = Pending -- general pending state
- IsValidCustomer = 1 -- excludes demo accounts, blocked countries, excluded labels
- Current-state row filter via DateRangeID: FromDateID <= @DateID AND ToDateID >= @DateID

### 2.3 Desk Column Deprecation

**What**: Same as BI_DB_ProfessionalCustomers -- the Desk column is defined in DDL but not populated by current SP.

**Rules**:
- INSERT column list has `--,[Desk]` (commented out)
- Sample data shows Desk values from historical loads (14 distinct desks matching Dim_Country.Desk)
- Do NOT use for current analysis

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN** distribution -- no colocation benefit; suitable for full-table scans
- **Clustered Index on DateID** -- always filter by DateID for efficient monthly range scans

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current pending applications | `WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_ProfessionalCustomersPending)` |
| Oldest pending applications | `ORDER BY DaysSinceApplication DESC` |
| Pending by country/tier | `GROUP BY Country, ClubTier` |
| Pending-to-approval conversion | JOIN to BI_DB_ProfessionalCustomers on RealCID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | RealCID = RealCID | Full customer demographics |
| BI_DB_dbo.BI_DB_ProfessionalCustomers | RealCID = RealCID | Track if pending applicant was eventually approved |
| BI_DB_dbo.BI_DB_ProfessionalCustomersDocuments | RealCID = CID | Document submissions for pending applications |

### 3.4 Gotchas

- **Desk is stale**: Same issue as BI_DB_ProfessionalCustomers -- column not populated by current SP.
- **6-month lookback**: Applications older than 6 months are excluded. A customer pending for 7+ months will disappear from the table.
- **Monthly snapshots only**: The same customer appears in multiple months if their application is still pending.
- **DaysSinceApplication max ~214**: Due to 6-month lookback + month boundary timing, theoretical max is ~214 days (7 months due to start-of-month alignment).

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
| 4 | ClubTier | varchar(50) | NO | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Passthrough from Dim_PlayerLevel.Name via Fact_SnapshotCustomer.PlayerLevelID. (Tier 1 — Dictionary.PlayerLevel) |
| 5 | Desk | nvarchar(256) | YES | Sales/support desk assignment. NOT POPULATED by current SP (INSERT commented out). Historical data present with 14 distinct desks matching Dim_Country.Desk values. Stale -- do not use. (Tier 2 — SP_ProfessionalCustomers, deprecated) |
| 6 | AM | nvarchar(256) | YES | Account manager full name (FirstName + ' ' + LastName from Dim_Manager via Fact_SnapshotCustomer.AccountManagerID). Derived concatenation. (Tier 2 — SP_ProfessionalCustomers) |
| 7 | Country | varchar(50) | NO | Country name for the customer. Passthrough from Dim_Country.Name via Fact_SnapshotCustomer.CountryID. (Tier 1 — Dictionary.Country) |
| 8 | DaysSinceApplication | int | YES | Number of days between the professional application submission (External_BI_OUTPUT_Customer_ProfessionalCustomers.ApplicationDate) and the snapshot @Date. DATEDIFF(DAY, ApplicationDate, @Date). Range 0-214, average 106. (Tier 2 — SP_ProfessionalCustomers) |
| 9 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by the ETL pipeline (GETDATE()). (Tier 2 — SP_ProfessionalCustomers) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Date | ETL | @StartOfMonth | DATEADD computation |
| DateID | ETL | @StartOfMonthINT | CAST(CONVERT) |
| RealCID | DWH_dbo.Fact_SnapshotCustomer | RealCID | Passthrough (MifidCategorizationID IN (4,5)) |
| ClubTier | DWH_dbo.Dim_PlayerLevel | Name | Dim lookup passthrough |
| Desk | _Not populated_ | — | Commented out in current SP |
| AM | DWH_dbo.Dim_Manager | FirstName, LastName | Concatenation |
| Country | DWH_dbo.Dim_Country | Name | Dim lookup passthrough |
| DaysSinceApplication | ETL + External | ApplicationDate | DATEDIFF(DAY, ApplicationDate, @Date) |
| UpdateDate | ETL | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
External_BI_OUTPUT_Customer_ProfessionalCustomers (lake parquet: BI_OUTPUT/Customer/ProfessionalCustomers)
  |-- Filter: ApplicationDate within last 6 months, SelectedCriteria > 1
  |-- DATEDIFF for DaysSinceApplication
  v
DWH_dbo.Fact_SnapshotCustomer (MifidCategorizationID IN (4,5), IsValidCustomer=1, current DateRangeID)
  |-- JOIN Dim_Range → current-state filter
  |-- JOIN Dim_Country → Country name
  |-- JOIN Dim_PlayerLevel → ClubTier
  |-- JOIN Dim_Manager → AM (FirstName + LastName)
  v
SP_ProfessionalCustomers @Date (monthly, Tom Boksenbojm 2020, second INSERT block)
  |-- DELETE WHERE DateID = @StartOfMonthINT
  |-- INSERT pending professional applications
  v
BI_DB_dbo.BI_DB_ProfessionalCustomersPending (200,154 rows, ROUND_ROBIN)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension via RealCID |
| ClubTier | DWH_dbo.Dim_PlayerLevel | Club tier lookup (Name) |
| Country | DWH_dbo.Dim_Country | Country lookup (Name) |
| AM | DWH_dbo.Dim_Manager | Account manager (FirstName + LastName) |

### 6.2 Referenced By (other objects point to this)

No known consumers in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Current Pending Applications by Country

```sql
SELECT Country, ClubTier, COUNT(*) AS pending_count,
       AVG(DaysSinceApplication) AS avg_days_waiting
FROM BI_DB_dbo.BI_DB_ProfessionalCustomersPending
WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_dbo.BI_DB_ProfessionalCustomersPending)
GROUP BY Country, ClubTier
ORDER BY pending_count DESC
```

### 7.2 Pending Applications Aging Analysis

```sql
SELECT CASE 
         WHEN DaysSinceApplication <= 30 THEN '0-30 days'
         WHEN DaysSinceApplication <= 90 THEN '31-90 days'
         WHEN DaysSinceApplication <= 180 THEN '91-180 days'
         ELSE '180+ days'
       END AS age_bucket,
       COUNT(*) AS applications
FROM BI_DB_dbo.BI_DB_ProfessionalCustomersPending
WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_dbo.BI_DB_ProfessionalCustomersPending)
GROUP BY CASE 
         WHEN DaysSinceApplication <= 30 THEN '0-30 days'
         WHEN DaysSinceApplication <= 90 THEN '31-90 days'
         WHEN DaysSinceApplication <= 180 THEN '91-180 days'
         ELSE '180+ days'
       END
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 3 T1, 5 T2, 0 T3, 0 T4, 0 T5 | Elements: 9/9, Logic: 8/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_ProfessionalCustomersPending | Type: Table | Production Source: Multi-source via SP_ProfessionalCustomers*
