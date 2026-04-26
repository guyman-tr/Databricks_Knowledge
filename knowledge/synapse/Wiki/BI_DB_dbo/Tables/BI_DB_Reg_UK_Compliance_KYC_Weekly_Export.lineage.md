# Column Lineage — BI_DB_dbo.BI_DB_Reg_UK_Compliance_KYC_Weekly_Export

**Writer SP**: `BI_DB_dbo.SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export`
**UC Target**: `_Not_Migrated`
**Generated**: 2026-04-21
**Author**: Nir Weber (2022-03-27) | Migrated to Synapse: Slavane (2023-06-06) | DSR-1848

## Column Lineage

| DWH Column | Source Table | Source Column | Transform | Tier |
|------------|-------------|---------------|-----------|------|
| Regulation | DWH_dbo.Dim_Regulation | Name | WHERE DesignatedRegulationID IN (1=CySEC, 2=FCA) | Tier 2 |
| RealCID | DWH_dbo.Dim_Customer | RealCID | Direct passthrough | Tier 2 |
| RelevKnowl | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Do you have relevant knowledge in trading?' | Tier 2 |
| Inv10Income | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Does the total amount invested by you represent 10% or more of your annual income?' | Tier 2 |
| EduTools | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Educational tools reviewed' | Tier 2 |
| PlanInvAmt | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'How much money do you plan to invest in your eToro account in the next year ?' | Tier 2 |
| NotCrimea | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'I am Not From Crimea region.' | Tier 2 |
| ReadRisks | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'I have read and understood the Risks involved in CFD\'s products and I am Above 18.' | Tier 2 |
| InvAmtCFD | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Invested amount-Leveraged CFDs' | Tier 2 |
| WhichInst | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'In which instruments do you plan To trade?' | Tier 2 |
| IsraeliQlf | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Israeli Qualified and Classified statement' | Tier 2 |
| RiskDiscl | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Risk disclosure disclaimer' | Tier 2 |
| RiskReview | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Risk disclosure reviewed' | Tier 2 |
| SuitExpHigh | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Suitability Assessment Experience High Tier disclaimer' | Tier 2 |
| SuitExpLow | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Suitability Assessment Experience Low Tier disclaimer' | Tier 2 |
| SuitObjHigh | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Suitability Assessment Objectives High Tier disclaimer' | Tier 2 |
| SuitObjLow | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Suitability Assessment Objectives Low Tier disclaimer' | Tier 2 |
| ExpCrypto | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Trading Experience-Crypto Assets' | Tier 2 |
| ExpEquities | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Trading Experience-Equities' | Tier 2 |
| ExpCFD | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Trading Experience-Leveraged CFDs' | Tier 2 |
| TradingFreq | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Trading frequency' | Tier 2 |
| KnowledgeAsst | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Trading Knowledge Assessment' | Tier 2 |
| SourceIncome | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'What are your main sources of income?' | Tier 2 |
| SourceFunds | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'What are your sources of funds' | Tier 2 |
| PurposeTrad | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'What best describes your primary purpose of trading with us?' | Tier 2 |
| TradExp | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'What is your level of trading experience?' | Tier 2 |
| AnnualInc | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'What is your net annual income?' | Tier 2 |
| Occupation | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'What Is your occupation?' | Tier 2 |
| CashLiquAst | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'What is your total cash and liquid assets?' | Tier 2 |
| MktsTraded | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Which markets have you traded?' | Tier 2 |
| RiskRewardSc | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT MAX WHERE QuestionText = 'Which risk/reward scenario best describes your expectations with respect to your annual investments with us?' | Tier 2 |
| OpenCFDPositions | DWH_dbo.Dim_Position | PositionID | COUNT(DISTINCT PositionID) WHERE IsSettled=0 AND CloseDateID=0 AND MirrorID=0 | Tier 2 |
| LastPosOpCFD | DWH_dbo.Dim_Position | OpenOccurred | MAX(OpenOccurred) WHERE MirrorID=0 AND IsSettled=0 AND OpenDateID >= @1yearagoid | Tier 2 |
| DaysLastPosOpCFD | DWH_dbo.Dim_Position | OpenOccurred | DATEDIFF(day, LastPositionOpenDateCFD, GETDATE()) — computed at insert time | Tier 2 |
| Club | BI_DB_dbo.BI_DB_CIDFirstDates | Club | Passthrough; SP filters to Gold/Platinum/Platinum Plus/Diamond eligible | Tier 2 |
| Desk | DWH_dbo.Dim_Country | Desk | Sales desk assignment from Dim_Country.Desk via CountryID | Tier 2 |
| Manager | BI_DB_dbo.BI_DB_CIDFirstDates | Manager | Passthrough from BI_DB_CIDFirstDates.Manager (account manager full name) | Tier 2 |
| MifidCategorisation | DWH_dbo.Dim_MifidCategorization | Name | Resolved via Dim_Customer.MifidCategorizationID | Tier 2 |
| CountryOfResidence | DWH_dbo.Dim_Country | Name | Country name text from Dim_Country.Name via Dim_Customer.CountryID | Tier 2 |
| UpdateDate | ETL metadata | — | GETDATE() at insert — weekly snapshot timestamp | Tier 3 |

## Source Objects

| Source | Role |
|--------|------|
| DWH_dbo.Dim_Customer | Customer identity — RealCID, DesignatedRegulationID, IsValidCustomer, IsDepositor, MifidCategorizationID, CountryID |
| DWH_dbo.Dim_Regulation | Regulation name (CySEC, FCA) |
| DWH_dbo.Dim_MifidCategorization | MiFID II categorisation name |
| DWH_dbo.Dim_Country | Country name and Desk assignment |
| BI_DB_dbo.BI_DB_CIDFirstDates | Club membership tier, Desk, Manager — filtered to Gold/Platinum/Platinum Plus/Diamond |
| BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | KYC questionnaire question/answer pairs per customer |
| DWH_dbo.Dim_Position | Open CFD position count and last CFD open date |
| DWH_dbo.Dim_Instrument | JOIN context for CFD position queries |

## Eligibility Filter

Only customers satisfying ALL conditions are included:
- DesignatedRegulationID IN (1=CySEC, 2=FCA)
- IsValidCustomer = 1
- IsDepositor = 1
- Club IN ('Platinum', 'Platinum Plus', 'Diamond', 'Gold') from BI_DB_CIDFirstDates

## ETL Pipeline

```
DWH_dbo.Dim_Customer (CySEC + FCA regulated depositors only)
  + DWH_dbo.Dim_Regulation, Dim_MifidCategorization, Dim_Country
  + BI_DB_dbo.BI_DB_CIDFirstDates (Club IN Gold/Platinum/PlatPlus/Diamond)
    → #Clients temp table
BI_DB_dbo.BI_DB_KYCUserRawDataLeveled
    → #kyc PIVOT(MAX AnswerText FOR QuestionText) — 29 KYC question columns
DWH_dbo.Dim_Position + Dim_Instrument
    → #opencfd (open CFD count) + #lastposcfd (last CFD date)
    |-- SP_W_Tue_Reg_UK_Compliance_KYC_Weekly_Export (Weekly/Tuesday, Priority 21, SB_Daily) ---|
    v                                                                 [TRUNCATE + INSERT]
BI_DB_dbo.BI_DB_Reg_UK_Compliance_KYC_Weekly_Export
  (400,591 rows | latest snapshot 2026-04-07 | ROUND_ROBIN HEAP)
    |-- UC: _Not_Migrated
```
