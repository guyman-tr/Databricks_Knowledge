select etr_ymd as Date
            ,'gold_jpm_eod_etoro_report_componentunderlyings' as FileName
            ,Name
            ,ISIN_Code
            ,RIC_Code
            ,Currency
            ,Quantity
            ,Current_Price
from general.gold_jpm_eod_etoro_report_componentunderlyings

union all

select etr_ymd as Date
            ,'gold_jpm_eod_etoro2_report_componentunderlyings' as FileName
            ,Name
            ,ISIN_Code
            ,RIC_Code
            ,Currency
            ,Quantity
            ,Current_Price
      from general.gold_jpm_eod_etoro2_report_componentunderlyings