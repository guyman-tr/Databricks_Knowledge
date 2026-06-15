SELECT count(DISTINCT base.AccountNumber) accounts_ct, sum(base.TotalEquity) aum, 
min(base.latest_balance_updated) min_balance_updated, max(base.latest_balance_updated) max_balance_updated
from 
(
    SELECT tab2.AccountNumber, tab2.ProcessDate AS latest_balance_updated, tab2.TotalEquity
FROM 
(
    SELECT bs.AccountNumber, bs.ProcessDate, bs.TotalEquity, row_number() OVER (PARTITION BY bs.AccountNumber order by bs.ProcessDate desc) rn  
    FROM 
    (
        SELECT DISTINCT 
            ca.AccountNumber Options_AccountNumber 
            --op.GCID
                       --MIN(ca.ProcessDate) OVER (PARTITION BY ca.AccountNumber) AS Options_ftd_date
        FROM main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ca
        JOIN main.general.bronze_usabroker_apex_options op 
            ON ca.AccountNumber=op.OptionsApexID
        WHERE ca.OfficeCode='4GS' 
        AND ca.RegisteredRepCode='GAT' 
    ) tab 
    JOIN main.general.bronze_sodreconciliation_apex_ext981_buypowersummary bs 
        ON bs.AccountNumber=tab.Options_AccountNumber 
    ) tab2
    WHERE tab2.rn=1
    GROUP BY tab2.AccountNumber, tab2.ProcessDate, tab2.TotalEquity

)base