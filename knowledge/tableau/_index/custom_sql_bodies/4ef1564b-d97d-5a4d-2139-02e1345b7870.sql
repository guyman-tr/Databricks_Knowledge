-- Target: EOM (End-of-Month) holdings by crypto and state							
    SELECT  
        last_day(efrbn.BalanceDate) AS EoM,
        d.Name                  as Regulation,
        coalesce(m.StateName, 'Unmapped') AS StateName,
        coalesce(m.StateShortName, 'Unmapped') AS StateShortName,
        efrbn.CryptoName,
        SUM(efrbn.BalanceUSD) BalanceUSD,
        count(DISTINCT efrbn.RealCID) Users
    FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew efrbn 
    JOIN main.wallet.bronze_walletdb_wallet_cryptotypes ect  
      ON efrbn.CryptoID =ect.CryptoID 
    left JOIN  bi_output_stg.bi_output_compliance_map_usa_cid_state_regulation_daily m
      ON efrbn.RealCID = m.RealCID
       AND efrbn.BalanceDateID BETWEEN m.FromDateID AND m.ToDateID
    join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation d  
       on d.ID=m.RegulationID
    WHERE efrbn.BalanceDate >= DATE_TRUNC('month', current_date() - INTERVAL '2' YEAR)
      and efrbn.BalanceDate =last_day(efrbn.BalanceDate)
      AND efrbn.RegulationID IN (7,8,14)
      AND efrbn.BalanceUSD >0 and efrbn.Balance>0
      AND efrbn.AMLClosureEvent=0
      AND efrbn.ComplianceClosureEvent=0
      AND efrbn.IsTestAccount=0
      AND ect.DisplayName NOT LIKE  'eToro%' 
    GROUP BY 	  
        last_day(efrbn.BalanceDate),
        d.Name,
        coalesce(m.StateName, 'Unmapped'),
        coalesce(m.StateShortName, 'Unmapped'),
        efrbn.CryptoName