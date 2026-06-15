SELECT op.OptionsApexID, op.GCID, dc.CID, dc.registered Reg_main_date_GMT, --DATEADD(HOUR, 5, dc.RegisteredReal) Reg_main_date_EST, 
case when dc.FirstDepositDate='1900-01-01' then null else dc.FirstDepositDate end as FTD_main_date_GMT, --DATEADD(HOUR, 5, dc.FirstDepositDate) FTD_main_date_EST, 
dc.FirstDepositAmount as FTDA_main, 
op.BeginTime AS Options_account_status_last_updated,
ca_ftd_base.FTD_options_date, ca_ftd_base.FTD_options_amount,
--fvt.date_requested,
TO_DATE(fvt.date_requested, 'M/d/yyyy') date_requested_trans
--concat_ws(' ', dc.FirstName, dc.LastName) FullName, dc.Email, 
FROM main.general.bronze_usabroker_apex_options op 
join main.bi_db.bronze_fivetran_google_sheets_fivetran_options_high_yield_interest_program_enrollee fvt on fvt.apex_id=op.OptionsApexID
LEFT JOIN bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked dc ON dc.GCID=op.GCID
left join (	
	SELECT AccountNumber, ProcessDate AS FTD_options_date, Amount_abs AS FTD_options_amount
	FROM (
		SELECT DISTINCT  AccountNumber, ProcessDate, ABS(ca.Amount) Amount_abs,
		ROW_NUMBER() OVER (PARTITION BY AccountNumber ORDER BY ProcessDate,SequenceNumber) rn --ftd_options_date
		FROM  main.finance.bronze_sodreconciliation_apex_ext869_cashactivity ca
		WHERE ca.PayTypeCode='C' and ca.EnteredBy in ('ACH','WRD') 
	--ORDER BY AccountNumber, ProcessDate, SequenceNumber
	)ranked_deposits
	WHERE rn=1
)ca_ftd_base on ca_ftd_base.AccountNumber=op.OptionsApexID