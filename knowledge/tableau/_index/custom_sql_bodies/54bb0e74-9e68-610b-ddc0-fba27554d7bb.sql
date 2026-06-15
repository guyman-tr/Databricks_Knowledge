SELECT
  COALESCE(us.ReportMonth,    a.ReportMonth)    AS ReportMonth,
  COALESCE(us.ReportMonthDay, a.ReportMonthDay) AS ReportMonthDay,
  COALESCE(us.PlayerLevel,    a.PlayerLevel)    AS PlayerLevel,
  us.Deposits,
  us.DepositsCount,
  COALESCE(us.Regulation,     a.Regulation)     AS Regulation,
  COALESCE(us.FundingType,    a.FundingType)    AS FundingType,
  COALESCE(us.Country,        a.Country)        AS Country,
  a.Cashouts,
  a.CashoutsCount
FROM (
  SELECT
      date_format(to_date(CAST(d.ModificationDateID AS string), 'yyyyMMdd'), 'yyyyMM')   AS ReportMonth,
      date_format(to_date(CAST(d.ModificationDateID AS string), 'yyyyMMdd'), 'yyyyMMdd') AS ReportMonthDay,
      SUM(d.AmountUSD) AS Deposits,
      COUNT(DISTINCT d.DepositID) AS DepositsCount,
      CASE
        WHEN r.Name IN ('ASIC & GAML') THEN 'ASIC'
        WHEN r.Name IN ('eToroUS','FinCEN+FINRA') THEN 'FinCEN'
        ELSE r.Name
      END AS Regulation,
      dp.Name AS PlayerLevel,
      c.Name  AS Country,
      f.Name  AS FundingType
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit d
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    ON dc.RealCID = d.CID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dp
    ON dp.PlayerLevelID = dc.PlayerLevelID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r
    ON r.ID = dc.RegulationID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country c
    ON c.CountryID = dc.CountryID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype f
    ON f.FundingTypeID = d.FundingTypeID
  WHERE d.ModificationDateID >= 20250101
    AND d.PaymentStatusID = 2
  GROUP BY
      date_format(to_date(CAST(d.ModificationDateID AS string), 'yyyyMMdd'), 'yyyyMM'),
      date_format(to_date(CAST(d.ModificationDateID AS string), 'yyyyMMdd'), 'yyyyMMdd'),
      dp.Name, f.Name, c.Name,
      CASE
        WHEN r.Name IN ('ASIC & GAML') THEN 'ASIC'
        WHEN r.Name IN ('eToroUS','FinCEN+FINRA') THEN 'FinCEN'
        ELSE r.Name
      END
) us
FULL OUTER JOIN (
  SELECT
      SUM(c.Amount_WithdrawToFunding) AS Cashouts,
      COUNT(DISTINCT c.WithdrawID)    AS CashoutsCount,
      ft.Name AS FundingType,
      CASE
        WHEN dc1.Name IN ('ASIC & GAML') THEN 'ASIC'
        WHEN dc1.Name IN ('eToroUS','FinCEN+FINRA') THEN 'FinCEN'
        ELSE dc1.Name
      END AS Regulation,
      pl.Name AS PlayerLevel,
      date_format(c.ModificationDate, 'yyyyMM')   AS ReportMonth,
      date_format(c.ModificationDate, 'yyyyMMdd') AS ReportMonthDay,
      dc2.Name AS Country
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw c
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ft
    ON ft.FundingTypeID = c.FundingTypeID_Funding
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    ON c.CID = dc.RealCID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dc1
    ON dc.RegulationID = dc1.ID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl
    ON pl.PlayerLevelID = dc.PlayerLevelID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc2
    ON dc2.CountryID = dc.CountryID
  WHERE c.ModificationDate >= '2025-01-01'
    AND c.CashoutStatusID_Funding = 3
  GROUP BY
      CASE
        WHEN dc1.Name IN ('ASIC & GAML') THEN 'ASIC'
        WHEN dc1.Name IN ('eToroUS','FinCEN+FINRA') THEN 'FinCEN'
        ELSE dc1.Name
      END,
      pl.Name, ft.Name,
      date_format(c.ModificationDate, 'yyyyMM'),
      date_format(c.ModificationDate, 'yyyyMMdd'),
      dc2.Name
) a
  ON  us.ReportMonth    = a.ReportMonth
  AND us.ReportMonthDay = a.ReportMonthDay
  AND us.PlayerLevel    = a.PlayerLevel
  AND us.Regulation     = a.Regulation
  AND us.FundingType    = a.FundingType
  AND us.Country        = a.Country