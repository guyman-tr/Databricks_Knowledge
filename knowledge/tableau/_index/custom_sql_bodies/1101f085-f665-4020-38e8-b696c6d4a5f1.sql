SELECT DISTINCT 
        c.Time,
        c.LiveChatTranscriptId,
        CASE 
            WHEN c.Detail LIKE '%Cashout%' THEN 'Cashout'
            WHEN c.Detail LIKE '%Deposit%' THEN 'Deposit'
            WHEN c.Detail LIKE '%Screening%' THEN 'KYC-Screening'
            WHEN c.Detail LIKE '%Verification%' THEN 'KYC-Verification'
            WHEN c.Detail LIKE '%Corporate%' THEN 'Corporate'
            WHEN c.Detail LIKE '%Risk%' THEN 'Risk' 
        END AS ChatSkill,c.CreatedDate,c.Type,c.Detail
    FROM crm.silver_crm_livechattranscriptevent c
    WHERE YEAR(c.Time)>=2025