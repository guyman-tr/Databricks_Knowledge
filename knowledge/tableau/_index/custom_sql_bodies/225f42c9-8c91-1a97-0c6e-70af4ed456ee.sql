SELECT
    c.CaseNumber,
    c.CID__c,
    c.CreatedDate AS Case_CreatedDate, -- Renamed for clarity
    c.origin AS Case_Origin,           -- Renamed for clarity
    ms.ChannelName AS Messaging_ChannelName,
    MIN(CASE WHEN d.PaymentStatusID = 2 AND d.Amount > 0 THEN d.PaymentDate ELSE NULL END) OVER (PARTITION BY c.CID__c) AS First_Deposit_Date,
    MAX(CASE WHEN d.PaymentStatusID = 2 AND d.Amount > 0 AND d.PaymentDate BETWEEN c.CreatedDate AND c.createddate + INTERVAL '30 days' THEN 1 ELSE 0 END) OVER (PARTITION BY c.CID__c) AS Deposited_Within_30_Days
FROM
    main.crm.silver_crm_case c
JOIN
    main.crm.silver_crm_messagingsession ms
    ON c.id = ms.caseid
LEFT JOIN -- Use LEFT JOIN here to keep all relevant chat cases, even if no deposit yet
    main.billing.bronze_etoro_billing_deposit d
    ON d.CID = c.CID__c
WHERE
    c.Lead_or_FTD__c = 'Lead'
    AND c.origin IN ('Chat', 'Chatbot')
    AND ms.ChannelName = 'Customer Service Web Chat'
    AND (c.club_level_on_creation__c <> 'Internal' or c.club_level_on_creation__c is null)
    -- You can uncomment the country filter if needed:
    -- AND c.Country__c <> 'United States'
QUALIFY
    ROW_NUMBER() OVER (PARTITION BY c.CaseNumber ORDER BY c.CreatedDate) = 1 -- Ensures unique case per row for chat-related metrics