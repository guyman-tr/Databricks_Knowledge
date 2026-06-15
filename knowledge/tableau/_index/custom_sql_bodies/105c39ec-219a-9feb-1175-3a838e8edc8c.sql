With accinfo AS (
SELECT 
    c.RealCID as CID,
    pl.Name as Club,
    ps.Name as PlayerStatus,
    r.Name as DesignatedRegulation,
    r2.Name as Regulation,
    cast(fd.LastLoggedIn as date) as LastLogin,
    c.HasWallet,
    co.Name as Country,
    pcs.PendingClosureStatusName as PendingClosureStatus,
     c.VerificationLevelID,
    ss.Name as ScreeningStatus,
    c.HasWallet,
    em.CurrencyBalanceStatus as eMoneyStatus,
    case when em.CID is null then 0 else 1 end as HaseMoney,
    risk.RiskClassificationName as RiskClassification,
    c.IsDepositor,
    cast(usc.LastUpdateDate as date) as ScreeningStatus_UpdateDate
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked c
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_riskclassification risk on risk.RiskClassificationID=c.RiskClassificationID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl on c.PlayerLevelID = pl.PlayerLevelID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ps on ps.PlayerStatusID = c.PlayerStatusID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus pcs on pcs.PendingClosureStatusID = c.PendingClosureStatusID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r on r.ID = c.DesignatedRegulationID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r2 on r2.ID = c.RegulationID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country co on co.CountryID = c.CountryID 
left join main.bi_db.bronze_screeningservice_screening_userscreening usc on usc.CID=c.RealCID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus ss on ss.ScreeningStatusID=usc.ScreeningStatusID
LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked fd on fd.CID = c.RealCID
left join main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account em on em.CID=c.RealCID
Where ( ss.ScreeningStatusID is null or ss.ScreeningStatusID <>1) and c.PlayerStatusID not in (2,4) --Blocked,BlockedUponRequest
)

,Liabilities as (
Select 
    a.CID
    ,sum(l.Liabilities + l.ActualNWA) AS Equity
    ,sum(l.credit) as Balance
From 
  accinfo a
LEFT JOIN  
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities l on l.CID = a.CID and DateID = date_format(date_sub(current_date(), 1), 'yyyyMMdd')
group by 
  a.CID
 ),emoney as

(
SELECT 
	ecb.CID
	,ecb.ClosingBalanceBO * ecb.USDApproxRate as eMoneyBalance
FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ecb 
WHERE
	ecb.BalanceDateID=date_format(date_sub(current_date(), 2), 'yyyyMMdd')
)



     SELECT 
     count(a.CID) as NoofClients
     ,a.Club
     ,a.IsDepositor
    ,a.Country
    ,a.HasWallet
     ,a.LastLogin
     ,  a.PendingClosureStatus
     ,CASE
        WHEN a.LastLogin >= DATEADD(MONTH, -3, GETDATE()) THEN 'A: Last 3 Months'
        WHEN a.LastLogin >= DATEADD(MONTH, -6, GETDATE()) THEN 'B: Last 6 Months'
        WHEN a.LastLogin >= DATEADD(YEAR, -1, GETDATE()) THEN 'C: Last 1 Year'
        ELSE 'D: More than 1 Year'
    END AS login_bucket
     ,a.VerificationLevelID
   ,a.PlayerStatus
    ,a.Regulation
    ,a.DesignatedRegulation
    ,a.IsDepositor
    ,l.Equity
    ,eMoneyStatus
,ScreeningStatus,
HaseMoney
,RiskClassification
    ,   CASE
        WHEN l.Equity <= 0 THEN 'A: 0 and under'
        WHEN l.Equity > 0 AND l.Equity <= 5 THEN 'B: 0 to 5'
        WHEN l.Equity > 5 AND l.Equity <= 29 THEN 'C: 5 to 29'
        WHEN l.Equity > 29 AND l.Equity <= 500 THEN 'D: 30 to 500'
        WHEN l.Equity > 500 AND l.Equity <= 10000 THEN 'E: 500 to 10K'
        ELSE 'F: 10K+'
    END AS equity_bucket
    ,eMoneyBalance
    ,   CASE
        WHEN eMoneyBalance <= 0 THEN 'A: 0 and under'
        WHEN eMoneyBalance > 0 AND l.Equity <= 5 THEN 'B: 0 to 5'
        WHEN eMoneyBalance > 5 AND l.Equity <= 29 THEN 'C: 5 to 29'
        WHEN eMoneyBalance > 29 AND l.Equity <= 500 THEN 'D: 30 to 500'
        WHEN eMoneyBalance > 500 AND l.Equity <= 10000 THEN 'E: 500 to 10K'
        ELSE 'F: 10K+' end as emoney_bucket,
        ScreeningStatus_UpdateDate
From 
    accinfo a
LEFT JOIN 
    Liabilities l on l.CID = a.CID
LEFT JOIN 
    emoney e on e.CID=a.CID
   GROUP BY    
    a.Club
    ,a.IsDepositor
,   a.Country
,   a.HasWallet
,   a.LastLogin
,   a.VerificationLevelID
,   a.PlayerStatus
,   a.Regulation
,   a.PendingClosureStatus
,   l.Equity
,   eMoneyStatus
,a.DesignatedRegulation
,a.IsDepositor
, ScreeningStatus,
HaseMoney,
RiskClassification
,     CASE
        WHEN l.Equity <= 0 THEN 'A: 0 and under'
        WHEN l.Equity > 0 AND l.Equity <= 5 THEN 'B: 0 to 5'
        WHEN l.Equity > 5 AND l.Equity <= 29 THEN 'C: 5 to 29'
        WHEN l.Equity > 29 AND l.Equity <= 500 THEN 'D: 30 to 500'
        WHEN l.Equity > 500 AND l.Equity <= 10000 THEN 'E: 500 to 10K'
        ELSE 'F: 10K+'
    END
     ,CASE
        WHEN a.LastLogin >= DATEADD(MONTH, -3, GETDATE()) THEN 'A: Last 3 Months'
        WHEN a.LastLogin >= DATEADD(MONTH, -6, GETDATE()) THEN 'B: Last 6 Months'
        WHEN a.LastLogin >= DATEADD(YEAR, -1, GETDATE()) THEN 'C: Last 1 Year'
        ELSE 'More than 1 Year'
    END
        ,eMoneyBalance,
        ScreeningStatus_UpdateDate