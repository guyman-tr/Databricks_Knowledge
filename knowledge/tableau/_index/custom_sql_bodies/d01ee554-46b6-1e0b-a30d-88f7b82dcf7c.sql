select date(Date) as Date,InstrumentType,InstrumentID,InstrumentName,Symbol,IsCFD,
sum(VolumeOnOpen) as VolumeOnOpen,
sum(VolumeOnClose) as VolumeOnClose,
 sum(TotalVolume) as TotalVolume,
 sum(FullCommissionOnOpen) as FullCommissionOnOpen,
 sum(FullCommissionOnClose) as FullCommissionOnClose,
 sum(FullCommission) as FullCommission,
 sum(NOP) as NOP,sum(TotalZero) as TotalZero,sum(OverNightFee) as OverNightFee
from main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_dealingdashboard_clients
where DateID>20240101
group by date(Date), InstrumentType,InstrumentID,InstrumentName,Symbol,IsCFD