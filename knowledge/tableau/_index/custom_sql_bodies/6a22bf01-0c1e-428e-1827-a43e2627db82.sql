select *,
CAST(CONVERT(char(8), DateID) AS DATE) AS Date_ ,
CAST(CONVERT(char(8), MirrorOpenID) AS DATE) AS Date_MirrorOpenID

from [BI_DB_dbo].[BI_DB_Investment_PIMeetup]
where CID IN
(
'34123028',
'44010081',
'36883064',
'41392282',
'13203279',
'21829514',
'23108659',
'5179192',
'10080316',
'44835827',
'31257578',
'42700419',
'5181316',
'29775023'
)
AND MirrorOpenID>= '20251120'
AND ParentCID = 11480370