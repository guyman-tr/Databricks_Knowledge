Select Distinct
    a.CID
    ,a.Processed_date_in_BO
    ,a.ProcessedBy
    --,a.BackofficeAmount
    --,a.GsheetAmount
    -- ,m.GsheetMID
    -- ,m.BackofficeMID
    -- ,d.Gsheet_Date_received_in_BANK
    -- ,d.BO_Date_received_in_BANK
    -- ,e.Gsheet_ExTransactionID
    -- ,e.BO_ExTransactionID
    ,a.MatchAmount
    ,m.MatchMID
    ,d.MatchDatereceivedinBank
    ,e.MatchExTransactionID
FROM 
    Amount a
LEFT JOIN 
    MID m ON m.CID = a.CID and m.Processed_date_in_BO = a.Processed_date_in_BO
LEFT JOIN 
    DatereceivedinBank d ON d.CID = a.CID and d.Processed_date_in_BO = a.Processed_date_in_BO
LEFT JOIN 
    ExTransactionID e ON e.CID = a.CID and e.Processed_date_in_BO = a.Processed_date_in_BO
WHERE 
    a.Processed_date_in_BO >= '2025-01-01'
    and (a.MatchAmount not in ('Match') or m.MatchMID not in ('Match') or d.MatchDatereceivedinBank not in ('Match') or e.MatchExTransactionID not in ('Match'))