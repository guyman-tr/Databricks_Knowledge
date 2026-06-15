(
select workbooks.id as id, workbooks.created_at as created_at,
workbooks.owner_name as owner_name, workbooks.domain_name as domain,
workbooks.project_name as project, workbooks.project_id as project_id,
workbooks.workbook_url as url,workbooks.name,size,'workbook' as type, NULL as last_access_time, sites.name as site, sites.url_namespace as site_id
from _workbooks workbooks, _sites sites
where sites.id = workbooks.site_id
)
union
(
select datasources.id as id, datasources.created_at as created_at,
datasources.owner_name as owner_name, datasources.domain_name as domain,
datasources.project_name as project, datasources.project_id as project_id,
datasources.datasource_url as url,datasources.name,size,'datasource' as type, last_access_time, sites.name as site, sites.url_namespace as site_id
from _datasources datasources, _sites sites, _datasources_stats datasources_stats
where sites.id = datasources.site_id
and datasources.id = datasources_stats.datasource_id
)