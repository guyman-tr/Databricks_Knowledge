# BI_DB_dbo.BI_DB_NonUS_Logins

> 11.7M-row compliance/regulatory table detecting US-based login activity from non-US regulated customers. For each non-US depositor who logged in on a given date, geolocates each login IP via `Dim_CountryIP` and counts US vs non-US logins. Only includes customers with at least one US login (USLogins > 0). Populated daily by `SP_NonUS_Logins(@date)` with DELETE/INSERT by DateID. Filters to non-US regulated depositors (RegulationID NOT IN (6,7) = not NFA/eToroUS, CountryID NOT IN (219) = not registered in US).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Row Count** | ~11.7M |
| **Date Range** | Aug 2019 – Apr 2026 (daily) |
| **Production Source** | `SP_NonUS_Logins(@date DATE)` |
| **Refresh** | Daily (DELETE/INSERT by DateID) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| | |
| **UC Target** | _Not_Migrated |

---

## 1. Business Meaning

`BI_DB_dbo.BI_DB_NonUS_Logins` is a compliance/regulatory table that identifies non-US regulated customers who log in from US IP addresses. Each row represents one customer on one date, with counts of US-geolocated and non-US-geolocated login events.

It answers: "Which non-US regulated depositors logged in from a US IP address today, and how many times?"

The table exists to support regulatory monitoring — customers registered under non-US regulations (excluding NFA and eToroUS) should not routinely access the platform from within the United States. Only rows where `USLogins > 0` are retained, so the table exclusively contains customers who had at least one US-origin login on the given date.

---

## 2. Business Logic

### 2.1 Population Filter

**What**: Restricts the customer population to non-US regulated depositors who logged in on the target date.

**Columns Involved**: `RealCID`, `DateID`

**Rules**:
- Customer must be a depositor (`IsDepositor = 1` from `Dim_Customer`)
- Customer must NOT be under US regulation (`RegulationID NOT IN (6, 7)` — excludes NFA and eToroUS)
- Customer must NOT be registered in the US (`CountryID NOT IN (219)`)
- Customer must have logged in on @date (`LastLoggedIn = @date` from `BI_DB_CIDFirstDates`)

### 2.2 IP Geolocation Logic

**What**: Each login event is geolocated to determine whether it originated from a US IP.

**Columns Involved**: `USLogins`, `NonUSLogin`

**Rules**:
- Login events are sourced from `Fact_CustomerAction` where `ActionTypeID = 14` (login) and `DateID = @date`
- Each login IP is resolved via `Dim_CountryIP` to determine the country
- `USLogins` = COUNT of logins where `CountryID = 219` (United States)
- `NonUSLogin` = COUNT of logins where `CountryID != 219`
- Only rows where `USLogins > 0` are output (at least one US-origin login)

### 2.3 Refresh Strategy

**What**: Daily DELETE/INSERT partitioned by DateID.

**Rules**:
- SP deletes all rows for the target DateID before inserting
- `UpdateDate` is set to `GETDATE()` at INSERT time

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on `DateID ASC`. Always filter by `DateID` for optimal index-aligned queries. With 11.7M rows, the table is moderately sized and full scans are feasible but unnecessary.

### 3.1b UC (Databricks) Storage & Partitioning

_Not_Migrated — this table has not been migrated to Unity Catalog._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customers with US logins on a date | `WHERE DateID = @dt` |
| Customers with heavy US activity | `WHERE USLogins >= N` |
| Customers with exclusively US logins | `WHERE USLogins > 0 AND NonUSLogin = 0` |
| Trend of US logins over time | `GROUP BY DateID` — SUM `USLogins` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_Customer` | `ON n.RealCID = dc.RealCID` | Customer demographics, regulation, country |
| `DWH_dbo.Dim_Date` | `ON n.DateID = dd.DateID` | Calendar attributes |

### 3.4 Gotchas

- **Only US-login rows exist** — every row has `USLogins >= 1`. If a customer logged in but never from a US IP, they are not in this table.
- **NonUSLogin can be 0** — a customer may have only US logins on a given date.
- **Population is depositors only** — non-depositor customers are excluded even if they log in from the US.
- **US regulation customers are excluded** — NFA (RegulationID=6) and eToroUS (RegulationID=7) customers are filtered out since US logins are expected for them.
- **Dim_Country join in SP may be vestigial** — the SP joins `Dim_Country` but does not appear to use it for column output.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tiers | Tag |
|-------|-------|-----|
| 3 stars | Tier 2 (Synapse SP code) | `(Tier 2 — ...)` |
| 0 stars | Tier 5 (ETL metadata) | `(Tier 5 — ...)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RealCID | int | YES | Customer ID from `Dim_Customer`. Identifies the non-US regulated depositor who had at least one login from a US IP address on the given date. (Tier 2 — SP_NonUS_Logins) |
| 2 | DateID | int | YES | Date as integer in YYYYMMDD format, from `Fact_CustomerAction.DateID`. Clustered index column. DELETE/INSERT partition key. (Tier 2 — SP_NonUS_Logins) |
| 3 | USLogins | int | YES | Count of login events (ActionTypeID=14) geolocated to US IPs (CountryID=219) on this date. Always >= 1 due to the output filter `USLogins > 0`. (Tier 2 — SP_NonUS_Logins) |
| 4 | NonUSLogin | int | YES | Count of login events (ActionTypeID=14) geolocated to non-US IPs (CountryID != 219) on this date. Can be 0 if all logins were from the US. (Tier 2 — SP_NonUS_Logins) |
| 5 | UpdateDate | datetime | YES | ETL metadata: `GETDATE()` at INSERT time. Indicates when the row was loaded by the stored procedure. (Tier 5 — SP_NonUS_Logins) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| RealCID | DWH_dbo.Dim_Customer | RealCID | Filtered: IsDepositor=1, RegulationID NOT IN (6,7), CountryID NOT IN (219) |
| DateID | DWH_dbo.Fact_CustomerAction | DateID | Passthrough (ActionTypeID=14, DateID=@date) |
| USLogins | DWH_dbo.Fact_CustomerAction + Dim_CountryIP | COUNT where CountryID=219 | Aggregated per customer per date |
| NonUSLogin | DWH_dbo.Fact_CustomerAction + Dim_CountryIP | COUNT where CountryID!=219 | Aggregated per customer per date |
| UpdateDate | — | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (IsDepositor=1, RegulationID NOT IN (6,7), CountryID NOT IN (219))
  + BI_DB_dbo.BI_DB_CIDFirstDates (LastLoggedIn=@date)
  + DWH_dbo.Fact_CustomerAction (ActionTypeID=14, DateID=@date)
  + DWH_dbo.Dim_CountryIP (IP geolocation → CountryID=219 = US)
  + DWH_dbo.Dim_Country (joined but possibly vestigial)
  |
  |-- SP_NonUS_Logins(@date):
  |     Filter non-US depositors who logged in on @date
  |     Geolocate each login IP via Dim_CountryIP
  |     COUNT US logins (CountryID=219) and non-US logins separately
  |     Output only rows where USLogins > 0
  |     DELETE/INSERT by DateID
  v
BI_DB_dbo.BI_DB_NonUS_Logins (11.7M rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Population | Dim_Customer + BI_DB_CIDFirstDates | Non-US regulated depositors who logged in on @date |
| Login Events | Fact_CustomerAction | Login actions (ActionTypeID=14) on @date |
| Geolocation | Dim_CountryIP | IP-to-country resolution for each login |
| ETL | SP_NonUS_Logins | Aggregate US/non-US login counts, filter USLogins > 0 |
| Target | BI_DB_NonUS_Logins | Compliance table for US login detection |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension (non-US regulated depositors) |
| DateID | DWH_dbo.Dim_Date | Date dimension |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| — | — | No known downstream consumers documented |

---

## 7. Sample Queries

### 7.1 Customers with US logins on a specific date

```sql
SELECT RealCID, USLogins, NonUSLogin
FROM BI_DB_dbo.BI_DB_NonUS_Logins
WHERE DateID = 20260420
ORDER BY USLogins DESC;
```

### 7.2 Customers who logged in exclusively from the US

```sql
SELECT RealCID, DateID, USLogins
FROM BI_DB_dbo.BI_DB_NonUS_Logins
WHERE NonUSLogin = 0
  AND DateID BETWEEN 20260401 AND 20260420
ORDER BY USLogins DESC;
```

### 7.3 Daily trend of US login activity

```sql
SELECT DateID,
       COUNT(DISTINCT RealCID) AS CustomersWithUSLogins,
       SUM(USLogins) AS TotalUSLogins
FROM BI_DB_dbo.BI_DB_NonUS_Logins
WHERE DateID BETWEEN 20260101 AND 20260420
GROUP BY DateID
ORDER BY DateID;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.0/10 (★★★★☆) | Phases: 14/14*
*Tiers: 0 T1, 4 T2, 0 T3, 0 T4, 1 T5 | Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_NonUS_Logins | Type: Table | Production Source: SP_NonUS_Logins(@date DATE)*
