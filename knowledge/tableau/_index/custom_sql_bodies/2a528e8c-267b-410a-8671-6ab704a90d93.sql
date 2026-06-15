With apex_trades_base as (
  SELECT DISTINCT OfficeCode, RegisteredRepCode, MarketCode, AccountNumber, BuySellCode, cast(ProcessDate as date) as ProcessDate, ExecutionTime,
  Symbol, OptionSymbolRoot,
  OrderId, abs(NetAmount) AbsAmount, abs(Quantity) AbsQuantity
  FROM main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity ta 
  where BuySellCode in ('B','S') 
  /*
    B = Buy
    C = Cancel Buy
    S = Sell
    T = Cancel Sell
  */
    and RegisteredRepCode<>'UK1'
    and ta.AccountNumber not in ('3ET00001',
    '3ET00100',
    '3ET00101',
    '3ET00002',
    '3ET05007',

    '4GS43999',
    '4GS00100',
    '4GS00101',
    '4GS00103',
    '4GS00104')
)
/*
SELECT * FROM apex_trades_base 
where ProcessDate >='2025-07-01' 
and marketcode='N'
and registeredrepcode='GAT'
*/
SELECT 
  ProcessDate AS FullDate,
  MarketCode,
  case 
    when MarketCode='N' then 'Equities'
    when MarketCode='5' then 'Options'
    end as InstrumentType,
  OptionSymbolRoot as Instrument,
  RegisteredRepCode, 
    count(distinct case when BuySellCode='B' then OrderId end) as NumberOfTrades_Buy,
    count(distinct case when BuySellCode='S' then OrderId end) as NumberOfTrades_Sell,
    sum( case when BuySellCode='B' then AbsAmount end) as VolumeOnOpen,
    sum( case when BuySellCode='S' then AbsAmount end) as VolumeOnClose

FROM apex_trades_base
where ProcessDate >= date_add(YEAR, -2, current_date())
group by   
  ProcessDate,
  MarketCode,
  case 
    when MarketCode='N' then 'Equities'
    when MarketCode='5' then 'Options'
    end,
  OptionSymbolRoot,
  RegisteredRepCode