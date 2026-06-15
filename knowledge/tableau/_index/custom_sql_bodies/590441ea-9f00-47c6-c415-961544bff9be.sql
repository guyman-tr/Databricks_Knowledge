select a.Name
      ,a.Status__c
      ,date(a.CreatedDate) RequestDate
      ,a.Substatus__c
      ,a.X1st_attempt_date__c
      ,a.X2nd_attempt_date__c
      ,a.Cashout_Reason__c as Cashout_ReasonSalesForce
      ,a.Comment__c Comments
      ,a.Trigger_Cashouts_Sum__c Withdraw_One
      ,dc.RealCID CID
      ,bdsmu.FirstName
      , bdsmu.LastName
      ,bdsmu.Position
      ,bdsmu.Team
      ,bdsmu.Site
       ,DATEDIFF(year,dc.BirthDate, getdate()) as Age
      ,bdsmu.Department
      ,bdsmu.Desk
      ,dc1.Name Country
     ,bdcdpfd.Equity
    ,bdcdpfd.EOD_Regulation
    ,bdcdpfd.Credit
    ,bdcdpfd.Revenue_Total
    ,dc1.MarketingRegionManualName
from main.crm.silver_crm_call_to_action__c a
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
on a.Account__c=dc.SalesForceAccountID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1
on dc1.CountryID=dc.CountryID
join bi_output.BI_OUTPUT_Customer_Customer_Support_Agent_User bdsmu
on CAST(bdsmu.AccountManagerID AS bigint)=dc.AccountManagerID
and bdsmu.ToDate = '9999-12-31T00:00:00.000Z'  
left join main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata bdcdpfd
on dc.RealCID=bdcdpfd.CID
and date(a.CreatedDate)=date(bdcdpfd.ActiveDate)
where a.Trigger_Definition__c='a480800000GWrRQAA1'
and date(a.CreatedDate)>='2025-02-01'