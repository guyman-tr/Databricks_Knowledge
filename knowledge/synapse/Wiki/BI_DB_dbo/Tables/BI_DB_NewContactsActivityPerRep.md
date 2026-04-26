# BI_DB_dbo.BI_DB_NewContactsActivityPerRep

> 319K-row daily sales activity table tracking phone calls, emails, and contacted FTD depositors per account manager, covering Oct 2017 – Apr 2026. Each row represents one manager on one day, with activity counts from Salesforce (BI_DB_UsageTracking_SF) and deposit metrics from BI_DB_NewBonusReport for contacted depositors. Populated by `SP_NewContactActivityPerRep(@dd DATE)` with daily DELETE/INSERT by Date.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `DWH_dbo.Dim_Manager` + `BI_DB_dbo.BI_DB_UsageTracking_SF` + `BI_DB_dbo.BI_DB_CIDFirstDates` + `BI_DB_dbo.BI_DB_NewBonusReport` |
| **Refresh** | Daily — DELETE/INSERT by Date |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_NewContactsActivityPerRep` tracks daily contact activity (phone calls, emails) per sales representative and links those activities to contacted first-time depositors. Each row represents one account manager on one reporting day, aggregating Salesforce action counts and deposit metrics for customers contacted within a 30-day window before their first deposit.

It answers: "How many phone calls, emails, and contacted FTD depositors did each account manager handle on a given day, and what was the total deposit amount from those contacted depositors?"

The SP `SP_NewContactActivityPerRep(@dd DATE)` runs daily. It first queries `Dim_Manager` (excluding system/special ManagerIDs 0, 342, 787, 283, 887), then aggregates Salesforce actions from `BI_DB_UsageTracking_SF` on the target date, and finally matches FTD depositors from `BI_DB_CIDFirstDates` (FirstDepositDate = @dd) to their first contact event within 30 days before deposit. Deposit amounts come from `BI_DB_NewBonusReport` where `IsContacted = 1`.

**Author**: Amir Gurewitz, 2018-05-27.

---

## 2. Business Logic

### 2.1 Manager Filter

**What**: Excludes system and special manager accounts from the population.

**Columns Involved**: `ManagerID`, `Manager`

**Rules**:
- Source: `DWH_dbo.Dim_Manager`
- Excludes ManagerIDs: 0, 342, 787, 283, 887
- Manager name computed as `FirstName + ' ' + LastName`

### 2.2 Salesforce Activity Aggregation

**What**: Counts distinct Salesforce action types per manager per day.

**Columns Involved**: `PhoneCalls`, `UnsuccessfullPhoneCalls`, `InBoundMail`, `OutBoundMail`

**Rules**:
- `PhoneCalls` = `SUM(CASE WHEN ActionName = 'Phone_Call_Succeed__c' THEN 1 ELSE 0 END)`
- `UnsuccessfullPhoneCalls` = `SUM(CASE WHEN ActionName = 'Contacted__c' THEN 1 ELSE 0 END)`
- `InBoundMail` = `SUM(CASE WHEN ActionName = 'Completed_Contact_Email__c' THEN 1 ELSE 0 END)`
- `OutBoundMail` = `SUM(CASE WHEN ActionName = 'Outbound_Email__c' THEN 1 ELSE 0 END)`
- Source: `BI_DB_dbo.BI_DB_UsageTracking_SF` filtered to @dd

### 2.3 ContactFTD Logic

**What**: Matches FTDs on @dd to their first contact (phone call or email) within 30 days before deposit.

**Columns Involved**: `CountDepositors`, `TotalContactedDepositAmount`, `TotalContactedFTDA`

**Rules**:
- FTD population: `BI_DB_CIDFirstDates` where `FirstDepositDate = @dd`
- Desk assignment: resolved via `DWH_dbo.Dim_Country`
- First contact determined by `ROW_NUMBER()` partitioned by CID, ordered by `CreatedDate_SF` — selects the earliest contact
- Contact must be within 30 days before the deposit date
- `CountDepositors`: COUNT(DISTINCT contacted depositors) from `BI_DB_NewBonusReport WHERE IsContacted = 1`
- `TotalContactedDepositAmount`: SUM of `TotalDepositAmount` from `BI_DB_NewBonusReport`
- `TotalContactedFTDA`: SUM of first-time deposit amounts, only for FTDs contacted within 30 days before deposit

### 2.4 Row Inclusion Filter

**What**: Only managers with any activity or depositors are included for each day.

**Rules**:
- `WHERE (PhoneCalls + UnsuccessfullPhoneCalls + InBoundMail + OutBoundMail) > 0 OR depositors exist`
- Early rows (pre-Salesforce tracking) may show 0 for all activity counts but still appear due to depositor data

### 2.5 NOLOCK Hints

**What**: SP uses `WITH (NOLOCK)` hints throughout.

**Rules**:
- NOLOCK is unnecessary in Synapse (Synapse uses snapshot isolation by default)
- No functional impact, but noted for code clarity

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on `Date ASC`. With 319K rows, the table is small. Filter on `Date` for optimal clustered index usage. No distribution key optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Activity summary for a manager | `WHERE Manager = 'Name' AND Date BETWEEN @start AND @end` |
| Top performers by phone calls | `ORDER BY PhoneCalls DESC` for a given date range |
| Total contacted FTD deposits per day | `GROUP BY Date` — SUM `TotalContactedDepositAmount` |
| Managers with depositors but no calls | `WHERE PhoneCalls = 0 AND CountDepositors > 0` |
| Conversion rate (contacts to deposits) | Compare `PhoneCalls + InBoundMail + OutBoundMail` vs `CountDepositors` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| `DWH_dbo.Dim_Manager` | `ON t.ManagerID = dm.ManagerID` | Additional manager attributes (desk, team) |
| `DWH_dbo.Dim_Date` | `ON t.Date = dd.Date` | Calendar attributes (weekday, month, quarter) |

### 3.4 Gotchas

- **UnsuccessfullPhoneCalls has a typo**: Double 'l' in "Unsuccessfull" — use exact column name `UnsuccessfullPhoneCalls`.
- **UnsuccessfullPhoneCalls maps to 'Contacted__c'**: Despite the name suggesting unsuccessful calls, the Salesforce action `Contacted__c` represents contact attempts (not necessarily failed phone calls).
- **Early rows have zero activity counts**: Pre-Salesforce tracking data (early 2017–2018) shows 0 for PhoneCalls/emails but may have depositor counts.
- **ContactFTD 30-day window**: Only FTDs whose first contact was within 30 days before deposit are counted. FTDs with no contact in that window are excluded from depositor metrics.
- **Manager exclusion is by ID, not name**: ManagerIDs 0, 342, 787, 283, 887 are hardcoded exclusions. Adding/removing exclusions requires SP code change.
- **NOLOCK hints**: Present in SP code but functionally unnecessary in Synapse.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★☆☆ | Tier 2 — Synapse SP code | `(Tier 2 — ...)` |
| ★☆☆☆☆ | Tier 5 — ETL metadata | `(Tier 5 — ...)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NO | The reporting date. Set to the @dd parameter of SP_NewContactActivityPerRep. Clustered index column. DELETE/INSERT partition key. (Tier 2 — SP_NewContactActivityPerRep) |
| 2 | ManagerID | int | YES | Account manager ID from Dim_Manager. Excludes system/special IDs: 0, 342, 787, 283, 887. (Tier 2 — SP_NewContactActivityPerRep) |
| 3 | Manager | varchar(50) | YES | Manager full name: `Dim_Manager.FirstName + ' ' + LastName`. (Tier 2 — SP_NewContactActivityPerRep) |
| 4 | PhoneCalls | int | YES | Count of successful phone calls: `SUM(CASE WHEN ActionName = 'Phone_Call_Succeed__c' THEN 1 ELSE 0 END)` from BI_DB_UsageTracking_SF on @dd. (Tier 2 — SP_NewContactActivityPerRep) |
| 5 | UnsuccessfullPhoneCalls | int | YES | Count of contact attempts (unsuccessful): `SUM(CASE WHEN ActionName = 'Contacted__c' THEN 1 ELSE 0 END)`. Note typo: "Unsuccessfull" has double 'l'. (Tier 2 — SP_NewContactActivityPerRep) |
| 6 | InBoundMail | int | YES | Count of completed inbound email contacts: `SUM(CASE WHEN ActionName = 'Completed_Contact_Email__c' THEN 1 ELSE 0 END)`. (Tier 2 — SP_NewContactActivityPerRep) |
| 7 | OutBoundMail | int | YES | Count of outbound emails: `SUM(CASE WHEN ActionName = 'Outbound_Email__c' THEN 1 ELSE 0 END)`. (Tier 2 — SP_NewContactActivityPerRep) |
| 8 | CountDepositors | int | YES | Count of distinct contacted depositors for this manager on @dd. From BI_DB_NewBonusReport WHERE IsContacted = 1. (Tier 2 — SP_NewContactActivityPerRep) |
| 9 | TotalContactedDepositAmount | money | YES | Total deposit amount from contacted depositors. SUM(TotalDepositAmount) from BI_DB_NewBonusReport. (Tier 2 — SP_NewContactActivityPerRep) |
| 10 | TotalContactedFTDA | money | YES | Total first-time deposit amounts from contacted FTDs. Only counts FTDs contacted within 30 days before deposit. ROW_NUMBER partitioned by CID, ordered by CreatedDate_SF selects the first contact. (Tier 2 — SP_NewContactActivityPerRep) |
| 11 | UpdateDate | datetime | YES | ETL metadata: GETDATE() at INSERT time. (Tier 5 — SP_NewContactActivityPerRep) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | — | — | @dd SP parameter |
| ManagerID | DWH_dbo.Dim_Manager | ManagerID | passthrough (filtered) |
| Manager | DWH_dbo.Dim_Manager | FirstName, LastName | concat: FirstName + ' ' + LastName |
| PhoneCalls | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | SUM CASE 'Phone_Call_Succeed__c' |
| UnsuccessfullPhoneCalls | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | SUM CASE 'Contacted__c' |
| InBoundMail | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | SUM CASE 'Completed_Contact_Email__c' |
| OutBoundMail | BI_DB_dbo.BI_DB_UsageTracking_SF | ActionName | SUM CASE 'Outbound_Email__c' |
| CountDepositors | BI_DB_dbo.BI_DB_NewBonusReport | IsContacted, CID | COUNT DISTINCT WHERE IsContacted=1 |
| TotalContactedDepositAmount | BI_DB_dbo.BI_DB_NewBonusReport | TotalDepositAmount | SUM |
| TotalContactedFTDA | BI_DB_dbo.BI_DB_CIDFirstDates + BI_DB_UsageTracking_SF | FirstDepositDate, CreatedDate_SF | ROW_NUMBER first contact within 30 days |
| UpdateDate | — | — | ETL-computed (GETDATE()) |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Manager (excluding ManagerIDs 0,342,787,283,887)
  + BI_DB_dbo.BI_DB_UsageTracking_SF (Salesforce actions on @dd)
  + BI_DB_dbo.BI_DB_CIDFirstDates (FTD population: FirstDepositDate=@dd)
  + DWH_dbo.Dim_Country (Desk for FTD)
  + BI_DB_dbo.BI_DB_NewBonusReport (deposit amounts, IsContacted=1)
    |
    |-- SP_NewContactActivityPerRep(@dd DATE):
    |     Manager population → Salesforce activity aggregation
    |     FTD matching via ROW_NUMBER (first contact within 30 days)
    |     DELETE WHERE Date = @dd → INSERT
    v
BI_DB_dbo.BI_DB_NewContactsActivityPerRep (319K rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | DWH_dbo.Dim_Manager | Manager population (filtered) |
| Source | BI_DB_dbo.BI_DB_UsageTracking_SF | Salesforce phone/email actions |
| Source | BI_DB_dbo.BI_DB_CIDFirstDates | FTD population by deposit date |
| Lookup | DWH_dbo.Dim_Country | Desk assignment for FTDs |
| Enrichment | BI_DB_dbo.BI_DB_NewBonusReport | Deposit amounts for contacted depositors |
| ETL | SP_NewContactActivityPerRep(@dd) | Daily DELETE/INSERT by Date |
| Target | BI_DB_dbo.BI_DB_NewContactsActivityPerRep | 319K rows, daily incremental |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| ManagerID | DWH_dbo.Dim_Manager | Account manager dimension |
| (source) | BI_DB_dbo.BI_DB_UsageTracking_SF | Salesforce activity actions |
| (source) | BI_DB_dbo.BI_DB_CIDFirstDates | FTD population by date |
| (source) | BI_DB_dbo.BI_DB_NewBonusReport | Deposit amounts for contacted depositors |
| (source) | DWH_dbo.Dim_Country | Country/Desk lookup for FTDs |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers identified in the SSDT repo. Used for sales management dashboards and rep performance analytics.

---

## 7. Sample Queries

### 7.1 Daily activity summary for a manager

```sql
SELECT
    Date,
    Manager,
    PhoneCalls,
    UnsuccessfullPhoneCalls,
    InBoundMail,
    OutBoundMail,
    CountDepositors,
    TotalContactedDepositAmount
FROM [BI_DB_dbo].[BI_DB_NewContactsActivityPerRep]
WHERE Manager = 'John Smith'
  AND Date BETWEEN '2026-01-01' AND '2026-03-31'
ORDER BY Date;
```

### 7.2 Top managers by contacted FTD deposit amount

```sql
SELECT
    Manager,
    SUM(CountDepositors) AS TotalDepositors,
    SUM(TotalContactedFTDA) AS TotalFTDA,
    SUM(PhoneCalls) AS TotalCalls
FROM [BI_DB_dbo].[BI_DB_NewContactsActivityPerRep]
WHERE Date BETWEEN '2026-01-01' AND '2026-03-31'
GROUP BY Manager
ORDER BY TotalFTDA DESC;
```

### 7.3 Daily team-wide activity trend

```sql
SELECT
    Date,
    COUNT(DISTINCT ManagerID) AS ActiveManagers,
    SUM(PhoneCalls) AS TotalPhoneCalls,
    SUM(InBoundMail + OutBoundMail) AS TotalEmails,
    SUM(CountDepositors) AS TotalDepositors,
    SUM(TotalContactedDepositAmount) AS TotalDepositAmount
FROM [BI_DB_dbo].[BI_DB_NewContactsActivityPerRep]
GROUP BY Date
ORDER BY Date DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.0/10 (★★★★☆) | Phases: 14/14*
*Tiers: 0 T1, 10 T2, 0 T3, 0 T4 [UNVERIFIED], 1 T5 | Elements: 10/10, Logic: 8/10, Relationships: 6/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_NewContactsActivityPerRep | Type: Table | Production Source: Dim_Manager + BI_DB_UsageTracking_SF + BI_DB_CIDFirstDates + BI_DB_NewBonusReport*
