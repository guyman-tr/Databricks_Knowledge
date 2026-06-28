BEGIN

DECLARE V_dateid  int 
;
set V_dateid=CAST(date_format(V_date, 'yyyyMMdd') AS int)
;
SELECT V_dateid;

/*bring daily action data*/
--drop table #FirstActions
DROP VIEW IF EXISTS TEMP_TABLE_FirstActions;
CREATE OR REPLACE TEMPORARY VIEW TEMP_TABLE_FirstActions  
 AS
select a.*,row_number() over(partition by HistoryID order by Occurred, PositionID,SessionID) as rn,row_number() over(partition by ActionTypeID,GCID order by Occurred, PositionID,SessionID) as rn2
--into #FirstActions
from dwh_daily_process.migration_tables.Fact_CustomerAction a
where DateID=V_dateid;

--CREATE CLUSTERED columnstore INDEX #FirstActions ON #FirstActions

delete from TEMP_TABLE_FirstActions where rn>1;

/*mearging with FirstAction table*/
MERGE INTO dwh_daily_process.migration_tables.Fact_FirstCustomerAction AS a
USING TEMP_TABLE_FirstActions AS b
ON a.ActionTypeID=b.ActionTypeID and a.GCID=b.GCID
WHEN NOT MATCHED and b.rn2=1 THEN INSERT ( GCID
,RealCID
,DemoCID
,FirstOccurred
,IPNumber
,IsReal
,ActionTypeID
,PlatformTypeID
,InstrumentID
,Amount
,PositionID
,CampaignID
,BonusTypeID
,FundingTypeID
,LoginID
,MirrorID
,WithdrawID
,PostID
,CaseID
,DateID
,TimeID
,CompensationReasonID
,WithdrawPaymentID
,DepositID
,HistoryID
,FirstEver
,UpdateDate)
VALUES(  b.GCID
,b.RealCID
,b.DemoCID
,b.Occurred
,b.IPNumber
,b.IsReal
,b.ActionTypeID
,b.PlatformTypeID
,b.InstrumentID
,b.Amount
,b.PositionID
,b.CampaignID
,b.BonusTypeID
,b.FundingTypeID
,b.LoginID
,b.MirrorID
,b.WithdrawID
,b.PostID
,b.CaseID
,b.DateID
,b.TimeID
,b.CompensationReasonID
,b.WithdrawPaymentID
,b.DepositID
,b.HistoryID
,1
,current_timestamp())
;
/*mergin again on HistoryID*/

MERGE INTO dwh_daily_process.migration_tables.Fact_FirstCustomerAction AS a
USING TEMP_TABLE_FirstActions AS b
ON a.HistoryID=b.HistoryID 
WHEN NOT MATCHED THEN INSERT ( GCID
,RealCID
,DemoCID
,FirstOccurred
,IPNumber
,IsReal
,ActionTypeID
,PlatformTypeID
,InstrumentID
,Amount
,PositionID
,CampaignID
,BonusTypeID
,FundingTypeID
,LoginID
,MirrorID
,WithdrawID
,PostID
,CaseID
,DateID
,TimeID
,CompensationReasonID
,WithdrawPaymentID
,DepositID
,HistoryID
,FirstEver
,UpdateDate)
VALUES(  b.GCID
,b.RealCID
,b.DemoCID
,b.Occurred
,b.IPNumber
,b.IsReal
,b.ActionTypeID
,b.PlatformTypeID
,b.InstrumentID
,b.Amount
,b.PositionID
,b.CampaignID
,b.BonusTypeID
,b.FundingTypeID
,b.LoginID
,b.MirrorID
,b.WithdrawID
,b.PostID
,b.CaseID
,b.DateID
,b.TimeID
,b.CompensationReasonID
,b.WithdrawPaymentID
,b.DepositID
,b.HistoryID
,0
,current_timestamp())
;
-- [cleanup] drop session-scoped temp objects so the SP leaves no residue
DROP VIEW IF EXISTS TEMP_TABLE_FirstActions;
END