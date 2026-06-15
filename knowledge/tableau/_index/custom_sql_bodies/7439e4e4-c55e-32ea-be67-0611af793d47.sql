---2025.08.08 note: this is for US Monthly KPI dashboard;
-------- this contains last month and previous month data only

/* topics include: 

- TP (trading platform) MIMO: deposits & withdrawals
- Apex MIMO: deposits & withdrawals
- Apex MIMO: deposits (breakdown of deposits into FTDA and redeposits) & withdrawals 

*/
WITH 
/*
apex_pfof AS (
	SELECT 
		last_day(TradeDate) EoM , 
		sum(CASE WHEN InstrumentType='Equity' THEN abs(CustomerPFOFPayback) END) AS EquitiesPFOF,
		sum(CASE WHEN InstrumentType='Option' THEN abs(CustomerPFOFPayback) END) AS OptionsPFOF
	FROM main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports
	WHERE TradeDate BETWEEN add_months(date_trunc('month', current_date()), -12) AND last_day(add_months(current_date(), -1))
	GROUP BY  last_day(TradeDate)
),


apex_equity AS (
	SELECT
		p.ProcessDate AS AdjEoM, 
		m.EOM AS TargetEoM, 
		SUM(p.TotalEquity) AS OptionsEquity
	FROM main.general.bronze_sodreconciliation_apex_ext981_buypowersummary AS p
	JOIN (   -- skip weekends/NYSE holidays: For each calendar month‐end, find MIN(ProcessDate) ≥ that EOM
			SELECT me.EOM,MIN(t.ProcessDate) AS FirstAvailProcessDate
			FROM (
					SELECT DISTINCT last_day(dd.FullDate) AS EOM
					FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_date AS dd
					WHERE dd.FullDate BETWEEN add_months(date_trunc('month', current_date()), -12) AND last_day(add_months(current_date(), -1))
				) AS me
			JOIN main.general.bronze_sodreconciliation_apex_ext981_buypowersummary AS t
					ON t.ProcessDate >= me.EOM AND t.OfficeCode IN ('4GS','5GU')
			GROUP BY me.EOM
		 ) AS m
			ON p.ProcessDate = m.FirstAvailProcessDate
	WHERE p.OfficeCode IN ('4GS','5GU')
		AND p.AccountNumber NOT IN ('4GS43999','3ET00001','3ET00100','3ET00101','3ET00002','3ET05007','4GS00103','4GS00104','4GS00101','4GS00100')
	GROUP BY p.ProcessDate, m.EOM
),
*/
tp_mimo as (
	SELECT 
			last_day(
			  to_date(
				cast(fca.DateID AS string),
				'yyyyMMdd'
			  )
			) AS EoM, 

			--deposits CID: ftda vs. redeposits
			Count(DISTINCT CASE WHEN fca.ActionTypeID=7 and fca.IsFTD = 1 THEN fca.RealCID end) AS TP_FTDA_CIDCount,
			Count(DISTINCT CASE WHEN fca.ActionTypeID=7 and fca.IsFTD = 0 THEN fca.RealCID end) AS TP_Redeposits_CIDCount,
			count(DISTINCT CASE WHEN fca.ActionTypeID=7 then fca.RealCID end) 					AS TP_TotalDeposits_CIDCount,

			--deposits count: ftda vs. redeposits
			Count(DISTINCT CASE WHEN fca.ActionTypeID=7 and fca.IsFTD = 1 THEN fca.DepositID end) AS TP_FTDACount,
			Count(DISTINCT CASE WHEN fca.ActionTypeID=7 and fca.IsFTD = 0 THEN fca.DepositID end) AS TP_RedepositsCount,
			count(DISTINCT CASE WHEN fca.ActionTypeID=7 THEN fca.DepositID end)					  AS TP_TotalDepositsCount,

			--deposits sum: ftda vs. redeposits
			sum(CASE WHEN fca.ActionTypeID=7 and fca.IsFTD = 1 THEN fca.Amount end) AS TP_FTDASum,
			sum(CASE WHEN fca.ActionTypeID=7 and fca.IsFTD = 0 THEN fca.Amount end) AS TP_RedepositsSum,
			SUM(CASE WHEN fca.ActionTypeID=7 THEN fca.Amount end) 					AS TP_TotalDepositsSum,

			--withdrawal: cid, count, sum
			count(DISTINCT CASE WHEN fca.ActionTypeID=8 then fca.RealCID end) 		AS TP_Withdrawals_CIDCount,
			count(DISTINCT CASE WHEN fca.ActionTypeID=8 THEN fca.WithdrawID end)		AS TP_WithdrawalsCount,
			SUM(CASE WHEN fca.ActionTypeID=8 THEN fca.Amount end) 					AS TP_WithdrawalsSum

		FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
			JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc1
				ON fca.RealCID = dc1.RealCID AND dc1.IsValidCustomer=1 AND dc1.RegulationID IN (6,7,8) 
		WHERE fca.ActionTypeID in (7,8) -- 7 - Deposit, 8 - withdrawal
			AND fca.FundingTypeID!=42
		    AND fca.DateID BETWEEN  date_format(add_months(date_trunc('month', current_date()), -12), 'yyyyMMdd')
						AND date_format(last_day(add_months(current_date(), -1)), 'yyyyMMdd')
		GROUP BY last_day(
					  to_date(
						cast(fca.DateID AS string),
						'yyyyMMdd'
					  )
					) 
),

--- as of Aug-6h, 2025, only clients in FINRAONLY bring in "net" deposits
apex_ftda_prep AS (
    SELECT DISTINCT 
        AccountNumber, 
        ProcessDate, 
        ACATSControlNumber, 
        ABS(Amount) AS abs_amount
    FROM main.finance.bronze_sodreconciliation_apex_ext869_cashactivity
    WHERE 
        RegisteredRepCode IN ('FO1')
        AND PayTypeCode = 'C'
        AND EnteredBy IN ('ACH', 'WRD')
        AND OfficeCode IN ('4GS', '5GU')
),

-----Data manipulation for FTDA / redeposits alignment from Apex: 
-- step 1. Prep deposits and identify each account’s FTD date

apex_ftda_base AS (
    SELECT 
        AccountNumber, 
        CAST(MIN(ProcessDate) AS DATE) AS apex_ftd_date
    FROM apex_ftda_prep
    GROUP BY AccountNumber
	HAVING CAST(MIN(ProcessDate) AS DATE) BETWEEN add_months(date_trunc('month', current_date()), -12)
           AND last_day(add_months(current_date(), -1))
),

-- step 2. Calculate per-account first-day sums, counts, and average FTDA
apex_ftda AS (
    SELECT 
        ftd.AccountNumber,
        ftd.apex_ftd_date,
        COUNT(DISTINCT p.ACATSControlNumber)		AS first_day_deposit_ct,
        SUM(p.abs_amount)							AS first_day_deposits_sum,
        SUM(p.abs_amount) * 1.0 
			/ COUNT(DISTINCT p.ACATSControlNumber)  AS cal_apex_ftda
    FROM apex_ftda_base ftd
    JOIN apex_ftda_prep p 
        ON ftd.AccountNumber = p.AccountNumber 
        AND ftd.apex_ftd_date = p.ProcessDate
    GROUP BY ftd.AccountNumber, ftd.apex_ftd_date
),

-- step 3. Aggregate FTDA to month level
apex_ftda_agg AS (
	SELECT 
		last_day(apex_ftd_date)		AS EoM,
		count(*)					AS ApexFTDA_CIDCount, --cid count is same as action action for FTDA
		sum(cal_apex_ftda)			AS ApexFTDASum
	FROM apex_ftda
	GROUP BY last_day(apex_ftd_date)
),

-- step 4. Same-day redeposit per account: only the “extra” deposits beyond the average FTDA
same_day_per_account AS (
    SELECT
        AccountNumber,
        last_day(apex_ftd_date)                                      AS EoM,
        CASE 
          WHEN first_day_deposit_ct > 1 
            THEN first_day_deposit_ct - 1 
          ELSE 0 
        END                                                         AS ApexSameDay_ActionCount,
        (first_day_deposits_sum - cal_apex_ftda)                    AS ApexSameDay_Sum
    FROM apex_ftda
),

-- step 5. Future redeposits per account
future_per_account AS (
    SELECT 
        b.AccountNumber,
        last_day(p.ProcessDate)                                      AS EoM,
        COUNT(DISTINCT p.ACATSControlNumber)                        AS ApexFuture_ActionCount,
        SUM(p.abs_amount)                                           AS ApexFuture_Sum
    FROM apex_ftda_prep p
    JOIN apex_ftda_base AS b 
      ON p.AccountNumber = b.AccountNumber
    WHERE 
		p.ProcessDate > b.apex_ftd_date
		AND p.ProcessDate BETWEEN add_months(date_trunc('month', current_date()), -12) AND
              last_day(add_months(current_date(), -1))
    GROUP BY b.AccountNumber, last_day(p.ProcessDate)
),

-- step 6. Combine same-day & future redeposits, then roll up **per account** into a single stream
combined_redeposits AS (
    SELECT 
        AccountNumber,
        EoM,
        ApexSameDay_ActionCount AS ActionCount,
        ApexSameDay_Sum         AS SumAmount
    FROM same_day_per_account
    WHERE ApexSameDay_ActionCount > 0

    UNION ALL

    SELECT
        AccountNumber,
        EoM,
        ApexFuture_ActionCount  AS ActionCount,
        ApexFuture_Sum          AS SumAmount
    FROM future_per_account
    WHERE ApexFuture_ActionCount > 0
),

-- 7. Final monthly redeposit metrics: sum of actions, sum of dollars, and **distinct** account count
redeposit_kpi AS (
    SELECT
        EoM,
        SUM(ActionCount)                               AS ApexRedepositsCount,
        SUM(SumAmount)                                 AS ApexRedepositsSum,
        COUNT(DISTINCT AccountNumber)                  AS ApexRedeposits_CIDCount
    FROM combined_redeposits
    GROUP BY EoM
),

all_deposits AS (
	SELECT
		COALESCE(f.EoM, r.EoM)                        AS EoM,
		coalesce(f.ApexFTDA_CIDCount,   0)              AS ApexFTDA_CIDCount,
		coalesce(f.ApexFTDA_CIDCount,   0)			  AS ApexFTDACount,
		coalesce(f.ApexFTDASum,        0)               AS ApexFTDASum,

		coalesce(r.ApexRedeposits_CIDCount,    0)        AS ApexRedeposits_CIDCount,
		coalesce(r.ApexRedepositsCount, 0)			   AS ApexRedepositsCount,
		coalesce(r.ApexRedepositsSum,          0)        AS ApexRedepositsSum

	FROM apex_ftda_agg AS f
	FULL OUTER JOIN redeposit_kpi AS r
	  ON f.EoM = r.EoM
),
-- 8. Final output: join FTDA & redeposit metrics

depositors_agg AS (
  SELECT 
		last_day(ProcessDate)                           AS EoM,
		COUNT(DISTINCT AccountNumber)                  AS ApexDeposit_CIDCount
  FROM apex_ftda_prep
  WHERE ProcessDate BETWEEN add_months(date_trunc('month', current_date()), -12) AND
              last_day(add_months(current_date(), -1))
  GROUP BY last_day(ProcessDate)
),

apex_deposits_kpi AS (

	SELECT
	   a.EoM,

	  coalesce(a.ApexFTDA_CIDCount, 0)         AS ApexFTDA_CIDCount,
	  coalesce(a.ApexFTDACount, 0)			 AS ApexFTDACount,
	  coalesce(a.ApexFTDASum, 0)               AS ApexFTDASum,

	  coalesce(a.ApexRedeposits_CIDCount, 0)   AS ApexRedeposits_CIDCount,
	  coalesce(a.ApexRedepositsCount,0)		 AS ApexRedepositsCount,
	  coalesce(a.ApexRedepositsSum, 0)         AS ApexRedepositsSum,

	  coalesce(d.ApexDeposit_CIDCount, 0)		 AS ApexDeposit_CIDCount,
	  coalesce(a.ApexFTDACount, 0)+coalesce(a.ApexRedepositsCount,0) AS ApexDepositsCount,
	  coalesce(a.ApexFTDASum, 0)+coalesce(a.ApexRedepositsSum, 0)	 AS ApexDepositsSum
	FROM all_deposits a
	LEFT JOIN depositors_agg AS d
	  ON a.EoM = d.EoM
	--ORDER BY EoM;
),

ops_with AS (
	SELECT 
		last_day(ProcessDate) EoM, 
        count(DISTINCT AccountNumber)		AS OptionsWithdrawals_CIDCount,
        count(DISTINCT ACATSControlNumber)  AS OptionsWithdrawalsCount, 
        sum(abs(Amount))					AS OptionsWithdrawalsSum
		/*
		count(DISTINCT CASE WHEN PayTypeCode = 'C' then AccountNumber end)		AS OptionsDeposits_CIDCount,
        count(DISTINCT CASE WHEN PayTypeCode = 'C' then ACATSControlNumber end) AS OptionsDepositsCount, 
        sum(CASE WHEN PayTypeCode = 'C' then Amount end)						AS OptionsDepositsSum
		*/
	FROM main.finance.bronze_sodreconciliation_apex_ext869_cashactivity 
	WHERE OfficeCode in ('4GS','5GU') 
		AND RegisteredRepCode IN ('FO1')
		AND EnteredBy IN ('ACH','WRD')
		AND PayTypeCode = 'D'
		AND AccountNumber NOT IN ('4GS43999', '3ET00001', '3ET00100', '3ET00101', '3ET00002', '3ET05007', '4GS00103', '4GS00104', '4GS00101', '4GS00100')
		AND ProcessDate BETWEEN add_months(date_trunc('month', current_date()), -12) AND last_day(add_months(current_date(), -1))
	GROUP BY last_day(ProcessDate)
)

/****************************************************************final selection********************************************************************************/

select
--ap.EoM, ae.TargetEoM as EoM,
tm.EoM,
--------------------- 
--ap.EquitiesPFOF,
--ap.OptionsPFOF,
---------------------- 
--ae.OptionsEquity,
---------------------- 
/*
tm.TP_FTDASum, 
tm.TP_RedepositsSum,
tm.TP_TotalDepositsSum,

tm.TP_FTDACount,
tm.TP_RedepositsCount,
tm.TP_TotalDepositsCount,

tm.TP_FTDA_CIDCount,
tm.TP_Redeposits_CIDCount,
tm.TP_TotalDeposits_CIDCount,

tm.TP_Withdrawals_CIDCount,
tm.TP_WithdrawalsCount,
tm.TP_WithdrawalsSum,
---------------------- 
ad.ApexFTDA_CIDCount,
ad.ApexFTDACount,
ad.ApexFTDASum,
	
ad.ApexRedeposits_CIDCount, 
ad.ApexRedepositsCount,
ad.ApexRedepositsSum,

ad.ApexDeposit_CIDCount,
ad.ApexDepositsCount,
ad.ApexDepositsSum,
---------------------- 
ow.OptionsWithdrawals_CIDCount,
ow.OptionsWithdrawalsCount, 
ow.OptionsWithdrawalsSum,
*/
---------------------- 
tm.TP_Withdrawals_CIDCount + 
	coalesce(ow.OptionsWithdrawals_CIDCount,0)						AS `TotalWithdrawals_CIDCount`,
tm.TP_WithdrawalsCount + coalesce(ow.OptionsWithdrawalsCount,0)		AS `TotalWithdrawalsCount`,
tm.TP_WithdrawalsSum + coalesce(ow.OptionsWithdrawalsSum,0)			AS `TotalWithdrawalsSum`,
---------------------- 
tm.TP_FTDASum + coalesce(ad.ApexFTDASum,0)							AS `Total FTDA $`, 
tm.TP_RedepositsSum + coalesce(ad.ApexRedepositsSum,0)				AS `Total Redeposits $`,
tm.TP_TotalDepositsSum + coalesce(ad.ApexDepositsSum,0)				AS `Total Deposits $`,

tm.TP_FTDACount+coalesce(ad.ApexFTDACount,0)						AS `Total FTDA #`,
tm.TP_RedepositsCount+coalesce(ad.ApexRedepositsCount,0)			AS `Total Redeposits #`,
tm.TP_TotalDepositsCount+coalesce(ad.ApexDepositsCount,0)			AS `Total Deposits #`,

tm.TP_FTDA_CIDCount + coalesce(ad.ApexFTDA_CIDCount,0)				AS `Total FTDA CID #`,
tm.TP_Redeposits_CIDCount + coalesce(ad.ApexRedeposits_CIDCount,0)	AS `Total Redeposits CID #`,
tm.TP_TotalDeposits_CIDCount + coalesce(ad.ApexDeposit_CIDCount,0)	AS `Total Deposits CID #`,

(tm.TP_TotalDepositsSum + coalesce(ad.ApexDepositsSum,0) - (tm.TP_WithdrawalsSum + coalesce(ow.OptionsWithdrawalsSum,0))) AS `Net Deposit`

FROM tp_mimo tm	 
left join apex_deposits_kpi ad 
	on ad.EoM = tm.EoM
left join ops_with ow	 
	on ow.EoM = tm.EoM
--ORDER BY tm.EoM