WITH date_spine AS (
  SELECT EXPLODE(SEQUENCE(
    DATE_SUB(CURRENT_DATE(), 70),  -- ~10 weeks ago
    CURRENT_DATE(),
    INTERVAL 1 DAY
  )) AS ProcessDate
),

-- Shared lookup: one deduplicated row per AccountNumber with its Regulation
acct_regulation AS (
  SELECT DISTINCT am.AccountNumber, r.Name AS Regulation
  FROM main.general.bronze_sodreconciliation_apex_ext765_accountmaster am
  JOIN main.general.bronze_usabroker_apex_options op ON am.AccountNumber = op.OptionsApexID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON dc.GCID = op.GCID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r ON r.ID = dc.RegulationID
),

op_wit AS (
  SELECT
    c.ProcessDate, COALESCE(acct_reg.Regulation, 'Unknown') AS Regulation,
    COUNT(DISTINCT c.AccountNumber) AS OptionsWithdrawals_CIDCount,
    COUNT(DISTINCT c.ACATSControlNumber) AS OptionsWithdrawalsCount, 
    SUM(c.Amount) AS OptionsWithdrawalsSum
  FROM main.finance.bronze_sodreconciliation_apex_ext869_cashactivity c
  LEFT JOIN acct_regulation acct_reg ON acct_reg.AccountNumber = c.AccountNumber
  WHERE c.OfficeCode IN ('4GS','5GU')
    AND c.RegisteredRepCode IN ('GAT','FO1')
    AND c.EnteredBy IN ('ACH','WRD')
    AND c.AccountNumber NOT IN ('4GS43999','3ET00001','3ET00100','3ET00101','3ET00002','3ET05007','4GS00103','4GS00104','4GS00101','4GS00100')
    AND c.PayTypeCode = 'D'  -- For withdraw
    AND c.ProcessDate >= DATE_SUB(CURRENT_DATE(), 70)
    AND acct_reg.Regulation = 'NYDFS+FINRA'
  GROUP BY c.ProcessDate, COALESCE(acct_reg.Regulation, 'Unknown')
),

pfof AS (
  SELECT rv.TradeDate, COALESCE(acct_reg.Regulation, 'Unknown') AS Regulation,
    SUM(CASE WHEN rv.InstrumentType = 'Equity' THEN ABS(rv.CustomerPFOFPayback) END) AS EquitiesPFOF,
    SUM(CASE WHEN rv.InstrumentType = 'Option' THEN ABS(rv.CustomerPFOFPayback) END) AS OptionsPFOF
  FROM main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports rv
  LEFT JOIN acct_regulation acct_reg ON acct_reg.AccountNumber = rv.ClearingAccount
  WHERE rv.TradeDate >= DATE_SUB(CURRENT_DATE(), 70)
  GROUP BY rv.TradeDate, COALESCE(acct_reg.Regulation, 'Unknown')
),

uk AS (
  SELECT tr.ProcessDate, COALESCE(acct_reg.Regulation, 'Unknown') AS Regulation,
    SUM(ABS(tr.Quantity)) * 0.5 AS UK_OptionsContractFee
  FROM main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity tr
  JOIN acct_regulation acct_reg ON acct_reg.AccountNumber = tr.AccountNumber
  WHERE tr.RegisteredRepCode = 'UK1'
    AND tr.MarketCode = '5' 
    AND tr.ProcessDate >= DATE_SUB(CURRENT_DATE(), 70)
  GROUP BY tr.ProcessDate, COALESCE(acct_reg.Regulation, 'Unknown')
),

ops_equity AS (
  SELECT b.ProcessDate, COALESCE(acct_reg.Regulation, 'Unknown') AS Regulation, 
    SUM(b.TotalEquity) AS OptionsEquity
  FROM main.general.bronze_sodreconciliation_apex_ext981_buypowersummary b
  JOIN acct_regulation acct_reg ON acct_reg.AccountNumber = b.AccountNumber
  WHERE b.OfficeCode IN ('4GS','5GU')
    AND b.AccountNumber NOT IN ('4GS43999','3ET00001','3ET00100','3ET00101','3ET00002','3ET05007','4GS00103','4GS00104','4GS00101','4GS00100')
    AND b.ProcessDate >= DATE_SUB(CURRENT_DATE(), 70)
  GROUP BY b.ProcessDate, COALESCE(acct_reg.Regulation, 'Unknown')
),

-- Collect all distinct regulations that appear in any CTE
all_regulations AS (
  SELECT DISTINCT Regulation FROM op_wit
  UNION
  SELECT DISTINCT Regulation FROM pfof
  UNION
  SELECT DISTINCT Regulation FROM uk
  UNION
  SELECT DISTINCT Regulation FROM ops_equity
),

-- Cross join dates x regulations for a gapless spine
date_reg_spine AS (
  SELECT ds.ProcessDate, ar.Regulation
  FROM date_spine ds
  CROSS JOIN all_regulations ar
)

SELECT 
  drs.ProcessDate,
  drs.Regulation,
  CASE 
    WHEN DAYOFWEEK(drs.ProcessDate) = 7 THEN LAG(COALESCE(op_wit.OptionsWithdrawals_CIDCount, 0)) OVER (PARTITION BY drs.Regulation ORDER BY drs.ProcessDate)
    WHEN DAYOFWEEK(drs.ProcessDate) = 1 THEN LAG(COALESCE(op_wit.OptionsWithdrawals_CIDCount, 0), 2) OVER (PARTITION BY drs.Regulation ORDER BY drs.ProcessDate)
    WHEN DAYOFWEEK(drs.ProcessDate) BETWEEN 2 AND 6 THEN COALESCE(op_wit.OptionsWithdrawals_CIDCount, 0)
  END AS OptionsWithdrawals_CIDCount,
  CASE 
    WHEN DAYOFWEEK(drs.ProcessDate) = 7 THEN LAG(COALESCE(op_wit.OptionsWithdrawalsCount, 0)) OVER (PARTITION BY drs.Regulation ORDER BY drs.ProcessDate)
    WHEN DAYOFWEEK(drs.ProcessDate) = 1 THEN LAG(COALESCE(op_wit.OptionsWithdrawalsCount, 0), 2) OVER (PARTITION BY drs.Regulation ORDER BY drs.ProcessDate)
    WHEN DAYOFWEEK(drs.ProcessDate) BETWEEN 2 AND 6 THEN COALESCE(op_wit.OptionsWithdrawalsCount, 0)
  END AS OptionsWithdrawalsCount,
  CASE 
    WHEN DAYOFWEEK(drs.ProcessDate) = 7 THEN LAG(COALESCE(op_wit.OptionsWithdrawalsSum, 0)) OVER (PARTITION BY drs.Regulation ORDER BY drs.ProcessDate)
    WHEN DAYOFWEEK(drs.ProcessDate) = 1 THEN LAG(COALESCE(op_wit.OptionsWithdrawalsSum, 0), 2) OVER (PARTITION BY drs.Regulation ORDER BY drs.ProcessDate)
    WHEN DAYOFWEEK(drs.ProcessDate) BETWEEN 2 AND 6 THEN COALESCE(op_wit.OptionsWithdrawalsSum, 0)
  END AS OptionsWithdrawalsSum,
  COALESCE(pfof.EquitiesPFOF, 0) AS EquitiesPFOF,
  COALESCE(pfof.OptionsPFOF, 0) AS OptionsPFOF,
  COALESCE(uk.UK_OptionsContractFee, 0) AS UK_OptionsContractFee,
  COALESCE(ops_equity.OptionsEquity, 0) AS OptionsEquity,
  COALESCE(
    ops_equity.OptionsEquity,
    MAX(ops_equity.OptionsEquity) OVER (
      PARTITION BY drs.Regulation
      ORDER BY drs.ProcessDate
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
    )
  ) AS OptionsEquity_Adj
FROM date_reg_spine drs
LEFT JOIN op_wit ON op_wit.ProcessDate = drs.ProcessDate AND op_wit.Regulation = drs.Regulation
LEFT JOIN pfof ON pfof.TradeDate = drs.ProcessDate AND pfof.Regulation = drs.Regulation
LEFT JOIN uk ON uk.ProcessDate = drs.ProcessDate AND uk.Regulation = drs.Regulation
LEFT JOIN ops_equity ON ops_equity.ProcessDate = drs.ProcessDate AND ops_equity.Regulation = drs.Regulation
WHERE 
  drs.Regulation = 'NYDFS+FINRA'
ORDER BY drs.ProcessDate, drs.Regulation