select  CASE WHEN Program='CARD' OR (Program='Potential' AND Club<>'Bronze') THEN 'Card' ELSE 'IBAN' END as Program,
aa.Country
,sum(Users) as Eligible

from
(
select 'Existing' AS Source,
mda.Club, 
mda.Country,
UPPER(mda.AccountProgram) AS Program,
count(DISTINCT mda.GCID) Users
--INTO #pop
from eMoney_Dim_Account mda 
JOIN DWH..Dim_Customer c
ON mda.CID=c.RealCID AND mda.IsValidETM=1 AND c.CountryID IN (54,100,102,126,135,165,168,191,218)
INNER JOIN DWH..Dim_Country dc ON c.CountryID = dc.CountryID
join DWH..Dim_PlayerLevel p on c.PlayerLevelID=p.PlayerLevelID

group by p.Name, 
mda.Club, 
mda.Country,
UPPER(mda.AccountProgram)

UNION ALL

select 'New' AS Source,
p.Name Club, 
dc.Name AS Country,
'Potential' AS  Program, 
count(c.GCID) Users
from DWH..Dim_Customer c
INNER JOIN DWH..Dim_Country dc ON c.CountryID = dc.CountryID
LEFT JOIN eMoney_Dim_Account mda ON mda.CID=c.RealCID AND mda.IsValidETM=1
join DWH..Dim_PlayerLevel p on c.PlayerLevelID=p.PlayerLevelID
where c.CountryID IN (54,100,102,126,135,165,168,191,218)
and c.IsValidCustomer=1
and c.VerificationLevelID=3
and c.IsDepositor=1
AND mda.CID IS null
group by p.Name,
dc.Name
) as aa
group by CASE WHEN Program='CARD' OR (Program='Potential' AND Club<>'Bronze') THEN 'Card' ELSE 'IBAN' END,aa.Country