select  T1.ReportDate,T1.Report, T1.Transaction_Count Audit_Transaction_Count, T2.Transaction_Count TraNa_Audit_Transaction_Count,T1.Transaction_Count-T2.Transaction_Count as Audit_vs_TraNa_Transaction_Count_Diff 

from 

(
Select ReportDate,  'MiFID UK CL' as Report ,Count ([TransactionReferenceNumber]) AS Transaction_Count from [dbo].[MIFID2_Report] [MIFID2_Report] 
where 
[RegulationID]='2' 
and OpenORClose in ('C','O')
and [AssetClass] = 'Equity'
And ReportDate >= <[Parameters].[Parameter 1]>
group by ReportDate 
)T1
inner join 
(
Select Trade_date,  'MiFID UK CL' as Report ,sum ([Transaction_Cnt]) AS Transaction_Count from [dbo].[RegulationAggTrans] [RegulationAggTrans] 
where 
[eToroEntity]='eToro UK' 
and OpenORClose in ('ClientOpen','ClientClose')
and [Asset class] in ('ETF','Indices','Stocks')
and [IsMifidByESMA]in (0,1)
and [IsMifidByFCA] in (1)
and Trade_date >= <[Parameters].[Parameter 1]>
group by Trade_date
)T2
on T1.ReportDate=T2.Trade_date
and T1.Report=T2.Report