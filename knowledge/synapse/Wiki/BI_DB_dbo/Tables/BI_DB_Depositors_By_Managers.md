# BI_DB_dbo.BI_DB_Depositors_By_Managers

> 28,463-row monthly end-of-month summary of customers and depositors per account manager, tracking how many managed customers deposited during each month — 694 distinct managers from September 2017 to March 2026, populated only on the last day of each month by the end-of-month section of SP_NewBonusReport.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_SnapshotCustomer (customer-manager assignments) + DWH_dbo.Fact_CustomerAction (deposits) via SP_NewBonusReport (EOM section) |
| **Refresh** | End-of-month only (SB_Daily, Priority 0) — IF EOMONTH(@dd) = @dd gate. DELETE month + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX([Month] ASC, [Manager] ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_Depositors_By_Managers is a monthly account manager performance report that tracks the number of managed customers and how many of those deposited during the month. Each row represents one manager for one month.

The table contains 28,463 rows spanning September 2017 to March 2026 with 694 distinct managers. It is only populated on the last day of each month (guarded by `IF EOMONTH(@dd) = @dd`), even though SP_NewBonusReport runs daily to populate the companion BI_DB_NewBonusReport table.

The customer-manager assignment is determined at the beginning of the month using Fact_SnapshotCustomer's DateRangeID, which captures the point-in-time assignment. Deposits are counted from Fact_CustomerAction (ActionTypeID=7) during the calendar month. Manager IDs 0, 342, 787, 283, and 887 are excluded (system/test accounts).

This feeds into the account manager bonus calculation and performance tracking.

---

## 2. Business Logic

### 2.1 Monthly Customer Assignment

**What**: Customers are assigned to managers based on their Fact_SnapshotCustomer record at the start of the month.
**Columns Involved**: Manager, ManagerID, NoOfCustomers, Month
**Rules**:
- DateRangeID from Fact_SnapshotCustomer must overlap the 1st of the month
- DateRangeID >= 201501010101 (excludes legacy pre-2015 snapshots)
- Excluded ManagerIDs: 0, 342, 787, 283, 887 (system/test)
- NoOfCustomers = COUNT of RealCIDs assigned to the manager

### 2.2 Monthly Depositor Count

**What**: Customers who made at least one deposit during the calendar month.
**Columns Involved**: Depositors
**Rules**:
- Deposit = Fact_CustomerAction.ActionTypeID = 7
- Deposit must occur between the 1st of the month and @dd (end of month)
- IsDepositor = 1 if any deposit exists, 0 otherwise
- Depositors = SUM(IsDepositor) per manager

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — small table (28K rows)
- **Clustered Index**: (Month ASC, Manager ASC) — efficient for monthly and manager filtering

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Manager deposit rate this month | `SELECT Manager, Depositors * 1.0 / NoOfCustomers WHERE Month = @month` |
| Deposit rate trend by manager | `WHERE ManagerID = @id ORDER BY Month` |
| Top managers by deposit count | `WHERE Month = @month ORDER BY Depositors DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Manager | ON ManagerID | Full manager profile |
| BI_DB_dbo.BI_DB_NewBonusReport | ON ManagerID + DateID range | Daily deposit detail for the manager |

### 3.4 Gotchas

- **Only populated at end-of-month** — querying for the current month before month-end returns no data
- **Manager name changes are not retroactive** — if a manager's name changes, historical rows retain the old name
- **NoOfCustomers is based on month-start snapshot** — customers added mid-month are not counted
- **SP writes to BOTH BI_DB_NewBonusReport (daily) and BI_DB_Depositors_By_Managers (EOM)** — they are different tables with different grains

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest |
| Tier 2 | SP code / ETL logic analysis | High |
| Tier 5 | Propagation rule (ETL metadata pattern) | Standard |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Manager | varchar(50) | YES | Account manager full name (FirstName + LastName) from Dim_Manager. 694 distinct managers. Excludes ManagerIDs 0, 342, 787, 283, 887 (system/test). (Tier 2 — SP_NewBonusReport) |
| 2 | Month | date | YES | First day of the reporting month (e.g., 2026-03-01 for March 2026). Range: 2017-09-01 to 2026-03-01. Only populated at end-of-month. (Tier 2 — SP_NewBonusReport) |
| 3 | NoOfCustomers | int | YES | Number of customers assigned to this manager at the start of the month. Based on Fact_SnapshotCustomer DateRangeID overlap with month start date. (Tier 2 — SP_NewBonusReport) |
| 4 | Depositors | int | YES | Number of the manager's customers who made at least one deposit (Fact_CustomerAction ActionTypeID=7) during the calendar month. (Tier 2 — SP_NewBonusReport) |
| 5 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at INSERT time. (Tier 5 — Propagation) |
| 6 | ManagerID | int | YES | Account manager ID from Dim_Manager.ManagerID. FK to DWH_dbo.Dim_Manager. (Tier 2 — SP_NewBonusReport) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Manager | DWH_dbo.Dim_Manager | FirstName + LastName | Concatenated |
| Month | SP parameter | @dd | DATEADD to 1st of month |
| NoOfCustomers | DWH_dbo.Fact_SnapshotCustomer | COUNT(RealCID) | Aggregation |
| Depositors | DWH_dbo.Fact_CustomerAction | SUM(IsDepositor) | ActionTypeID=7 in month |
| ManagerID | DWH_dbo.Dim_Manager | ManagerID | Passthrough |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (customer-manager assignments at month start)
  + DWH_dbo.Dim_Manager (manager name, ID filtering)
  + DWH_dbo.Dim_Range (DateRangeID resolution)
  |-- Customer population per manager ---|
  v
#m_bom (temp: RealCID, Manager, ManagerID)
  + DWH_dbo.Fact_CustomerAction (deposits ActionTypeID=7 in month)
  + BI_DB_CIDFirstDates (country metadata)
  + DWH_dbo.Dim_Country (desk)
  |-- IsDepositor flag per CID ---|
  v
#Depositors (temp: per-CID deposit status)
  |-- COUNT(RealCID), SUM(IsDepositor) GROUP BY Manager ---|
  |-- DELETE month + INSERT (EOM only) ---|
  v
BI_DB_dbo.BI_DB_Depositors_By_Managers (28K rows, ROUND_ROBIN, CI(Month, Manager))
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ManagerID | DWH_dbo.Dim_Manager.ManagerID | Manager dimension |

### 6.2 Referenced By (other objects point to this)

| Object | Relationship | Description |
|--------|-------------|-------------|
| (none found in SSDT) | — | Manager performance/bonus dashboards |

---

## 7. Sample Queries

### 7.1 Manager Deposit Rate for Latest Month

```sql
SELECT Manager, ManagerID, NoOfCustomers, Depositors,
       CAST(Depositors AS FLOAT) / NULLIF(NoOfCustomers, 0) AS deposit_rate
FROM [BI_DB_dbo].[BI_DB_Depositors_By_Managers]
WHERE Month = (SELECT MAX(Month) FROM [BI_DB_dbo].[BI_DB_Depositors_By_Managers])
ORDER BY Depositors DESC;
```

### 7.2 Monthly Trend for a Specific Manager

```sql
SELECT Month, NoOfCustomers, Depositors,
       CAST(Depositors AS FLOAT) / NULLIF(NoOfCustomers, 0) AS deposit_rate
FROM [BI_DB_dbo].[BI_DB_Depositors_By_Managers]
WHERE ManagerID = 784
ORDER BY Month;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 13/14 (P10 Atlassian unavailable)*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 1 T5 | Elements: 6/6, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_Depositors_By_Managers | Type: Table | Production Source: Fact_SnapshotCustomer + Fact_CustomerAction via SP_NewBonusReport (EOM)*
