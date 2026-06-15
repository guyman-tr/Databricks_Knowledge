SELECT 
    Chat_Transcript_Id__c,
   get_json_object(Response__c, '$.errorText') AS ErrorMessage,
    CASE 
        WHEN get_json_object(Response__c, '$.errorText') LIKE '%Blocked word%' THEN 
            trim(regexp_extract(get_json_object(Response__c, '$.errorText'), 'Blocked word(.*)detected', 1))
        ELSE NULL 
    END AS `Blocked word`
FROM 
    main.crm.silver_crm_etoro_assistant_bot_request__c
WHERE 
    get_json_object(Response__c, '$.errorText') IS NOT NULL
    AND (get_json_object(Response__c, '$.errorText') LIKE '%Content blocked% detected%' 
         OR get_json_object(Response__c, '$.errorText') LIKE '%Blocked word% detected%')