WIth master as (
SELECT 
    CID AS SubAccountCID,
    CAST(xpath_string(a.AuditActionParameters, '//MasterAccountCid') AS INT) AS MasterAccountCID,
    CAST(a.etr_ymd AS DATE) AS LinkDate
FROM
    main.general.bronze_db_logs_backoffice_auditaction a
WHERE 
    a.AuditActionTypeID IN (33, 295) -- UpdateCustomerMaster, ChangeMasterAccount
   AND xpath_string(a.AuditActionParameters, '//MasterAccountCid') IS NOT NULL
)

,mas AS (
Select DISTINCT
    m.*
    ,row_number() over(partition by m.SubAccountCID order by m.LinkDate desc) as rn
FROM
     master m 
WHERE
    m.MasterAccountCID is not null
)

Select distinct
    m.*
FROM
    mas m
WHERE rn = 1  AND MasterAccountCID<>0