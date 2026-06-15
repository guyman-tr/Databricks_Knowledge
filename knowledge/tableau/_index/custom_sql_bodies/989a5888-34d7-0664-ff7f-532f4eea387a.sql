SELECT 
DISTINCT B.GCID,
B.Status,
B.Provider,
cast(B.CreatedAt as date) CreatedAt,
cast(B.UpdatedOrCompletedOn as date) UpdatedOrCompletedOn,
B._ts,
B.RN, 
B.Attempts,
B.LatestIdentificationIdCreated,
dc1.Name as Country, 
dr.Name as Regulation 
FROM 
(
    SELECT 
    DISTINCT GCID,
    Status,
    Provider,
    cast(CreatedAt as date) CreatedAt,
    cast(UpdatedOrCompletedOn as date) UpdatedOrCompletedOn,
    _ts,
    RN, 
    Attempts,
    LatestIdentificationIdCreated
    FROM 
    (
        SELECT 
        gcid*1 as GCID,
        case 
            when GlobalStatus in ('successful') then 'Success'
            when GlobalStatus in ('failed') then 'Failed'
            when GlobalStatus in ('created') then 'Created'
            when GlobalStatus in ('pending') then 'Pending' 
        end as Status,
        'Solaris' as Provider,
        to_date(from_unixtime(unix_timestamp(s.CreatedAt, 'yyyy-MM-dd\'T\'HH:mm:ss.SSSSSSSXXX'))) AS CreatedAt,
        CASE 
    WHEN s.CompleteAt LIKE '____-__-__T__:__:__%.%' THEN 
      to_date(from_unixtime(unix_timestamp(s.CompleteAt, 'yyyy-MM-dd\'T\'HH:mm:ss.SSSSSSSXXX')))
    WHEN s.CompleteAt LIKE '____-__-__T__:__:__' THEN 
      to_date(from_unixtime(unix_timestamp(s.CompleteAt, 'yyyy-MM-dd\'T\'HH:mm:ss')))
    ELSE NULL
  END AS UpdatedOrCompletedOn,
        _ts,
        ROW_NUMBER() OVER (PARTITION BY gcid ORDER BY _ts desc ) AS RN,
        COUNT(gcid) OVER (PARTITION BY gcid) AS Attempts,
        LatestIdentificationIdCreated
        FROM main.compliance.bronze_solarisbankidentdb_solarisbankident s
    ) a
    WHERE a.RN=1

    UNION

    SELECT 
    DISTINCT GCID,
    Status,
    Provider,
    cast(CreatedAt as date) CreatedAt,
    cast(UpdatedOrCompletedOn as date) UpdatedOrCompletedOn,
    _ts,
    RN, 
    Attempts,
    LatestIdentificationIdCreated
    FROM 
    (
        SELECT 
        gcid*1 as GCID,
        case 
            when Status in ('New') then 'Created' 
            else Status 
        end as Status,
        Provider,
to_date(from_unixtime(unix_timestamp(CreatedOn, 'MM/dd/yyyy HH:mm:ss'))) as CreatedAt,
to_date(from_unixtime(unix_timestamp(UpdatedOn, 'MM/dd/yyyy HH:mm:ss'))) as UpdatedOrCompletedOn,
        _ts,
        ROW_NUMBER() OVER (PARTITION BY gcid ORDER BY to_date(from_unixtime(unix_timestamp(UpdatedOn, 'MM/dd/yyyy HH:mm:ss'))) desc ) AS RN,
        COUNT(gcid) OVER (PARTITION BY gcid) AS Attempts,
        'OK' as LatestIdentificationIdCreated
        FROM main.general.bronze_videoidentdb_videoident s
    ) a
    WHERE a.RN=1
) B
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.GCID=B.GCID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1 on dc1.CountryID=dc.CountryID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr on dr.ID=dc.DesignatedRegulationID