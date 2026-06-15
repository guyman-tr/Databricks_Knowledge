WITH cids as (
SELECT DISTINCT 
  c.CID,c.CaseNumber,c.CaseID
  --,c.Type
  ,c.Sub_Type
  ,c.CreatedDate
  ,c.Status,OwnerSubrole,ch.OldValue
  ,c.OwnerRoleName
  ,CASE WHEN c.OwnerId in('0051p000009Pl84AAC','00524000001JJbQAAW')and c.Status in ('Closed','Solved') then 'Rejected by the system and CS' 
  when (ch.OldValue is null or OwnerRoleName='Customer Service') and c.Status in ('Closed','Solved') THEN 'Rejected by the system and CS' when c.Status in ('Closed','Solved') then 'Rejected by agent' else 'UnderReview' end as AutomaticClosed
from
  bi_output.bi_output_customer_customer_support_case c
left join (select CaseId,OldValue,NewValue,a.Department from crm.silver_crm_casehistory ch 
join  bi_output.bi_output_customer_customer_support_agent_user a on a.ID=ch.OldValue and year(a.ToDate)=9999
and a.Department like 'Operation%') ch on ch.CaseId=c.CaseId and  ch.Department like 'Op%'
where
  --Status in ('In Routing','Open','On-hold') and 
  c.Sub_Type in ('Blocked Account Reactivation')
)

 ,pop AS (
  SELECT a.CID
      ,a.PlayerStatusID AS Current_ID
      ,dps.Name AS Current_PlayerStatus     
      ,a.Previous_PlayerStatusID AS Previous_ID
      ,pps.Name AS Previous_PlayerStatus
      ,a.PlayerStatusReasonID AS Current_Reason_ID
      ,dpsr.Name AS Current_PlayerStatusReason
      ,a.Previous_PlayerStatus_Reason_ID
      ,dpsr1.Name AS Previous_PlayerStatus_Reason
      ,a.PlayerStatusSubReasonID as Current_Sub_Reason_ID
      ,dpssr.PlayerStatusSubReasonName AS Current_PlayerStatusSubReason
      ,a.Previous_PlayerStatus_Sub_Reason_ID
      ,dpssr1.PlayerStatusSubReasonName as Previous_PlayerStatus_Sub_Reason
      ,a.Change_Date
      ,a.Is_FTD      
      ,ROW_NUMBER() OVER (PARTITION BY a.CID ORDER BY a.Change_Date DESC) AS RowNum
  FROM (
    SELECT fsc.RealCID AS CID
          ,CASE WHEN fsc.IsDepositor = 1 THEN 1 ELSE 0 END AS Is_FTD
          ,fsc.PlayerStatusID 
          ,fsc.PlayerStatusReasonID
          ,fsc.PlayerStatusSubReasonID
          ,TO_DATE(CAST(dr.FromDateID AS STRING), 'yyyyMMdd') AS Change_Date            
          ,LAG(fsc.PlayerStatusID, 1, 0) OVER(PARTITION BY fsc.RealCID ORDER BY dr.FromDateID ASC) AS Previous_PlayerStatusID
          ,LAG(fsc.PlayerStatusReasonID, 1, 0) OVER(PARTITION BY fsc.RealCID ORDER BY dr.FromDateID ASC) AS Previous_PlayerStatus_Reason_ID
          ,LAG(fsc.PlayerStatusSubReasonID, 1, 0) OVER(PARTITION BY fsc.RealCID ORDER BY dr.FromDateID ASC) AS Previous_PlayerStatus_Sub_Reason_ID
    FROM 
      dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    INNER JOIN 
      main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr ON fsc.DateRangeID = dr.DateRangeID
    INNER JOIN 
        cids c on c.CID = fsc.RealCID
    WHERE 
      fsc.IsValidCustomer = 1            
  ) a

  INNER JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus dps ON a.PlayerStatusID = dps.PlayerStatusID
  INNER JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus pps ON a.Previous_PlayerStatusID = pps.PlayerStatusID
  LEFT JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons dpsr ON a.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
  LEFT JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons dpsr1 ON a.Previous_PlayerStatus_Reason_ID = dpsr1.PlayerStatusReasonID
  LEFT JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons dpssr ON a.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID
  LEFT JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons dpssr1 ON a.Previous_PlayerStatus_Sub_Reason_ID = dpssr1.PlayerStatusSubReasonID
  WHERE 
    a.PlayerStatusID <> a.Previous_PlayerStatusID
    and (a.PlayerStatusID = 2 OR a.Previous_PlayerStatusID = 2)
)

,final as (
SELECT DISTINCT
  p.CID
  ,p.Previous_PlayerStatus
  ,p.Previous_PlayerStatus_Reason
  ,p.Previous_PlayerStatus_Sub_Reason
  ,p.Change_Date
  ,ps.Name as Current_PlayerStatus
  ,psr.Name as Current_PlayerStatusReason
  ,pssr.PlayerStatusSubReasonName as Current_PlayerStatusSubReason
  ,CASE
    WHEN c.Status IN ('Open', 'New', 'In Routing','Pending') AND dc.PlayerStatusID = 2 THEN 'UnderReview'
    WHEN c.Status IN ('Closed', 'Solved') AND dc.PlayerStatusID in (2,4) THEN 'Rejected'
    WHEN c.Status IN ('Open','Pending', 'On-hold') AND dc.PlayerStatusID  NOT IN (1,2) THEN 'UnderReview'
    WHEN c.Status IN ('Solved', 'Closed') AND dc.PlayerStatusID = 1  THEN 'Approved'
    ELSE 'Other'
  END  as ReOpen,
  c.OwnerRoleName
  ,cast(c.CreatedDate as date) as TicketCreatedDate
  ,c.Status as TicketStatus
  ,c.AutomaticClosed
  ,dc.IsDepositor
FROM 
  pop p
inner JOIN 
  cids c on c.CID = p.CID
LEFT JOIN 
  dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.RealCID = p.CID
LEFT JOIN 
	dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ps on ps.PlayerStatusID = dc.PlayerStatusID
LEFT JOIN 
	dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr on psr.PlayerStatusReasonID = dc.PlayerStatusReasonID
LEFT JOIN 
	dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons pssr on pssr.PlayerStatusSubReasonID = dc.PlayerStatusSubReasonID
WHERE 
  p.RowNum = 1
  --and p.Current_PlayerStatus = 'Normal'
  --and p.Previous_PlayerStatus = 'Blocked'
)


,deposits as (
Select d.CID, sum(d.AmountUSD) as TotalDepositAfterReactivation
From dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit d 
LEFT JOIN (Select distinct f.cid,f.change_date from  final f) c  on d.CID = c.CID
where d.PaymentStatusID = 2 and d.ModificationDate >= c.change_date
group by d.CID
)

,pos as (
SELECT DISTINCT p.CID
FROM final c
JOIN main.dwh.dim_position p on p.CID = c.CID
WHERE p.CloseDateID = 0
)


,trades as (
SELECT DISTINCT p.CID,count(p.PositionID) as NumOfTradesAfterReactivation
FROM main.dwh.dim_position p 
JOIN (Select distinct f.cid,f.change_date from  final f) c on p.CID = c.CID
WHERE  p.OpenOccurred >= c.change_date
group by p.CID
)


SELECT
  f.*
  ,d.totaldepositafterreactivation
  ,case when p.CID is NULL then 'No' else 'Yes' end as Has_Open_Positions
  ,t.numoftradesafterreactivation
FROM 
  final f
LEFT JOIN 
  deposits d on d.CID = f.CID
LEFT JOIN 
  pos p on p.CID = f.CID
LEFT JOIN 
  trades t on t.CID = f.CID