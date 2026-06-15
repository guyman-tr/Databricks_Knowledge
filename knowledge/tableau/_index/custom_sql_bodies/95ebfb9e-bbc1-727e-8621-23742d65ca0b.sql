Select Trade_date,  'MiFID UK CL' as Report ,sum ([Transaction_Cnt]) as 'Transaction Count',sum([Transaction_Sum]) Transaction_Sum  from [dbo].[RegulationAggTrans] [RegulationAggTrans] 
where 
[eToroEntity]='eToro UK' 
and OpenORClose in ('ClientOpen','ClientClose')
and [Asset class] in ('ETF','Indices','Stocks')
and [IsMifidByESMA]in (0,1)
and [IsMifidByFCA] in (1)
group by Trade_date 

union
Select Trade_date,  'MIFID UK HE' as Report ,sum ([Transaction_Cnt]) as 'Transaction Count',sum([Transaction_Sum]) Transaction_Sum  from [dbo].[RegulationAggTrans] [RegulationAggTrans] 
where 
[eToroEntity]in ('eToro UK') 
and OpenORClose in ('HedgeExecution')
and [Asset class] in ('ETF','Indices','Stocks')
and [IsMifidByESMA]in (0,1)
and [IsMifidByFCA] in (1)
group by Trade_date 



union 
Select Trade_date,  'MiFID EU CL' as Report ,sum ([Transaction_Cnt]) as 'Transaction Count',sum([Transaction_Sum]) Transaction_Sum  from [dbo].[RegulationAggTrans] [RegulationAggTrans] 
where 
[eToroEntity]in ('eToro EU') 
and OpenORClose in ('ClientOpen','ClientClose')
and [Asset class] in ('ETF','Indices','Stocks')
and [IsMifidByESMA]in (1)
and [IsMifidByFCA] in (0,1)
group by Trade_date 


union 
Select Trade_date,  'MiFID EU HE' as Report ,sum ([Transaction_Cnt]) as 'Transaction Count',sum([Transaction_Sum]) Transaction_Sum  from [dbo].[RegulationAggTrans] [RegulationAggTrans] 
where 
[eToroEntity]in ('eToro EU','eToro UK') 
and OpenORClose in ('HedgeExecution')
and [Asset class] in ('ETF','Indices','Stocks')
and [IsMifidByESMA]in (1)
and [IsMifidByFCA] in (0,1)
group by Trade_date 



union
Select Trade_date,  'EMIR CL' as Report ,sum ([Transaction_Cnt]) as 'Transaction Count',sum([Transaction_Sum]) Transaction_Sum  from [dbo].[RegulationAggTrans] [RegulationAggTrans] 
where 
[eToroEntity]in ('eToro EU','eToro UK') 
and OpenORClose in ('ClientOpen','ClientClose')
and [IsMifidByESMA]in (0,1)
and [IsMifidByFCA] in (0,1)
and [CFD/Real] in ('CFD')

group by Trade_date

union
Select [Trade_date],  'ASIC CL' as Report ,sum ([Transaction_Cnt]) as 'Transaction Count',sum([Transaction_Sum]) Transaction_Sum  from [dbo].[RegulationAggTrans] [RegulationAggTrans] 
where 
[eToroEntity]in ('eToro AUS') 
and OpenORClose in ('ClientOpen','ClientClose')
and [IsMifidByESMA]in (0,1)
and [IsMifidByFCA] in (0,1)
and [CFD/Real] in ('CFD')

group by Trade_date