SELECT DISTINCT
    c.Name as Country,
    dv.Vendor as DocVendor,
    cast(cd.DateAdded as date) as DateAdded,
    count(distinct dc.RealCID) as NoOfCIDsSent,
    count(distinct case when  lower(cc2.Comments) like ('%registration abuse%')then cc2.CID end) as NoOfCIDsSent_Abuse,
    count(cd.documentid) as NoOfDocs
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
JOIN main.billing.bronze_etoro_backoffice_customerdocument cd   ON cd.CID = dc.RealCID
JOIN main.billing.bronze_etoro_backoffice_documentvendors dv   ON dv.DocumentID = cd.DocumentID
JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country c on c.CountryID=dc.CountryID
LEFT JOIN 
  main.general.bronze_etoro_customer_customer_masked cc2 on cc2.CID = dc.RealCID
where 
    cast(cd.DateAdded as date)>='2025-10-01'
Group by 
    c.Name ,
    dv.Vendor,
    cast(cd.DateAdded as date)