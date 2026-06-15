SELECT 
    get_json_object(Response__c, '$.sessionId') AS Messaging_session_id_bw,
   get_json_object(Response__c, '$.errorText') AS ErrorMessage_bw,
   createddate as createddate_bw,
    CASE 
        WHEN get_json_object(Response__c, '$.errorText') LIKE '%Blocked word%' THEN 
            trim(regexp_extract(get_json_object(Response__c, '$.errorText'), 'Blocked word(.*)detected', 1))
        ELSE NULL 
    END AS Blocked_word_bw
FROM 
    main.crm.silver_crm_etoro_assistant_bot_request__c
WHERE 
   get_json_object(Response__c, '$.errorText') IS NOT NULL
    AND (get_json_object(Response__c, '$.errorText') LIKE '%Content blocked% detected%' 
        OR get_json_object(Response__c, '$.errorText') LIKE '%Blocked word% detected%')