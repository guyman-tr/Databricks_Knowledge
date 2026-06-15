select *,
CAST(CONVERT(char(8), DateID) AS DATE) AS Date_ ,
CAST(CONVERT(char(8), MirrorOpenID) AS DATE) AS Date_MirrorOpenID

from [BI_DB_dbo].[BI_DB_Investment_PIMeetup]
where CID IN
(
'1709335',
'3419487',
'7184902',
'8804508',
'9131699',
'10405141',
'13114941',
'14024930',
'14592648',
'17860422',
'18363665',
'19152000',
'24686943',
'32508365',
'34288453',
'36564089',
'36926288',
'40182573',
'42126684',
'44476476'
)
AND MirrorOpenID>= '20251124'
AND ParentCID = 12569157