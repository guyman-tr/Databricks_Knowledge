WITH
-- 1) base cash activity
cash AS (
  SELECT
    CAST(ca.ProcessDate AS date)       AS ProcessDate,
    ca.PayTypeCode,
    ca.EnteredBy,
    ca.TerminalID,
    ca.RegisteredRepCode,
    ca.AccountNumber,
    ca.ACATSControlNumber,
    ca.Amount
  FROM main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ca
  WHERE
    ca.OfficeCode       in ( '4GS','5GU')
    and (
            ca.EnteredBy IN ('ACH','WRD','RET')
            or ca.TerminalID = 'OMJNL'
        )
    AND ca.ProcessDate  >= add_months(current_date(), -3)
    AND ca.AccountNumber NOT IN (
      '4GS43999','4GS00103','4GS00104','4GS00101','4GS00100'
    )
),

-- 2) enrich with options + customer + regulation
qualified AS (
  SELECT
    c.ProcessDate,
    c.PayTypeCode,
    c.EnteredBy,
    c.TerminalID,
    c.RegisteredRepCode,
    c.AccountNumber,
    c.ACATSControlNumber,
    abs(c.Amount) Amount,
    r.Name AS Regulation
  FROM cash c
  JOIN main.general.bronze_usabroker_apex_options op
    ON c.AccountNumber = op.OptionsApexID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked g
    ON op.GCID = g.GCID
   AND g.IsValidCustomer = 1
   AND g.RegulationID   IN (2,6,7,8,12,14)
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r
    ON r.ID = g.RegulationID
),

-- 3) direct‐funding metrics off of the enriched set
direct AS (
  SELECT
    DATEADD(DAY, 7 - DAYOFWEEK(ProcessDate), ProcessDate) as EoW_Sat,
    Regulation,
    COUNT(DISTINCT CASE
      WHEN EnteredBy IN ('ACH','WRD') AND PayTypeCode = 'C' THEN ACATSControlNumber
    END)                       AS OptionsDepositCount,
    COUNT(DISTINCT CASE
      WHEN EnteredBy IN ('ACH','WRD') AND PayTypeCode = 'D' THEN ACATSControlNumber
    END)                       AS OptionsWithdrawalsCount,
    SUM(CASE
      WHEN EnteredBy IN ('ACH','WRD') AND PayTypeCode = 'C' THEN Amount
    END)                       AS OptionsDepositSum,
    SUM(CASE
      WHEN EnteredBy IN ('ACH','WRD') AND PayTypeCode = 'D' THEN Amount
    END)                       AS OptionsWithdrawalsSum,
    SUM(CASE
      WHEN EnteredBy = 'RET' THEN Amount
    END)                       AS OptionsCB
  FROM qualified
  WHERE EnteredBy IN ('ACH','WRD','RET')
  GROUP BY 
    DATEADD(DAY, 7 - DAYOFWEEK(ProcessDate), ProcessDate),
    Regulation

),

-- 4) ICT metrics off of the same enriched set
ict AS (
  SELECT
    DATEADD(DAY, 7 - DAYOFWEEK(ProcessDate), ProcessDate) as EoW_Sat,
    Regulation,
    COUNT(DISTINCT CASE
      WHEN PayTypeCode = 'C' THEN ACATSControlNumber
    END)                       AS Main_to_Options_ICT_Count,
    COUNT(DISTINCT CASE
      WHEN PayTypeCode = 'D' THEN ACATSControlNumber
    END)                       AS Options_to_Main_ICT_Count,
    SUM(CASE
      WHEN PayTypeCode = 'C' THEN Amount
    END)                       AS Main_to_Options_ICT_Sum,
    SUM(CASE
      WHEN PayTypeCode = 'D' THEN Amount
    END)                       AS Options_to_Main_ICT_Sum
  FROM qualified
  WHERE
    TerminalID = 'OMJNL'
    --AND RegisteredRepCode = 'GAT'
  GROUP BY 
    DATEADD(DAY, 7 - DAYOFWEEK(ProcessDate), ProcessDate), 
    Regulation
)

-- 5) stitch them together
SELECT
  cast(COALESCE(d.EoW_Sat, i.EoW_Sat) as date)            AS EoW_Sat,
  COALESCE(d.Regulation, i.Regulation) AS Regulation,

  d.OptionsDepositCount,
  d.OptionsWithdrawalsCount,
  d.OptionsDepositSum,
  d.OptionsWithdrawalsSum,
  d.OptionsCB,

  i.Main_to_Options_ICT_Count,
  i.Options_to_Main_ICT_Count,
  i.Main_to_Options_ICT_Sum,
  i.Options_to_Main_ICT_Sum

FROM direct d
FULL OUTER JOIN ict i
  ON d.EoW_Sat = i.EoW_Sat
 AND d.Regulation = i.Regulation

--ORDER BY WeekStartSun, Regulation;