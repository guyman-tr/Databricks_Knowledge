select *,
CAST(CONVERT(char(8), DateID) AS DATE) AS Date_ ,
CAST(CONVERT(char(8), MirrorOpenID) AS DATE) AS Date_MirrorOpenID

from [BI_DB_dbo].[BI_DB_Investment_PIMeetup]
where CID IN
(
'20485996',
'21535984',
'32282780',
'23669658',
'17319172',
'45061919',
'34754640',
'13353901',
'17481470',
'33188238',
'14192507',
'24710360',
'20621317',
'36083471',
'35048398',
'35208009',
'29894391'
)
AND MirrorOpenID>= '20251126'
AND ParentCID = 6117997