SELECT
    -- Columns from silver_crm_document_insight_bundle__c (alias: dib)
    dib.Id AS Id_dib,
    dib.OwnerId AS OwnerId_dib,
    dib.IsDeleted AS IsDeleted_dib,
    dib.Name AS Name_dib,
    dib.CreatedDate AS CreatedDate_dib,
    -- dib.CreatedById AS CreatedById_dib,
    -- dib.LastModifiedDate AS LastModifiedDate_dib,
    -- dib.LastModifiedById AS LastModifiedById_dib,
    -- dib.SystemModstamp AS SystemModstamp_dib,
    -- dib.LastActivityDate AS LastActivityDate_dib,
    -- dib.DocumentClassificationSubType__c AS DocumentClassificationSubType__c_dib,
    -- dib.DocumentClassificationType__c AS DocumentClassificationType__c_dib,
    dib.Integration_Error_Message__c AS Integration_Error_Message__c_dib,
    
    -- *** CRITICAL JOIN KEY ***
    dib.Messaging_Session_Id__c AS Messaging_Session_Id__c_dib,
    
    dib.Overall_Integration_Status__c AS Overall_Integration_Status__c_dib,
    -- dib.Suggested_Document_SubType__c AS Suggested_Document_SubType__c_dib,
    -- dib.Suggested_Document_Type__c AS Suggested_Document_Type__c_dib,
    dib.Total_Sides__c AS Total_Sides__c_dib,
    -- dib.source_file AS source_file_dib,
    -- dib.etr_y AS etr_y_dib,
    -- dib.etr_ym AS etr_ym_dib,
    dib.etr_ymd AS etr_ymd_dib,
    -- dib.processing_time AS processing_time_dib,
    -- dib.__Timestamp AS __Timestamp_dib,
    -- dib.__DeleteVersion AS __DeleteVersion_dib,
    -- dib.__UpsertVersion AS __UpsertVersion_dib,
    -- dib.__DROP_EXPECTATIONS_COL AS __DROP_EXPECTATIONS_COL_dib,
    -- dib.__MEETS_DROP_EXPECTATIONS AS __MEETS_DROP_EXPECTATIONS_dib,
    -- dib.__ALLOW_EXPECTATIONS_COL AS __ALLOW_EXPECTATIONS_COL_dib,

    -- Columns from Joins
    ddc.name AS DocumentClassificationName_ddc,
    dt.Name AS DocumentType_dt

FROM main.crm.silver_crm_document_insight_bundle__c dib
left JOIN main.general.bronze_etoro_dictionary_documentclassification ddc
  ON dib.DocumentClassificationSubType__c = ddc.DocumentClassificationID
left JOIN main.general.bronze_etoro_dictionary_documenttype dt
  ON dib.DocumentClassificationType__c = dt.DocumentTypeID