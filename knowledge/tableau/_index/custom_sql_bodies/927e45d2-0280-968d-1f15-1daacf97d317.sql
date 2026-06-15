select 
  sum(InvestmentEarnings)TotalEarningsBNY
 ,sum(ClientEarnings)/2 UserEarningsBNY
 ,sum(ClientEarnings)/2 eToroEarningsBNY
 ,sum(InvestmentEarnings-ClientEarnings) BrokerEarningsBNY
 ,e.etr_ymd
,BusinessDate
,1-sum(ClientEarnings)/sum(InvestmentEarnings) as PercBrokerEarningsBNY
,sum(ClientEarnings)/sum(InvestmentEarnings)/2 as PercClientEarningsBNY
,sum(ClientEarnings)/sum(InvestmentEarnings)/2 as PerceToroEarningsBNY
 from main.general.gold_bny_gsl250___mtd___monthly_history___earnings e
 WHERE e.etr_ymd >=   <[Parameters].[Parameter 2]>
and e.etr_ymd <=    <[Parameters].[Parameter 3]>
 AND Account=754961
group by all