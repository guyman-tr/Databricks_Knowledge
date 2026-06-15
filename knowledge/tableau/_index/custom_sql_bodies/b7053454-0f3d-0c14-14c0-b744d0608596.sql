select 
sum (eToro_Quantity)eToro_Quantity , 
sum (DLT_Quantity)DLT_Quantity,
etoroSymbol,
InstrumentID,
cast(etr_ymd as date)etr_ymd
from main.tangany.gold_de_dlt_reconciliation_report 
group by etoroSymbol,InstrumentID,etr_ymd