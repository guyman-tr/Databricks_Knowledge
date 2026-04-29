# BI_DB_dbo.BI_DB_W_Mon_Compliance_CDIM_Report — Column Lineage

## Source Objects

| Source Object | Schema | Role | Join Condition |
|--------------|--------|------|----------------|
| DWH_dbo.Dim_Customer | DWH_dbo | Primary — FCA verified depositors | IsValidCustomer=1, VerificationLevelID=3, IsDepositor=1 |
| DWH_dbo.Dim_Country | DWH_dbo | Dim lookup — country + desk | CountryID = dc.CountryID |
| DWH_dbo.Dim_PlayerStatus | DWH_dbo | Dim lookup — player status (NOT IN 2,4) | PlayerStatusID = dc.PlayerStatusID |
| DWH_dbo.Dim_PlayerLevel | DWH_dbo | Dim lookup — club tier | PlayerLevelID = dc.PlayerLevelID |
| DWH_dbo.Dim_Regulation | DWH_dbo | Dim lookup — regulation (FCA only) | DWHRegulationID = dc.RegulationID AND DWHRegulationID=2 |
| DWH_dbo.Dim_MifidCategorization | DWH_dbo | LEFT JOIN — MiFID classification | MifidCategorizationID = dc.MifidCategorizationID |
| BI_DB_dbo.BI_DB_CIDFirstDates | BI_DB_dbo | LEFT JOIN — manager, VL3 date | CID = dc.RealCID |
| DWH_dbo.Dim_Position | DWH_dbo | JOIN — active traders filter (opened/closed past year) | CID = pp.CID, OpenDateID or CloseDateID >= 1yearago |
| BI_DB_dbo.BI_DB_KYC_Panel | BI_DB_dbo | LEFT JOIN — KYC questionnaire answers | CID = pp.CID (via RealCID) |
| BI_DB_dbo.BI_DB_Demo_CID_Panel | BI_DB_dbo | LEFT JOIN — demo trading history | CID = pp.CID |
| BI_DB_dbo.BI_DB_First5Actions | BI_DB_dbo | JOIN — first action date for demo timing | CID = pp.CID |
| BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market | BI_DB_dbo | LEFT JOIN — appropriateness + negative market | RealCID = pp.CID |
| BI_DB_dbo.BI_DB_KYC_Knowledge_Assessment | BI_DB_dbo | LEFT JOIN — knowledge assessment scores | GCID match via Dim_Customer |
| DWH_dbo.Dim_Instrument | DWH_dbo | JOIN — instrument type for PnL split | InstrumentID |
| BI_DB_dbo.BI_DB_PositionPnL | BI_DB_dbo | JOIN — unrealized PnL | CID, DateID = yesterday |
| DWH_dbo.Fact_CustomerAction | DWH_dbo | JOIN — rollover fees | RealCID, ActionTypeID=35, IsFeeDividend=1 |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---------------|-------------|---------------|-----------|
| CID | DWH_dbo.Dim_Customer | RealCID | Rename |
| Regulation | DWH_dbo.Dim_Regulation | Name | Passthrough (always 'FCA') |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus | Name | Passthrough (excludes Blocked, Blocked Upon Request) |
| Club | DWH_dbo.Dim_PlayerLevel | Name | Passthrough via dim lookup |
| Desk | DWH_dbo.Dim_Country | Desk | Passthrough via dim lookup |
| Manager | BI_DB_dbo.BI_DB_CIDFirstDates | Manager | Passthrough |
| MifidCategorisation | DWH_dbo.Dim_MifidCategorization | Name | Passthrough via dim lookup |
| CountryOfResidence | DWH_dbo.Dim_Country | Name | Passthrough via dim lookup |
| BirthDate | DWH_dbo.Dim_Customer | BirthDate | Passthrough |
| CameFromAffiliate | DWH_dbo.Dim_Customer | SubChannelID | CASE WHEN SubChannelID IN (20,31) THEN 1 ELSE 0 |
| VerificationLevel3Date | BI_DB_dbo.BI_DB_CIDFirstDates | VerificationLevel3Date | CONVERT(DATE) |
| Occupation | BI_DB_dbo.BI_DB_KYC_Panel | Q18_AnswerText | Passthrough |
| RiskRewardSc | BI_DB_dbo.BI_DB_KYC_Panel | Q9_AnswerText | Passthrough |
| AnnualInc | BI_DB_dbo.BI_DB_KYC_Panel | Q10_AnswerText | Passthrough |
| CashLiquAst | BI_DB_dbo.BI_DB_KYC_Panel | Q11_AnswerText | Passthrough |
| PurposeTrad | BI_DB_dbo.BI_DB_KYC_Panel | Q8_AnswerText | Passthrough |
| PlanInvAmt | BI_DB_dbo.BI_DB_KYC_Panel | Q14_AnswerText | Passthrough |
| Appropriateness_Status | BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market | ApproprietnessScore_Status | Passthrough |
| AVG_CFD_Leverage | DWH_dbo.Dim_Position | Leverage | AVG(Leverage) WHERE IsSettled=0 |
| IsTradedDemo | BI_DB_dbo.BI_DB_Demo_CID_Panel | IsTradedDemo | Passthrough |
| UsedDemoBeforeLivePlatform | BI_DB_dbo.BI_DB_Demo_CID_Panel + BI_DB_First5Actions | FirstDemoTrade, FirstActionDate | CASE: 1 if demo before live, 0 if after, NULL if no demo |
| KnowledgeAsst | BI_DB_dbo.BI_DB_KYC_Panel | Q23_AnswerText | Passthrough |
| RelevKnowl | BI_DB_dbo.BI_DB_KYC_Panel | Q3_AnswerText | Passthrough (composite STRING_AGG) |
| InvAmtCFD | BI_DB_dbo.BI_DB_KYC_Panel | Q45_AnswerText | Passthrough |
| InvAmtEquities | BI_DB_dbo.BI_DB_KYC_Panel | Q47_AnswerText | Passthrough |
| InvAmtCrypto | BI_DB_dbo.BI_DB_KYC_Panel | Q48_AnswerText | Passthrough |
| ExpCrypto | BI_DB_dbo.BI_DB_KYC_Panel | Q34_AnswerText | Passthrough |
| ExpEquities | BI_DB_dbo.BI_DB_KYC_Panel | Q33_AnswerText | Passthrough |
| ExpCFD | BI_DB_dbo.BI_DB_KYC_Panel | Q35_AnswerText | Passthrough |
| SourceIncome | BI_DB_dbo.BI_DB_KYC_Panel | Q15_AnswerText | Passthrough (multi-select STRING_AGG) |
| SourceFunds | BI_DB_dbo.BI_DB_KYC_Panel | Q26_AnswerText | Passthrough (multi-select STRING_AGG) |
| NegativeMarket | BI_DB_dbo.BI_DB_Scored_Appropriateness_Negative_Market | BlockReasonDesc | Passthrough WHERE BlockReasonID=12 AND RestrictionStatusDesc='Failed' |
| CFD_Copy_PnL | DWH_dbo.Dim_Position + BI_DB_PositionPnL + Fact_CustomerAction | NetProfit, PositionPnL, Rollover | SUM(realised+unrealised) - rollover WHERE MirrorID<>0, IsSettled=0 |
| CFD_Manual_PnL | DWH_dbo.Dim_Position + BI_DB_PositionPnL + Fact_CustomerAction | NetProfit, PositionPnL, Rollover | SUM(realised+unrealised) - rollover WHERE MirrorID=0, IsSettled=0 |
| Stocks_Copy_PnL | DWH_dbo.Dim_Position + BI_DB_PositionPnL | NetProfit, PositionPnL | SUM(realised+unrealised) WHERE MirrorID<>0, IsSettled=1, Stocks/ETF |
| Stocks_Manual_PnL | DWH_dbo.Dim_Position + BI_DB_PositionPnL | NetProfit, PositionPnL | SUM(realised+unrealised) WHERE MirrorID=0, IsSettled=1, Stocks/ETF |
| Crypto_Copy_PnL | DWH_dbo.Dim_Position + BI_DB_PositionPnL | NetProfit, PositionPnL | SUM(realised+unrealised) WHERE MirrorID<>0, IsSettled=1, Crypto |
| Crypto_Manual_PnL | DWH_dbo.Dim_Position + BI_DB_PositionPnL | NetProfit, PositionPnL | SUM(realised+unrealised) WHERE MirrorID=0, IsSettled=1, Crypto |
| UpdateDate | ETL | GETDATE() | ETL metadata timestamp |
| Knowledge_Assessment_Pass | BI_DB_dbo.BI_DB_KYC_Knowledge_Assessment | Is_Assessment_142_146_Pass | CASE: -1='No Answer', 1='Yes', else 'No' |
| Knowledge_Assessment_Score | BI_DB_dbo.BI_DB_KYC_Knowledge_Assessment | Total_Points_Assessment_142_146 | Passthrough |
| Trading_Strategy | BI_DB_dbo.BI_DB_KYC_Panel | Q5_AnswerText | Passthrough |

*Generated: 2026-04-27*
