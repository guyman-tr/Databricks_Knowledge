select l.*,c.IsDepositor,r.Name as Regulation from main.bi_output.bi_output_Compliance_kycScreeningLimitation l 
left join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked c on c.RealCID = l.RealCID
LEFT JOIN 
    main.general.bronze_etoro_dictionary_regulation r on c.RegulationID = r.ID