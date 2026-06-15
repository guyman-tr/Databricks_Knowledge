select
    count(distinct WTF.ID) as NoOfWithdraws,
    cast(WTF.ModificationDate as date) as Date,
    sum(WTF.Amount) as AmountUSD,
    ft.Name as FundingType,
    dc1.Name as Country,
    WTY.Description AS Type,
DF.Description AS Flow, r.Name as Regulation
from 
    main.billing.bronze_etoro_billing_vwithdrawtofunding WTF 
JOIN 
    main.billing.bronze_etoro_billing_funding_datafactory bf on bf.FundingID = WTF.FundingID
join 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ft on ft.FundingTypeID = bf.FundingTypeID
join 
    billing.bronze_etoro_billing_withdraw bw on bw.WithdrawID=WTF.WithdrawID
JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked CM ON CM.RealCID=bw.CID
JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1 on dc1.CountryID=CM.CountryID
JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r on r.Id = CM.RegulationID 
LEFT JOIN 
    main.bi_db.bronze_etoro_dictionary_withdrawtype WTY ON WTY.WithdrawTypeID=bw.WithdrawTypeID
LEFT JOIN 
    main.general.bronze_etoro_dictionary_flow DF ON DF.FlowID=bw.FlowID
where 
    WTF.CashoutStatusID = 3 
    and WTF.ModificationDate >= DATEADD(
    MONTH, 
    DATEDIFF(MONTH, TIMESTAMP '1970-01-01 00:00:00', CURRENT_TIMESTAMP) - 2, 
    TIMESTAMP '1970-01-01 00:00:00'
)
group by 
    cast(WTF.ModificationDate as date), 
    ft.Name, 
    dc1.Name,
     WTY.Description , 
DF.Description,r.Name