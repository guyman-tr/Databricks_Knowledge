select dt.CID
      ,dt.GCID
      ,dt.CountryTxDate
      ,da.Country
      ,dl.Name as Language
      ,att.Name Account_Type
      ,da.Club
      ,dt.HolderCurrencyDesc CardCurrency
      ,case when dc.GuruStatusID>1 then 'PI' else 'Not PI' end as PI
      ,TRUNC(dt.TxStatusModificationDate, 'MM') Transaction_Date 
      ,ifnull(tc.InstrumentID,'No Choice Instrument') InstrumentID_Choice
      ,ifnull(tc.InstrumentDisplayName,'No Choise') Stock_Choise
      ,ifnull(date(tc.Action),'1999-31-01') submitted
      ,da.ProviderHolderID
      ,SUM((dt.HolderAmount) ) AS Total_Use_Local 
      ,SUM(((dt.HolderAmount) ) * 0.01 ) AS CashBack_Amount_1_Local 
      ,SUM(((dt.HolderAmount) ) * 0.0102 ) AS CashBack_Amount_102_Local 
     
 
      ,SUM((dt.USDAmountApprox) ) AS Total_Use_USD 
      ,SUM(((dt.USDAmountApprox) ) * 0.01 ) AS CashBack_Amount_1_USD 
      ,SUM(((dt.USDAmountApprox) ) * 0.0102 ) AS CashBack_Amount_102_USD 
 
from main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction dt
join main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account da
on dt.CID=da.CID
left join (
            select a.GCID
                  , di.InstrumentType
                  , di.InstrumentDisplayName
                  , di.InstrumentID
                  , a.Action
                  , row_number() over(partition by a.GCID order by a.Action desc) rn
            from main.sfmc.silver_sfmc_accountjourneylogtracking a
            join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
            on di.InstrumentID=a.Message
            where a.Journey_Name = '9037759373_CashBack_Log_BI'
            and a.Action<>'StockSelection'
            ) tc
on dt.GCID=tc.GCID
and tc.rn=1
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
on dt.CID=dc.RealCID
join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype att
on att.AccountTypeID=dc.AccountTypeID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_language dl
on dl.LanguageID=dc.LanguageID
where dt.IsTxSettled=1
AND da.IsValidCustomer=1
AND da.IsTestAccount=0
AND da.IsValidETM=1
AND da.GCID_Unique_Count=1
and dt.TxTypeID = 14
and da.AccountSubProgramID in (2,1,4,6,7,9,11,12)
and dt.TxStatusModificationDate>='2025-03-01'
group by  dt.CID
      ,dt.GCID
      ,dt.CountryTxDate
      ,da.Country
      ,dl.Name
      ,att.Name 
      ,dc.Email
      ,da.Club
      ,dt.HolderCurrencyDesc
      ,case when dc.GuruStatusID>1 then 'PI' else 'Not PI' end
      ,TRUNC(dt.TxStatusModificationDate, 'MM')
      ,ifnull(tc.InstrumentID,'No Choice Instrument')
      ,ifnull(tc.InstrumentDisplayName,'No Choise') 
      ,ifnull(date(tc.Action),'1999-31-01')
       ,da.ProviderHolderID