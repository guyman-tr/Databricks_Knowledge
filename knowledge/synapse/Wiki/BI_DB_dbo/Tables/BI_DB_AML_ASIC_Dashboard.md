# BI_DB_dbo.BI_DB_AML_ASIC_Dashboard

> AML compliance watchlist for ASIC-regulated high-risk customers — 4,307-row daily snapshot of every High-risk depositor under Australian (ASIC / ASIC & GAML) regulation, with equity exposure, deposit totals, regulation migration history, and open AML case flag.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Primary Sources** | DWH_dbo.Dim_Customer + External_RiskClassification + Fact_CustomerAction + Fact_SnapshotCustomer + V_Liabilities + BI_DB_SF_Cases_Panel |
| **Refresh** | Daily (OpsDB Priority 0, SB_Daily) |
| **Distribution** | ROUND_ROBIN |
| **Index** | HEAP |
| **Column Count** | 18 |
| **Row Count** | ~4,307 (2026-04-22) |
| **Writer SP** | SP_AML_ASIC_Dashboard |
| **Load Pattern** | TRUNCATE TABLE + INSERT (full refresh, no date parameter) |
| **Population Filter** | RegulationID IN (4=ASIC, 10=ASIC&GAML) AND RiskScoreName='High' AND IsValidCustomer=1 AND IsDepositor=1 AND VerificationLevelID≥2 AND PlayerStatusID NOT IN (2,4) |
| **Downstream Consumers** | None registered in OpsDB — terminal analytics table |
| **UC Target** | Pending |

---

## 1. Business Meaning

`BI_DB_AML_ASIC_Dashboard` is the AML compliance watchlist for eToro customers regulated under ASIC (Australian Securities and Investments Commission) or ASIC & GAML (Global Anti-Money Laundering) who carry a High risk classification. It provides AML officers with a consolidated daily view of every high-risk ASIC depositor — their current compliance status, financial exposure, and whether they came from another regulatory jurisdiction.

The table is deliberately narrow: it is not a general ASIC customer view but specifically the high-risk compliance watchlist. Low and Medium risk ASIC customers are excluded. The 4,307 current members represent the active ASIC AML monitoring universe.

**Key operational insights from current data:**
- 61% are `Pending Verification` (VerificationLevelID=2) — these customers deposited and passed identity verification but have not completed full KYC. Under ASIC, high-risk customers without full verification require priority review.
- 13% migrated to ASIC from another regulation (predominantly CySEC), making them potentially subject to enhanced due diligence.
- `RiskScoreName` is always 'High' (it is a population filter, not a variable field).
- `Has_Open_AML_Case` is 0 for all current records — no open ASIC high-risk AML Salesforce cases at time of last run.

---

## 2. Business Logic

### 2.1 Population Selection

The SP builds `#pop` with all four conditions applied simultaneously:
```
Dim_Customer  WHERE IsValidCustomer=1 AND IsDepositor=1
JOIN Dim_Regulation  WHERE DWHRegulationID IN (4, 10)       -- ASIC only
JOIN Dim_PlayerStatus WHERE PlayerStatusID NOT IN (2, 4)    -- not Blocked
JOIN External_RiskClassification WHERE RiskScoreName = 'High'
AND VerificationLevelID >= 2                                 -- at minimum identity-verified
```

### 2.2 Equity Computation

```sql
Equity = ISNULL(V_Liabilities.Liabilities, 0) + ISNULL(V_Liabilities.ActualNWA, 0)
```
- `Liabilities`: customer's net position value including leveraged exposures
- `ActualNWA`: net wallet amount  
- Date-bound to yesterday: `DateID = CAST(CONVERT(CHAR(8), GETDATE()-1, 112) AS INT)`
- 0 if customer not found in V_Liabilities (no active positions)

### 2.3 Regulation Change Detection (3-Step Pipeline)

Identifies customers who migrated TO ASIC/ASIC&GAML FROM another regulatory entity:

**Step 1** (`#status01`): Uses `LAG(RegulationID) OVER (PARTITION BY RealCID ORDER BY DateRangeID ASC)` on `Fact_SnapshotCustomer` to detect any row where RegulationID changed. Converts `Dim_Range.FromDateID` → change date.

**Step 2** (`#status02`): Computes `DaysBetweenChanges` using `LAG(Change_Date)`.

**Step 3** (`#status03`): Filters to changes where:
- `Curr_Regulation IN ('ASIC', 'ASIC & GAML')`  
- `Previous_Regulation NOT IN ('BVI', 'None', 'ASIC', 'ASIC & GAML')`

Takes most recent qualifying change per customer (`ROW_NUMBER DESC`). Observed prior regulations: CySEC (majority), FCA, eToroUS, FSA Seychelles.

### 2.4 Open AML Case Detection

```sql
Has_Open_AML_Case = 1 WHERE:
  BI_DB_SF_Cases_Panel.ActionType_AtOpen LIKE '%AML%'
  AND TicketStatus NOT IN ('Closed', 'Solved')
  AND CID_Last = customer CID
```
Currently 0 for all rows (no open ASIC high-risk AML cases as of 2026-04-22).

---

## 3. Query Advisory

- **Primary filter**: `Has_Open_AML_Case = 1` for active case management (currently empty; monitor for non-zero values).
- **Migration cohort**: `Has_Changed_Regulation = 1` identifies 571 customers who switched to ASIC. Use `Pre_Regulation_Change` for origin jurisdiction.
- **Verification priority**: `VerificationLevelID = 2` (65%) are partially-verified high-risk customers — likely highest-priority for KYC completion outreach.
- **PlayerStatus filter**: `PlayerStatus = 'Pending Verification'` (61%) — these customers are restricted from trading but are depositors pending KYC completion.
- **No date parameter**: SP always produces a full snapshot of the current ASIC high-risk population. No historical data retained.
- **Equity = 0**: Legitimate for customers with no active positions. `Total_Deposits > 0` still applies given IsDepositor=1 filter.
- **ROUND_ROBIN HEAP**: Small table (4K rows) — full scans are cheap; no join optimization needed.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer identifier (Dim_Customer.RealCID). Primary key for this table. All customers are ASIC-regulated, high-risk, depositor, at least partially KYC-verified. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 2 | Regulation | varchar(250) | YES | Regulatory entity from Dim_Regulation. Always 'ASIC' or 'ASIC & GAML' (population filter: DWHRegulationID IN (4, 10)). Distribution: ASIC & GAML 71%, ASIC 29%. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_Regulation) |
| 3 | KYC_Country | varchar(250) | YES | Country of residence name from Dim_Country (joined via Dim_Customer.CountryID). Top countries: Australia 40%, Thailand 9%, Morocco 8%, Vietnam 7%, Saudi Arabia 6%. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_Country) |
| 4 | PlayerStatus | varchar(250) | YES | Account restriction status from Dim_PlayerStatus. Population excludes Blocked (2) and Blocked Upon Request (4). Distribution: Pending Verification 61%, Normal 18%, Block Deposit & Trading 18%, Trade & MIMO Blocked 3%. (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_PlayerStatus) |
| 5 | Club | varchar(250) | YES | eToro Club loyalty tier from Dim_PlayerLevel. 97% Bronze (high-risk ASIC population has low engagement/wealth). (Tier 1 — DWH_dbo.Dim_Customer wiki via Dim_PlayerLevel) |
| 6 | RegisteredReal | datetime | YES | Customer registration timestamp from Dim_Customer.RegisteredReal. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 7 | FirstDepositDate | datetime | YES | Date and time of first deposit from Dim_Customer.FirstDepositDate. Observed range: 2008-12-14 to 2026-04-12. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 8 | FirstDepositAmount | money | YES | First deposit amount in USD from Dim_Customer.FirstDepositAmount. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 9 | VerificationLevelID | int | YES | KYC verification level from Dim_Customer. Population filter: ≥2. Distribution: Level 2 (65% — identity-verified, partial KYC), Level 3 (35% — fully verified). For ASIC high-risk customers, Level 2 represents the primary compliance gap population. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 10 | HasWallet | int | YES | 1 if customer has an active eToro Money wallet product from Dim_Customer. 96% = 0 in this population. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 11 | RiskScoreName | varchar(250) | YES | AML risk classification from External_RiskClassification_dbo_V_RiskClassificationDataLake. Always 'High' — a population filter, not a variable field. The column serves as an audit trail of the filter applied. (Tier 2 — SP_AML_ASIC_Dashboard via External_RiskClassification) |
| 12 | Total_Deposits | money | YES | Cumulative all-time deposit total (USD) from Fact_CustomerAction (ActionTypeID=7 Deposits). 0 if no deposit action records found (ISNULL applied). Average: ~$11,537. (Tier 2 — SP_AML_ASIC_Dashboard via Fact_CustomerAction) |
| 13 | Equity | money | YES | Total economic exposure yesterday: ISNULL(Liabilities,0) + ISNULL(ActualNWA,0) from DWH_dbo.V_Liabilities. 0 if customer not in V_Liabilities (no active positions). Average: ~$2,705. (Tier 2 — SP_AML_ASIC_Dashboard via DWH_dbo.V_Liabilities) |
| 14 | Has_Changed_Regulation | int | YES | 1 if customer migrated TO ASIC/ASIC&GAML FROM a prior regulation (excluding BVI and None). 0 if always ASIC. 13% of population (571 customers). (Tier 2 — SP_AML_ASIC_Dashboard via Fact_SnapshotCustomer LAG-based change detection) |
| 15 | Last_Regulation_Change_Date | date | YES | Date of the most recent qualifying regulation switch to ASIC/ASIC&GAML. NULL if Has_Changed_Regulation = 0. (Tier 2 — SP_AML_ASIC_Dashboard via Fact_SnapshotCustomer) |
| 16 | Pre_Regulation_Change | varchar(250) | YES | Regulation held before the most recent switch to ASIC. Observed values: CySEC (majority of migration cohort), FCA, eToroUS, FSA Seychelles. NULL if Has_Changed_Regulation = 0. (Tier 2 — SP_AML_ASIC_Dashboard via Fact_SnapshotCustomer) |
| 17 | Has_Open_AML_Case | int | YES | 1 if customer has an open Salesforce AML case (ActionType_AtOpen LIKE '%AML%' AND TicketStatus NOT IN ('Closed','Solved')). Currently 0 for all 4,307 records — no open ASIC high-risk AML cases as of 2026-04-22. (Tier 2 — SP_AML_ASIC_Dashboard via BI_DB_dbo.BI_DB_SF_Cases_Panel) |
| 18 | UpdateDate | datetime | YES | ETL load timestamp set to GETDATE() at SP execution time. Not a business event timestamp. (Tier 5 — ETL metadata propagation blacklist) |

---

## 5. Lineage

### 5.1 Sources

| Source | Schema | Role |
|--------|--------|------|
| Dim_Customer | DWH_dbo | Core population: RealCID, RegisteredReal, FirstDepositDate, FirstDepositAmount, VerificationLevelID, HasWallet, CountryID, RegulationID, PlayerStatusID, PlayerLevelID |
| Dim_Regulation | DWH_dbo | Regulation name decode; JOIN filter on DWHRegulationID IN (4, 10) |
| Dim_Country | DWH_dbo | KYC_Country name decode via Dim_Customer.CountryID |
| Dim_PlayerStatus | DWH_dbo | PlayerStatus name decode; filter NOT IN (2, 4) |
| Dim_PlayerLevel | DWH_dbo | Club name decode |
| External_RiskClassification_dbo_V_RiskClassificationDataLake | BI_DB_dbo | Risk score; JOIN filter on RiskScoreName='High' |
| V_Liabilities | DWH_dbo | Equity computation (Liabilities + ActualNWA for yesterday) |
| Fact_CustomerAction | DWH_dbo | Total_Deposits: SUM(Amount) where ActionTypeID=7 |
| Fact_SnapshotCustomer | DWH_dbo | Regulation change history via LAG over DateRangeID |
| Dim_Range | DWH_dbo | Convert DateRangeID → FromDateID (regulation change dates) |
| BI_DB_SF_Cases_Panel | BI_DB_dbo | Salesforce AML case tracking (open cases flag) |

### 5.2 ETL Pipeline

```
Dim_Customer
  JOIN Dim_Regulation (RegulationID IN 4,10)
  JOIN Dim_Country
  JOIN Dim_PlayerStatus (NOT IN 2,4)
  JOIN Dim_PlayerLevel
  JOIN External_RiskClassification (RiskScoreName='High')
  WHERE IsValidCustomer=1, IsDepositor=1, VerificationLevelID>=2
       |
       v
  #pop  (base population: ASIC high-risk depositors)
       |
       +-- V_Liabilities (DateID=yesterday)
       |    → #equity  (Liabilities + ActualNWA per CID)
       |
       +-- Fact_CustomerAction (ActionTypeID=7, SUM all-time)
       |    → #deposits  (Total_Deposits per CID)
       |
       +-- Fact_SnapshotCustomer
       |    LAG(RegulationID) OVER (PARTITION BY RealCID ORDER BY DateRangeID)
       |    → #status01  (all regulation changes)
       |    → #status02  (+ DaysBetweenChanges)
       |    → #status03  (latest change TO ASIC FROM non-ASIC/non-BVI; ROW_NUMBER DESC)
       |
       +-- BI_DB_SF_Cases_Panel
            (ActionType_AtOpen LIKE '%AML%', NOT Closed/Solved)
            → #amlSF  (distinct CIDs with open AML case)
       |
       v
  #final  (LEFT JOIN all above; compute Has_Changed_Regulation, Has_Open_AML_Case)
       |
       v
  TRUNCATE TABLE BI_DB_AML_ASIC_Dashboard
  INSERT INTO    BI_DB_AML_ASIC_Dashboard  (full refresh)
```

---

## 6. Data Quality Notes

| Issue | Severity | Detail |
|-------|----------|--------|
| `Has_Open_AML_Case` = 0 for all rows | INFO | Either no ASIC high-risk customers have open Salesforce AML cases currently, or the BI_DB_SF_Cases_Panel join criteria matches no records. Monitor if this column ever produces non-zero values. |
| `RiskScoreName` has no variation | INFO | Always 'High' — column is not useful for filtering/grouping; it documents the population filter. |
| 61% `Pending Verification` population | INFO | High proportion of partially-verified (VerificationLevelID=2) customers suggests this is the primary KYC completion target pool for ASIC AML compliance. |
| `Equity` sourced from yesterday | INFO | `V_Liabilities` is joined for DateID = GETDATE()-1. Intraday position changes not reflected. |

---

## 7. Relationships

| Related Table | Join Key | Relationship |
|--------------|----------|-------------|
| `DWH_dbo.Dim_Customer` | CID = RealCID | Customer master |
| `BI_DB_dbo.BI_DB_SF_Cases_Panel` | CID = CID_Last | Salesforce case tracking (AML open case flag) |
| `BI_DB_dbo.External_RiskClassification_dbo_V_RiskClassificationDataLake` | CID | AML risk score source |
| `DWH_dbo.Fact_SnapshotCustomer` | CID = RealCID | Regulation change history |

---

## 8. Atlassian

No direct Confluence documentation found for this specific table. Context:
- ASIC (Australian Securities and Investments Commission) regulatory requirements and AML obligations documented in eToro's Compliance space.
- `External_RiskClassification_dbo_V_RiskClassificationDataLake` sources the High/Medium/Low risk classifications from the RiskClassification database. Confirm with the AML Compliance team for risk scoring methodology documentation.
