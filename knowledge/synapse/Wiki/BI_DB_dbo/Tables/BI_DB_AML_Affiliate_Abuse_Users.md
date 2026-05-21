# BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Users

> CID-level affiliate abuse risk profile table — 1,208,122 rows of enriched customer records for activated affiliate customers registered since 2023, with equity snapshot, 30-day activity flags, and demographic data. Part of the AML Affiliate Abuse monitoring suite written by SP_AML_Affiliate_Abuse (disabled 2024-12-31); data is frozen.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Dim_Customer + V_Liabilities + Fact_BillingWithdraw + Fact_BillingDeposit + Dim_Position + Dim_Affiliate + Dim_Country + Dim_Regulation + Dim_PlayerLevel + BI_DB_First5Actions |
| **Refresh** | DISABLED (SP_AML_Affiliate_Abuse disabled 2024-12-31 per BI team request) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **Writer SP** | SP_AML_Affiliate_Abuse |
| **UC Target** | Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **OpsDB Priority** | Not in OpsDB |

---

## 1. Business Meaning

`BI_DB_AML_Affiliate_Abuse_Users` is the customer-level (CID-level) backbone of the AML Affiliate Abuse monitoring suite. It contains **1,208,122 rows** — one row per customer — enriched with demographic attributes, equity snapshot, 30-day post-FTD activity flags, and first trading action details. It is the table an analyst would query to drill from an affiliate-level risk signal (from `BI_DB_AML_Affiliate_Abuse_Agg` or `BI_DB_AML_Affiliate_Abuse_SameIP`) down to the individual customers at risk.

The population is restricted to **activated affiliate customers** (SubChannelID IN 20,31,39,40,41,42,44) who registered as real customers on or after 2023-01-01. The equity snapshot is pinned to @DateID = 2024-12-30 (the day before SP disable). The 30-day flags (`Is_CO_30`, `Is_Dep_30`, `Is_Open_Trade_30`) capture whether the customer engaged in cashout, deposit, or position activity within 30 days of their First Deposit Date — a key AML indicator for rapid withdrawal after deposit.

**The SP was permanently disabled on 2024-12-31** at the request of Lior Ben Dor from the BI team. The table is a frozen historical snapshot reflecting the state as of 2024-12-31.

The ETL pipeline:

```
DWH_dbo.Dim_Customer (RealCID, demographics, AffiliateID)
  JOIN DWH_dbo.Dim_Affiliate (SubChannelID filter)
  JOIN DWH_dbo.Dim_PlayerStatus, Dim_Regulation, Dim_Country, Dim_PlayerLevel
  LEFT JOIN BI_DB_dbo.BI_DB_First5Actions ON CID
  |-- #cidlevel (1.2M+ activated affiliate customers, RegisteredReal>=2023-01-01) ---|
  v
DWH_dbo.V_Liabilities (DateID=2024-12-30) INNER JOIN → equity snapshot
  |-- #liabilities ---|
  v
Fact_BillingWithdraw / Fact_BillingDeposit / Dim_Position (30d from FirstDepositDate)
  |-- #co_30, #dep_30, #position30 ---|
  v
#final_CID (all fields merged)
  |-- TRUNCATE + INSERT (SP disabled 2024-12-31) ---|
  v
BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Users (1,208,122 rows, frozen)
```

---

## 2. Business Logic

### 2.1 30-Day Activity Window (AML Rapid-Cash Signal)

**What**: Flags customers who performed financial activity within 30 days of their First Time Deposit.

**Columns Involved**: Is_CO_30, Is_Dep_30, Count_Positions_30, Is_Open_Trade_30

**Rules**:
- Window: FirstDepositDate to FirstDepositDate + 30 days
- `Is_CO_30`: 1 if any approved cashout (CashoutStatusID_Funding=3) within window, else 0
- `Is_Dep_30`: 1 if any approved deposit (PaymentStatusID=2) within window, else 0
- `Count_Positions_30`: COUNT DISTINCT PositionID opened within window (OpenOccurred >= 2023-01-01)
- `Is_Open_Trade_30`: CASE WHEN Count_Positions_30 ≠ 0 THEN 1 ELSE 0
- AML interpretation: Is_CO_30=1 with Is_Open_Trade_30=0 = "deposited and immediately withdrew without trading" — classic money mule pattern

### 2.2 Equity Snapshot (V_Liabilities)

**What**: Point-in-time financial position for each customer as of 2024-12-30.

**Columns Involved**: TotalEquity, RealizedEquity, PositionPnL, Credit, BonusCredit

**Rules**:
- Source: V_Liabilities with DateID = @DateID (2024-12-30)
- `TotalEquity` = ISNULL(Liabilities, 0) + ISNULL(ActualNWA, 0) — represents total financial exposure
- INNER JOIN to V_Liabilities: customers with no equity record are excluded from this table
- This means ~1.2M rows are customers who had financial activity at some point

### 2.3 Blocked Customer Classification

**What**: Identifies customers whose accounts have been restricted.

**Columns Involved**: Is_Blocked

**Rules**:
- `Is_Blocked` = CASE WHEN PlayerStatusID NOT IN (1, 5) THEN 1 ELSE 0
- PlayerStatusID=1 (Active) and PlayerStatusID=5 (Warning) are considered unblocked
- All other statuses (suspended, dormant, closed) are blocked
- AML use: blocked affiliates' customers may indicate prior compliance action

### 2.4 Age Sentinel

**What**: Customer age computed from birth date, with sentinel for missing values.

**Columns Involved**: User_Age

**Rules**:
- `User_Age` = DATEDIFF(YEAR, BirthDate, GETDATE())
- BirthDate = '1900-01-02' is the sentinel for unknown/missing birth date → User_Age = 0 (DATEDIFF from 1900 would be ~124, but the SP likely overwrites with 0 via CASE — confirm)
- Note: GETDATE() at SP runtime (2024-12-31) means ages reflect the last run date, not current date

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP. 1,208,122 rows — moderate table. Full scans are acceptable for targeted affiliate analysis but avoid Cartesian joins.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All customers for a specific affiliate | `WHERE AffiliateID = @id` |
| Mule pattern customers (deposit+cashout, no trade) | `WHERE Is_CO_30=1 AND Is_Open_Trade_30=0` |
| High-equity blocked customers by affiliate | `WHERE Is_Blocked=1 AND TotalEquity > 1000 ORDER BY TotalEquity DESC` |
| Customers by country for an affiliate | `GROUP BY Country, COUNT(*)` |
| Non-depositors in affiliate pool | `WHERE IsDepositor=0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_AML_Affiliate_Abuse_Agg | ON AffiliateID, Channel | Add monthly risk aggregates to CID analysis |
| BI_DB_AML_Affiliate_Abuse_Aff_data | ON AffiliateID, Channel | Add contract/profitability context |
| BI_DB_AML_Affiliate_Abuse_SameIP | ON AffiliateID | Identify if this customer is on a shared-IP affiliate |
| DWH_dbo.Dim_Affiliate | ON AffiliateID | Additional affiliate attributes |

### 3.4 Gotchas

- **Data is frozen**: Equity snapshot at 2024-12-30; registration scope up to 2024-12-31. Do NOT use for current monitoring.
- **User_Age is as of 2024-12-31**: Ages do not update. A 2023-registered customer's age is from the last SP run.
- **FirstDepositDate sentinel**: 1900-01-01 = customer has never deposited. The 30-day window calculations for such customers should produce NULL or 0.
- **Is_Blocked logic**: PlayerStatusID NOT IN (1,5) = blocked. The IN list may not cover all "safe" statuses — confirm with BI team if PlayerStatusID=5 (Warning) truly should be unblocked.
- **V_Liabilities INNER JOIN**: Customers with no equity record are missing. If an analyst expects all 2023+ affiliate registrants but gets fewer, this join is the likely cause.
- **EOM_FTD and EOM_Reg**: EOMONTH() of FirstDepositDate and RegisteredReal — last day of the respective month. Useful for cohort-month analysis without datetime comparison.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream DWH_dbo wiki (canonical source for BI_DB) |
| Tier 2 | Derived from SP code analysis or intermediate DWH dimension |
| Tier 5 | ETL infrastructure — canonical description applies universally |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | AffiliateID | int | YES | Unique affiliate partner identifier from AffWizz system. Primary key of Dim_Affiliate. Groups CID-level risk profiles by affiliate channel. (Tier 2 — SP_AML_Affiliate_Abuse Step 03 via Dim_Customer) |
| 2 | Channel | varchar(500) | YES | Marketing channel classification. Values: Affiliate, Media Performance, Mobile Acquisition, Media Programmatic, Content Partnerships. Passthrough from Dim_Affiliate via JOIN on AffiliateID. (Tier 2 — SP_AML_Affiliate_Abuse Step 03 via Dim_Affiliate) |
| 3 | SubChannel | varchar(500) | YES | Sub-classification within the Channel. More granular than Channel. Passthrough from Dim_Affiliate via JOIN on AffiliateID. (Tier 2 — SP_AML_Affiliate_Abuse Step 03 via Dim_Affiliate) |
| 4 | CID | int | YES | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Aliased from DWH_dbo.Dim_Customer.RealCID. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 5 | FirstDepositDate | datetime | YES | Date and time of the customer's first deposit. Sentinel value 1900-01-01 00:00:00 indicates no deposit has been made. Passthrough from Dim_Customer. (Tier 2 — DWH_dbo.Dim_Customer wiki) |
| 6 | EOM_FTD | date | YES | Last day of the month in which the customer made their first deposit: EOMONTH(FirstDepositDate). Used for cohort-month binning. NULL if never deposited (1900-01-01 sentinel propagates). (Tier 2 — SP_AML_Affiliate_Abuse Step 03) |
| 7 | RegisteredReal | datetime | YES | Datetime when the customer completed real account registration (as distinct from demo). Restricted to >= 2023-01-01 in this table. Passthrough from Dim_Customer. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 8 | EOM_Reg | date | YES | Last day of the month in which the customer registered: EOMONTH(RegisteredReal). Used for registration cohort analysis. (Tier 2 — SP_AML_Affiliate_Abuse Step 03) |
| 9 | FirstDepositAmount | float | YES | Amount of the customer's first deposit. 0 or NULL if no deposit. Passthrough from Dim_Customer. (Tier 2 — DWH_dbo.Dim_Customer wiki) |
| 10 | VerificationLevelID | int | YES | KYC verification level: 0=unverified, 1=partial, 2=intermediate, 3=fully verified. Passthrough from Dim_Customer. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 11 | IsValidCustomer | bit | YES | 1 if customer passes basic validity checks (not internal/test/blocked at registration). Passthrough from Dim_Customer. (Tier 2 — DWH_dbo.Dim_Customer wiki) |
| 12 | IsDepositor | bit | YES | 1 if customer has made at least one approved deposit. 0 for non-depositors. Passthrough from Dim_Customer. (Tier 2 — DWH_dbo.Dim_Customer wiki) |
| 13 | User_Age | int | YES | Customer age in years, computed as DATEDIFF(YEAR, BirthDate, GETDATE()) at SP runtime (2024-12-31). BirthDate='1900-01-02' sentinel for unknown birth date → 0. Ages reflect last SP run, not current date. (Tier 2 — SP_AML_Affiliate_Abuse Step 03 via Dim_Customer.BirthDate) |
| 14 | Gender | varchar | YES | Customer-declared gender: M, F, or U (Unknown). Passthrough from Dim_Customer. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 15 | IP | varchar | YES | Registration IP address of the customer. Used in BI_DB_AML_Affiliate_Abuse_SameIP for IP clustering analysis. Passthrough from Dim_Customer. (Tier 1 — DWH_dbo.Dim_Customer wiki) |
| 16 | Country | varchar(500) | YES | Full country name in English, resolved from Dim_Country via CountryID. Passthrough from Dim_Country.Name. (Tier 1 — DWH_dbo.Dim_Country wiki) |
| 17 | Region | varchar(500) | YES | Manual override name for the marketing region: Dim_Country.MarketingRegionManualName. Broad geographic grouping above country level. (Tier 2 — DWH_dbo.Dim_Country wiki) |
| 18 | Regulation | varchar(500) | YES | Short code for the regulatory entity under which the customer is governed (e.g., FCA, CySEC). From Dim_Regulation.Name via DWHRegulationID. (Tier 1 — DWH_dbo.Dim_Regulation wiki) |
| 19 | Club | varchar(500) | YES | Customer loyalty tier: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. From Dim_PlayerLevel.Name via PlayerLevelID. (Tier 1 — DWH_dbo.Dim_PlayerLevel wiki) |
| 20 | Is_Blocked | int | YES | 1 if customer account is restricted/blocked (PlayerStatusID NOT IN (1,5)); 0 if active or warning. (Tier 2 — SP_AML_Affiliate_Abuse Step 03 via Dim_Customer.PlayerStatusID) |
| 21 | TotalEquity | float | YES | Total financial exposure: ISNULL(Liabilities,0) + ISNULL(ActualNWA,0) from V_Liabilities as of 2024-12-30. Represents the customer's combined liabilities and net worth adjustment. (Tier 2 — SP_AML_Affiliate_Abuse Step 04 via V_Liabilities) |
| 22 | RealizedEquity | float | YES | Realized equity component from V_Liabilities as of 2024-12-30. Excludes unrealized P&L from open positions. Passthrough from V_Liabilities. (Tier 2 — SP_AML_Affiliate_Abuse Step 04 via V_Liabilities) |
| 23 | PositionPnL | float | YES | Unrealized profit/loss on open positions from V_Liabilities as of 2024-12-30. Passthrough from V_Liabilities. (Tier 2 — SP_AML_Affiliate_Abuse Step 04 via V_Liabilities) |
| 24 | Credit | float | YES | Credit balance from V_Liabilities as of 2024-12-30. Company-provided credit (not customer funds). Passthrough from V_Liabilities. (Tier 2 — SP_AML_Affiliate_Abuse Step 04 via V_Liabilities) |
| 25 | BonusCredit | float | YES | Bonus credit balance from V_Liabilities as of 2024-12-30. Promotional credits. Passthrough from V_Liabilities. (Tier 2 — SP_AML_Affiliate_Abuse Step 04 via V_Liabilities) |
| 26 | Is_CO_30 | int | YES | 1 if customer made at least one approved cashout (CashoutStatusID_Funding=3) within 30 days of their FirstDepositDate; else 0. AML signal: early cashout before trading. (Tier 2 — SP_AML_Affiliate_Abuse Step 05 via Fact_BillingWithdraw) |
| 27 | Is_Dep_30 | int | YES | 1 if customer made at least one approved deposit (PaymentStatusID=2) within 30 days of their FirstDepositDate; else 0. Confirms deposit activity post-FTD. (Tier 2 — SP_AML_Affiliate_Abuse Step 05 via Fact_BillingDeposit) |
| 28 | Count_Positions_30 | int | YES | Count of distinct positions (PositionID) opened within 30 days of FirstDepositDate (OpenOccurred >= 2023-01-01). 0 if no positions opened in window. (Tier 2 — SP_AML_Affiliate_Abuse Step 05 via Dim_Position) |
| 29 | Is_Open_Trade_30 | int | YES | 1 if Count_Positions_30 > 0 (customer opened at least one position within 30 days of FTD); else 0. AML signal complement to Is_CO_30: is the customer actually trading? (Tier 2 — SP_AML_Affiliate_Abuse Step 06 via #final_CID) |
| 30 | FirstAction | varchar | YES | Asset class of the customer's first open position: Crypto, FX, Stocks-ETFs, Copy Fund, Copy. NULL if no position has been opened (~88.3% of eToro customers). From BI_DB_First5Actions. (Tier 2 — BI_DB_First5Actions wiki) |
| 31 | FirstActionDate | datetime | YES | Datetime of the customer's first open position. NULL if no position. From BI_DB_First5Actions. (Tier 2 — BI_DB_First5Actions wiki) |
| 32 | FirstInstrument | varchar | YES | Display name of the first instrument traded (e.g., "Bitcoin", "Tesla"). NULL if no position. From BI_DB_First5Actions. (Tier 2 — BI_DB_First5Actions wiki) |
| 33 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last inserted. All rows show 2024-12-31 — the date the SP was last run before being disabled. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| AffiliateID | DWH_dbo.Dim_Customer | AffiliateID | passthrough |
| Channel | DWH_dbo.Dim_Affiliate | Channel | passthrough via JOIN on AffiliateID |
| SubChannel | DWH_dbo.Dim_Affiliate | SubChannel | passthrough via JOIN on AffiliateID |
| CID | DWH_dbo.Dim_Customer | RealCID | passthrough (aliased as CID) |
| FirstDepositDate | DWH_dbo.Dim_Customer | FirstDepositDate | passthrough; 1900-01-01 sentinel for non-depositors |
| EOM_FTD | SP computation | FirstDepositDate | EOMONTH(FirstDepositDate) |
| RegisteredReal | DWH_dbo.Dim_Customer | RegisteredReal | passthrough |
| EOM_Reg | SP computation | RegisteredReal | EOMONTH(RegisteredReal) |
| FirstDepositAmount | DWH_dbo.Dim_Customer | FirstDepositAmount | passthrough |
| VerificationLevelID | DWH_dbo.Dim_Customer | VerificationLevelID | passthrough |
| IsValidCustomer | DWH_dbo.Dim_Customer | IsValidCustomer | passthrough |
| IsDepositor | DWH_dbo.Dim_Customer | IsDepositor | passthrough |
| User_Age | DWH_dbo.Dim_Customer | BirthDate | DATEDIFF(YEAR, BirthDate, GETDATE()); sentinel 1900-01-02 → 0 |
| Gender | DWH_dbo.Dim_Customer | Gender | passthrough |
| IP | DWH_dbo.Dim_Customer | IP | passthrough |
| Country | DWH_dbo.Dim_Country | Name | passthrough via JOIN on CountryID |
| Region | DWH_dbo.Dim_Country | MarketingRegionManualName | passthrough via JOIN on CountryID |
| Regulation | DWH_dbo.Dim_Regulation | Name | passthrough via DWHRegulationID=RegulationID |
| Club | DWH_dbo.Dim_PlayerLevel | Name | passthrough via PlayerLevelID |
| Is_Blocked | SP computation | Dim_Customer.PlayerStatusID | CASE WHEN NOT IN (1,5) THEN 1 ELSE 0 |
| TotalEquity | DWH_dbo.V_Liabilities | Liabilities + ActualNWA | ISNULL(Liabilities,0) + ISNULL(ActualNWA,0) |
| RealizedEquity | DWH_dbo.V_Liabilities | RealizedEquity | passthrough |
| PositionPnL | DWH_dbo.V_Liabilities | PositionPnL | passthrough |
| Credit | DWH_dbo.V_Liabilities | Credit | passthrough |
| BonusCredit | DWH_dbo.V_Liabilities | BonusCredit | passthrough |
| Is_CO_30 | DWH_dbo.Fact_BillingWithdraw | WithdrawID | 1 if any approved CO (CashoutStatusID_Funding=3) within 30d of FTD |
| Is_Dep_30 | DWH_dbo.Fact_BillingDeposit | DepositID | 1 if any approved deposit (PaymentStatusID=2) within 30d of FTD |
| Count_Positions_30 | DWH_dbo.Dim_Position | PositionID | COUNT DISTINCT positions opened within 30d of FTD |
| Is_Open_Trade_30 | SP computation | Count_Positions_30 | CASE Count_Positions_30 ≠ 0 THEN 1 ELSE 0 |
| FirstAction | BI_DB_dbo.BI_DB_First5Actions | FirstAction | passthrough via LEFT JOIN on CID |
| FirstActionDate | BI_DB_dbo.BI_DB_First5Actions | FirstActionDate | passthrough via LEFT JOIN on CID |
| FirstInstrument | BI_DB_dbo.BI_DB_First5Actions | FirstInstrument | passthrough via LEFT JOIN on CID |
| UpdateDate | ETL | — | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Customer (RegisteredReal >= 2023-01-01)
  JOIN Dim_Affiliate (SubChannelID IN 20,31,39,40,41,42,44)
  JOIN Dim_PlayerStatus, Dim_Regulation, Dim_Country, Dim_PlayerLevel
  LEFT JOIN BI_DB_First5Actions ON CID
  |-- SP Step 03: #cidlevel ---|
  v
DWH_dbo.V_Liabilities (DateID=2024-12-30) INNER JOIN
  |-- SP Step 04: #liabilities ---|
  v
Fact_BillingWithdraw (CashoutStatusID_Funding=3, within 30d of FTD) → Is_CO_30
Fact_BillingDeposit (PaymentStatusID=2, within 30d of FTD) → Is_Dep_30
Dim_Position (OpenOccurred within 30d of FTD, >=2023-01-01) → Count_Positions_30
  |-- SP Step 05: #co_30, #dep_30, #position30 ---|
  v
Is_Open_Trade_30 = CASE Count_Positions_30 ≠ 0
  |-- SP Step 06: #final_CID ---|
  v
TRUNCATE + INSERT (SP disabled 2024-12-31)
  v
BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Users (1,208,122 rows, frozen)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| AffiliateID | DWH_dbo.Dim_Affiliate | Affiliate partner master |
| CID | DWH_dbo.Dim_Customer | Customer master |
| AffiliateID + Channel | BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Agg | Monthly aggregated risk signals for same affiliate |
| AffiliateID + Channel | BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Aff_data | Contract/profitability context |
| AffiliateID | BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_SameIP | IP clustering signals for same affiliate |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers (SP was disabled; AML monitoring suite decommissioned).

---

## 7. Sample Queries

### Money mule pattern: deposited + cashed out without trading, within 30 days

```sql
SELECT
    AffiliateID,
    Channel,
    CID,
    Country,
    Regulation,
    FirstDepositDate,
    FirstDepositAmount,
    TotalEquity,
    Is_CO_30,
    Is_Dep_30,
    Is_Open_Trade_30,
    VerificationLevelID,
    Is_Blocked
FROM [BI_DB_dbo].[BI_DB_AML_Affiliate_Abuse_Users]
WHERE Is_CO_30 = 1
  AND Is_Open_Trade_30 = 0
  AND IsDepositor = 1
ORDER BY FirstDepositAmount DESC
```

### Blocked high-equity customers by affiliate

```sql
SELECT
    AffiliateID,
    Channel,
    CID,
    Country,
    TotalEquity,
    RealizedEquity,
    VerificationLevelID,
    Club
FROM [BI_DB_dbo].[BI_DB_AML_Affiliate_Abuse_Users]
WHERE Is_Blocked = 1
  AND TotalEquity > 5000
ORDER BY AffiliateID, TotalEquity DESC
```

### Customer breakdown by regulation and country for a specific affiliate

```sql
SELECT
    Regulation,
    Country,
    COUNT(*) AS customer_count,
    SUM(IsDepositor) AS depositors,
    AVG(CAST(TotalEquity AS FLOAT)) AS avg_equity
FROM [BI_DB_dbo].[BI_DB_AML_Affiliate_Abuse_Users]
WHERE AffiliateID = @affiliate_id
GROUP BY Regulation, Country
ORDER BY customer_count DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. The AML Affiliate Abuse suite was internally tracked — refer to BI team communications with Lior Ben Dor (2024-12-31 disable request).

---

*Generated: 2026-04-23 | Quality: 9.0/10 | Phases: 11/14*
*Tiers: 10 T1, 22 T2, 0 T3, 0 T4, 1 T5 | Elements: 33/33*
*Object: BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Users | Type: Table | Production Source: SP_AML_Affiliate_Abuse (DISABLED 2024-12-31)*
