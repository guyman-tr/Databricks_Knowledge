# BI_DB_dbo.BI_DB_AML_Singapore_Risk_Classification — Lineage

**Generated**: 2026-04-22  
**Writer SP**: SP_AML_Singapore_Risk_Classification  
**Load Pattern**: TRUNCATE + INSERT daily (@Date parameter)  

---

## Source Objects

| Object | Schema | Type | Role |
|---|---|---|---|
| Fact_SnapshotCustomer | DWH_dbo | Fact (snapshot) | Base population: point-in-time customer snapshot for @Date; supplies VerificationLevelID, CountryID, RegulationID, PlayerLevelID, PlayerStatusID |
| Dim_Customer | DWH_dbo | Dimension | Current customer attributes: GCID, CitizenshipCountryID, CountryIDByIP, POBCountryID, RegisteredReal, FirstDepositDate, IsDepositor, ScreeningStatusID |
| Dim_Regulation | DWH_dbo | Dimension | Regulation name (always 'MAS' — RegulationID=13 filter) |
| Dim_Country | DWH_dbo | Dimension | Country name lookups for Country, Nationality_Country, POBCountry, CountryIDByIP |
| Dim_PlayerLevel | DWH_dbo | Dimension | Club/loyalty tier name |
| Dim_PlayerStatus | DWH_dbo | Dimension | PlayerStatus name; excludes status IDs 2 (Blocked) and 4 (Blocked Upon Request) |
| Dim_ScreeningStatus | DWH_dbo | Dimension | Screening status; drives ScreeningStatus enrichment (Domestic PEP / Foreign PEP logic) |
| Dim_Range | DWH_dbo | Dimension | Date range for Fact_SnapshotCustomer point-in-time lookup (DateRangeID filter: @DateID BETWEEN FromDateID AND ToDateID) |
| Dim_Position | DWH_dbo | Dimension/Fact | Instrument positions; crypto detection (InstrumentTypeID=10, IsSettled=1) for Instrument_Risk_Score |
| Dim_Instrument | DWH_dbo | Dimension | Instrument type lookup; used to identify crypto positions (InstrumentTypeID=10) |
| Fact_CustomerAction | DWH_dbo | Fact | Deposits (ActionTypeID=7) and cashouts (ActionTypeID=8) for Net_Deposits + Redeem_Score (IsRedeem=1) |
| BI_DB_KYC_Panel | BI_DB_dbo | Table | Q10 (annual income), Q11 (liquid assets), Q18 (occupation), Q26 (source of funds) answers |
| BI_DB_KYC_Questions_Answers_Row_Data | BI_DB_dbo | Table | Q216 (employment status) answer |
| BI_DB_CIDFirstDates | BI_DB_dbo | Table | VerificationLevel2Date, VerificationLevel3Date (first dates by level) |
| External_Fivetran_google_sheets_risk_score_country | BI_DB_dbo | External | Singapore-specific AML country risk scores (sg_country_aml_rank: Low/Medium/High/Blocked) via Fivetran |
| External_UserApiDB_Customer_ExtendedUserField | BI_DB_dbo | External | TIN declaration (FieldId=6) for TIN_CountryName |
| External_UserApiDB_KYC_CountryTaxType | BI_DB_dbo | External | Tax country type validation for TIN lookup |
| External_UserApiDB_Customer_AdditionalCitizenship | BI_DB_dbo | External | Second citizenship country for Citizenship_Sec_Final_Score |

---

## Writer

| SP | Author | Date | Load Pattern |
|---|---|---|---|
| SP_AML_Singapore_Risk_Classification | — | — | TRUNCATE TABLE + INSERT from #riskscore2; @Date parameter |

---

## Downstream Consumers

None identified in the SSDT repository. This table is an AML compliance operational feed for the Singapore (MAS) regulatory team.

---

## ETL Data Flow

```
[Date Parameter]
@Date → @DateID = BI_DB_dbo.DateToDateID(@Date)

[Base Population — MAS only]
DWH_dbo.Fact_SnapshotCustomer (IsValidCustomer=1, VerificationLevelID>=2, RegulationID=13/MAS)
  JOIN Dim_Range (point-in-time: @DateID BETWEEN FromDateID AND ToDateID)
  JOIN Dim_Regulation (RegulationID=13 → 'MAS')
  JOIN Dim_PlayerLevel (via PlayerLevelID) → Club
  JOIN Dim_PlayerStatus (PlayerStatusID NOT IN 2,4) → PlayerStatus
  JOIN Dim_Customer (via RealCID) → GCID, CitizenshipCountryID, CountryIDByIP, POBCountryID, RegisteredReal, FirstDepositDate, ScreeningStatusID
  JOIN Dim_Country dc1 (via fsc.CountryID) → Country
  LEFT JOIN Dim_Country dc2 (via CitizenshipCountryID) → Nationality_Country, Nationality_Country_ID
  LEFT JOIN Dim_Country dc3 (via CountryIDByIP) → CountryIDByIP (resolved name)
  LEFT JOIN Dim_Country dc4 (via POBCountryID) → POBCountry
  LEFT JOIN Dim_ScreeningStatus → ScreeningStatus, ScreeningStatusID
  LEFT JOIN BI_DB_CIDFirstDates → VerificationLevel2Date, VerificationLevel3Date
  @Date → Report_Date
  → #pop (MAS base population)

CREATE CLUSTERED INDEX ON #pop (CID)

[TIN]
External_UserApiDB_Customer_ExtendedUserField (FieldId=6, GCID JOIN)
  JOIN External_UserApiDB_KYC_CountryTaxType (valid tax countries)
  JOIN Dim_Country (name lookup)
  → #TIN_Value (CID, TaxCountry)

[Screening Enrichment]
#pop WHERE ScreeningStatusID <> 7 (exclude Sanctions Match):
  Domestic PEP (ScreeningStatusID=3, Nationality=Singapore/CountryID=183) → score=50
  Foreign PEP (ScreeningStatusID=3, Nationality≠Singapore) → score=200
  Risk Match (ScreeningStatusID=4) → score=200
  No Match (ScreeningStatusID=1) → score=0
  → #Screening (ScreeningStauts_Final_Score)

#pop WHERE ScreeningStatusID = 7 (Sanctions Match only):
  → #ScreeningB (Screening_Block_Final='Blocked')

[KYC Answers]
BI_DB_KYC_Panel Q26 → #sof_kyc:
  Savings/Salary/Investments/Pension/Severance = 0
  Inheritance/Other/Family financial support = 50
  Lottery/Gambling = 100
  MAX score per CID when multiple answers
  → Sources_of_funds_Final_Score

BI_DB_KYC_Panel Q18 (by AnswerID) → #occupation:
  List of 29 high-risk occupation IDs → 50
  4 moderate-risk IDs → 25
  Others → 0
  → Occupation_Final_Score

BI_DB_KYC_Questions_Answers_Row_Data Q216 → #Employment:
  Self-employed / Not Employed / Retired → 50; Others → 0
  → Employment_Status, Employment_Status_Final_Score

BI_DB_KYC_Panel Q10 → #AnnualIncome:
  '$1M-$5M' → 50; Others → 0
  → Annual_Income_Answer, Annual_Income_Final_Score

BI_DB_KYC_Panel Q11 → #LiquidAssets:
  'Over $1M' or '$1M-$5M' → 50; Others → 0
  → Q11_Liquid_Assets_Answer, Liquid_Assets_Final_Score

[Country Risk — Singapore GRC Sheet]
External_Fivetran_google_sheets_risk_score_country (sg_country_aml_rank):
  Low=0, Medium=50, High=100, Blocked=300

  Via Nationality_Country → #natinonality (Nationality_Final_Score) + #natinonalityB (Nationality_B flag)
  Via KYC Country → #KYC_Country (KYC_Country_Final_Score) + #KYC_Country_B (KYC_Country_B flag)
  Via POBCountry → #POB (POB_Final_Score) + #POB_B (POB_B flag)
  Via Second Citizenship (External_UserApiDB_Customer_AdditionalCitizenship)
    → #Citizenship_Sec (Citizenship_Sec_Final_Score) + #Citizenship_Sec_B (Citizenship_Sec_B flag)

  MAX(Nationality, POB, KYC_Country, Citizenship_Sec scores) → #final_Country.Max_Final_Score

[Financial Risk]
Fact_CustomerAction (ActionTypeID=7 deposits) → #deposits (TotalDeposits)
Fact_CustomerAction (ActionTypeID=8 cashouts) → #co (TotalCO)
#deposits - #co → #NetDeposit → #NetDeposit2:
  Net_Deposits > $1,000,000 → 100; else 0
  → Net_Deposits, Net_Deposits_Final_Score

[Product/Instrument Risk]
Dim_Position + Dim_Instrument (InstrumentTypeID IN 1,2,4,5,6,10):
  Has settled crypto position (InstrumentTypeID=10, IsSettled=1) → Instrument_Risk_Score=50; else 0

[Redeem Risk]
Fact_CustomerAction (ActionTypeID=8, IsRedeem=1) → #Redeem:
  Has redeem cashout → Redeem_Score=100; else 0

[Assembly]
#pop LEFT JOIN all temp tables above → #final

[Max Country Score]
#final CROSS APPLY MAX(Nationality, POB, KYC_Country, Citizenship_Sec scores) → #final_Country

[Final Score]
ScreeningStauts_Final_Score + Sources_of_funds_Final_Score + Occupation_Final_Score
+ Employment_Status_Final_Score + Annual_Income_Final_Score + Liquid_Assets_Final_Score
+ Net_Deposits_Final_Score + Max_Final_Score + Redeem_Score + Instrument_Risk_Score
= Final_Score → #FinalScore, #riskscore

[Risk Classification]
Blocked: Screening_Block_Final='Blocked' OR NationalityB='Blocked' OR POB_B='Blocked'
         OR Citizenship_Sec_B='Blocked' OR KYC_Country_B='Blocked'
High: Final_Score >= 200 (and not Blocked)
Low: Final_Score < 100 (and not Blocked)
Medium: 100 ≤ Final_Score ≤ 199 (and not Blocked)
→ #riskscore2

TRUNCATE TABLE BI_DB_dbo.BI_DB_AML_Singapore_Risk_Classification
INSERT INTO BI_DB_dbo.BI_DB_AML_Singapore_Risk_Classification FROM #riskscore2
```
