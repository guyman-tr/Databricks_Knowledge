select *,
CAST(CONVERT(char(8), DateID) AS DATE) AS Date_ ,
CAST(CONVERT(char(8), MirrorOpenID) AS DATE) AS Date_MirrorOpenID

from [BI_DB_dbo].[BI_DB_Investment_PIMeetup]
where CID IN
(
'19279089',
'13860225',
'31370715',
'16773762',
'12819281',
'13891322',
'15293487',
'3272291',
'12245278',
'14265491',
'18090122',
'36193946',
'15653440',
'17215075',
'18996621',
'13152522',
'13552031',
'9720869',
'15387961',
'41375071',
'17458937',
'17848016',
'5103891',
'44681131',
'7608546',
'21079531'
)
AND MirrorOpenID>= '20250910'
---ParentCID = 6216244