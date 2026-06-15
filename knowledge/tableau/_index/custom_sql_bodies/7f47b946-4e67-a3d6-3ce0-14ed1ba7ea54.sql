SELECT
    a.date,
    a.realcid,
    b.group,
    b.ingroup,
    SUM(CASE WHEN MIMOAction = 'Deposit' THEN coalesce(AmountUSD,0) ELSE 0 END) AS deposit,
    SUM(CASE WHEN MIMOAction = 'Withdraw' THEN coalesce(AmountUSD,0) ELSE 0 END) AS withdrawal
  FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms a 
  join main.bi_dealing.bi_output_dealing_premier_customer_2026 b on a.realcid = b.cid and date_trunc('mm', a.date) = b.date
  where IsInternalTransfer = 0  and DateID > '20260000' 
  GROUP BY ALL