SELECT
    Id AS Id_SAR,
    OwnerId AS OwnerId_SAR,
    IsDeleted AS IsDeleted_SAR,
    Name AS Name_SAR,
    CreatedDate AS CreatedDate_SAR,
    CreatedById AS CreatedById_SAR,
    -- LastModifiedDate AS LastModifiedDate_SAR,
    -- LastModifiedById AS LastModifiedById_SAR,
    -- SystemModstamp AS SystemModstamp_SAR,
    -- LastActivityDate AS LastActivityDate_SAR,
    -- LastViewedDate AS LastViewedDate_SAR,
    -- LastReferencedDate AS LastReferencedDate_SAR,
    Account__c AS Account__c_SAR,
    BO_Comments__c AS BO_Comments__c_SAR,
    Case__c AS Case__c_SAR,
    Close_SAR__c AS Close_SAR__c_SAR,
    Country_Place_of_Birth__c AS Country_Place_of_Birth__c_SAR,
    EDD_Analyst_Additional_Comments__c AS EDD_Analyst_Additional_Comments__c_SAR,
    EDD_Final_Result__c AS EDD_Final_Result__c_SAR,
    EDD_Generation_Date__c AS EDD_Generation_Date__c_SAR,
    EDD_Summary__c AS EDD_Summary__c_SAR,
    EDD__c AS EDD__c_SAR,
    Full_Name__c AS Full_Name__c_SAR,
    Informed_Details__c AS Informed_Details__c_SAR,
    IsDocumentProcessingCompleted__c AS IsDocumentProcessingCompleted__c_SAR,
    IsDocumentUploadCompleted__c AS IsDocumentUploadCompleted__c_SAR,
    IsSnapshotingCompleted__c AS IsSnapshotingCompleted__c_SAR,
    IsWebSearchCompleted__c AS IsWebSearchCompleted__c_SAR,
    NCA_First_Contact_Date__c AS NCA_First_Contact_Date__c_SAR,
    NCA_Reference_Code__c AS NCA_Reference_Code__c_SAR,
    NCA_Response__c AS NCA_Response__c_SAR,
    NCA_Submitted_Date__c AS NCA_Submitted_Date__c_SAR,
    Occupation__c AS Occupation__c_SAR,
    PIN__c AS PIN__c_SAR,
    Passport_Number__c AS Passport_Number__c_SAR,
    Person_Responsible__c AS Person_Responsible__c_SAR,
    Prompt_Input__c AS Prompt_Input__c_SAR,
    Raised_By_Department__c AS Raised_By_Department__c_SAR,
    Requested_By__c AS Requested_By__c_SAR,
    Requested_Date__c AS Requested_Date__c_SAR,
    Requested_Documents__c AS Requested_Documents__c_SAR,
    Risk_Classification__c AS Risk_Classification__c_SAR,
    Run_EDD__c AS Run_EDD__c_SAR,
    Run_Web_Search__c AS Run_Web_Search__c_SAR,
    Source_of_Funds__c AS Source_of_Funds__c_SAR,
    Status__c AS Status__c_SAR,
    TIN__c AS TIN__c_SAR,
    Type__c AS Type__c_SAR,
    CID__c AS CID__c_SAR,
    Customer_Status__c AS Customer_Status__c_SAR,
    Date_of_Birth__c AS Date_of_Birth__c_SAR,
    GCID__c AS GCID__c_SAR,
    IsPersonResponsibleCurrentUser__c AS IsPersonResponsibleCurrentUser__c_SAR,
    NCA_Contact_Awaiting_Days_Left__c AS NCA_Contact_Awaiting_Days_Left__c_SAR,
    NCA_Submission_Awaiting_Days_Left__c AS NCA_Submission_Awaiting_Days_Left__c_SAR,
    Nationality__c AS Nationality__c_SAR,
    Register_Address__c AS Register_Address__c_SAR,
    Regulation__c AS Regulation__c_SAR,
    Is_EDD_Null__c AS Is_EDD_Null__c_SAR,
    AMLCO__c AS AMLCO__c_SAR,
    Initial_Regulation__c AS Initial_Regulation__c_SAR,
    Person_Responsible_Role__c AS Person_Responsible_Role__c_SAR,
    Rank_1_Countries_SLA__c AS Rank_1_Countries_SLA__c_SAR,
    Club_Level__c AS Club_Level__c_SAR,
    source_file AS source_file_SAR
    -- etr_y AS etr_y_SAR,
    -- etr_ym AS etr_ym_SAR,
    -- etr_ymd AS etr_ymd_SAR
FROM
    main.crm.silver_crm_sar__c