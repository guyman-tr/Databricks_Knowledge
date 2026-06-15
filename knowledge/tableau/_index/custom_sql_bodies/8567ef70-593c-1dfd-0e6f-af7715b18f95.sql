SELECT 
    get_json_object(Response__c, '$.sessionId') AS Messaging_session_id_bw,
   get_json_object(Response__c, '$.errorText') AS ErrorMessage_bw,
    CASE 
        WHEN get_json_object(Response__c, '$.errorText') LIKE '%Blocked word%' THEN 
            trim(regexp_extract(get_json_object(Response__c, '$.errorText'), 'Blocked word(.*)detected', 1))
        ELSE NULL 
    END AS Blocked_word_bw
FROM 
    main.crm.silver_crm_etoro_assistant_bot_request__c
WHERE 
 length(trim(get_json_object(Response__c, '$.errorText')))>1
  and CreatedDate >= current_date - interval '12 months' AND CreatedDate >= '2025-04-02'