# Lineage: BI_DB_dbo.BI_DB_M_Compliance_CDIM_Report

## Source Objects

| Source Object | Type | Relationship | Join/Filter |
|---|---|---|---|
| DWH_dbo.Dim_Customer | Table | Primary population | WHERE IsValidCustomer=1 AND VerificationLevelID=3 AND IsDepositor=1 AND RegulationID=2 (FCA) |
| DWH_dbo.Dim_Country | Table | JOIN (country decode) | ON dc1.CountryID = dc.CountryID |
| DWH_dbo.Dim_PlayerStatus | Table | JOIN (status decode) | ON dc.PlayerStatusID = dps.PlayerStatusID AND PlayerStatusID NOT IN (2,4) |
| DWH_dbo.Dim_PlayerLevel | Table | JOIN (club tier decode) | ON dc.PlayerLevelID = dpl.PlayerLevelID |
| DWH_dbo.Dim_Regulation | Table | JOIN (regulation decode) | ON dr.DWHRegulationID = dc.RegulationID AND DWHRegulationID=2 (FCA only) |
| DWH_dbo.Dim_MifidCategorization | Table | LEFT JOIN (MiFID decode) | ON mif.MifidCategorizationID = dc.MifidCategorizationID |
| BI_DB_dbo.BI_DB_CIDFirstDates | Table | LEFT JOIN (lifecycle milestones) | ON dc.RealCID = fd.CID |
| DWH_dbo.Dim_Channel | Table | LEFT JOIN (channel decode) | ON dch.SubChannelID = dc.SubChannelID |
| DWH_dbo.Dim_Position | Table | JOIN (position activity + PnL) | ON dp.CID = pp.CID; filters OpenDateID/CloseDateID >= @1yearagoid |
| DWH_dbo.Dim_Instrument | Table | JOIN (instrument type decode) | ON dp.InstrumentID = di.InstrumentID |
| BI_DB_dbo.BI_DB_First5Actions | Table | JOIN (first action date) | ON fa.CID = pp.CID |
| BI_DB_dbo.BI_DB_Demo_CID_Panel | Table | JOIN (demo trading info) | ON demo.CID = pp.CID |
| BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market | Table | JOIN (appropriateness + negative market) | ON pp.CID = neg.RealCID |
| BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | Table | LEFT JOIN (KYC answers pivot) | ON KYC.RealCID = pp.CID |
| BI_DB_dbo.BI_DB_PositionPnL | Table | JOIN (unrealised PnL) | ON pp.CID = ppl.CID WHERE DateID = @PnLDateid |
| DWH_dbo.Fact_CustomerAction | Table | JOIN (rollover fees) | ON fca.RealCID = pp.CID WHERE ActionTypeID=35 AND IsFeeDividend=1 |

## Column Lineage

| Target Column | Source Object | Source Column | Transform |
|---|---|---|---|
| CID | DWH_dbo.Dim_Customer | RealCID | Rename (RealCID AS CID) |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup passthrough via Dim_Customer.RegulationID |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Dim-lookup passthrough via Dim_Customer.PlayerStatusID |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Dim-lookup passthrough via Dim_Customer.PlayerLevelID |
| Desk | DWH_dbo.Dim_Country | Desk | Dim-lookup passthrough via Dim_Customer.CountryID |
| Manager | BI_DB_dbo.BI_DB_CIDFirstDates | Manager | Passthrough |
| MifidCategorisation | DWH_dbo.Dim_MifidCategorization | Name | Dim-lookup passthrough via Dim_Customer.MifidCategorizationID |
| CountryOfResidence | DWH_dbo.Dim_Country | Name | Dim-lookup passthrough via Dim_Customer.CountryID |
| BirthDate | DWH_dbo.Dim_Customer | BirthDate | Passthrough |
| CameFromAffiliate | DWH_dbo.Dim_Customer | SubChannelID | CASE WHEN SubChannelID IN (20,31) THEN 1 ELSE 0 END |
| VerificationLevel3Date | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel3Date | CONVERT(DATE, ...) |
| Occupation | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='What Is your occupation?' |
| RiskRewardSc | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Which risk/reward scenario...' |
| AnnualInc | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='What is your net annual income?' |
| CashLiquAst | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='What is your total cash and liquid assets?' |
| PurposeTrad | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='What best describes your primary purpose of trading with us?' |
| PlanInvAmt | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='How much money do you plan to invest...' |
| Appropriateness_Status | BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market | ApproprietnessScore_Status | Passthrough (renamed) |
| AVG_CFD_Leverage | DWH_dbo.Dim_Position | Leverage | AVG(CASE WHEN IsSettled=0 THEN Leverage*1.00 END) per CID |
| IsTradedDemo | BI_DB_dbo.BI_DB_Demo_CID_Panel | IsTradedDemo | Passthrough |
| UsedDemoBeforeLivePlatform | BI_DB_dbo.BI_DB_Demo_CID_Panel / BI_DB_dbo.BI_DB_First5Actions | FirstDemoTrade, FirstActionDate | CASE WHEN IsTradedDemo=0 THEN NULL WHEN FirstDemoTrade < FirstActionDate THEN 1 WHEN >= THEN 0 END |
| KnowledgeAsst | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Trading Knowledge Assessment' |
| RelevKnowl | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Do you have relevant knowledge in trading?' |
| Inv10Income | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Does the total amount invested...10% or more...' |
| EduTools | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Educational tools reviewed' |
| NotCrimea | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='I am Not From Crimea region.' |
| ReadRisks | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='I have read and understood the Risks...' |
| InvAmtCFD | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Invested amount-Leveraged CFDs' |
| WhichInst | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='In which instruments do you plan To trade?' |
| IsraeliQlf | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Israeli Qualified and Classified statement' |
| RiskDiscl | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Risk disclosure disclaimer' |
| RiskReview | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Risk disclosure reviewed' |
| SuitExpHigh | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Suitability Assessment Experience High Tier disclaimer' |
| SuitExpLow | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Suitability Assessment Experience Low Tier disclaimer' |
| SuitObjHigh | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Suitability Assessment Objectives High Tier disclaimer' |
| SuitObjLow | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Suitability Assessment Objectives Low Tier disclaimer' |
| ExpCrypto | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Trading Experience-Crypto Assets' |
| ExpEquities | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Trading Experience-Equities' |
| ExpCFD | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Trading Experience-Leveraged CFDs' |
| TradingFreq | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Trading frequency' |
| SourceIncome | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='What are your main sources of income?' |
| TradExp | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='What is your level of trading experience?' |
| MktsTraded | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='Which markets have you traded?' |
| SourceFunds | BI_DB_dbo.BI_DB_KYCUserRawDataLeveled | AnswerText | PIVOT on QuestionText='What are your sources of funds' |
| NegativeMarket | BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market | BlockReasonDesc | Passthrough WHERE BlockReasonID=12 AND RestrictionStatusDesc='Failed' (renamed to NegativeMarket) |
| CFD_Copy_PnL | DWH_dbo.Dim_Position / BI_DB_dbo.BI_DB_PositionPnL / DWH_dbo.Fact_CustomerAction | NetProfit, PositionPnL, Amount | SUM(realised+unrealised) WHERE MirrorID<>0 AND IsSettled=0, minus copy rollover fees |
| CFD_Manual_PnL | DWH_dbo.Dim_Position / BI_DB_dbo.BI_DB_PositionPnL / DWH_dbo.Fact_CustomerAction | NetProfit, PositionPnL, Amount | SUM(realised+unrealised) WHERE MirrorID=0 AND IsSettled=0, minus manual rollover fees |
| Stocks_Copy_PnL | DWH_dbo.Dim_Position / BI_DB_dbo.BI_DB_PositionPnL | NetProfit, PositionPnL | SUM(realised+unrealised) WHERE MirrorID<>0 AND IsSettled=1 AND InstrumentType IN ('Stocks','ETF') |
| Stocks_Manual_PnL | DWH_dbo.Dim_Position / BI_DB_dbo.BI_DB_PositionPnL | NetProfit, PositionPnL | SUM(realised+unrealised) WHERE MirrorID=0 AND IsSettled=1 AND InstrumentType IN ('Stocks','ETF') |
| Crypto_Copy_PnL | DWH_dbo.Dim_Position / BI_DB_dbo.BI_DB_PositionPnL | NetProfit, PositionPnL | SUM(realised+unrealised) WHERE MirrorID<>0 AND IsSettled=1 AND InstrumentType='Crypto Currencies' |
| Crypto_Manual_PnL | DWH_dbo.Dim_Position / BI_DB_dbo.BI_DB_PositionPnL | NetProfit, PositionPnL | SUM(realised+unrealised) WHERE MirrorID=0 AND IsSettled=1 AND InstrumentType='Crypto Currencies' |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |
