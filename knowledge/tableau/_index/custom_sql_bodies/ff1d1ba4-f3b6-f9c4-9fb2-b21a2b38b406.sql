select *
from
(
SELECT RealCID
,CopyFundCID
,CopyFundName
,OccurredDate
,Manager
,ROW_NUMBER() over (partition by RealCID order by OccurredDate asc) as rn_CF
from [dbo].[BI_DB_SalesCopyFund]
where Mirrors_Open = 1 and CopyFundCID not in (6421394,6215327)
)a
where rn_CF = 1