# Lineage: BI_DB_dbo.BI_DB_KYC_Panel

## Source Chain

| Level | Object | Type | Role |
|-------|--------|------|------|
| L0 | UserApiDB.KYC.CustomerAnswers (production) | Production DB | Raw customer KYC question-answer records (180M+ rows, keyed by GCID + QuestionId + AnswerId) |
| L0 | UserApiDB.dbo.V_CustomerAnswers | Production View | Denormalized KYC answers with question/answer text and thresholds |
| L1 | BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel | External Table | Lake bridge for UserApiDB.dbo.V_CustomerAnswers (KYC Panel scope) |
| L1 | BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data | BI_DB Table | Intermediate pivot staging for KYC questions |
| L1 | BI_DB_dbo.BI_DB_First5Actions | BI_DB Table | First-action trading windows per customer (FirstAction*, Deposit/Revenue/Equity 7/14/30 day metrics) |
| L1 | BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market | BI_DB Table | CFD eligibility scores (CFD_Status, block/release dates and reasons) |
| L1 | DWH_dbo.Dim_Customer | DWH Dimension | Master customer attributes (RealCID, GCID, registration date, FTD date, IsDepositor, VerificationLevelID, CountryID, Club/PlayerLevel, Gender, Age) |
| L1 | DWH_dbo.Dim_Country | DWH Dimension | Country → Region, EU flag |
| L1 | DWH_dbo.Dim_Regulation | DWH Dimension | RegulationID → regulation name |
| L1 | DWH_dbo.Dim_PlayerLevel | DWH Dimension | PlayerLevelID → Club tier name |
| L1 | DWH_dbo.Dim_Funnel | DWH Dimension | AffiliateID → FunnelName (SocialCopy/Copy/Direct/None) |
| L2 | BI_DB_dbo.BI_DB_KYC_Panel | **THIS TABLE** | Daily full-rebuild KYC snapshot: 21.7M rows per assessment type per customer |

## ETL Pipeline

```
UserApiDB.KYC.CustomerAnswers (production — 180M+ rows, GCID+QuestionId+AnswerId)
  └── UserApiDB.dbo.V_CustomerAnswers (denormalized view: GCID, QuestionText, AnswerText, thresholds)
        └── BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel (external table — lake bridge, KYC Panel scope)
              └── BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data (intermediate pivot staging)

DWH_dbo.Dim_Customer (IsValidCustomer=1, population gate)
DWH_dbo.Dim_Country, Dim_Regulation, Dim_PlayerLevel, Dim_Funnel (dimension enrichment)
BI_DB_dbo.BI_DB_First5Actions (trading window metrics: FirstAction, Deposit/Revenue/Equity 7/14/30d)
BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market (CFD eligibility: CFD_Status, block/release)

  └── SP_KYC_Panel (@Date, daily TRUNCATE + INSERT)
        ├── PIVOT KYC answers by QuestionId → Q3, Q2, Q5, Q8, Q9, Q10, Q11, Q14, Q15, Q18,
        │   Q23, Q26, Q27, Q29, Q30, Q32, Q33, Q34, Q35, Q36, Q40, Q45, Q47, Q48, Q50
        ├── Compute Experience_Level = MAX(mapped Q33/Q34/Q35 answer IDs) → Non/Low/Med/High/N/A
        ├── Compute Assessment_Type = answer ID range check → AnswerID_84_87/101_104/142_146/N/A
        ├── Compute Total_Points_Assessment_142_146 = +2 correct / -2 wrong (sentinel -100 for non-142-146)
        ├── Compute GapInDays_Reg_to_FTD_Group = DATEDIFF(Reg_Date→FTD_Date) bucketed (0/1-3/4-7/8-14/15-30/31+/N/A)
        ├── Compute DaysFromFTD_Group = DATEDIFF(FTD_Date→yesterday) bucketed (refreshed every run)
        ├── Extract Q27 multi-choice flags: Is_PI_Stocks, Is_PI_Crypto, Is_PI_FX, Total_PI_Answers
        ├── Extract Q30 FINRA flags: Is_Shareholder, Is_Employed_By_Broker, Is_Public_Official, Is_None_Apply_To_Me
        ├── Extract Q32 PEP/MM flags: (same set as Q30)
        └── DELETE rows where all KYC answers NULL (customers with no responses)

              v
BI_DB_dbo.BI_DB_KYC_Panel (21,690,259 rows — 2026-04-13 daily snapshot, HASH(GCID))
  └── UC: Not Migrated
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | RealCID | Dim_Customer | RealCID | Direct — eToro production CID (customer real account ID) | Tier 1 |
| 2 | GCID | Dim_Customer | GCID | Direct — Global Customer ID from UserApiDB; distribution key | Tier 1 |
| 3 | IsFTD | Dim_Customer | IsDepositor | `CASE WHEN IsDepositor=1 THEN 1 ELSE 0` — 1 if customer has made at least one deposit | Tier 2 |
| 4 | IsFirstAction | BI_DB_First5Actions | FirstAction | `CASE WHEN FirstAction IS NOT NULL THEN 1 ELSE 0` — 1 if customer has performed any trading action | Tier 2 |
| 5 | FunnelName | Dim_Funnel | Name | CASE mapped: SocialCopy/Copy/Direct/None based on funnel name pattern | Tier 2 |
| 6 | Reg_Date | Dim_Customer | RegisteredReal | `CONVERT(CHAR(8), RegisteredReal, 112)` → date string YYYYMMDD | Tier 2 |
| 7 | Reg_Month | Dim_Customer | RegisteredReal | `YEAR*100+MONTH` → YYYYMM integer | Tier 2 |
| 8 | FTD_Date | Dim_Customer | FirstDepositDate | `CONVERT(CHAR(8), FirstDepositDate, 112)` → date string; 1900-01-01 for non-depositors | Tier 2 |
| 9 | FTD_Month | Dim_Customer | FirstDepositDate | `YEAR*100+MONTH` → YYYYMM integer | Tier 2 |
| 10 | Q3_Trading_Knowledge | KYC source (pivot) | AnswerId for Q3 | Pivoted raw answer ID for Q3 (trading knowledge question) | Tier 2 |
| 11 | Q3_Is_Professional_Knowledge | KYC source (computed) | Q3 flags | 1 if Q3 answer indicates professional experience/courses/academic degree | Tier 2 |
| 12 | Q3_AnswerText | KYC source (computed) | Q3 flags | STRING_AGG composite of Is_Courses/Is_Professional_Experience/Is_Academic_Degree flags | Tier 2 |
| 13 | Q23_Assessment | KYC source (pivot) | AnswerId for Q23 | Pivoted raw answer ID for Q23 (assessment question) | Tier 2 |
| 14 | Q23_Is_Assessment_Pass | KYC source (computed) | Q23_AnswerID | 1 if Q23 answer ID indicates pass threshold | Tier 2 |
| 15 | Q23_AnswerText | KYC source (pivot) | AnswerText for Q23 | Answer text for Q23 | Tier 2 |
| 16 | Experience_Level | KYC source (computed) | Q33/Q34/Q35 answer IDs | MAX(mapped IDs) → 1=Non/2=Low/3=Med/4=High (label version); N/A if no answers | Tier 2 |
| 17 | Q33_Experience_Equities | KYC source (pivot) | AnswerId for Q33 | Pivoted raw answer ID for Q33 (equities experience) | Tier 2 |
| 18 | Q33_AnswerText | KYC source (pivot) | AnswerText for Q33 | Answer text for Q33 | Tier 2 |
| 19 | Q34_Experience_Crypto | KYC source (pivot) | AnswerId for Q34 | Pivoted raw answer ID for Q34 (crypto experience) | Tier 2 |
| 20 | Q34_AnswerText | KYC source (pivot) | AnswerText for Q34 | Answer text for Q34 | Tier 2 |
| 21 | Q35_Experience_CFDs | KYC source (pivot) | AnswerId for Q35 | Pivoted raw answer ID for Q35 (CFDs experience) | Tier 2 |
| 22 | Q35_AnswerText | KYC source (pivot) | AnswerText for Q35 | Answer text for Q35 | Tier 2 |
| 23 | Q2_Experience | KYC source (pivot) | AnswerId for Q2 | Pivoted raw answer ID for Q2 (trading experience) | Tier 2 |
| 24 | Q2_AnswerText | KYC source (pivot) | AnswerText for Q2 | Answer text for Q2 | Tier 2 |
| 25 | Q10_Annual_Income | KYC source (pivot) | AnswerId for Q10 | Pivoted raw answer ID for Q10 (annual income) | Tier 2 |
| 26 | Q10_AnswerText | KYC source (pivot) | AnswerText for Q10 | Answer text for Q10 | Tier 2 |
| 27 | Q11_Liquid_Assets | KYC source (pivot) | AnswerId for Q11 | Pivoted raw answer ID for Q11 (liquid assets) | Tier 2 |
| 28 | Q11_AnswerText | KYC source (pivot) | AnswerText for Q11 | Answer text for Q11 | Tier 2 |
| 29 | Q9_Risk_Reward_Scenario | KYC source (pivot) | AnswerId for Q9 | Pivoted raw answer ID for Q9 (risk/reward understanding) | Tier 2 |
| 30 | Q9_AnswerText | KYC source (pivot) | AnswerText for Q9 | Answer text for Q9 | Tier 2 |
| 31 | Q14_Planned_Invested_Amount | KYC source (pivot) | AnswerId for Q14 | Pivoted raw answer ID for Q14 (planned investment amount) | Tier 2 |
| 32 | Q14_AnswerText | KYC source (pivot) | AnswerText for Q14 | Answer text for Q14 | Tier 2 |
| 33 | Q27_Planned_Investment_Instrument | KYC source (pivot) | AnswerId for Q27 | Pivoted raw answer ID for Q27 (planned investment instrument — multi-select) | Tier 2 |
| 34 | Is_PI_Stocks | KYC source (computed) | Q27 answer IDs | 1 if customer answered Stocks in Q27 | Tier 2 |
| 35 | Is_PI_Crypto | KYC source (computed) | Q27 answer IDs | 1 if customer answered Crypto in Q27 | Tier 2 |
| 36 | Is_PI_FX | KYC source (computed) | Q27 answer IDs | 1 if customer answered FX/CFDs in Q27 | Tier 2 |
| 37 | Total_PI_Answers | KYC source (computed) | Q27 answer IDs | Count of distinct planned-instrument selections in Q27 | Tier 2 |
| 38 | Q5_Trading_Strategy | KYC source (pivot) | AnswerId for Q5 | Pivoted raw answer ID for Q5 (trading strategy) | Tier 2 |
| 39 | Q5_AnswerText | KYC source (pivot) | AnswerText for Q5 | Answer text for Q5 | Tier 2 |
| 40 | Q8_Trading_Primary_Purpose | KYC source (pivot) | AnswerId for Q8 | Pivoted raw answer ID for Q8 (primary trading purpose) | Tier 2 |
| 41 | Q8_AnswerText | KYC source (pivot) | AnswerText for Q8 | Answer text for Q8 | Tier 2 |
| 42 | Q15_Sources_of_Income | KYC source (pivot) | AnswerId for Q15 | Pivoted raw answer ID for Q15 (sources of income — multi-select, STRING_AGG) | Tier 2 |
| 43 | Q15_AnswerText | KYC source (computed) | Q15 answer texts | STRING_AGG of all Q15 multi-select answers | Tier 2 |
| 44 | Q26_Sources_of_Funds | KYC source (pivot) | AnswerId for Q26 | Pivoted raw answer ID for Q26 (sources of funds — multi-select, STRING_AGG) | Tier 2 |
| 45 | Q26_AnswerText | KYC source (computed) | Q26 answer texts | STRING_AGG of all Q26 multi-select answers | Tier 2 |
| 46 | Q18_Occupation | KYC source (pivot) | AnswerId for Q18 | Pivoted raw answer ID for Q18 (occupation) | Tier 2 |
| 47 | Q18_AnswerText | KYC source (pivot) | AnswerText for Q18 | Answer text for Q18 | Tier 2 |
| 48 | GapInDays_Reg_to_FTD_Group | SP-computed | Reg_Date, FTD_Date | `DATEDIFF(DAY, Reg_Date, FTD_Date)` bucketed: 0/1-3/4-7/8-14/15-30/31+/N/A | Tier 2 |
| 49 | DaysFromFTD_Group | SP-computed | FTD_Date, GETDATE()-1 | `DATEDIFF(DAY, FTD_Date, yesterday)` bucketed: 0/1-7/8-14/15-30/31+/N/A — recomputed every run | Tier 2 |
| 50 | VerificationLevelID | Dim_Customer | VerificationLevelID | Direct — KYC verification level (1=Basic, 2=Verified, 3=Fully Verified, etc.) | Tier 1 |
| 51 | CountryID | Dim_Customer | CountryID | Direct — FK to Dim_Country | Tier 1 |
| 52 | CountryName | Dim_Country | Country | Direct — country name | Tier 1 |
| 53 | Region | Dim_Country | Region | Direct — marketing region label | Tier 1 |
| 54 | EU | Dim_Country | EU | Direct — 1 if country is EU member | Tier 1 |
| 55 | RegulationID | Dim_Customer | RegulationID | Direct — FK to Dim_Regulation | Tier 1 |
| 56 | RegulatgionName | Dim_Regulation | Name | Direct — regulation name; column has deliberate typo (`RegulatgionName`) matching SP code — do NOT rename | Tier 2 |
| 57 | Club | Dim_PlayerLevel | Name | Direct — eToro Club tier name (Bronze/Silver/Gold/Platinum/Platinum Plus/Diamond) | Tier 1 |
| 58 | Gender | Dim_Customer | Gender | Direct — customer gender | Tier 1 |
| 59 | Age_Curr | Dim_Customer | Age_Curr | Direct — current age in years | Tier 1 |
| 60 | Age_On_Reg | Dim_Customer | Age_On_Reg | Direct — age at registration | Tier 3 |
| 61 | CFD_Status | BI_DB_Scored_Appropriateness | CFD_Status | Direct — CFD_Allowed / CFD_Blocked / NULL (no assessment) | Tier 2 |
| 62 | CFD_BlockDate | BI_DB_Scored_Appropriateness | BlockDate | Date CFD access was blocked | Tier 2 |
| 63 | CFD_BlockReasonDesc | BI_DB_Scored_Appropriateness | BlockReasonDesc | Text description of CFD block reason | Tier 2 |
| 64 | CFD_ReleaseDate | BI_DB_Scored_Appropriateness | ReleaseDate | Date CFD access was restored after being blocked | Tier 2 |
| 65 | CFD_ReleaseReasonDesc | BI_DB_Scored_Appropriateness | ReleaseReasonDesc | Text description of CFD release reason | Tier 2 |
| 66 | DateDiffBlockRelease | BI_DB_Scored_Appropriateness | DateDiffBlockRelease | Days between CFD block and release | Tier 2 |
| 67 | FirstDepositAmount | Dim_Customer | FirstDepositAmount | Direct — first deposit amount in USD | Tier 1 |
| 68 | FirstAction_Date | BI_DB_First5Actions | FirstActionDate | `CONVERT(CHAR(8), FirstActionDate, 112)` → date string | Tier 2 |
| 69 | FirstAction_Month | BI_DB_First5Actions | FirstActionDate | `YEAR*100+MONTH` → YYYYMM | Tier 2 |
| 70 | FirstAction | BI_DB_First5Actions | FirstAction | First trading action type (e.g., Buy/Sell) | Tier 2 |
| 71 | FirstAction_Detailed | BI_DB_First5Actions | FirstAction_Detailed | Detailed first action description | Tier 2 |
| 72 | FirstInstrument | BI_DB_First5Actions | FirstInstrument | First instrument traded | Tier 2 |
| 73 | Deposit7days | BI_DB_First5Actions | Deposit7days | Total deposits in first 7 days after FTD | Tier 2 |
| 74 | Deposit14days | BI_DB_First5Actions | Deposit14days | Total deposits in first 14 days after FTD | Tier 2 |
| 75 | Deposit30days | BI_DB_First5Actions | Deposit30days | Total deposits in first 30 days after FTD | Tier 2 |
| 76 | Revenue7days | BI_DB_First5Actions | Revenue7days | Revenue generated in first 7 days after FTD | Tier 2 |
| 77 | Revenue14days | BI_DB_First5Actions | Revenue14days | Revenue generated in first 14 days after FTD | Tier 2 |
| 78 | Revenue30days | BI_DB_First5Actions | Revenue30days | Revenue generated in first 30 days after FTD | Tier 2 |
| 79 | Equity7days | BI_DB_First5Actions | Equity7days | Customer equity at 7 days after FTD | Tier 2 |
| 80 | Equity14days | BI_DB_First5Actions | Equity14days | Customer equity at 14 days after FTD | Tier 2 |
| 81 | Equity30days | BI_DB_First5Actions | Equity30days | Customer equity at 30 days after FTD | Tier 2 |
| 82 | Q23_AnswerID | KYC source (pivot) | AnswerId for Q23 | Raw numeric answer ID for Q23 | Tier 2 |
| 83 | Q33_AnswerID | KYC source (pivot) | AnswerId for Q33 | Raw numeric answer ID for Q33 | Tier 2 |
| 84 | Q34_AnswerID | KYC source (pivot) | AnswerId for Q34 | Raw numeric answer ID for Q34 | Tier 2 |
| 85 | Q35_AnswerID | KYC source (pivot) | AnswerId for Q35 | Raw numeric answer ID for Q35 | Tier 2 |
| 86 | Q2_AnswerID | KYC source (pivot) | AnswerId for Q2 | Raw numeric answer ID for Q2 | Tier 2 |
| 87 | Q10_AnswerID | KYC source (pivot) | AnswerId for Q10 | Raw numeric answer ID for Q10 | Tier 2 |
| 88 | Q11_AnswerID | KYC source (pivot) | AnswerId for Q11 | Raw numeric answer ID for Q11 | Tier 2 |
| 89 | Q9_AnswerID | KYC source (pivot) | AnswerId for Q9 | Raw numeric answer ID for Q9 | Tier 2 |
| 90 | Q14_AnswerID | KYC source (pivot) | AnswerId for Q14 | Raw numeric answer ID for Q14 | Tier 2 |
| 91 | Q5_AnswerID | KYC source (pivot) | AnswerId for Q5 | Raw numeric answer ID for Q5 | Tier 2 |
| 92 | Q8_AnswerID | KYC source (pivot) | AnswerId for Q8 | Raw numeric answer ID for Q8 | Tier 2 |
| 93 | Q18_AnswerID | KYC source (pivot) | AnswerId for Q18 | Raw numeric answer ID for Q18 | Tier 2 |
| 94 | UpdateDate | SP-computed | GETDATE() | ETL metadata: timestamp when this row was last updated by the ETL pipeline | Tier 2 |
| 95 | KYC_LastUpdateDate | KYC source | MAX(OccurredAt) | Latest KYC answer submission timestamp from UserApiDB (max OccurredAt per GCID) | Tier 2 |
| 96 | Q29_Time_Frame_Investing | KYC source (pivot) | AnswerId for Q29 | Pivoted raw answer ID for Q29 (investment time frame) | Tier 2 |
| 97 | Q29_AnswerID | KYC source (pivot) | AnswerId for Q29 | Raw numeric answer ID for Q29 | Tier 2 |
| 98 | Q29_AnswerText | KYC source (pivot) | AnswerText for Q29 | Answer text for Q29 | Tier 2 |
| 99 | Q36_US_Permanent_Resident | KYC source (pivot) | AnswerId for Q36 | Pivoted raw answer ID for Q36 (US permanent residency — US-specific) | Tier 2 |
| 100 | Q36_AnswerID | KYC source (pivot) | AnswerId for Q36 | Raw numeric answer ID for Q36 | Tier 2 |
| 101 | Q36_AnswerText | KYC source (pivot) | AnswerText for Q36 | Answer text for Q36 | Tier 2 |
| 102 | Q40_W9_Certification | KYC source (pivot) | AnswerId for Q40 | Pivoted raw answer ID for Q40 (W9 tax certification — US-specific) | Tier 2 |
| 103 | Q40_AnswerID | KYC source (pivot) | AnswerId for Q40 | Raw numeric answer ID for Q40 | Tier 2 |
| 104 | Q40_AnswerText | KYC source (pivot) | AnswerText for Q40 | Answer text for Q40 | Tier 2 |
| 105 | Q30_FINRA | KYC source (pivot) | AnswerId for Q30 | Pivoted raw answer ID for Q30 (FINRA affiliation question — multi-select) | Tier 2 |
| 106 | Q30_Is_Shareholder | KYC source (computed) | Q30 answer IDs | 1 if Q30 answer includes "shareholder" option | Tier 2 |
| 107 | Q30_Is_Employed_By_Broker | KYC source (computed) | Q30 answer IDs | 1 if Q30 answer includes "employed by broker/dealer" option | Tier 2 |
| 108 | Q30_Is_Public_Official | KYC source (computed) | Q30 answer IDs | 1 if Q30 answer includes "public official/government employee" option | Tier 2 |
| 109 | Q30_Is_None_Apply_To_Me | KYC source (computed) | Q30 answer IDs | 1 if Q30 answer is "none of the above" | Tier 2 |
| 110 | Q32_PEP_MM_Question | KYC source (pivot) | AnswerId for Q32 | Pivoted raw answer ID for Q32 (PEP/money manager question — multi-select) | Tier 2 |
| 111 | Q32_Is_Shareholder | KYC source (computed) | Q32 answer IDs | 1 if Q32 answer includes shareholder option | Tier 2 |
| 112 | Q32_Is_Employed_By_Broker | KYC source (computed) | Q32 answer IDs | 1 if Q32 answer includes broker/dealer employment | Tier 2 |
| 113 | Q32_Is_Public_Official | KYC source (computed) | Q32 answer IDs | 1 if Q32 answer includes public official status | Tier 2 |
| 114 | Q32_Is_None_Apply_To_Me | KYC source (computed) | Q32 answer IDs | 1 if Q32 answer is "none apply" | Tier 2 |
| 115 | Q50_Is_Vulnerable_Client | KYC source (pivot) | AnswerId for Q50 | Pivoted raw answer ID for Q50 (vulnerable client self-assessment — FCA-specific) | Tier 2 |
| 116 | Q50_AnswerID | KYC source (pivot) | AnswerId for Q50 | Raw numeric answer ID for Q50 | Tier 2 |
| 117 | Q50_AnswerText | KYC source (pivot) | AnswerText for Q50 | Answer text for Q50 | Tier 2 |
| 118 | Q45_Invested_Amount_CFDs | KYC source (pivot) | AnswerId for Q45 | Pivoted raw answer ID for Q45 (invested amount in CFDs) | Tier 2 |
| 119 | Q45_AnswerID | KYC source (pivot) | AnswerId for Q45 | Raw numeric answer ID for Q45 | Tier 2 |
| 120 | Q45_AnswerText | KYC source (pivot) | AnswerText for Q45 | Answer text for Q45 | Tier 2 |
| 121 | Q47_Invested_Amount_Equities | KYC source (pivot) | AnswerId for Q47 | Pivoted raw answer ID for Q47 (invested amount in equities) | Tier 2 |
| 122 | Q47_AnswerID | KYC source (pivot) | AnswerId for Q47 | Raw numeric answer ID for Q47 | Tier 2 |
| 123 | Q47_AnswerText | KYC source (pivot) | AnswerText for Q47 | Answer text for Q47 | Tier 2 |
| 124 | Q48_Invested_Amount_Crypto | KYC source (pivot) | AnswerId for Q48 | Pivoted raw answer ID for Q48 (invested amount in crypto) | Tier 2 |
| 125 | Q48_AnswerID | KYC source (pivot) | AnswerId for Q48 | Raw numeric answer ID for Q48 | Tier 2 |
| 126 | Q48_AnswerText | KYC source (pivot) | AnswerText for Q48 | Answer text for Q48 | Tier 2 |
| 127 | Assessment_Type | SP-computed | Q23/Q33/Q34/Q35 answer IDs | Answer ID range → AnswerID_84_87/AnswerID_101_104/AnswerID_142_146/N/A | Tier 2 |
| 128 | Total_Points_Assessment_142_146 | SP-computed | Q23/appropriateness answers | +2 per correct / -2 per wrong answer (142-146 type only); -100 sentinel for non-142-146 | Tier 2 |

## UC External Lineage

UC Target: Not Migrated
