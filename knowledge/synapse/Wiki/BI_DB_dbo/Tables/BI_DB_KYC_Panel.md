# BI_DB_dbo.BI_DB_KYC_Panel

> Daily full-rebuild KYC questionnaire snapshot (21.7M rows) covering every valid eToro customer's assessment-questionnaire answers, experience level, CFD eligibility, trading activity windows, and demographic enrichment — pivoted from UserApiDB.KYC.CustomerAnswers via an external table bridge and rebuilt from scratch every day.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | UserApiDB.dbo.V_CustomerAnswers_Range_KYC_Panel (external table) + Dim_Customer (population gate) + BI_DB_First5Actions + BI_DB_Scored_Appropriateness_Negative_Market |
| **Refresh** | Daily — SP_KYC_Panel @Date; full TRUNCATE + INSERT; rows with all KYC answers NULL are deleted post-insert |
| **Synapse Distribution** | HASH(GCID) |
| **Synapse Index** | CLUSTERED INDEX (GCID ASC) |
| **UC Target** | Not Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_KYC_Panel` is the central KYC analytics table in the BI_DB schema. It holds one row per valid eToro customer (IsValidCustomer=1 from Dim_Customer), pivoted from the raw KYC questionnaire answer store in UserApiDB. Each row aggregates all of a customer's KYC question responses alongside computed assessments, regulatory demographics, CFD eligibility, and early trading behavior metrics.

The table is rebuilt daily from scratch (TRUNCATE + full INSERT). It is keyed by `GCID` (Global Customer ID from UserApiDB), not by `RealCID` (eToro production CID). Both identifiers are present. Post-insert, rows where all KYC answer columns are NULL are deleted — ensuring the table only contains customers with at least one questionnaire response.

As of 2026-04-13: 21,690,259 rows. Four assessment types are present: AnswerID_101_104 (38.8%), AnswerID_142_146 (32.8%), N/A (28.3%), AnswerID_84_87 (0.15%). CFD status: 65.8% CFD_Allowed, 17.2% CFD_Blocked, 16.9% NULL (no CFD assessment). Experience levels: Non (30.7%), Low (24.4%), N/A (23.1%), High (9.7%), Med (7.7%).

**KEY ANOMALY — `RegulatgionName` column typo**: Column 56 is named `[RegulatgionName]` (extra 'g' in "Regulation"). This matches the SP code exactly. Do NOT reference this column as `RegulatgionName` in queries — use `RegulationID` + join to Dim_Regulation instead, or use `QUOTENAME` to handle the typo.

---

## 2. Business Logic

### 2.1 Population Gate

**What**: Only "valid" customers are included. Non-valid customers (internal accounts, excluded markets, blocked countries) are excluded at the source query.
**Columns Involved**: All columns
**Rules**:
- `JOIN DWH_dbo.Dim_Customer WHERE IsValidCustomer=1` — excludes PlayerLevelID=4 (Internal), certain label IDs, and CountryID=250 (excluded market)
- Post-insert DELETE: `WHERE [all KYC answer columns] IS NULL` — removes customers with zero questionnaire responses
- Non-depositor FTD_Date = '1900-01-01' (from Dim_Customer.FirstDepositDate sentinel)

### 2.2 Assessment Type Segmentation

**What**: The `Assessment_Type` column categorizes each customer's KYC appropriateness assessment version. Three answer ID ranges correspond to three questionnaire generations.
**Columns Involved**: `Assessment_Type`, `Total_Points_Assessment_142_146`, `Q23_Assessment`, `Q23_AnswerID`
**Rules**:
- Answer IDs 84–87 → `'AnswerID_84_87'` (0.15% of customers — oldest/legacy assessment)
- Answer IDs 101–104 → `'AnswerID_101_104'` (38.8% — second-generation assessment)
- Answer IDs 142–146 → `'AnswerID_142_146'` (32.8% — current assessment)
- All others → `'N/A'` (28.3% — no valid appropriateness assessment)

```
Assessment generations:
  Legacy (84-87)       0.15%  — oldest questionnaire form
  2nd-Gen (101-104)   38.8%  — standard assessment
  Current (142-146)   32.8%  — latest assessment
  N/A                 28.3%  — no assessment recorded
```

### 2.3 Appropriateness Score (142-146 Type Only)

**What**: `Total_Points_Assessment_142_146` contains a numeric appropriateness score only for customers with Assessment_Type='AnswerID_142_146'. All other customers receive a sentinel value of -100.
**Columns Involved**: `Total_Points_Assessment_142_146`, `Assessment_Type`
**Rules**:
- For 142-146 type: +2 per correct answer, -2 per wrong answer. Higher score = more appropriate for CFD trading.
- For all other types: value = -100 (sentinel — NOT a real score, DO NOT average or compare across Assessment_Type values)
- A score of 0 indicates equal correct/wrong answers, not "no data"

```
CRITICAL: -100 = sentinel for non-142-146 customers
           0   = tied correct/wrong for 142-146 customers
  Always filter: WHERE Assessment_Type = 'AnswerID_142_146' before scoring analysis
```

### 2.4 Experience Level Computation

**What**: `Experience_Level` aggregates trading experience across three asset classes (equities, crypto, CFDs) into a single tier.
**Columns Involved**: `Experience_Level`, `Q33_Experience_Equities`, `Q34_Experience_Crypto`, `Q35_Experience_CFDs`, `Q33_AnswerID`, `Q34_AnswerID`, `Q35_AnswerID`
**Rules**:
- Each of Q33/Q34/Q35 answer IDs is mapped to a numeric tier: 1=Non, 2=Low, 3=Med, 4=High
- `Experience_Level = MAX(tier across Q33, Q34, Q35)` → labeled as Non/Low/Med/High
- 'N/A' when no Q33/Q34/Q35 answers exist

```
Experience_Level derivation:
  Q33 answer ID → tier (Non/Low/Med/High)
  Q34 answer ID → tier
  Q35 answer ID → tier
  Experience_Level = MAX(Q33_tier, Q34_tier, Q35_tier) as label
```

### 2.5 Multi-Select Question Handling (Q15, Q26, Q27, Q30, Q32)

**What**: Several questions allow multiple answers. These are handled differently from single-select questions.
**Columns Involved**: `Q15_AnswerText`, `Q26_AnswerText`, `Is_PI_Stocks`, `Is_PI_Crypto`, `Is_PI_FX`, `Q30_Is_*`, `Q32_Is_*`
**Rules**:
- **Q15 (Sources of Income) / Q26 (Sources of Funds)**: Multi-select. `_AnswerText` columns are STRING_AGG of all selected answer texts. `_AnswerID` columns hold only the last/primary answer ID.
- **Q27 (Planned Investment Instrument)**: Multi-select. `Q27_Planned_Investment_Instrument` is the last answer ID. Boolean flags `Is_PI_Stocks`, `Is_PI_Crypto`, `Is_PI_FX` = 1 if that instrument was selected.
- **Q30 (FINRA)**: Multi-select. Flags extracted: `Q30_Is_Shareholder`, `Q30_Is_Employed_By_Broker`, `Q30_Is_Public_Official`, `Q30_Is_None_Apply_To_Me`.
- **Q32 (PEP/Money Manager)**: Same flag pattern as Q30.

### 2.6 CFD Status

**What**: `CFD_Status` reflects whether the customer is currently allowed to trade CFDs, based on scores from the appropriateness assessment.
**Columns Involved**: `CFD_Status`, `CFD_BlockDate`, `CFD_BlockReasonDesc`, `CFD_ReleaseDate`, `CFD_ReleaseReasonDesc`, `DateDiffBlockRelease`
**Rules**:
- Sourced from `BI_DB_Scored_Appropriateness_Negative_Market` (LEFT JOIN on RealCID)
- 'CFD_Allowed': customer scored sufficiently on appropriateness OR passed re-assessment
- 'CFD_Blocked': customer failed appropriateness threshold
- NULL: no CFD assessment record (16.9% of population — newer or unassessed customers)
- `DateDiffBlockRelease`: days from block to release; NULL if still blocked or never blocked

### 2.7 Temporal Grouping Columns

**What**: Two bucketed time-distance columns describe how quickly customers deposited and how long ago they deposited.
**Columns Involved**: `GapInDays_Reg_to_FTD_Group`, `DaysFromFTD_Group`
**Rules**:
- `GapInDays_Reg_to_FTD_Group`: `DATEDIFF(DAY, Reg_Date, FTD_Date)` bucketed: '0', '1-3', '4-7', '8-14', '15-30', '31+', 'N/A'
- `DaysFromFTD_Group`: `DATEDIFF(DAY, FTD_Date, GETDATE()-1)` bucketed: '0', '1-7', '8-14', '15-30', '31+', 'N/A'. **CRITICAL: This column is recalculated every day. A customer who deposited 7 days ago will move from '1-7' to '8-14' on the 8th day. The value is a snapshot of "age since FTD as of yesterday" — NOT a stable dimension.**
- Non-depositors: both columns = 'N/A'

### 2.8 Q3 Composite Answer Text

**What**: `Q3_AnswerText` for Q3 (Trading Knowledge) is a computed composite string, not a raw answer text.
**Columns Involved**: `Q3_AnswerText`, `Q3_Trading_Knowledge`, `Q3_Is_Professional_Knowledge`
**Rules**:
- Q3 is a multi-part question assessing educational/professional credentials
- `Q3_AnswerText` = STRING_AGG of active indicators from: Is_Courses, Is_Professional_Experience, Is_Academic_Degree
- Possible composite values: e.g., "Professional Experience, Academic Degree" (multiple flags can be active)
- `Q3_Is_Professional_Knowledge` = 1 if any professional indicator flag is active

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID) with CLUSTERED INDEX(GCID ASC). Point-lookups and joins on GCID are fast. With 21.7M rows, always use a WHERE clause when possible. The table is rebuilt daily — snapshot date is reflected in the single UpdateDate value (all rows have the same UpdateDate from the daily run).

### 3.2 GCID vs. RealCID

This table is **keyed on GCID**, not CID/RealCID. Most DWH fact tables use RealCID/CID as the join key. When joining this table to fact tables, use `RealCID` for the join, not GCID. The `GCID` column in this table maps to `Dim_Customer.GCID` and is the distribution key for performance.

### 3.3 RegulatgionName Typo

Column 56 has a **deliberate typo**: `[RegulatgionName]` (extra 'g'). This matches the SP code. Reference it in queries using square-bracket quoting: `[RegulatgionName]`. Alternatively, join to Dim_Regulation on RegulationID for cleaner access to the regulation name.

### 3.4 Assessment Score Filtering

**Always filter by Assessment_Type before using Total_Points_Assessment_142_146**: The -100 sentinel for non-142-146 customers will corrupt averages and ranges if included. Pattern:
```sql
WHERE Assessment_Type = 'AnswerID_142_146'
-- then: AVG(Total_Points_Assessment_142_146), etc.
```

### 3.5 DaysFromFTD_Group Is Not Stable

Do NOT use `DaysFromFTD_Group` as a join key or in GROUP BY for time-series analysis. Its value changes every day. Use `FTD_Date` and compute the desired window in your query. `DaysFromFTD_Group` is useful only as a filter (e.g., "customers who deposited in the last 7 days yesterday").

### 3.6 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get KYC profile for a customer | `WHERE RealCID = X` (use RealCID, not GCID, for DWH joins) |
| Appropriateness score distribution | `WHERE Assessment_Type = 'AnswerID_142_146' GROUP BY Total_Points_Assessment_142_146` |
| CFD-blocked customers by regulation | `WHERE CFD_Status = 'CFD_Blocked' GROUP BY [RegulatgionName]` |
| Recent depositors (last 7 days) | `WHERE DaysFromFTD_Group = '0' OR DaysFromFTD_Group = '1-7'` |
| Customers who plan to invest in stocks | `WHERE Is_PI_Stocks = 1` |
| PEP-flagged customers | `WHERE Q32_Is_Public_Official = 1` |
| Experience level by regulation | `GROUP BY Experience_Level, [RegulatgionName]` |

---

## 4. Elements

| # | Column | Type | Nullable | Confidence | Tier | Description |
|---|--------|------|----------|------------|------|-------------|
| 1 | RealCID | bigint | YES | CODE-BACKED | T2 | eToro production CID (RealCID from Dim_Customer). Join key to all DWH fact tables via CID=RealCID. |
| 2 | GCID | bigint | YES | CODE-BACKED | T2 | Global Customer ID from UserApiDB. Distribution key. Join key to KYC source tables. Prefer RealCID for DWH joins. |
| 3 | IsFTD | bit | YES | CODE-BACKED | T2 | 1 if customer has made at least one deposit (Dim_Customer.IsDepositor=1). 0 for non-depositors. |
| 4 | IsFirstAction | bit | YES | CODE-BACKED | T2 | 1 if customer has performed at least one trading action (BI_DB_First5Actions.FirstAction IS NOT NULL). |
| 5 | FunnelName | varchar(200) | YES | CODE-BACKED | T2 | Acquisition funnel segment: 'SocialCopy' (came via copy trading), 'Copy' (other copy), 'Direct' (organic), 'None' (unclassified). |
| 6 | Reg_Date | date | YES | CODE-BACKED | T2 | Registration date (YYYYMMDD char format cast to date). From Dim_Customer.RegisteredReal. |
| 7 | Reg_Month | bigint | YES | CODE-BACKED | T2 | Registration year-month as YYYYMM integer. Useful for monthly cohort aggregation. |
| 8 | FTD_Date | date | YES | CODE-BACKED | T2 | First Time Deposit date. '1900-01-01' for non-depositors. |
| 9 | FTD_Month | bigint | YES | CODE-BACKED | T2 | FTD year-month as YYYYMM integer. |
| 10 | Q3_Trading_Knowledge | varchar(200) | YES | CODE-BACKED | T2 | Q3 raw answer ID (trading knowledge: educational and professional background). |
| 11 | Q3_Is_Professional_Knowledge | smallint | YES | CODE-BACKED | T2 | 1 if Q3 responses indicate professional trading knowledge (courses, experience, or academic degree). |
| 12 | Q3_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Composite STRING_AGG of Q3 credential flags (e.g., "Professional Experience, Academic Degree"). Not a single answer text. |
| 13 | Q23_Assessment | varchar(200) | YES | CODE-BACKED | T2 | Q23 raw answer ID. Q23 is the core appropriateness assessment question. |
| 14 | Q23_Is_Assessment_Pass | smallint | YES | CODE-BACKED | T2 | 1 if Q23 answer ID meets the pass threshold. |
| 15 | Q23_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q23. |
| 16 | Experience_Level | varchar(50) | YES | CODE-BACKED | T2 | Composite experience tier: MAX(Q33, Q34, Q35 tiers) → 'Non', 'Low', 'Med', 'High', 'N/A'. See §2.4. |
| 17 | Q33_Experience_Equities | varchar(200) | YES | CODE-BACKED | T2 | Q33 raw answer ID (equities trading experience). |
| 18 | Q33_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q33. |
| 19 | Q34_Experience_Crypto | varchar(200) | YES | CODE-BACKED | T2 | Q34 raw answer ID (crypto trading experience). |
| 20 | Q34_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q34. |
| 21 | Q35_Experience_CFDs | varchar(200) | YES | CODE-BACKED | T2 | Q35 raw answer ID (CFD trading experience). |
| 22 | Q35_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q35. |
| 23 | Q2_Experience | varchar(200) | YES | CODE-BACKED | T2 | Q2 raw answer ID (general trading experience years). |
| 24 | Q2_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q2. |
| 25 | Q10_Annual_Income | varchar(200) | YES | CODE-BACKED | T2 | Q10 raw answer ID (annual income bracket). |
| 26 | Q10_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q10. |
| 27 | Q11_Liquid_Assets | varchar(200) | YES | CODE-BACKED | T2 | Q11 raw answer ID (liquid assets bracket). |
| 28 | Q11_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q11. |
| 29 | Q9_Risk_Reward_Scenario | varchar(200) | YES | CODE-BACKED | T2 | Q9 raw answer ID (risk/reward scenario understanding). |
| 30 | Q9_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q9. |
| 31 | Q14_Planned_Invested_Amount | varchar(200) | YES | CODE-BACKED | T2 | Q14 raw answer ID (total planned investment amount bracket). |
| 32 | Q14_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q14. |
| 33 | Q27_Planned_Investment_Instrument | varchar(200) | YES | CODE-BACKED | T2 | Q27 raw answer ID (planned instrument types — multi-select). Prefer Is_PI_* flags for individual instrument checks. |
| 34 | Is_PI_Stocks | bit | YES | CODE-BACKED | T2 | 1 if customer plans to invest in Stocks (from Q27 multi-select). |
| 35 | Is_PI_Crypto | bit | YES | CODE-BACKED | T2 | 1 if customer plans to invest in Crypto (from Q27). |
| 36 | Is_PI_FX | bit | YES | CODE-BACKED | T2 | 1 if customer plans to invest in FX/CFDs (from Q27). |
| 37 | Total_PI_Answers | smallint | YES | CODE-BACKED | T2 | Count of distinct instrument selections in Q27 (0–3). |
| 38 | Q5_Trading_Strategy | varchar(200) | YES | CODE-BACKED | T2 | Q5 raw answer ID (preferred trading strategy). |
| 39 | Q5_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q5. |
| 40 | Q8_Trading_Primary_Purpose | varchar(200) | YES | CODE-BACKED | T2 | Q8 raw answer ID (primary purpose for trading: income/growth/speculation/etc.). |
| 41 | Q8_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q8. |
| 42 | Q15_Sources_of_Income | varchar(200) | YES | CODE-BACKED | T2 | Q15 primary/last answer ID (sources of income — multi-select question). |
| 43 | Q15_AnswerText | varchar(max) | YES | CODE-BACKED | T2 | STRING_AGG of all selected income source answer texts (multi-select). |
| 44 | Q26_Sources_of_Funds | varchar(200) | YES | CODE-BACKED | T2 | Q26 primary/last answer ID (sources of funds for investment — multi-select). |
| 45 | Q26_AnswerText | varchar(max) | YES | CODE-BACKED | T2 | STRING_AGG of all selected fund source answer texts (multi-select). |
| 46 | Q18_Occupation | varchar(200) | YES | CODE-BACKED | T2 | Q18 raw answer ID (occupation category). |
| 47 | Q18_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q18. |
| 48 | GapInDays_Reg_to_FTD_Group | varchar(200) | YES | CODE-BACKED | T2 | Days from registration to FTD, bucketed: '0', '1-3', '4-7', '8-14', '15-30', '31+', 'N/A'. |
| 49 | DaysFromFTD_Group | varchar(200) | YES | CODE-BACKED | T2 | Days from FTD to yesterday, bucketed: '0', '1-7', '8-14', '15-30', '31+', 'N/A'. RECOMPUTED DAILY — not stable. |
| 50 | VerificationLevelID | smallint | YES | CODE-BACKED | T1 | KYC verification tier ID. 1=Basic, 2=Verified, 3=Fully Verified, etc. From Dim_Customer. |
| 51 | CountryID | int | YES | CODE-BACKED | T1 | FK to Dim_Country. Customer's registered country. |
| 52 | CountryName | varchar(100) | YES | CODE-BACKED | T1 | Country name from Dim_Country. |
| 53 | Region | varchar(100) | YES | CODE-BACKED | T1 | Marketing region label from Dim_Country (e.g., 'EMEA', 'LatAm', 'APAC'). |
| 54 | EU | bit | YES | CODE-BACKED | T1 | 1 if customer's country is an EU member state. From Dim_Country. |
| 55 | RegulationID | int | YES | CODE-BACKED | T1 | FK to Dim_Regulation. Regulatory jurisdiction governing this customer. |
| 56 | RegulatgionName | varchar(200) | YES | CODE-BACKED | T2 | Regulation name from Dim_Regulation. NOTE: column name contains typo 'RegulatgionName' (extra 'g') — matches SP code. Use square brackets when referencing. |
| 57 | Club | varchar(200) | YES | CODE-BACKED | T1 | eToro Club loyalty tier name (Bronze/Silver/Gold/Platinum/Platinum Plus/Diamond) from Dim_PlayerLevel. |
| 58 | Gender | varchar(200) | YES | CODE-BACKED | T1 | Customer self-reported gender. From Dim_Customer. |
| 59 | Age_Curr | int | YES | CODE-BACKED | T1 | Current age in years. From Dim_Customer. |
| 60 | Age_On_Reg | int | YES | INFERRED | T3 | Age at time of registration. From Dim_Customer. |
| 61 | CFD_Status | varchar(50) | YES | CODE-BACKED | T2 | CFD access status: 'CFD_Allowed', 'CFD_Blocked', or NULL (no assessment). From BI_DB_Scored_Appropriateness_Negative_Market. See §2.6. |
| 62 | CFD_BlockDate | date | YES | CODE-BACKED | T2 | Date CFD access was blocked. NULL if never blocked. |
| 63 | CFD_BlockReasonDesc | varchar(200) | YES | CODE-BACKED | T2 | Reason description for CFD block (e.g., 'Failed Appropriateness Test'). |
| 64 | CFD_ReleaseDate | date | YES | CODE-BACKED | T2 | Date CFD access was restored after blocking. NULL if still blocked or never blocked. |
| 65 | CFD_ReleaseReasonDesc | varchar(200) | YES | CODE-BACKED | T2 | Reason description for CFD release. |
| 66 | DateDiffBlockRelease | int | YES | CODE-BACKED | T2 | Days between CFD block date and release date. NULL if still blocked or never blocked. |
| 67 | FirstDepositAmount | bigint | YES | CODE-BACKED | T1 | First deposit amount in USD. From Dim_Customer.FirstDepositAmount. |
| 68 | FirstAction_Date | date | YES | CODE-BACKED | T2 | Date of customer's first trading action. From BI_DB_First5Actions. |
| 69 | FirstAction_Month | bigint | YES | CODE-BACKED | T2 | First action year-month as YYYYMM. |
| 70 | FirstAction | varchar(200) | YES | CODE-BACKED | T2 | Type of first trading action (e.g., 'Buy', 'CopyTrade'). From BI_DB_First5Actions. |
| 71 | FirstAction_Detailed | varchar(200) | YES | CODE-BACKED | T2 | More detailed first action description. From BI_DB_First5Actions. |
| 72 | FirstInstrument | varchar(200) | YES | CODE-BACKED | T2 | First instrument traded (symbol or instrument name). From BI_DB_First5Actions. |
| 73 | Deposit7days | decimal(38,2) | YES | CODE-BACKED | T2 | Total deposits in first 7 days after FTD. From BI_DB_First5Actions. |
| 74 | Deposit14days | decimal(38,2) | YES | CODE-BACKED | T2 | Total deposits in first 14 days after FTD. From BI_DB_First5Actions. |
| 75 | Deposit30days | decimal(38,2) | YES | CODE-BACKED | T2 | Total deposits in first 30 days after FTD. From BI_DB_First5Actions. |
| 76 | Revenue7days | decimal(38,2) | YES | CODE-BACKED | T2 | Revenue generated in first 7 days after FTD. From BI_DB_First5Actions. |
| 77 | Revenue14days | decimal(38,2) | YES | CODE-BACKED | T2 | Revenue in first 14 days after FTD. From BI_DB_First5Actions. |
| 78 | Revenue30days | decimal(38,2) | YES | CODE-BACKED | T2 | Revenue in first 30 days after FTD. From BI_DB_First5Actions. |
| 79 | Equity7days | decimal(38,4) | YES | CODE-BACKED | T2 | Customer account equity at 7 days after FTD. From BI_DB_First5Actions. |
| 80 | Equity14days | decimal(38,4) | YES | CODE-BACKED | T2 | Customer equity at 14 days after FTD. From BI_DB_First5Actions. |
| 81 | Equity30days | decimal(38,4) | YES | CODE-BACKED | T2 | Customer equity at 30 days after FTD. From BI_DB_First5Actions. |
| 82 | Q23_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q23 (appropriateness assessment). Used in Assessment_Type derivation. |
| 83 | Q33_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q33 (equities experience). Used in Experience_Level computation. |
| 84 | Q34_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q34 (crypto experience). Used in Experience_Level computation. |
| 85 | Q35_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q35 (CFD experience). Used in Experience_Level computation. |
| 86 | Q2_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q2. |
| 87 | Q10_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q10. |
| 88 | Q11_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q11. |
| 89 | Q9_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q9. |
| 90 | Q14_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q14. |
| 91 | Q5_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q5. |
| 92 | Q8_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q8. |
| 93 | Q18_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q18. |
| 94 | UpdateDate | datetime | YES | CODE-BACKED | T2 | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |
| 95 | KYC_LastUpdateDate | datetime | YES | CODE-BACKED | T2 | Latest KYC answer submission timestamp from UserApiDB (MAX OccurredAt per GCID). Reflects when customer last updated their questionnaire responses. |
| 96 | Q29_Time_Frame_Investing | varchar(200) | YES | CODE-BACKED | T2 | Q29 raw answer ID (intended investment time frame: short/medium/long term). |
| 97 | Q29_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q29. |
| 98 | Q29_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q29. |
| 99 | Q36_US_Permanent_Resident | varchar(200) | YES | CODE-BACKED | T2 | Q36 raw answer ID (US permanent residency status — FinCEN/NFA-regulated customers). |
| 100 | Q36_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q36. |
| 101 | Q36_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q36. |
| 102 | Q40_W9_Certification | varchar(200) | YES | CODE-BACKED | T2 | Q40 raw answer ID (W9 tax certification — US-specific compliance). |
| 103 | Q40_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q40. |
| 104 | Q40_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q40. |
| 105 | Q30_FINRA | varchar(200) | YES | CODE-BACKED | T2 | Q30 raw answer ID (FINRA/broker affiliation — multi-select, US-regulated customers). |
| 106 | Q30_Is_Shareholder | bit | YES | CODE-BACKED | T2 | 1 if Q30 includes "10%+ shareholder of a publicly traded company". |
| 107 | Q30_Is_Employed_By_Broker | bit | YES | CODE-BACKED | T2 | 1 if Q30 includes "employed by a broker/dealer or FINRA member firm". |
| 108 | Q30_Is_Public_Official | bit | YES | CODE-BACKED | T2 | 1 if Q30 includes "government official or public figure". |
| 109 | Q30_Is_None_Apply_To_Me | bit | YES | CODE-BACKED | T2 | 1 if Q30 answer is "none of the above". |
| 110 | Q32_PEP_MM_Question | varchar(200) | YES | CODE-BACKED | T2 | Q32 raw answer ID (PEP / money manager declaration — multi-select). |
| 111 | Q32_Is_Shareholder | bit | YES | CODE-BACKED | T2 | 1 if Q32 includes shareholder status. |
| 112 | Q32_Is_Employed_By_Broker | bit | YES | CODE-BACKED | T2 | 1 if Q32 includes broker/dealer employment. |
| 113 | Q32_Is_Public_Official | bit | YES | CODE-BACKED | T2 | 1 if Q32 includes public official / PEP status. |
| 114 | Q32_Is_None_Apply_To_Me | bit | YES | CODE-BACKED | T2 | 1 if Q32 is "none apply to me". |
| 115 | Q50_Is_Vulnerable_Client | varchar(200) | YES | CODE-BACKED | T2 | Q50 raw answer ID (FCA Consumer Duty vulnerable client self-assessment — FCA-regulated only). |
| 116 | Q50_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q50. |
| 117 | Q50_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q50. |
| 118 | Q45_Invested_Amount_CFDs | varchar(200) | YES | CODE-BACKED | T2 | Q45 raw answer ID (total amount invested in CFDs historically). |
| 119 | Q45_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q45. |
| 120 | Q45_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q45. |
| 121 | Q47_Invested_Amount_Equities | varchar(200) | YES | CODE-BACKED | T2 | Q47 raw answer ID (total amount invested in equities historically). |
| 122 | Q47_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q47. |
| 123 | Q47_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q47. |
| 124 | Q48_Invested_Amount_Crypto | varchar(200) | YES | CODE-BACKED | T2 | Q48 raw answer ID (total amount invested in crypto historically). |
| 125 | Q48_AnswerID | int | YES | CODE-BACKED | T2 | Raw numeric answer ID for Q48. |
| 126 | Q48_AnswerText | varchar(200) | YES | CODE-BACKED | T2 | Answer text for Q48. |
| 127 | Assessment_Type | varchar(200) | YES | CODE-BACKED | T2 | KYC assessment questionnaire version: 'AnswerID_84_87' (legacy), 'AnswerID_101_104', 'AnswerID_142_146' (current), 'N/A'. See §2.2. |
| 128 | Total_Points_Assessment_142_146 | int | YES | CODE-BACKED | T2 | Appropriateness score for AnswerID_142_146 type (+2 correct/-2 wrong). -100 sentinel for all other Assessment_Type values. See §2.3. |

---

## 5. Lineage

See `BI_DB_KYC_Panel.lineage.md` for full column lineage.

### ETL Pipeline Summary

```
UserApiDB.KYC.CustomerAnswers (production — 180M+ rows)
  └── V_CustomerAnswers (UserApiDB view — GCID + QuestionId + AnswerId + texts)
        └── UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel (external table — KYC Panel scope)
              └── BI_DB_KYC_Questions_Answers_Row_Data (intermediate pivot staging)

DWH_dbo.Dim_Customer (IsValidCustomer=1) + Dim_Country + Dim_Regulation + Dim_PlayerLevel + Dim_Funnel
BI_DB_dbo.BI_DB_First5Actions (trading window metrics)
BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market (CFD eligibility)

  └── SP_KYC_Panel (@Date) — TRUNCATE + full INSERT + DELETE (null-answer rows)
        v
BI_DB_dbo.BI_DB_KYC_Panel (21.7M rows, HASH(GCID), daily snapshot)
```

---

## 6. Relationships

### Produced By
| SP | Schedule | Priority | Pattern |
|----|----------|----------|---------|
| SP_KYC_Panel | Daily | P0 (base layer) | TRUNCATE + full INSERT; delete rows with all answers NULL |

### Read By (known consumers)
| Consumer | Join Key | Purpose |
|---------|---------|---------|
| SP_Regulation_Change_Abuse | Listed in OpsDB dependencies (unverified at code level — SP code does not reference BI_DB_KYC_Panel) | Suspected stale dependency |

---

## 7. Tier Legend

| Tier | Meaning |
|------|---------|
| T1 | Verbatim from upstream wiki (DWH_dbo Dim* docs) |
| T2 | ETL-computed — traced to SP code |
| T3 | Inferred from data sampling or naming |
| T4 | Best-available guess |

---

*Documented 2026-04-22 — Batch 33 | SP: SP_KYC_Panel | Quality target: 8.5+*
