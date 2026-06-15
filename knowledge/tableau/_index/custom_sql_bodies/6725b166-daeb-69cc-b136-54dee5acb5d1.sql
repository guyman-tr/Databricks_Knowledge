select  
 DISTINCT sh.ResultId as HitID,
 case when sh.SuggestedHitResolutionStatusId=1 then 'Possible'
 when sh.SuggestedHitResolutionStatusId=2 then 'Positive'
 when sh.SuggestedHitResolutionStatusId=3 then 'False'
 when sh.SuggestedHitResolutionStatusId=4 then 'APU/More Info Needed' end as AIRecommndation,

  case when sh.ActualHitResolutionStatusId=1 then 'Possible'
 when sh.ActualHitResolutionStatusId=2 then 'Positive'
 when sh.ActualHitResolutionStatusId=3 then 'False'
end as AgentStatus,
--sh.ReferenceId as HitID,
sh.Comment as AIResolutionReason,
sh.CreatedAt,
ProviderScreening.GCID,
ProviderScreening.CaseID,
dc.RealCID


 from main.bi_db.bronze_screeningservice_screening_hits sh
left join main.bi_db.bronze_screeningservice_screening_providerscreening ProviderScreening on ProviderScreening.CaseID=sh.CaseSystemId
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.GCID=ProviderScreening.GCID
where (SuggestedHitResolutionStatusId is not null or SuggestedHitResolutionStatusId<>'Null')
and (sh.ActualHitResolutionStatusId is not null or ActualHitResolutionStatusId<>'Null')