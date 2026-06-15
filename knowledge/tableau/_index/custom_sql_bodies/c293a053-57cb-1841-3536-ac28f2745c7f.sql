WITH base AS (
SELECT 
    ca.AccountNumber, 
    op.GCID, 
    dc.CID,
    ca.ProcessDate as FTD_Date,
    abs(ca.Amount) as Amount,
    r.Name as Regulation,
    cast(dc.Registered as date) as Reg_Date,
    
    ROW_NUMBER() OVER (
        PARTITION BY ca.AccountNumber
        ORDER BY ca.ProcessDate ASC
    ) as rn

FROM 
    main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ca

JOIN 
    main.general.bronze_sodreconciliation_apex_ext765_accountmaster am 
    ON ca.AccountNumber = am.AccountNumber

LEFT JOIN 
    main.general.bronze_usabroker_apex_options op 
    ON am.AccountNumber = op.OptionsApexID

LEFT JOIN 
    main.general.bronze_etoro_customer_customer_masked dc 
    ON dc.GCID = op.GCID

JOIN 
    general.bronze_etoro_backoffice_customer bc 
    ON bc.CID = dc.CID
LEFT JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r on r.ID = bc.RegulationID
WHERE 
    am.OfficeCode in ('4GS','5GU')
    AND (
        ca.EnteredBy IN ('ACH','WRD')
        OR ca.TerminalID = 'OMJNL'
    )
    --AND ca.AccountNumber = '4GS74351'
    AND ca.PayTypeCode IN ('C')
    AND bc.RegulationID = 12
    AND ca.AccountNumber NOT IN (
        '4GS43999','4GS00100','4GS00101','4GS00103','4GS00104'
    )
)

SELECT *
FROM base
WHERE rn = 1