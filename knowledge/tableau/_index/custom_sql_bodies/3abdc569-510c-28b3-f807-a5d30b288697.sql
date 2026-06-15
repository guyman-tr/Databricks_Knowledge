select  CASE WHEN Program='Card' OR (Program='Potential' AND Club<>'Bronze') THEN 'Card' ELSE 'IBAN' END as Program,
aa.Country
,sum(Users) as Eligible
from
(
select 'Existing' AS Source,
p.Name Club, 
dc.Name AS Country,
case when a.AccountProgramId=1 then 'Card' when AccountProgramId=2 then 'IBANO' end Program, 
count(DISTINCT a.Gcid) Users
--INTO #pop
from  ETL_FiatAccount a
JOIN DWH..Dim_Customer c
ON a.Gcid=c.GCID
INNER JOIN DWH..Dim_Country dc ON c.CountryID = dc.CountryID
join DWH..Dim_PlayerLevel p on c.PlayerLevelID=p.PlayerLevelID
LEFT JOIN eMoney_TestUsers mtu ON a.Gcid = mtu.GCID
WHERE mtu.GCID IS NULL 
group by p.Name, 
dc.Name,
case when a.AccountProgramId=1 then 'Card' when AccountProgramId=2 then 'IBANO' END
UNION ALL

select 'New' AS Source,
p.Name Club, 
dc.Name AS Country,
'Potential' AS  Program, 
count(c.GCID) Users
from DWH..Dim_Customer c
INNER JOIN DWH..Dim_Country dc ON c.CountryID = dc.CountryID
LEFT JOIN eMoney_TestUsers mtu ON c.GCID = mtu.GCID
LEFT JOIN ETL_FiatAccount efa ON c.GCID = efa.Gcid
join DWH..Dim_PlayerLevel p on c.PlayerLevelID=p.PlayerLevelID
where c.CountryID=218
and c.IsValidCustomer=1
and c.VerificationLevelID=3
and /*c.IsDepositor=1*/c.FirstDepositDate>'20000101'
AND efa.Gcid IS NULL AND mtu.GCID IS null
group by p.Name,
dc.Name
) as aa
group by CASE WHEN Program='Card' OR (Program='Potential' AND Club<>'Bronze') THEN 'Card' ELSE 'IBAN' END,aa.Country