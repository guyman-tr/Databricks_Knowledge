select
A.ApexID,
dc.RealCID AS CID,
A.GCID,
st.Name AS 'ApexStatus',
ud.ApproverName,
A.BeginTime,
A.EndTime,
dc.RegisteredReal as RegisteredDate_TP,
dr.Name as Regulation,
dc.VerificationLevelID
FROM
	(
select 
ad.ApexID,
ad.GCID,
ad.BeginTime,
ad.EndTime,
ad.StatusID,
row_number () over (partition by ad.ApexID order by ad.BeginTime desc) as RN
from [BI_DB_dbo].[External_USABroker_Apex_ApexData] ad
 
	) A
LEFT JOIN [BI_DB_dbo].[External_USABroker_Dictionary_ApexStatus] st  ON A.StatusID = st.StatusID
LEFT JOIN [BI_DB_dbo].[External_USABroker_Apex_UserData] ud  ON A.GCID = ud.GCID
LEFT join DWH_dbo.Dim_Customer dc on dc.GCID=A.GCID
LEFT join DWH_dbo.Dim_Regulation dr on dr.ID=dc.RegulationID
WHERE A.RN=1