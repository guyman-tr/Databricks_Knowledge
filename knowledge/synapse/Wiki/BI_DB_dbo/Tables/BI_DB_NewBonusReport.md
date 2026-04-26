# BI_DB_dbo.BI_DB_NewBonusReport

> Account manager deposit and cash-out event report. Each row represents a single deposit or cash-out (CO) transaction by a customer (RealCID), enriched with the assigned account manager, customer segmentation (country, region, desk, channel, club tier), and contact tracking (IsContacted, DaysSinceContact). 56.7M rows covering 2017-08-31 to 2026-04-11; 4.9M distinct customers; 591 account managers. Populated daily by SP_NewBonusReport (SB_Daily pipeline).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Deposit and cash-out events + customer/manager assignments (via SP_NewBonusReport) |
| **Refresh** | Daily; SP_NewBonusReport, Priority 0, SB_Daily process |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC); NONCLUSTERED INDEX (Date) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_NewBonusReport` is the account manager activity tracking table for deposit and cash-out events. It surfaces each new deposit or large cash-out transaction alongside the responsible account manager, enabling manager-level performance reporting, follow-up prioritisation, and client lifecycle monitoring.

Each row represents one transaction (deposit or cash-out) by a customer on a given date, enriched with:
- **Manager assignment**: The account manager responsible for the customer (ManagerID, Manager)
- **Transaction amounts**: TotalDepositAmount (for deposits) or TotalCoAmount (for cash-outs) — these are mutually exclusive per row
- **Customer segmentation**: Country, Region, Desk, Channel, SubChannel, Club tier — all denormalized from the customer dimension
- **Contact status**: IsContacted (flag), ContactByManager (last contacting manager), DaysSinceContact (days since last manager contact)

Despite the "Bonus" name, the table covers all deposit types and cash-out events, not just bonus-related transactions. The name likely reflects the table's original scope at creation. SP_NewBonusReport also writes the sibling `BI_DB_Depositors_By_Managers` table.

Scale: 56.7M rows spanning 8+ years; 591 distinct managers; avg 1.21 rows per customer per day (max 65 for customers with many same-day transactions).

---

## 2. Business Logic

### 2.1 Deposit vs Cash-Out (CO) Row Types

**What**: Each row represents either a deposit event or a cash-out event — not both simultaneously.
**Columns Involved**: `TotalDepositAmount`, `TotalCoAmount`
**Rules**:
- Deposit rows: `TotalDepositAmount > 0`, `TotalCoAmount = 0` (or NULL)
- Cash-out rows: `TotalCoAmount > 0`, `TotalDepositAmount = 0` (or NULL)
- Both can be $0 (0.6% of recent rows) — zero-amount rows may represent contact events or data corrections
- CO amounts can be very large — up to $1.37M+ observed for institutional/high-net-worth withdrawals
- "CO" meaning is most likely "Cash Out" (client withdrawal); confirm with domain expert

### 2.2 Contact Tracking

**What**: Three columns track account manager outreach for follow-up.
**Columns Involved**: `IsContacted`, `ContactByManager`, `DaysSinceContact`
**Rules**:
- `IsContacted = 0`: Manager has not yet contacted the customer about this event (97% of rows)
- `IsContacted = 1`: Manager has contacted the customer (3% of rows in recent data)
- `ContactByManager`: Name of the manager who last reached out (may differ from the assigned Manager)
- `DaysSinceContact`: Computed integer days since the last contact — refreshed daily in the ETL
- NULL in ContactByManager and DaysSinceContact = no contact has been made

### 2.3 Multi-Row Customer Days

**What**: A customer may have multiple rows on the same date for multiple transactions.
**Columns Involved**: `RealCID`, `Date`
**Rules**:
- One row per transaction, not per customer per day
- Average 1.21 rows per RealCID per date; maximum 65 observed (high-frequency depositing customers)
- Do NOT expect 1 row per CID when filtering to a single date

---

## 3. Query Advisory

### 3.1 Distribution & Index

`HASH(RealCID)` — queries filtering by customer are co-located. Clustered index on `DateID` (integer) is the primary sort key; non-clustered on `Date` supports date-range queries. For daily slices, filter by `Date =` or `DateID =`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Today's new deposits by manager | `SELECT Manager, SUM(TotalDepositAmount) AS total_deposits, COUNT(DISTINCT RealCID) AS new_depositors FROM [BI_DB_dbo].[BI_DB_NewBonusReport] WHERE Date = @date AND TotalDepositAmount > 0 GROUP BY Manager ORDER BY total_deposits DESC` |
| Customers not yet contacted (new deposits yesterday) | `SELECT RealCID, Manager, TotalDepositAmount, Country FROM [BI_DB_dbo].[BI_DB_NewBonusReport] WHERE Date = DATEADD(day,-1,GETDATE()) AND IsContacted = 0 AND TotalDepositAmount > 0 ORDER BY TotalDepositAmount DESC` |
| Large cash-outs requiring follow-up | `SELECT RealCID, Manager, TotalCoAmount, Country, DaysSinceContact FROM [BI_DB_dbo].[BI_DB_NewBonusReport] WHERE Date >= DATEADD(day,-7,GETDATE()) AND TotalCoAmount > 10000 ORDER BY TotalCoAmount DESC` |
| Manager performance - monthly deposits | `SELECT Manager, YEAR(Date) AS yr, MONTH(Date) AS mo, SUM(TotalDepositAmount) AS monthly_deposits FROM [BI_DB_dbo].[BI_DB_NewBonusReport] WHERE TotalDepositAmount > 0 GROUP BY Manager, YEAR(Date), MONTH(Date) ORDER BY yr, mo, monthly_deposits DESC` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `r.RealCID = dc.RealCID` | Customer demographics (registration date, email, etc.) |
| BI_DB_dbo.BI_DB_Depositors_By_Managers | `r.RealCID = d.RealCID` | Sibling table from same SP; aggregated depositor view by manager |

### 3.4 Gotchas

- **Multiple rows per CID per day** — avg 1.21 rows; SUM(TotalDepositAmount) per CID per day counts all deposits, but COUNT(*) does not equal unique customers.
- **TotalDepositAmount and TotalCoAmount are mutually exclusive** — do not SUM both in the same aggregate; filter by which event type you need.
- **"CO" meaning unconfirmed** — likely "Cash Out" (withdrawal) but the SP code is unavailable for verification. See review questions.
- **SP code inaccessible** — SP_NewBonusReport has empty sys.sql_modules definition. Column logic is inferred from data sampling.
- **56.7M rows** — always filter by Date or DateID. Both indexes enable date-bounded queries.
- **UpdateDate is batch-uniform** — all rows for a given ETL run share the same UpdateDate (next morning). Not a per-row write timestamp.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (DWH_dbo wiki or production DB_Schema wiki) |
| Tier 2 | Derived from data sampling, naming conventions, or dimension passthrough analysis |
| Tier 3 | Inferred from naming conventions or data evidence only |
| Tier 4 | Undetermined — pending review |
| P | Propagation metadata (ETL timestamp columns) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | NO | Customer ID — platform-internal primary key. NOT NULL; primary join key for all CID-based queries. (Tier 1 — Customer.CustomerStatic) |
| 2 | ManagerID | int | YES | ID of the account manager assigned to this customer. 591 distinct managers observed. (Tier 3 — inferred from naming + data) |
| 3 | Manager | varchar(50) | YES | Full name of the assigned account manager. Denormalized from manager roster. Examples: "Farzana Begum", "Harry Blagden". (Tier 3 — inferred from naming + data) |
| 4 | DateID | int | YES | Integer date key in YYYYMMDD format (e.g., 20260411 for 2026-04-11). Primary sort column (CLUSTERED INDEX). (Tier 2 — data evidence) |
| 5 | Date | date | YES | Calendar date of the deposit or cash-out event. Range: 2017-08-31 to 2026-04-11. Non-clustered index enables fast date-bounded queries. (Tier 2 — data evidence) |
| 6 | TotalDepositAmount | money | YES | USD amount of the deposit event. Positive when deposit row; $0 for cash-out rows. Use WHERE TotalDepositAmount > 0 to isolate deposit events. (Tier 2 — naming + data evidence) |
| 7 | TotalCoAmount | money | YES | USD amount of the cash-out (CO) event. Positive when cash-out row; $0 for deposit rows. Large values observed ($1.37M+) for institutional-scale withdrawals. "CO" likely = Cash Out — pending confirmation. (Tier 3 — inferred; "CO" meaning unconfirmed) |
| 8 | IsContacted | int | YES | Contact status flag: 1 = account manager has contacted this customer about the event; 0 = not yet contacted. 97% of rows are 0 (uncontacted) in recent data. (Tier 3 — data evidence) |
| 9 | Country | varchar(50) | YES | Customer country name. Denormalized from customer dimension. Examples: "United Kingdom", "Germany", "France". (Tier 2 — data evidence + Dim_Customer passthrough) |
| 10 | Region | varchar(50) | YES | Sales region segment. Examples: "UK", "Eastern Europe", "French", "Other EU". Denormalized from customer dimension. (Tier 2 — data evidence + Dim_Customer passthrough) |
| 11 | Desk | varchar(50) | YES | Sales desk assignment. Examples: "UK", "French", "Other EU". Used to route customers to appropriate sales teams. (Tier 2 — data evidence + Dim_Customer passthrough) |
| 12 | Channel | varchar(50) | YES | Customer acquisition channel. Examples: "SEM", "Affiliate", "Direct", "Mobile Acquisition". Denormalized from customer acquisition data. (Tier 2 — data evidence + Dim_Customer passthrough) |
| 13 | SubChannel | varchar(50) | YES | Acquisition sub-channel detail. Examples: "FB" (Facebook), "Mobile CPA", "Direct Mobile", "Affiliate". (Tier 2 — data evidence + Dim_Customer passthrough) |
| 14 | Club | varchar(50) | YES | eToro Club membership tier at the time of the event. Values: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond. Distribution (April 2026): Bronze 44%, Gold 17%, Platinum 15%, Silver 14%, Platinum Plus 12%, Diamond 2%. (Tier 2 — data evidence) |
| 15 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was written by SP_NewBonusReport. All rows in a batch share the same UpdateDate. (P) |
| 16 | ContactByManager | varchar(50) | YES | Name of the manager who last contacted this customer. May differ from the assigned Manager. NULL when no contact has been made. (Tier 3 — inferred from naming + data) |
| 17 | DaysSinceContact | int | YES | Integer days elapsed since the last manager contact with this customer. Recomputed daily by ETL. NULL when no contact has been made. (Tier 3 — inferred from naming + data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RealCID | Customer source | CID | Passthrough |
| ManagerID | Account manager assignment system | ManagerID | Passthrough |
| Manager | Account manager roster | Manager name | Denormalized |
| DateID | Deposit/CO event | date | YYYYMMDD integer |
| Date | Deposit/CO event | event date | Passthrough |
| TotalDepositAmount | Deposit events (DWH) | deposit amount | Sum/passthrough for event |
| TotalCoAmount | Cash-out events (DWH) | CO amount | Sum/passthrough for event |
| IsContacted | Manager activity tracking | contact flag | 0/1 flag |
| Country | DWH_dbo.Dim_Customer | CountryName | Denormalized |
| Region | DWH_dbo.Dim_Customer | Region | Denormalized |
| Desk | DWH_dbo.Dim_Customer | Desk | Denormalized |
| Channel | DWH_dbo.Dim_Customer | Channel | Denormalized |
| SubChannel | DWH_dbo.Dim_Customer | SubChannel | Denormalized |
| Club | DWH_dbo.Dim_Customer | Club | Denormalized |
| UpdateDate | ETL pipeline | — | ETL write timestamp |
| ContactByManager | Manager activity tracking | manager name | Last contacting manager name |
| DaysSinceContact | ETL computed | — | Days since last contact, recomputed daily |

### 5.2 ETL Pipeline

```
DWH deposit events + cash-out events + Dim_Customer segments + manager assignments
  |-- SP_NewBonusReport (Daily, SB_Daily, Priority 0) ---|
  |-- Also writes BI_DB_Depositors_By_Managers (sibling table)
  v
BI_DB_dbo.BI_DB_NewBonusReport (56.7M rows, per deposit/CO event)
  |-- (downstream: account manager reporting tools — not confirmed in Synapse SPs)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | Customer.CustomerStatic (CID) | Customer reference |
| RealCID | DWH_dbo.Dim_Customer (RealCID) | Customer demographics |

### 6.2 Referenced By

| Object | How Used |
|--------|---------|
| BI_DB_dbo.BI_DB_Depositors_By_Managers | Sibling table produced by same SP_NewBonusReport run |

---

## 7. Sample Queries

### Daily new deposits by manager (most recent day)

```sql
SELECT
    Manager,
    COUNT(DISTINCT RealCID) AS depositing_customers,
    SUM(TotalDepositAmount) AS total_deposit_usd,
    AVG(TotalDepositAmount) AS avg_deposit_usd
FROM [BI_DB_dbo].[BI_DB_NewBonusReport]
WHERE Date = '2026-04-11'
  AND TotalDepositAmount > 0
GROUP BY Manager
ORDER BY total_deposit_usd DESC;
```

### Uncontacted customers with large deposits in last 7 days

```sql
SELECT
    RealCID,
    Manager,
    Date,
    TotalDepositAmount,
    Country,
    Club,
    DaysSinceContact
FROM [BI_DB_dbo].[BI_DB_NewBonusReport]
WHERE Date >= DATEADD(day, -7, '2026-04-11')
  AND TotalDepositAmount >= 1000
  AND IsContacted = 0
ORDER BY TotalDepositAmount DESC;
```

### Club tier breakdown of recent deposits

```sql
SELECT
    Club,
    COUNT(DISTINCT RealCID) AS depositing_customers,
    SUM(TotalDepositAmount) AS total_deposit_usd
FROM [BI_DB_dbo].[BI_DB_NewBonusReport]
WHERE Date >= '2026-04-01'
  AND TotalDepositAmount > 0
GROUP BY Club
ORDER BY total_deposit_usd DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. SP_NewBonusReport author details unavailable (SP code inaccessible). Despite the "Bonus" name, the table covers all deposit and cash-out events tracked by account managers. Sibling output: BI_DB_Depositors_By_Managers.

---

*Generated: 2026-04-23 | Quality: 7.8/10 | Phases: 11/14*
*Tiers: 1 T1, 8 T2, 7 T3, 0 T4, 1 P | Elements: 17/17, Logic: 7/10, Data Evidence: 9/10*
*Object: BI_DB_dbo.BI_DB_NewBonusReport | Type: Table | Production Source: Deposit/CO events + manager assignments via SP_NewBonusReport*
