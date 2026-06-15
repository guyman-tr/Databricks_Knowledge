select SettlementReport.[Regulation Filter],
    SettlementReport.[InstrumentID]  ,
	SettlementReport.[Instrument Name]   ,
	SettlementReport.[Settlement Date]   ,
        SettlementReport.[Symbol]            ,
        SettlementReport.InstrumentType,
	cast([Instrument Closing Price]  as decimal(16,2))  as [Instrument Closing Price]  ,
	cast([Etoro Clients Settled positions in Units]   as decimal(16,2))   as [Etoro Clients Settled positions in Units] ,
	cast([Custodian Settled positions in units]  as decimal(16,2))  as  [Custodian Settled positions in units],
	cast([Etoro-Custodian Diff in Units]   as decimal(16,2))   as [Etoro-Custodian Diff in Units] ,
	cast([Etoro Clients Settled positions in $ (Total Holdings)]    as decimal(16,2))    as    [Etoro Clients Settled positions in $ (Total Holdings)] ,
	cast([Custodian Settled positions in $ (total Holdings)]   as decimal(16,2))   as   [Custodian Settled positions in $ (total Holdings)]  ,
	cast([Etoro-Custodian Total Holding Diff in $]   as decimal(16,2))   as  [Etoro-Custodian Total Holding Diff in $]    ,
	cast([Daily Diff in Total Holdings in $]   as decimal(16,2))   as  [Daily Diff in Total Holdings in $]     ,
	Ins.[ISINCode]
        
     




from [dbo].[SettlementReport_Ver2]  SettlementReport with(nolock)
inner join [dbo].[InstrumentMetaData] Ins on Ins.InstrumentID=SettlementReport.InstrumentID