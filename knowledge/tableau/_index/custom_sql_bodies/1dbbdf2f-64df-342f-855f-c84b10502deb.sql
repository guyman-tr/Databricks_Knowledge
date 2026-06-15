select bo.CID, bo.EIDStatusID, eid.EIDStatusName , 'UAEPass' as UAEFunnel
from main.general.bronze_etoro_backoffice_customer        as bo 
 join  dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked as dc on dc.RealCID = bo.CID
 join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country          as dmc on dmc.CountryID = dc.CountryID
 JOIN main.general.bronze_etoro_dictionary_eidstatus       as eid on eid.EIDStatusID = bo.EIDStatusID
where dmc.Name = 'United Arab Emirates'
and bo.EIDStatusID is not null