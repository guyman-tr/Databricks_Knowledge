SELECT
    Id AS Id_EDD,
    OwnerId AS OwnerId_EDD,
    IsDeleted AS IsDeleted_EDD,
    Name AS Name_EDD,
    CreatedDate AS CreatedDate_EDD,
    CreatedById AS CreatedById_EDD,
    -- LastModifiedDate AS LastModifiedDate_EDD,
    -- LastModifiedById AS LastModifiedById_EDD,
    -- SystemModstamp AS SystemModstamp_EDD,
    -- LastActivityDate AS LastActivityDate_EDD,
    -- LastViewedDate AS LastViewedDate_EDD,
    -- LastReferencedDate AS LastReferencedDate_EDD,
    Account__c AS Account__c_EDD,
    Case__c AS Case__c_EDD,
    EDD_AI_Recommendation__c AS EDD_AI_Recommendation__c_EDD,
    Generation_Date__c AS Generation_Date__c_EDD,
    Missing_Documents__c AS Missing_Documents__c_EDD,
    Prompt_Input__c AS Prompt_Input__c_EDD,
    Recommended_Next_Actions__c AS Recommended_Next_Actions__c_EDD,
    SAR__c AS SAR__c_EDD,
    Status__c AS Status__c_EDD,
    Summary__c AS Summary__c_EDD,
    Initial_Regulation__c AS Initial_Regulation__c_EDD,
    Created_By_Role__c AS Created_By_Role__c_EDD,
    source_file AS source_file_EDD
    -- etr_y AS etr_y_EDD,
    -- etr_ym AS etr_ym_EDD,
    -- etr_ymd AS etr_ymd_EDD,
FROM
    main.crm.silver_crm_edd__c