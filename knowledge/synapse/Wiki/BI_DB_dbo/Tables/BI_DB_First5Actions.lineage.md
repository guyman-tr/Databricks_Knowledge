# BI_DB_First5Actions — Column Lineage

**Schema**: BI_DB_dbo  
**Object Type**: Table  
**Writer SP**: SP_First5Actions  
**Generated**: 2026-04-22

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|--------------|-----------|------|
| 1 | CID | BI_DB_dbo.BI_DB_CIDFirstDates | CID | passthrough (WHERE FirstDepositDate IS NOT NULL) | Tier 1 |
| 2 | AffiliateID | BI_DB_dbo.BI_DB_CIDFirstDates | SerialID | passthrough (renamed) | Tier 1 |
| 3 | FirstDepositDate | BI_DB_dbo.BI_DB_CIDFirstDates | FirstDepositDate | passthrough | Tier 2 |
| 4 | FirstDepositAmount | BI_DB_dbo.BI_DB_CIDFirstDates | FirstDepositAmount | passthrough | Tier 2 |
| 5 | Region | BI_DB_dbo.BI_DB_CIDFirstDates | Region | passthrough | Tier 2 |
| 6 | Country | BI_DB_dbo.BI_DB_CIDFirstDates | Country | passthrough | Tier 2 |
| 7 | Channel | BI_DB_dbo.BI_DB_CIDFirstDates | Channel | passthrough | Tier 2 |
| 8 | SubChannel | BI_DB_dbo.BI_DB_CIDFirstDates | SubChannel | passthrough | Tier 2 |
| 9 | FirstAction | BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions | InstrumentTypeID+MirrorID+AccountTypeID=9 | CASE: 'Crypto'/'FX/Commodities/Indices'/'Stocks/ETFs'/'Copy Fund'/'Copy' for ActionNumber=1 | Tier 2 |
| 10 | FirstActionDate | BI_DB_dbo.BI_DB_CustomerCross | Occurred | PIVOT: MAX(Occurred) WHERE rn=1 | Tier 2 |
| 11 | FirstInstrument | BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions + DWH_dbo.Dim_Mirror | InstrumentName / ParentUserName | ISNULL(ParentUserName, InstrumentName) for rank=1 | Tier 2 |
| 12 | SecondAction | BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions | ActionType | ActionType CASE for ActionNumber=2 | Tier 2 |
| 13 | SecondInstrument | same as FirstInstrument | — | rank=2 | Tier 2 |
| 14 | ThirdAction | BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions | ActionType | rank=3 | Tier 2 |
| 15 | ThirdInstrument | same pattern | — | rank=3 | Tier 2 |
| 16 | FourthAction | BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions | ActionType | rank=4 | Tier 2 |
| 17 | FourthInstrument | same pattern | — | rank=4 | Tier 2 |
| 18 | FifthAction | BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions | ActionType | rank=5 | Tier 2 |
| 19 | FifthInstrument | same pattern | — | rank=5 | Tier 2 |
| 20 | Traded_FX/Commodities/Indices | Computed from #Actions2 + BI_DB_CustomerCross | ActionType values | 1 if any of first action or 5 crosses = 'FX/Commodities/Indices', else 0 | Tier 2 |
| 21 | Traded_Stocks/ETFs | same | ActionType values | 1 if any = 'Stocks/ETFs' or 'Real/CFD Stocks/ETFs', else 0 | Tier 2 |
| 22 | TradedCrypto | same | ActionType values | 1 if any = 'Crypto', else 0 | Tier 2 |
| 23 | TradedCopy | same | ActionType values | 1 if any = 'Copy', else 0 | Tier 2 |
| 24 | TradedCopyFund | same | ActionType values | 1 if any = 'Copy Fund', else 0 | Tier 2 |
| 25 | FirstCross | BI_DB_dbo.BI_DB_CustomerCross | ActionType_Detailed | PIVOT: MAX(ActionType_Detailed) WHERE rn=1 (legacy) | Tier 2 |
| 26 | FirstCrossDate | BI_DB_dbo.BI_DB_CustomerCross | Occurred | PIVOT: MAX(Occurred) WHERE rn=1 | Tier 2 |
| 27 | SecondCross | BI_DB_dbo.BI_DB_CustomerCross | ActionType_Detailed | rn=2 | Tier 2 |
| 28 | SecondCrossDate | same | Occurred | rn=2 | Tier 2 |
| 29 | ThirdCross | same | ActionType_Detailed | rn=3 | Tier 2 |
| 30 | ThirdCrossDate | same | Occurred | rn=3 | Tier 2 |
| 31 | FourthCross | same | ActionType_Detailed | rn=4 | Tier 2 |
| 32 | FourthCrossDate | same | Occurred | rn=4 | Tier 2 |
| 33 | UpdateDate | SP_First5Actions | — | GETDATE() at INSERT time | Tier 2 |
| 34 | LTV | SP_First5Actions | — | Hardcoded 0 (disabled since 2022-06-02) | Tier 2 |
| 35 | FirstLeverage | BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions | Leverage | MAX(Leverage) WHERE rank=1 | Tier 2 |
| 36 | SecondActionDate | BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions | Occurred | MAX(Occurred) WHERE rank=2 | Tier 2 |
| 37 | ThirdActionDate | same | Occurred | rank=3 | Tier 2 |
| 38 | FourthActionDate | same | Occurred | rank=4 | Tier 2 |
| 39 | FifthActionDate | same | Occurred | rank=5 | Tier 2 |
| 40 | SecondLeverage | same | Leverage | rank=2 | Tier 2 |
| 41 | ThirdLeverage | same | Leverage | rank=3 | Tier 2 |
| 42 | FourthLeverage | same | Leverage | rank=4 | Tier 2 |
| 43 | FifthLeverage | same | Leverage | rank=5 | Tier 2 |
| 44 | FirstAction_Detailed | BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions | InstrumentTypeID+Leverage+IsBuy+MirrorID | CASE: 'Real Stocks/ETFs'/'CFD Stocks/ETFs'/'Crypto'/'FX/Commodities/Indices'/'Copy Fund'/'Copy' for rank=1 | Tier 2 |
| 45 | Revenue1day | BI_DB_dbo.BI_DB_CID_BalanceDays | Revenue1day | NULL if DATEDIFF(FirstDepositDate, yesterday) < 0 | Tier 2 |
| 46 | Revenue7days | same | Revenue7days | NULL if < 6 days elapsed | Tier 2 |
| 47 | Revenue14days | same | Revenue14days | NULL if < 13 days | Tier 2 |
| 48 | Revenue30days | same | Revenue30days | NULL if < 29 days | Tier 2 |
| 49 | Revenue60days | same | Revenue60days | NULL if < 59 days | Tier 2 |
| 50 | Revenue90days | same | Revenue90days | NULL if < 89 days | Tier 2 |
| 51 | Revenue180days | same | Revenue180days | NULL if < 179 days | Tier 2 |
| 52 | Revenue360days | BI_DB_dbo.BI_DB_CID_BalanceDays | Revenue365days | NULL if < 364 days; column rename | Tier 2 |
| 53 | Deposit1day | BI_DB_dbo.BI_DB_CID_BalanceDays | Deposit1day | NULL if < 0 days elapsed | Tier 2 |
| 54–60 | Deposit7days..Deposit360days | same | Deposit7–365days | Same elapsed-day guards as Revenue | Tier 2 |
| 61 | Equity1day | BI_DB_dbo.BI_DB_CID_BalanceDays | Equity1day | NULL if < 0 days | Tier 2 |
| 62–68 | Equity7days..Equity360days | same | Equity7–365days | Same elapsed-day guards | Tier 2 |
| 69 | SecondAction_Detailed | BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions | ActionType_Detailed | rank=2 | Tier 2 |
| 70 | ThirdAction_Detailed | same | ActionType_Detailed | rank=3 | Tier 2 |
| 71 | FourthAction_Detailed | same | ActionType_Detailed | rank=4 | Tier 2 |
| 72 | FifthAction_Detailed | same | ActionType_Detailed | rank=5 | Tier 2 |
| 73 | FifthCross | BI_DB_dbo.BI_DB_CustomerCross | ActionType_Detailed | PIVOT rn=5 (legacy) | Tier 2 |
| 74 | FifthCrossDate | same | Occurred | PIVOT rn=5 | Tier 2 |
| 75 | NewMarketingRegion | BI_DB_dbo.BI_DB_CIDFirstDates | NewMarketingRegion | passthrough | Tier 2 |
| 76 | FirstActionTypeNew | BI_DB_dbo.BI_DB_CustomerFirst5OpenPositions | ActionTypeNew | CASE: 'Crypto'/'FX/Commodities'/'Stocks/ETFs/Indices'/'Copy Fund'/'Copy' for rank=1 | Tier 2 |
| 77 | FirstCrossDateNew | BI_DB_dbo.BI_DB_CustomerCross_New | Occurred | PIVOT rn=1 (new classification dates) | Tier 2 |
| 78 | SecondCrossNew | BI_DB_dbo.BI_DB_CustomerCross_New | ActionTypeNew | PIVOT rn=2 | Tier 2 |
| 79 | SecondCrossDateNew | same | Occurred | rn=2 | Tier 2 |
| 80 | ThirdCrossNew | same | ActionTypeNew | rn=3 | Tier 2 |
| 81 | ThirdCrossDateNew | same | Occurred | rn=3 | Tier 2 |
| 82 | FourthCrossNew | same | ActionTypeNew | rn=4 | Tier 2 |
| 83 | FourthCrossDateNew | same | Occurred | rn=4 | Tier 2 |
| 84 | FifthCrossNew | same | ActionTypeNew | rn=5 | Tier 2 |
| 85 | FifthCrossDateNew | same | Occurred | rn=5 | Tier 2 |
| 86 | FirstCrossNew | BI_DB_dbo.BI_DB_CustomerCross_New | ActionTypeNew | PIVOT rn=1 (new cross type) | Tier 2 |

---

## ETL Pipeline

```
BI_DB_CIDFirstDates (demographics: CID, FTD date/amount, region, country, channel)
  + BI_DB_CustomerFirst5OpenPositions (first 5 position events per depositor)
  + BI_DB_CustomerCross (legacy cross-asset sequence, ActionType_Detailed)
  + BI_DB_CustomerCross_New (new cross-asset sequence, ActionTypeNew)
  + DWH_dbo.Dim_Instrument (InstrumentTypeID → ActionType CASE)
  + DWH_dbo.Dim_Mirror (MirrorID → ParentCID/ParentUserName for Copy)
  + BI_DB_CID_BalanceDays (Revenue/Deposit/Equity at N-day windows)
  |-- SP_First5Actions (TRUNCATE + INSERT, full refresh) --|
  v
BI_DB_dbo.BI_DB_First5Actions (46.3M rows, one per depositor)
  |-- UC: Not Migrated --|
  |-- Downstream: BI_DB_DepositUsersFirstTouchPoints --|
```

---

## Source Objects

| Source Schema | Source Object | Role |
|---|---|---|
| BI_DB_dbo | BI_DB_CIDFirstDates | Demographics anchor: CID, AffiliateID, FTD date/amount, region, country, channel |
| BI_DB_dbo | BI_DB_CustomerFirst5OpenPositions | First 5 open positions per depositor (ActionNumber 1–5); drives Action/Instrument/Leverage/Date columns |
| BI_DB_dbo | BI_DB_CustomerCross | Legacy cross-asset type sequence (ActionType_Detailed); drives FirstCross..FifthCross |
| BI_DB_dbo | BI_DB_CustomerCross_New | New cross-asset sequence (ActionTypeNew); drives FirstCrossNew..FifthCrossNew |
| BI_DB_dbo | BI_DB_CID_BalanceDays | Revenue/Deposit/Equity at 1/7/14/30/60/90/180/360-day windows post-FTD |
| DWH_dbo | Dim_Instrument | InstrumentTypeID → ActionType/ActionType_Detailed/ActionTypeNew CASE classification |
| DWH_dbo | Dim_Mirror | MirrorID → ParentCID, ParentUserName (for Copy/Copy Fund identification) |
| DWH_dbo | Dim_Customer | AccountTypeID=9 filter for Copy Fund manager identification |

---

## UC External Lineage

UC Target: **Not Migrated** — no UC entry exists for this table.
