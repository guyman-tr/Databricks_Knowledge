# BI_DB_dbo.BI_DB_AB_Test

> 314,240-row AB test customer assignment table tracking control/treatment group membership for 2 experiments (AB_Test_Onboarding_202007, AB_Test_lead_conv_202202) across 312,861 distinct customers from 2020-06-10 to 2023-04-29. Manually loaded (no ETL SP). Production source unknown (dormant). No scheduled refresh.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown (dormant) — manually loaded, no writer SP; created via Jira DS-1703 |
| **Refresh** | None detected — last UpdateDate 2023-04-29; table appears dormant |
| **Synapse Distribution** | HASH(RealCID) |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC, Name ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | None |
| **UC Table Type** | — |

---

## 1. Business Meaning

BI_DB_AB_Test is a customer-level AB test assignment table used by the BI and Product Analytics teams to track which customers were placed into control vs. treatment groups for specific experiments. The table contains 314,240 rows spanning 312,861 distinct customers across 2 named experiments:

- **AB_Test_Onboarding_202007** (75,054 rows, Business Owner: Steven Freedman) — an onboarding flow experiment launched June 2020.
- **AB_Test_lead_conv_202202** (239,186 rows, Business Owner: Elie Edery) — a lead conversion experiment launched circa February 2022.

Each row represents one customer's assignment to a test on a specific date, with a binary IsControl flag (0=treatment, 1=control). The table was created via Jira ticket DS-1703 and has no automated ETL — data was loaded manually or via an external process. The table appears dormant: the most recent UpdateDate is 2023-04-29 and no stored procedures read from or write to it. A companion table, `BI_DB_AB_Test_Data`, stores additional test configuration (date ranges, portfolio flags, service levels).

All columns are non-NULL in the current dataset. BI_Owner is uniformly "Tom Boksenbojm" across all rows.

---

## 2. Business Logic

### 2.1 Control vs. Treatment Assignment

**What**: Each customer is assigned to either the control group or the treatment group for a given experiment.
**Columns Involved**: RealCID, IsControl, Name
**Rules**:
- IsControl = 1 means the customer is in the control group (no experimental change applied).
- IsControl = 0 means the customer is in the treatment group (experimental change applied).
- Control/treatment split is approximately 35%/65% (108,894 control vs. 205,346 treatment across all tests).

### 2.2 Test Ownership

**What**: Each experiment has a BI analyst owner and a business stakeholder owner.
**Columns Involved**: BI_Owner, Business_Owner, Name
**Rules**:
- BI_Owner is always "Tom Boksenbojm" for both tests in the current dataset.
- Business_Owner varies by test: "Steven Freedman" for the onboarding test, "Elie Edery" for the lead conversion test.

### 2.3 Date Tracking

**What**: Each assignment is tied to a specific calendar date, recorded both as an integer key and a date value.
**Columns Involved**: DateID, Date
**Rules**:
- DateID is in YYYYMMDD integer format (e.g., 20200624).
- Date is the corresponding calendar date.
- Date range: 2020-06-10 to 2023-04-29.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: HASH(RealCID) — queries filtering on RealCID are single-node. JOINs to other RealCID-hashed tables (e.g., Dim_Customer) are co-located.
- **Index**: CLUSTERED INDEX on (DateID ASC, Name ASC) — efficient for date-range + test-name queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Which customers are in the control group for a specific test? | `WHERE Name = 'AB_Test_lead_conv_202202' AND IsControl = 1` |
| How many customers per test and group? | `GROUP BY Name, IsControl` |
| Join to customer attributes for test analysis | `JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID = t.RealCID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | `Dim_Customer.RealCID = BI_DB_AB_Test.RealCID` | Enrich with customer demographics, regulation, country |
| BI_DB_dbo.BI_DB_AB_Test_Data | `BI_DB_AB_Test_Data.RealCID = BI_DB_AB_Test.RealCID AND BI_DB_AB_Test_Data.TestName = BI_DB_AB_Test.Name` | Extended test configuration (date ranges, portfolio flags) |

### 3.4 Gotchas

- **Dormant table**: No automated refresh. Data ends April 2023. Do not expect current experiment data here.
- **Near-unique RealCID**: 312,861 distinct CIDs out of 314,240 rows — most customers appear once but a small number appear on multiple dates within the same test.
- **Fixed BI_Owner**: BI_Owner is "Tom Boksenbojm" for 100% of rows; the column provides no filtering value in the current dataset.
- **No FK enforcement**: RealCID is not enforced as a foreign key to Dim_Customer.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (production source documented) |
| Tier 3 | Grounded in DDL + live data evidence, no upstream wiki available |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DateID | int | YES | Integer date key in YYYYMMDD format representing the date the customer was assigned to the AB test group. Range: 20200610–20230429. All values non-NULL in current data. (Tier 3 — DDL + data sample, no upstream wiki) |
| 2 | Date | date | YES | Calendar date corresponding to DateID. The date the customer entered the experiment cohort. Range: 2020-06-10 to 2023-04-29. All values non-NULL in current data. (Tier 3 — DDL + data sample, no upstream wiki) |
| 3 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| 4 | IsControl | int | YES | Binary flag indicating AB test group assignment. 0=treatment group (experimental change applied), 1=control group (no change). 205,346 treatment vs. 108,894 control rows in current data. All values non-NULL. (Tier 3 — DDL + data distribution, no upstream wiki) |
| 5 | BI_Owner | varchar(14) | YES | Name of the BI analyst responsible for the experiment. Currently "Tom Boksenbojm" for 100% of rows. All values non-NULL. (Tier 3 — DDL + data sample, no upstream wiki) |
| 6 | Business_Owner | varchar(15) | YES | Name of the business stakeholder who owns the experiment. "Steven Freedman" for AB_Test_Onboarding_202007, "Elie Edery" for AB_Test_lead_conv_202202. All values non-NULL. (Tier 3 — DDL + data sample, no upstream wiki) |
| 7 | Name | varchar(25) | YES | Identifier string for the AB test experiment. 2 distinct values: "AB_Test_Onboarding_202007" (75,054 rows), "AB_Test_lead_conv_202202" (239,186 rows). All values non-NULL. (Tier 3 — DDL + data sample, no upstream wiki) |
| 8 | UpdateDate | datetime | YES | Timestamp of when the row was inserted or last updated. Range: 2020-06-24 to 2023-04-29. All values non-NULL. (Tier 3 — DDL + data sample, no upstream wiki) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-------------------|---------------|-----------|
| RealCID | Customer.CustomerStatic | CID | Passthrough (shared DWH identifier via Dim_Customer convention) |
| DateID | Unknown | — | Manual load |
| Date | Unknown | — | Manual load |
| IsControl | Unknown | — | Manual load |
| BI_Owner | Unknown | — | Manual load |
| Business_Owner | Unknown | — | Manual load |
| Name | Unknown | — | Manual load |
| UpdateDate | Unknown | — | Manual load |

### 5.2 ETL Pipeline

```
Unknown external source (manual load / ad-hoc process)
  |-- No SP / No Generic Pipeline ---|
  v
BI_DB_dbo.BI_DB_AB_Test (314,240 rows, dormant since 2023-04-29)
  |-- Not migrated to UC ---|
  x
(No UC target)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| RealCID | DWH_dbo.Dim_Customer | Customer dimension — join on Dim_Customer.RealCID for demographics |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Element | Description |
|--------------------|---------|-------------|
| BI_DB_dbo.BI_DB_AB_Test_Data | RealCID, TestName/Name | Companion table with extended test configuration |

---

## 7. Sample Queries

### 7.1 Customer Count by Test and Group

```sql
SELECT
    Name AS TestName,
    IsControl,
    COUNT(*) AS CustomerCount
FROM BI_DB_dbo.BI_DB_AB_Test
GROUP BY Name, IsControl
ORDER BY Name, IsControl;
```

### 7.2 Join AB Test Assignment to Customer Demographics

```sql
SELECT
    ab.Name AS TestName,
    ab.IsControl,
    dc.CountryID,
    dc.RegulationID,
    COUNT(*) AS Customers
FROM BI_DB_dbo.BI_DB_AB_Test ab
JOIN DWH_dbo.Dim_Customer dc ON dc.RealCID = ab.RealCID
WHERE ab.Name = 'AB_Test_lead_conv_202202'
GROUP BY ab.Name, ab.IsControl, dc.CountryID, dc.RegulationID
ORDER BY Customers DESC;
```

### 7.3 Check for Customers in Multiple Tests

```sql
SELECT RealCID, COUNT(DISTINCT Name) AS TestCount
FROM BI_DB_dbo.BI_DB_AB_Test
GROUP BY RealCID
HAVING COUNT(DISTINCT Name) > 1
ORDER BY TestCount DESC;
```

---

## 8. Atlassian Knowledge Sources

| Source | Title | Relevance |
|--------|-------|-----------|
| [DS-1703](https://etoro-jira.atlassian.net/browse/DS-1703) | Create table BI_DB_dbo.BI_DB_AB_Test + BI_DB_AB_Test_Data in Prod + DEV Synapse | Table creation ticket |
| [AB Test Steps](https://etoro-jira.atlassian.net/wiki/spaces/PA/pages/11838458854/AB+Test+Steps) | AB Test methodology and checklist (Product Analytics) | General AB testing process context |

---

*Generated: 2026-04-27 | Quality: 6/10 | Phases: 8/14*
*Tiers: 1 T1, 0 T2, 7 T3, 0 T4, 0 T5 | Elements: 8/8, Logic: 6/10, Lineage: 3/10*
*Object: BI_DB_dbo.BI_DB_AB_Test | Type: Table | Production Source: Unknown (dormant)*
