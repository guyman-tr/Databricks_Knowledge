select * from BI_DB..BI_DB_CurrentUnits_Per_EffLev 
where UpdateDate in (select Max(UpdateDate) from BI_DB..BI_DB_CurrentUnits_Per_EffLev )