select SUM(Final) as [Total Loss],YearMonth,Regulation,[Method Of Payment] from #videoident
group by YearMonth,Regulation,[Method Of Payment]