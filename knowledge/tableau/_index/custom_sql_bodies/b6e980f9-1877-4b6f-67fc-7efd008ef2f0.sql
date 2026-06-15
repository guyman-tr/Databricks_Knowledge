select  ecfee.RealCID CID
      ,ecfee.GCID
      ,ecfee.Country
      ,dl.Name as Language
      ,att.Name Account_Type
      ,ecfee.Club
      ,ecfee.FiatCurrency CardCurrency
      ,case when dc.GuruStatusID>1 then 'PI' else 'Not PI' end as PI
      ,TRUNC(ecfee.LastModificationDate, 'MM') Transaction_Date 
      ,ifnull(tc.InstrumentID,'No Choice Instrument') InstrumentID_Choice
      ,ifnull(tc.InstrumentDisplayName,'No Choise') Stock_Choise
      ,ifnull((tc.Action),'1999-31-01') submitted
      ,ifnull((tcreg.Action),'1999-31-01') registrated
      
      ,SUM((ecfee.FiatAmount) ) AS Total_Use_Local 
      ,SUM(((ecfee.FiatAmount) ) * 0.01 ) AS CashBack_Amount_1_Local 
      ,SUM(((ecfee.FiatAmount) ) * 0.0102 ) AS CashBack_Amount_102_Local 
     
 
      ,SUM((UsdAmount) ) AS Total_Use_USD 
      ,SUM(((UsdAmount) ) * 0.01 ) AS CashBack_Amount_1_USD 
      ,SUM(((UsdAmount) ) * 0.0102 ) AS CashBack_Amount_102_USD 
	  ,MAX(ecfee.LastModificationDate) LastC2FTransactionDate
	  ,MAX(ecfee.UpdateDate) C2FDataUpdateDate
      ,tc.ActionMonth
      ,tc.ActionEOM
       ,last_day(ecfee.LastModificationDate) EOM
from main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ecfee

left join (
            select a.GCID
                  , di.InstrumentType
                  , di.InstrumentDisplayName
                  , di.InstrumentID
                  , TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') Action
                  ,date_format(TRY_TO_TIMESTAMP( a.Action,'M/d/yyyy h:mm:ss a' ),'yyyy-MM'  ) AS ActionMonth 
                  ,last_day(TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a')) AS ActionEOM
                  ,row_number() OVER (PARTITION BY a.GCID, date_format(TRY_TO_TIMESTAMP(a.Action,'M/d/yyyy h:mm:ss a' ), 'yyyy-MM' )
                  ORDER BY TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a' )desc) AS rn --per month
	            from main.sfmc.silver_sfmc_accountjourneylogtracking a
            join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
            on di.InstrumentID=a.Message
            where 1=1
			AND etr_ymd >= '2025-09-11' --this is to reduce partitions number, jorney min was recorderd after this date
			AND a.Journey_Name = '10027452589_1PerCashBack_Log_BI'
            and a.Action<>'StockSelection'
            and TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') <'2025-12-08'
            ) tc
on ecfee.GCID=tc.GCID
and tc.ActionEOM <=last_day(ecfee.LastModificationDate) 
and tc.rn=1

left join (
            select a.GCID
                  , di.InstrumentType
                  , di.InstrumentDisplayName
                  , di.InstrumentID
                  , TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') Action
                   ,row_number() over(partition by a.GCID order by TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') asc) Reg
            from main.sfmc.silver_sfmc_accountjourneylogtracking a
            join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
            on di.InstrumentID=a.Message
            where 1=1
			AND etr_ymd >= '2025-09-11' --this is to reduce partitions number, jorney min was recorderd after this date
			AND a.Journey_Name = '10027452589_1PerCashBack_Log_BI'
            and a.Action<>'StockSelection'
            and TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') <'2025-12-08'
            ) tcreg
on ecfee.GCID=tcreg.GCID
and tcreg.reg=1

join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
on ecfee.RealCID=dc.RealCID
join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype att
on att.AccountTypeID=dc.AccountTypeID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dl
on dl.LanguageID=dc.LanguageID
where dc.IsValidCustomer=1

and ecfee.ConversionCycle ='Full Cycle'
 
AND ecfee.eMoneyAccountSubProgram  IN ('Card Premium UK'
,'Card Standard UK'
,'IBAN Standard UK'
,'IBAN EU Green'
,'IBAN EU Black'
,'IBAN LIMITED EU'
,'Card Green EU'
,'Card Black EU'
,'IBAN Black AUS'
,'IBAN Green AUS')
 AND ecfee.IsTestAccount =0
 and ecfee.eMoneyIsValidETM =1
and TargetPlatformId =1
  AND (
       (
         ecfee.eMoneyAccountSubProgram IN (
            'Card Premium UK','Card Standard UK','IBAN Standard UK',
            'IBAN EU Green','IBAN EU Black','IBAN LIMITED EU',
            'Card Green EU','Card Black EU'
         )
         AND ecfee.LastModificationDate >= DATE '2025-11-04'
       )
       OR
       (
         ecfee.eMoneyAccountSubProgram IN ('IBAN Black AUS','IBAN Green AUS')
         AND ecfee.LastModificationDate >= DATE '2025-11-25'
       )
  )

--and ecfee.LastModificationDate <'2025-12-08'
group by all