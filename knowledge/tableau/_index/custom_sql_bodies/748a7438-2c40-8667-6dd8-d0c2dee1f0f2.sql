-- Blocked Customers Analysis - Converted from Synapse to Databricks SQL
-- Original T-SQL temp tables converted to CTEs, functions adapted to Databricks SQL syntax

WITH 
-- Variables as CTE
params AS (
  SELECT 
    current_date() - 1 AS EndDate,
    CAST(date_format(current_date() - 1, 'yyyyMMdd') AS INT) AS EndDateID
),

-- #active equivalent
active AS (
  SELECT 
    fd.CID,
    fd.LastLoggedIn,
    regulation.Name AS Regulation,
    vl.Credit AS Balance,
    vl.Liabilities + vl.ActualNWA AS TotalEquity,
    dc.PlayerStatusID
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked fd
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON dc.RealCID = fd.CID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl ON vl.CID = fd.CID 
    AND vl.DateID = (SELECT EndDateID FROM params)
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation regulation ON regulation.ID = dc.RegulationID
  WHERE dc.IsValidCustomer = 1
    AND dc.IsDepositor = 1
    AND dc.PlayerStatusID NOT IN (0, 1)  -- Exclude N/A and Normal
),

-- #blockedtime equivalent - find when status changed
blockedtime_base AS (
  SELECT 
    fsc.RealCID,
    fsc.PlayerStatusID,
    to_date(CAST(fsc.FromDateID AS STRING), 'yyyyMMdd') AS Change_Date,
    LAG(fsc.PlayerStatusID, 1, 0) OVER (PARTITION BY fsc.RealCID ORDER BY fsc.FromDateID ASC) AS Previous_PlayerStatusID
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
  WHERE fsc.RealCID IN (SELECT CID FROM active)
),

blockedtime AS (
  SELECT 
    a.RealCID AS CID,
    a.PlayerStatusID,
    MAX(a.Change_Date) AS BlockedTime
  FROM blockedtime_base a
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
    ON dc.RealCID = a.RealCID AND dc.PlayerStatusID = a.PlayerStatusID
  WHERE a.PlayerStatusID <> a.Previous_PlayerStatusID
  GROUP BY a.RealCID, a.PlayerStatusID
),

-- #aging equivalent
aging AS (
  SELECT 
    b.*,
    CASE 
      WHEN timestampdiff(HOUR, b.BlockedTime, current_timestamp()) <= 24 THEN 'Under 24h'
      WHEN timestampdiff(HOUR, b.BlockedTime, current_timestamp()) <= 48 THEN 'Under 48h'
      WHEN datediff(current_date(), b.BlockedTime) <= 5 THEN '5 days'
      WHEN datediff(current_date(), b.BlockedTime) <= 10 THEN '10 days'
      WHEN datediff(current_date(), b.BlockedTime) <= 15 THEN '15 days'
      WHEN months_between(current_date(), b.BlockedTime) <= 1 THEN '1 month'
      WHEN months_between(current_date(), b.BlockedTime) <= 2 THEN '2 months'
      ELSE 'Over 2 Months' 
    END AS TimeBucket
  FROM blockedtime b
),

-- #CASHOUTS equivalent
cashouts AS (
  SELECT 
    bw.CID, 
    MIN(bw.RequestDate) AS CashoutRequestDate,
    dcs.Name AS CashoutStatus,
    bt.BlockedTime
  FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw bw
  LEFT JOIN blockedtime bt ON bt.CID = bw.CID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_cashoutstatus dcs ON dcs.CashoutStatusID = bw.CashoutStatusID_Withdraw
  WHERE bw.FundingTypeID_Withdraw = 19 OR bw.FundingTypeID_Funding = 19
  GROUP BY bw.CID, dcs.Name, bt.BlockedTime
  HAVING MIN(bw.RequestDate) >= bt.BlockedTime
),

-- #lastcashouts equivalent
lastcashouts AS (
  SELECT 
    CID, 
    CashoutRequestDate,
    CashoutStatus,
    ROW_NUMBER() OVER (PARTITION BY CID ORDER BY CashoutRequestDate DESC) AS RN
  FROM cashouts
),

-- #sf equivalent (support cases)
sf AS (
  SELECT DISTINCT SF.CID
  FROM main.bi_output.bi_output_customer_customer_support_case SF
  JOIN cashouts C ON C.CID = SF.CID
  WHERE SF.CreatedDate >= C.CashoutRequestDate
),

-- #final equivalent
final_data AS (
  SELECT 
    a.CID,
    a.LastLoggedIn,
    a.Regulation,
    a.Balance,
    a.TotalEquity,
    a.PlayerStatusID,
    ps.Name AS PlayerStatus,
    psr.Name AS PlayerStatusReason,
    pssr.PlayerStatusSubReasonName AS PlayerStatusSubReason,
    a1.TimeBucket,
    COALESCE(pcs.PendingClosureStatusName, 'No') AS PendingClosureStatus,
    a1.BlockedTime,
    CASE 
      WHEN COALESCE(a.TotalEquity, 0) < 5 THEN 'A:0-5' 
      WHEN COALESCE(a.TotalEquity, 0) >= 5 AND COALESCE(a.TotalEquity, 0) < 50 THEN 'B:5-50'
      WHEN COALESCE(a.TotalEquity, 0) >= 50 AND COALESCE(a.TotalEquity, 0) < 500 THEN 'C:50-500'
      WHEN COALESCE(a.TotalEquity, 0) >= 500 THEN 'D: 500+'
    END AS Equity_Level,
    CASE WHEN lastc.CID IS NOT NULL THEN 'Yes' ELSE 'No' END AS Cashouts,
    lastc.CashoutRequestDate,
    lastc.CashoutStatus,
    CASE WHEN sf.CID IS NOT NULL THEN 'Yes' ELSE 'No' END AS Tickets,
    dc.RiskGroupID,
    CASE 
      WHEN pssr.PlayerStatusSubReasonName IN ('Selfie') THEN CONCAT(ps.Name, ' - ', psr.Name, ' - ', pssr.PlayerStatusSubReasonName)
      WHEN psr.Name IN ('AML') THEN CONCAT(ps.Name, ' - ', psr.Name, ' - ', pssr.PlayerStatusSubReasonName)
      ELSE CONCAT(ps.Name, ' - ', psr.Name)
    END AS FinalGrouping,
    dc.Region, 
    dc.Name AS Country,
    at.Name AS AccountType,
    -- Owner classification
    CASE
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Abusive Trading' THEN 'Compliance'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('PayPal CHBK', 'SAR filed') THEN 'FCMU'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'AML' THEN 'AML'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Chargeback' THEN 'FCMU'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Corporate' THEN 'Corporate'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'CS management decision' THEN 'CS'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Deceased' THEN 'AML'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Deposits' THEN 'Money In'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'eToro Money Restriction' THEN 'FCMU'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Hacked Account' THEN 'FCMU'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Partners & PIs' THEN 'Partners'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Risk' AND pssr.PlayerStatusSubReasonName = 'Affiliate Fraud' THEN 'Partners'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Risk' THEN 'FCMU'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Tax' THEN 'FCMU'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Underage' THEN 'AML'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('PayPal CHBK', 'SAR filed') THEN 'FCMU'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'AML' THEN 'AML'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'Chargeback' THEN 'FCMU'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'Corporate' THEN 'Corporate'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'CS management decision' THEN 'CS'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'Deposits' THEN 'Money In'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'eToro Money Restriction' THEN 'FCMU'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'KYC' THEN 'KYC'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'Partners & PIs' THEN 'Partners'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'PWMB Chargeback' THEN 'Money In'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'Risk' AND pssr.PlayerStatusSubReasonName = 'Affiliate Fraud' THEN 'FCMU/Partners'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'Risk' THEN 'FCMU'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'Tax' THEN 'FCMU'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('PayPal CHBK', 'SAR filed') THEN 'FCMU'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'AML' THEN 'AML'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'Chargeback' THEN 'FCMU'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'Corporate' THEN 'Corporate'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'Deposits' THEN 'Deposits'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'eToro Money Restriction' THEN 'FCMU'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'KYC' THEN 'KYC'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'Risk' AND pssr.PlayerStatusSubReasonName = 'Affiliate Fraud' THEN 'FCMU/Partners'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'Risk' THEN 'FCMU'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'Tax' THEN 'FCMU'
      WHEN ps.Name = 'Pending Verification' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('PayPal CHBK', 'SAR filed') THEN 'FCMU'
      WHEN ps.Name = 'Pending Verification' AND psr.Name = 'AML' THEN 'AML'
      WHEN ps.Name = 'Pending Verification' AND psr.Name = 'Chargeback' THEN 'FCMU'
      WHEN ps.Name = 'Pending Verification' AND psr.Name = 'KYC' THEN 'KYC'
      WHEN ps.Name = 'Pending Verification' AND psr.Name = 'Risk' AND pssr.PlayerStatusSubReasonName = 'Affiliate Fraud' THEN 'Partners'
      WHEN ps.Name = 'Pending Verification' AND psr.Name = 'Risk' THEN 'FCMU'
      WHEN ps.Name = 'Warning' AND psr.Name = 'Abusive Trading' THEN 'Compliance'
      WHEN ps.Name = 'Warning' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('PayPal CHBK', 'SAR filed') THEN 'FCMU'
      WHEN ps.Name = 'Warning' AND psr.Name = 'AML' THEN 'AML'
      WHEN ps.Name = 'Warning' AND psr.Name = 'AML review' THEN 'AML'
      WHEN ps.Name = 'Warning' AND psr.Name = 'Deposits' THEN 'Money In'
      WHEN ps.Name = 'Warning' AND psr.Name = 'Overpayment' THEN 'Money Out'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Account Closed' THEN 'Money Out'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('PayPal CHBK', 'SAR filed') THEN 'FCMU'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'AML' THEN 'AML'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Chargeback' THEN 'FCMU'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Corporate' THEN 'Corporate'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Deceased' THEN 'AML'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'eToro Money Restriction' THEN 'FCMU'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'KYC' THEN 'KYC'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Other' THEN 'KYC'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Partners & PIs' THEN 'Partners'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Risk' AND pssr.PlayerStatusSubReasonName = 'Affiliate Fraud' THEN 'Partners'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Risk' THEN 'FCMU'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Tax' THEN 'FCMU'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Underage' THEN 'AML'
      WHEN ps.Name = 'Copy Blocked' AND psr.Name = 'Abusive Trading' THEN 'Compliance'
      WHEN ps.Name = 'Copy Blocked' AND psr.Name = 'Partners & PIs' THEN 'Partners'
      ELSE 'Unknown'
    END AS Owner,
    -- Handling team classification
    CASE
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Abusive Trading' THEN 'Money In'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'Abusive Trading Investigation' THEN 'AML'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'AML Trigger' THEN 'AML OPS'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('Closed - Failed Verification', 'Cross Border', 'Expired POI/POA', 'HRC', 'Screening - Negative Results', 'Screening - PEP', 'Screening - Possible Match', 'Screening - Sanctions') THEN 'KYC'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('Investigation', 'Selfie') THEN 'AML OPS'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'Law enforcement request' THEN 'AML'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('PayPal CHBK', 'SAR filed') THEN 'FCMU'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Chargeback' THEN 'FCMU'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Corporate' THEN 'Corporate'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'CS management decision' THEN 'CS'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Deceased' THEN 'Money Out'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Deposits' THEN 'Money In'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'eToro Money Restriction' THEN 'ETM'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Hacked Account' THEN 'FCMU'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Partners & PIs' THEN 'Partners'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Risk' AND pssr.PlayerStatusSubReasonName = 'Affiliate Fraud' THEN 'Partners'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Risk' THEN 'FCMU'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Tax' THEN 'FCMU'
      WHEN ps.Name = 'Trade & MIMO Blocked' AND psr.Name = 'Underage' THEN 'KYC / Risk / AML'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'Abusive Trading Investigation' THEN 'AML'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'AML Trigger' THEN 'AML OPS'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('Closed - Failed Verification', 'Cross Border', 'Expired POI/POA', 'HRC', 'Screening - Negative Results', 'Screening - PEP', 'Screening - Possible Match', 'Screening - Sanctions') THEN 'KYC'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('Investigation', 'Selfie') THEN 'AML OPS'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'Law enforcement request' THEN 'AML'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('PayPal CHBK', 'SAR filed') THEN 'FCMU'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'Chargeback' THEN 'FCMU'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'Corporate' THEN 'Corporate'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'CS management decision' THEN 'CS'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'Deposits' THEN 'Money In'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'eToro Money Restriction' THEN 'ETM'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'KYC' THEN 'KYC'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'Partners & PIs' THEN 'Partners'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'PWMB Chargeback' THEN 'Money In'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'Risk' AND pssr.PlayerStatusSubReasonName = 'Affiliate Fraud' THEN 'FCMU/Partners'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'Risk' THEN 'FCMU'
      WHEN ps.Name = 'Block Deposit & Trading' AND psr.Name = 'Tax' THEN 'FCMU'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'Abusive Trading Investigation' THEN 'AML'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'AML Trigger' THEN 'AML OPS'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('Closed - Failed Verification', 'Cross Border', 'Expired POI/POA', 'HRC', 'Screening - Negative Results', 'Screening - PEP', 'Screening - Possible Match', 'Screening - Sanctions') THEN 'KYC'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('Investigation', 'Selfie') THEN 'AML OPS'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'Law enforcement request' THEN 'AML'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('PayPal CHBK', 'SAR filed') THEN 'FCMU'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'Chargeback' THEN 'FCMU'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'Corporate' THEN 'Corporate'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'Deposits' THEN 'Deposits'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'eToro Money Restriction' THEN 'ETM'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'KYC' THEN 'KYC'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'Risk' AND pssr.PlayerStatusSubReasonName = 'Affiliate Fraud' THEN 'FCMU/Partners'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'Risk' THEN 'FCMU'
      WHEN ps.Name = 'Deposit Blocked' AND psr.Name = 'Tax' THEN 'FCMU'
      WHEN ps.Name = 'Pending Verification' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'Abusive Trading Investigation' THEN 'AML'
      WHEN ps.Name = 'Pending Verification' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'AML Trigger' THEN 'AML OPS'
      WHEN ps.Name = 'Pending Verification' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('Closed - Failed Verification', 'Cross Border', 'Expired POI/POA', 'HRC', 'Screening - Negative Results', 'Screening - PEP', 'Screening - Possible Match', 'Screening - Sanctions') THEN 'KYC'
      WHEN ps.Name = 'Pending Verification' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('Investigation', 'Selfie') THEN 'AML OPS'
      WHEN ps.Name = 'Pending Verification' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'Law enforcement request' THEN 'AML'
      WHEN ps.Name = 'Pending Verification' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('PayPal CHBK', 'SAR filed') THEN 'FCMU'
      WHEN ps.Name = 'Pending Verification' AND psr.Name = 'Chargeback' THEN 'FCMU'
      WHEN ps.Name = 'Pending Verification' AND psr.Name = 'KYC' THEN 'KYC'
      WHEN ps.Name = 'Pending Verification' AND psr.Name = 'Risk' AND pssr.PlayerStatusSubReasonName = 'Affiliate Fraud' THEN 'Partners'
      WHEN ps.Name = 'Pending Verification' AND psr.Name = 'Risk' THEN 'FCMU'
      WHEN ps.Name = 'Warning' AND psr.Name = 'Abusive Trading' THEN 'Money In'
      WHEN ps.Name = 'Warning' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'Abusive Trading Investigation' THEN 'AML'
      WHEN ps.Name = 'Warning' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'AML Trigger' THEN 'AML OPS'
      WHEN ps.Name = 'Warning' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('Closed - Failed Verification', 'Cross Border', 'Expired POI/POA', 'HRC', 'Screening - Negative Results', 'Screening - PEP', 'Screening - Possible Match', 'Screening - Sanctions') THEN 'KYC'
      WHEN ps.Name = 'Warning' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('Investigation', 'Selfie') THEN 'AML OPS'
      WHEN ps.Name = 'Warning' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'Law enforcement request' THEN 'AML'
      WHEN ps.Name = 'Warning' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('PayPal CHBK', 'SAR filed') THEN 'FCMU'
      WHEN ps.Name = 'Warning' AND psr.Name = 'AML review' THEN 'AML'
      WHEN ps.Name = 'Warning' AND psr.Name = 'Deposits' THEN 'Money In'
      WHEN ps.Name = 'Warning' AND psr.Name = 'Overpayment' THEN 'Money Out'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Account Closed' THEN 'Money Out'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'Abusive Trading Investigation' THEN 'AML'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'AML Trigger' THEN 'AML OPS'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('Closed - Failed Verification', 'Cross Border', 'Expired POI/POA', 'HRC', 'Screening - Negative Results', 'Screening - PEP', 'Screening - Possible Match', 'Screening - Sanctions') THEN 'KYC'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('Investigation', 'Selfie') THEN 'AML OPS'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName = 'Law enforcement request' THEN 'AML'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'AML' AND pssr.PlayerStatusSubReasonName IN ('PayPal CHBK', 'SAR filed') THEN 'FCMU'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Chargeback' AND pssr.PlayerStatusSubReasonName = 'PWMB CHBK' THEN 'Money In'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Chargeback' THEN 'FCMU'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Corporate' THEN 'Corporate'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Deceased' THEN 'Money Out'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'eToro Money Restriction' THEN 'ETM'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'KYC' THEN 'KYC'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Other' THEN 'KYC'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Partners & PIs' THEN 'Partners'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Risk' AND pssr.PlayerStatusSubReasonName = 'Affiliate Fraud' THEN 'Partners'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Risk' THEN 'FCMU'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Tax' THEN 'FCMU'
      WHEN ps.Name = 'Blocked' AND psr.Name = 'Underage' THEN 'KYC / Risk / AML'
      WHEN ps.Name = 'Copy Blocked' AND psr.Name = 'Abusive Trading' THEN 'Money In'
      WHEN ps.Name = 'Copy Blocked' AND psr.Name = 'Partners & PIs' THEN 'Partners'
      ELSE 'Unknown'
    END AS Handeling,
    current_timestamp() AS UpdateDate
  FROM active a
  LEFT JOIN aging a1 ON a.CID = a1.CID 
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked c ON a.CID = c.RealCID
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc ON dc.CountryID = c.CountryID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ps ON c.PlayerStatusID = ps.PlayerStatusID 
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus pcs ON c.PendingClosureStatusID = pcs.PendingClosureStatusID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr ON c.PlayerStatusReasonID = psr.PlayerStatusReasonID 
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons pssr ON pssr.PlayerStatusSubReasonID = c.PlayerStatusSubReasonID
  LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype at ON at.AccountTypeID = c.AccountTypeID
  LEFT JOIN lastcashouts lastc ON lastc.CID = a.CID AND lastc.RN = 1
  LEFT JOIN sf ON sf.CID = a.CID
),

-- Open positions check
open_positions AS (
  SELECT DISTINCT CID 
  FROM main.dwh.dim_position 
  WHERE CloseDateID = 0
)

-- Final output
SELECT 
  l.*,
  pl.Name AS ClubLevel,
  dc.VerificationLevelID,
  CASE WHEN p.CID IS NULL THEN 'No' ELSE 'Yes' END AS `Has Open Position`
FROM final_data l
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON dc.RealCID = l.CID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl ON pl.PlayerLevelID = dc.PlayerLevelID
LEFT JOIN open_positions p ON p.CID = dc.RealCID