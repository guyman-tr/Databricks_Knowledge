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

      ,SUM((ecfee.FiatAmount) ) AS Total_Use_Local 
      ,SUM(((ecfee.FiatAmount) ) * 0.01 ) AS CashBack_Amount_1_Local 
      ,SUM(((ecfee.FiatAmount) ) * 0.0102 ) AS CashBack_Amount_102_Local 
     
 
      ,SUM((UsdAmount) ) AS Total_Use_USD 
      ,SUM(((UsdAmount) ) * 0.01 ) AS CashBack_Amount_1_USD 
      ,SUM(((UsdAmount) ) * 0.0102 ) AS CashBack_Amount_102_USD 
 
from main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e ecfee
left join (
            select a.GCID
                  , di.InstrumentType
                  , di.InstrumentDisplayName
                  , di.InstrumentID
                  ,  TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') Action
                  , row_number() over(partition by a.GCID order by TRY_TO_TIMESTAMP(a.Action, 'M/d/yyyy h:mm:ss a') desc) rn
            from main.sfmc.silver_sfmc_accountjourneylogtracking a
            join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
            on di.InstrumentID=a.Message
            where a.Journey_Name = '10027452589_1PerCashBack_Log_BI'
            and a.Action<>'StockSelection'
            ) tc
on ecfee.GCID=tc.GCID
and tc.rn=1
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
on ecfee.RealCID=dc.RealCID
join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype att
on att.AccountTypeID=dc.AccountTypeID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dl
on dl.LanguageID=dc.LanguageID
where dc.IsValidCustomer=1

and ecfee.ConversionCycle ='Full Cycle'
 AND ecfee.IsTestAccount =0
and TargetPlatformId =2
and ecfee.LastModificationDate>='2025-11-24'
and ecfee.CountryID=217
group by  ecfee.RealCID
      ,ecfee.GCID
      ,ecfee.Country
      ,dl.Name
      ,att.Name 
      ,dc.Email
      ,ecfee.Club
      ,ecfee.FiatCurrency
      ,case when dc.GuruStatusID>1 then 'PI' else 'Not PI' end
      ,TRUNC(ecfee.LastModificationDate, 'MM')
      ,ifnull(tc.InstrumentID,'No Choice Instrument')
      ,ifnull(tc.InstrumentDisplayName,'No Choise') 
      ,ifnull((tc.Action),'1999-31-01')