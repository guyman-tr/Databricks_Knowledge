# BI_DB_dbo.BI_DB_Crypto_Top_1000_List

> Static outreach list of exactly 1,000 eToro crypto clients with low revenue between 2023-08-01 and 2023-11-15, rebuilt daily by SP_Crypto_Top_1000_List (Author: Jan Iablunovskey, 2023-11-08) from a hardcoded CID IN-list via TRUNCATE + INSERT; provides account manager engagement attributes to support win-back campaigns.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Campaign Target List) |
| **Production Source** | BI_DB_CID_MonthlyPanel_FullData + BI_DB_CIDFirstDates + BI_DB_DailyCommisionReport + BI_DB_UsageTracking_SF + Dim_Position |
| **Writer SP** | SP_Crypto_Top_1000_List |
| **Refresh** | Daily — TRUNCATE + INSERT (full replace, @Date parameter) |
| **Row Count** | Exactly 1,000 (one row per CID); last loaded 2026-04-27 |
| **Date Range** | Static — no date grain; attributes as of @BeginOfMonth |
| **Synapse Distribution** | HASH(CID) |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Crypto_Top_1000_List` is a daily-refreshed outreach target list for account managers, containing exactly 1,000 high-value crypto clients whose crypto revenue (FullCommissions + RollOverFee on InstrumentTypeID=10) was between $0 and $1,000 in the window 2023-08-01 to 2023-11-15. The 1,000 CIDs are **hardcoded** in SP_Crypto_Top_1000_List (identified via a TOP 1,000 query run in November 2023 and frozen). Revenue metrics span two date windows: 2023-08-01–2023-11-15 (original cohort selection window) and 2023-12-01 to present (campaign response tracking). Customer attributes — equity, club, region, account manager, last contact, last crypto position — are refreshed daily from current BI_DB_dbo/DWH_dbo sources, so AMs see live engagement context. Equity ranges from -$1,954 to $6,472,324 (mean ~$141K); all 1,000 CIDs have prior crypto positions (null_last_crypto=0). 19 of 1,000 CIDs have never been contacted via Salesforce.

---

## 2. Business Logic

### 2.1 Hardcoded Population — Campaign Cohort

**What**: The 1,000 target CIDs are fixed in SP code; no dynamic selection runs each day.

**Columns Involved**: CID

**Rules**:
- #List = `SELECT * FROM Dim_Customer WHERE RealCID IN (<1000 literal IDs>)`
- Original cohort criteria (not re-evaluated daily): InstrumentTypeID=10 revenue between $0 and $1,000 for DateID 20230801–20231115, ordered by lifetime crypto revenue DESC, TOP 1,000
- List was revised 2023-11-23 "due to calculation change"
- TRUNCATE on every run means any CID departing the 1,000 list would be dropped, but the list is static

### 2.2 Revenue Window Logic

**What**: Two distinct revenue accumulation periods per CID, both sourced from BI_DB_DailyCommisionReport.

**Columns Involved**: ACC_Revenue_Crypto, Revenue_Crypto_from_20230801, Revenue_Crypto_from_20231201

**Rules**:
```
ACC_Revenue_Crypto          = SUM(FullCommissions + RollOverFee) WHERE InstrumentTypeID=10   [all time]
Revenue_Crypto_from_20230801 = SUM(...) WHERE InstrumentTypeID=10 AND DateID BETWEEN 20230801 AND 20231115
Revenue_Crypto_from_20231201 = SUM(...) WHERE InstrumentTypeID=10 AND DateID >= 20231201
```
- Revenue_Crypto_from_20231201 has no end-date filter; it grows each daily refresh

---

## 3. Query Advisory

### 3.1 Distribution & Index

HASH(CID) with HEAP. No clustered index — table has exactly 1,000 rows so full scans are trivial. All 1,000 rows are co-located with other HASH(CID) tables in BI_DB_dbo.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All 1,000 targets with attributes | `SELECT * FROM BI_DB_Crypto_Top_1000_List` |
| By marketing region | `WHERE Region = 'UK'` (13 distinct values) |
| Uncontacted targets | `WHERE LastContacted IS NULL` (19 CIDs) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Customer | ON CID = RealCID | Full customer profile |
| BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData | ON CID AND ActiveDate | Monthly panel enrichment |

### 3.4 Gotchas

- **Hardcoded CID list**: The 1,000 targets were frozen in November 2023; daily refresh only updates attributes, not the population.
- **Revenue_Crypto_from_20231201 grows daily**: No end-date cap — values increase with every daily load.
- **Revenue_Crypto_from_20230801 is a fixed window**: DateID 20230801–20231115 only; will not change as historical data is stable.
- **HEAP with no index**: Efficient for this 1,000-row table; do not add an index without understanding the distribution.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag |
|------|-----|
| Tier 1 — upstream wiki verbatim passthrough | (Tier 1 — source) |
| Tier 2 — ETL-computed in SP_Crypto_Top_1000_List | (Tier 2 — SP_Crypto_Top_1000_List) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer ID — platform-internal primary key. Identifies the depositor. HASH distribution key. Equivalent to DWH_dbo.Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | GCID | int | YES | Group Customer ID — cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. (Tier 1 — Customer.CustomerStatic) |
| 3 | Region | nvarchar(50) | YES | Marketing region label (newer vintage than Region). Values observed: UK=293, German=182, Arabic=127, French=64, CEE=62, SEA=56, Spain=44, Italian=41, Nordics=36, Australia=33, USA=24, Latam=23, ROW=15. Renamed from NewMarketingRegion in BI_DB_CID_MonthlyPanel_FullData. (Tier 2 — BI_DB_CID_MonthlyPanel_FullData.NewMarketingRegion) |
| 4 | AccountManager | nvarchar(150) | YES | Name of the assigned account manager at ETL run time. (Tier 1 — DWH_dbo.Dim_Customer) |
| 5 | Club | nvarchar(50) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup from Dim_PlayerLevel.Name via PlayerLevelID. Observed: Diamond=401, Platinum Plus=313, Platinum=95, Bronze=88, Gold=73, Silver=30. (Tier 1 — Dictionary.PlayerLevel) |
| 6 | LastLoggedIn | date | YES | Date of the customer's last login before end of this month. (Tier 1 — DWH_dbo.Dim_Customer) |
| 7 | LastDepositDate | date | YES | Most recent deposit date. From Fact_BillingDeposit.ModificationDate for today's deposits. CAST from datetime to DATE. (Tier 2 — BI_DB_CIDFirstDates) |
| 8 | LastPosOpenDate | date | YES | Most recent position open timestamp. MAX(Occurred) from Fact_CustomerAction WHERE ActionTypeID IN (1,2). CAST from datetime to DATE. (Tier 2 — BI_DB_CIDFirstDates) |
| 9 | LastContacted | date | YES | Last date of a successful CRM contact (phone or email). MAX(CAST(CreatedDate AS DATE)) from BI_DB_UsageTracking_SF WHERE ActionName IN ('Phone_Call_Succeed__c','Completed_Contact_Email__c'). NULL for 19 of 1,000 CIDs. (Tier 2 — SP_Crypto_Top_1000_List) |
| 10 | LastCryptoPosOpenDate | date | YES | Last date a manual crypto position was opened. MAX(CAST(OpenOccurred AS DATE)) from Dim_Position WHERE InstrumentTypeID=10 AND MirrorID=0. All 1,000 CIDs have a value (no NULLs). (Tier 2 — SP_Crypto_Top_1000_List) |
| 11 | Equity | decimal(19,4) | YES | Total account equity (USD) at end of month from V_Liabilities. Includes all open position unrealised PnL + cash balance. Renamed from EOM_Equity. Range observed: -$1,954 to $6,472,324 (mean ~$141K). (Tier 2 — BI_DB_CID_MonthlyPanel_FullData.EOM_Equity) |
| 12 | ACC_Revenue | decimal(19,4) | YES | Running lifetime accumulated revenue total (legacy formula: FullCommissions across all asset classes, excluding function fees). Renamed from ACC_Revenue_Total in BI_DB_CID_MonthlyPanel_FullData. Retained for historical comparability; use ACC_Revenue_Total_New in MonthlyPanel for current analysis. (Tier 2 — BI_DB_CID_MonthlyPanel_FullData.ACC_Revenue_Total) |
| 13 | ACC_Revenue_Crypto | decimal(19,4) | YES | Lifetime cumulative crypto revenue: SUM(FullCommissions + RollOverFee) WHERE InstrumentTypeID=10, all-time. Sourced from BI_DB_DailyCommisionReport filtered to the hardcoded CID list. Observed range: $27,128–$1,787,784. (Tier 2 — SP_Crypto_Top_1000_List) |
| 14 | Revenue_Crypto_from_20230801 | decimal(19,4) | YES | Crypto revenue (FullCommissions + RollOverFee, InstrumentTypeID=10) for the fixed window 2023-08-01 to 2023-11-15. This was the campaign cohort selection criterion (must be between $0 and $1,000). (Tier 2 — SP_Crypto_Top_1000_List) |
| 15 | Revenue_Crypto_from_20231201 | decimal(19,4) | YES | Crypto revenue (FullCommissions + RollOverFee, InstrumentTypeID=10) from 2023-12-01 to present (no end date). Tracks campaign response revenue. Added 2023-11-13. Grows with each daily refresh. (Tier 2 — SP_Crypto_Top_1000_List) |
| 16 | UpdateDate | datetime | NO | ETL execution timestamp — GETDATE() at SP_Crypto_Top_1000_List INSERT. All 1,000 rows share the same UpdateDate (single TRUNCATE+INSERT batch). (Tier 2 — SP_Crypto_Top_1000_List) |

---

## 5. Lineage

### 5.1 Production Sources

| Column | Source Object | Source Column | Transform |
|--------|---------------|---------------|-----------|
| CID | BI_DB_CID_MonthlyPanel_FullData | CID | Passthrough; filtered to 1,000 hardcoded CIDs |
| GCID | BI_DB_CIDFirstDates | GCID | Passthrough |
| Region | BI_DB_CID_MonthlyPanel_FullData | NewMarketingRegion | Rename |
| AccountManager | BI_DB_CID_MonthlyPanel_FullData | AccountManager | Passthrough |
| Club | BI_DB_CIDFirstDates | Club | Passthrough |
| LastLoggedIn | BI_DB_CID_MonthlyPanel_FullData | LastLoggedIn | Passthrough |
| LastDepositDate | BI_DB_CIDFirstDates | LastDepositDate | CAST to DATE |
| LastPosOpenDate | BI_DB_CIDFirstDates | LastPosOpenDate | CAST to DATE |
| LastContacted | BI_DB_UsageTracking_SF | CreatedDate | MAX(DATE) WHERE ActionName IN successful contacts |
| LastCryptoPosOpenDate | Dim_Position + Dim_Instrument | OpenOccurred | MAX(DATE) WHERE crypto instrument, manual |
| Equity | BI_DB_CID_MonthlyPanel_FullData | EOM_Equity | Rename |
| ACC_Revenue | BI_DB_CID_MonthlyPanel_FullData | ACC_Revenue_Total | Rename |
| ACC_Revenue_Crypto | BI_DB_DailyCommisionReport | FullCommissions, RollOverFee | SUM WHERE InstrumentTypeID=10 |
| Revenue_Crypto_from_20230801 | BI_DB_DailyCommisionReport | FullCommissions, RollOverFee | SUM WHERE InstrumentTypeID=10, DateID 20230801–20231115 |
| Revenue_Crypto_from_20231201 | BI_DB_DailyCommisionReport | FullCommissions, RollOverFee | SUM WHERE InstrumentTypeID=10, DateID >= 20231201 |
| UpdateDate | SP execution | — | GETDATE() |

### 5.2 ETL Pipeline

```
Hardcoded list of 1,000 CIDs (frozen 2023-11-23)
  │
  ├─ #List = DWH_dbo.Dim_Customer WHERE RealCID IN (<1000 IDs>)
  │
  ├─ #Pop = BI_DB_DailyCommisionReport INNER JOIN #List
  │         → Revenue_Crypto (all-time), Revenue_Crypto_from_20230801, Revenue_Crypto_from_20231201
  │
  ├─ #Last_Contact = BI_DB_UsageTracking_SF INNER JOIN #Pop
  │                  WHERE ActionName IN ('Phone_Call_Succeed__c','Completed_Contact_Email__c')
  │                  → MAX(CreatedDate AS DATE) per CID
  │
  ├─ #Last_Crypto_open = Dim_Position INNER JOIN Dim_Instrument (InstrumentTypeID=10)
  │                      INNER JOIN #Pop WHERE MirrorID=0
  │                      → MAX(OpenOccurred AS DATE) per CID
  │
  └─ TRUNCATE TABLE BI_DB_Crypto_Top_1000_List
     INSERT FROM:
       BI_DB_CID_MonthlyPanel_FullData (WHERE ActiveDate = @BeginOfMonth)
         INNER JOIN #Pop
         LEFT JOIN #Last_Contact
         LEFT JOIN BI_DB_CIDFirstDates
         LEFT JOIN #Last_Crypto_open
     → BI_DB_dbo.BI_DB_Crypto_Top_1000_List (1,000 rows | HASH(CID) | HEAP)
        UC Target: _Not_Migrated
```

---

## 6. Relationships

### 6.1 References To

| Column | Related Object | Join Condition |
|--------|---------------|----------------|
| CID | DWH_dbo.Dim_Customer | CID = RealCID |
| CID | BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData | CID = CID |
| CID | BI_DB_dbo.BI_DB_CIDFirstDates | CID = CID |

### 6.2 Referenced By

No downstream objects identified that read this table. It is a campaign operational output consumed directly by account managers or BI reports.

---

## 7. Sample Queries

Current campaign targets sorted by uncontacted + highest equity.

```sql
SELECT CID, AccountManager, Region, Club, Equity,
       LastLoggedIn, LastCryptoPosOpenDate, LastContacted,
       Revenue_Crypto_from_20231201
FROM BI_DB_dbo.BI_DB_Crypto_Top_1000_List
WHERE LastContacted IS NULL
   OR LastContacted < DATEADD(DAY, -30, GETDATE())
ORDER BY Equity DESC;
```

Revenue breakdown by region to prioritise AM outreach effort.

```sql
SELECT Region,
       COUNT(*)                          AS CustomerCount,
       AVG(Equity)                       AS AvgEquity,
       SUM(ACC_Revenue_Crypto)           AS TotalLifetimeCryptoRev,
       SUM(Revenue_Crypto_from_20231201) AS CampaignPeriodRev
FROM BI_DB_dbo.BI_DB_Crypto_Top_1000_List
GROUP BY Region
ORDER BY TotalLifetimeCryptoRev DESC;
```

---

## 8. Atlassian Knowledge

- SP comment: "Populate the top 1000 Crypto clients that has less than $100 revenue since 20230801. This data will be used by AMs to bring those clients back." (Author: Jan Iablunovskey, 2023-11-08)
- 2023-11-13: Column `Revenue_Crypto_from_20231201` added to track campaign period conversion
- 2023-11-23: CID list revised due to calculation change

---

*Generated: 2026-04-28 | Quality: 8.5/10 | Phases: 11/14 (P7 Views N/A, P10 Jira skipped — regen harness)*
*Tiers: 10 T1, 6 T2, 0 T3, 0 T4 | Object: BI_DB_dbo.BI_DB_Crypto_Top_1000_List | Source: SP_Crypto_Top_1000_List*
