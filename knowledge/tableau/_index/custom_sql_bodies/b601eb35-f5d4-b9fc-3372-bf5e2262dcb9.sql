SELECT 
  distinct 
  cd.CID, dc.GCID, dr.Name as Regulation, 
  cd.DocumentID, DateAdded, ExpiryDate, 
  dt.Name as DocumentTypeName, cl.Name as DocumentClassificationName, cd.Comment
  -- VisaTypeID
FROM  main.billing.bronze_etoro_backoffice_customerdocument cd
  join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
    on cd.CID=dc.RealCID  
      and dc.RegulationID in (6,7,8,12,14)
  join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr  
    on dr.ID=dc.RegulationID
  join main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype cddt
    on cddt.DocumentID=cd.DocumentID
  join main.finance.bronze_usabroker_dictionary_documenttype dt 
    on dt.DocumentTypeID=cddt.DocumentTypeID
  join general.bronze_etoro_dictionary_documentclassification cl 
    on cl.DocumentClassificationID = cddt.DocumentClassificationID
where cddt.DocumentClassificationID=65