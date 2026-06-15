SELECT
  COUNT(dc.CID) AS NoOfClients,
  bc.VerificationLevelID,
  dr.Name AS Regulation,
  dr1.Name as DesignatedRegulation,
  dc1.Name AS Country,
  dc1.Region,
  MONTH(dc.Registered) AS Month,
  YEAR(dc.Registered) AS Year,
  date_format(dc.Registered, 'yyyyMM') AS YearMonth,
  CAST(dc.Registered AS DATE) AS RegDate,
  -- Calculates if date is within the last 6 weeks from the start of the current week
  CASE
    WHEN dc.Registered >= date_sub(date_trunc('week', current_timestamp()), 42) THEN 1
    ELSE 0
  END AS `6WeekIndicator`,
  CASE
    WHEN bc.PhoneVerifiedID IN (1, 2) THEN 'Verified'
    ELSE 'Unverified'
  END AS PhoneVerified,
  ps.Name AS PlayerStatus,
  case
    when d.cid is not null then 1
    else 0
  end as Converted,
  case
    when d.cid is null then false
    else true
  end as IsDepositor
FROM
  main.general.bronze_etoro_customer_customer_masked dc
    JOIN general.bronze_etoro_backoffice_customer bc
      ON bc.CID = dc.CID
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr
      ON dr.ID = bc.RegulationID
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr1
      ON dr1.ID = bc.DesignatedRegulationID
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1
      ON dc1.CountryID = dc.CountryID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_phoneverified ph
      ON ph.PhoneVerifiedID = bc.PhoneVerifiedID
    LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ps
      ON ps.PlayerStatusID = dc.PlayerStatusID
    left join (
      Select DISTINCT
        d.CID
      from
        main.general.bronze_etoro_dwh_billingdeposithourly d
      where
        d.PaymentStatusID = 2
    ) d
      on d.cid = dc.CID
WHERE
  dc.Registered >= add_months(date_trunc('month', current_date()), -24)
  AND IsReal = true
GROUP BY
  bc.VerificationLevelID,
  dr.Name,
  dc1.Name,
  case
    when d.cid is not null then 1
    else 0
  end,
  case
    when d.cid is null then false
    else true
  end,
  MONTH(dc.Registered),
  YEAR(dc.Registered),
  date_format(dc.Registered, 'yyyyMM'),
  CAST(dc.Registered AS DATE),
  dr1.Name,
  CASE
    WHEN dc.Registered >= date_sub(date_trunc('week', current_timestamp()), 42) THEN 1
    ELSE 0
  END,
  dc1.Region,
  CASE
    WHEN bc.PhoneVerifiedID IN (1, 2) THEN 'Verified'
    ELSE 'Unverified'
  END,
  ps.Name