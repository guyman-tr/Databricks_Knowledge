select 
case 
/*when ((InstrumentTypeID<>PrevInstrumentTypeID and PrevInstrumentTypeID is not null) or
(InstrumentDisplayName<>PrevInstrumentDisplayName and PrevInstrumentDisplayName is not null) or 
(Symbol<>PrevSymbol and PrevSymbol is not null) or
(SymbolFull<>PrevSymbolFull and PrevSymbolFull is not null) or
(Tradable<>PrevTradable and PrevTradable is not null) or
(ISINCode<>PrevISINCode and PrevISINCode is not null) or
(InstrumentVisible<>PrevInstrumentVisible and PrevInstrumentVisible is not null) or
(BuyCurrencyID<>PrevBuyCurrencyID and PrevBuyCurrencyID is not null) or
(SellCurrencyID<>PrevSellCurrencyID and PrevSellCurrencyID is not null) or
(IsMifid<>PrevIsMifid and PrevIsMifid is not null) or
(ContractExpire<>PrevContractExpire and PrevContractExpire is not null) or
(ExchangeID<>PrevExchangeID and PrevExchangeID is not null))then 'Multiple Fileds Changes' */
when (IsMifid<>PrevIsMifid) then 'IsMifid'
when (ISINCode<>PrevISINCode) then 'ISINCode'
when (InstrumentDisplayName<>PrevInstrumentDisplayName) then 'Instrument Display Name'
when (Symbol<>PrevSymbol) then 'Symbol'
when (SymbolFull<>PrevSymbolFull) then 'SymbolFull'
when (Tradable<>PrevTradable) then 'Tradable'
when (InstrumentVisible<>PrevInstrumentVisible) then 'Instrument Visible'
when (InstrumentTypeID<>PrevInstrumentTypeID) then 'Instrument TypeID'
when (BuyCurrencyID<>PrevBuyCurrencyID) then 'BuyCurrencyID'
when (SellCurrencyID<>PrevSellCurrencyID) then 'SellCurrencyID'
when (ContractExpire<>PrevContractExpire) then 'Contract Expire'
when (ExchangeID<>PrevExchangeID) then 'ExchangeID'  
when (CurrentValidFromByInstrumentID> dateadd(minute ,-1440,UpdateDate) and ValidFrom<>MinValidFrom) then 'New'
else 'No Change Occurred'  end ChangeType,
case when (ValidFrom=CurrentValidFromByInstrumentID) then 1 else 0 end as IsLast,*
from (
  select 
   InstrumentID,	  
   InstrumentTypeID,	  
   InstrumentDisplayName,  
   Symbol,	  
   SymbolFull,	  
   Tradable,	  
   ISINCode,	  
   InstrumentVisible,	
   BuyCurrencyID,	
   SellCurrencyID, 
   IsMifid,	  
   ContractExpire,	
   ExchangeID,
  
ValidFrom,
ValidTo,
UpdateDate,
count (ValidFrom) OVER (PARTITION BY InstrumentID) #_Of_Instances,
Max (ValidFrom) OVER (PARTITION BY InstrumentID) CurrentValidFromByInstrumentID,
Min (ValidFrom) OVER () MinValidFrom,
LAG(ValidTo ,1 ) OVER (PARTITION BY InstrumentID ORDER BY ValidFrom) PrevValidTo, 
LAG(  InstrumentTypeID,1 ) OVER (PARTITION BY InstrumentID ORDER BY ValidFrom) PrevInstrumentTypeID,										
LAG(  InstrumentDisplayName,1 ) OVER (PARTITION BY InstrumentID ORDER BY ValidFrom) PrevInstrumentDisplayName,										
LAG(  Symbol,1 ) OVER (PARTITION BY InstrumentID ORDER BY ValidFrom) PrevSymbol,
LAG(  SymbolFull,1 ) OVER (PARTITION BY InstrumentID ORDER BY ValidFrom) PrevSymbolFull,										
LAG(  Tradable,1 ) OVER (PARTITION BY InstrumentID ORDER BY ValidFrom) PrevTradable,										
LAG(  ISINCode,1 ) OVER (PARTITION BY InstrumentID ORDER BY ValidFrom ) PrevISINCode,										
LAG(  InstrumentVisible,1 ) OVER (PARTITION BY InstrumentID ORDER BY ValidFrom) PrevInstrumentVisible,										
LAG(BuyCurrencyID,1 ) OVER (PARTITION BY InstrumentID ORDER BY ValidFrom) PrevBuyCurrencyID,										
LAG(SellCurrencyID,1 ) OVER (PARTITION BY InstrumentID ORDER BY ValidFrom) PrevSellCurrencyID ,	
LAG( IsMifid,1 ) OVER (PARTITION BY InstrumentID ORDER BY ValidFrom) PrevIsMifid,	
LAG(  ContractExpire,1 ) OVER (PARTITION BY InstrumentID ORDER BY ValidFrom) PrevContractExpire,										
LAG(ExchangeID,1 ) OVER (PARTITION BY InstrumentID ORDER BY ValidFrom) PrevExchangeID

	from Reg_Instruments_SCD ) Instruments