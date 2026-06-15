select Date
      ,Manager
      ,ManagerID
	  ,Desk
	  ,sum(case when  IsContacted = 1 then TotalDepositAmount else 0 end) as DepositsWithContact
	  ,sum(case when  IsContacted = 0 then TotalDepositAmount else 0 end) as DepositsWithoutContact
	  ,sum(TotalCoAmount) as TotalCO
from BI_DB_NewBonusReport with(nolock)
group by Date
      ,Manager
      ,ManagerID
	  ,Desk