select *,
CAST(CONVERT(char(8), DateID) AS DATE) AS Date_ ,
CAST(CONVERT(char(8), MirrorOpenID) AS DATE) AS Date_MirrorOpenID

from [BI_DB_dbo].[BI_DB_Investment_PIMeetup]
where CID IN
(
'24308786',
'8118301',
'24928522',
'44332800',
'20503488',
'12929581',
'27452983',
'40552909',
'32508365',
'5094035',
'17458766',
'4795044',
'36564089',
'40854533',
'10607956',
'17860422',
'33407124',
'18193521',
'28240276',
'12237179'
)
AND MirrorOpenID>= '20250917'
AND ParentCID = 32503878