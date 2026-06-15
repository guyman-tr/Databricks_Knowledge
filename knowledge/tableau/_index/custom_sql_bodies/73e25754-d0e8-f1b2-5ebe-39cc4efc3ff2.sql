/* PFOF for options and equity, US and UK*/
WITH rev AS ( 
  SELECT TradeMonth, TradeDate, ClearingAccount,InstrumentType, OrderID ,CustomerPFOFPayback
  FROM main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports 
  where TradeMonth>=202504
  group by TradeMonth, TradeDate, ClearingAccount,InstrumentType, OrderID ,CustomerPFOFPayback
)

, monthly_pfof as (
  select 
    cast(DATEADD(DAY, 7 - DAYOFWEEK(TradeDate), TradeDate) as date) as EoW_Sat,
    ClearingAccount, 	
    sum(CASE WHEN InstrumentType='Equity' THEN abs(CustomerPFOFPayback) END) AS EquitiesPFOF,
	sum(CASE WHEN InstrumentType='Option' THEN abs(CustomerPFOFPayback) END) AS OptionsPFOF
  from rev
  GROUP BY     cast(DATEADD(DAY, 7 - DAYOFWEEK(TradeDate), TradeDate) as date),
    ClearingAccount
)

, acct_map as (
    SELECT mp.EoW_Sat, mp.ClearingAccount, mp.EquitiesPFOF, mp.OptionsPFOF,
            am.OfficeCode, am.RegisteredRepCode
    FROM monthly_pfof mp 
    left join main.general.bronze_sodreconciliation_apex_ext765_accountmaster am 
        on am.AccountNumber=mp.ClearingAccount
    group by mp.EoW_Sat, mp.ClearingAccount, mp.EquitiesPFOF, mp.OptionsPFOF,
            am.OfficeCode, am.RegisteredRepCode
)

  select 
    EoW_Sat, 
    case 
      when OfficeCode in ('4GS','5GU') THEN
        CASE WHEN RegisteredRepCode='GAT' then 'FinCEN+FINRA' 
            WHEN RegisteredRepCode='UK1' THEN 'FCA'
            WHEN RegisteredRepCode='FO1' THEN 'FINRAONLY'
            WHEN RegisteredRepCode='NY1' THEN 'NYDFS+FINRA'
          END 
      WHEN LEFT(OfficeCode,2)='3E' THEN 'FinCEN+FINRA' 
     end AS Regulation, -- rev.ClearingAccount='3ET00001' 
     sum(EquitiesPFOF) AS EquitiesPFOF,
     sum(OptionsPFOF) AS OptionsPFOF
  from acct_map 
  group by EoW_Sat, 
    case 
      when OfficeCode in ('4GS','5GU') THEN
        CASE WHEN RegisteredRepCode='GAT' then 'FinCEN+FINRA' 
            WHEN RegisteredRepCode='UK1' THEN 'FCA'
            WHEN RegisteredRepCode='FO1' THEN 'FINRAONLY'
            WHEN RegisteredRepCode='NY1' THEN 'NYDFS+FINRA'
          END 
      WHEN LEFT(OfficeCode,2)='3E' THEN 'FinCEN+FINRA' 
     end