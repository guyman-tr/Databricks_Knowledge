select
    count(distinct bd.DepositID) as NoOfDeposits,
    cast(bd.ModificationDate as date) as Date,
    sum(bd.Amount * bd.ExchangeRate) as AmountUSD,
    ft.Name as FundingType,
    dc1.Name as Country,
    dept.Description as Type,
DF.Description AS  Flow,
r.Name as Regulation
from 
    main.general.bronze_etoro_dwh_billingdeposithourly bd
JOIN 
    main.billing.bronze_etoro_billing_funding_datafactory bf on bf.FundingID = bd.FundingID
join 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype ft on ft.FundingTypeID = bf.FundingTypeID
JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked CM ON CM.RealCID=bd.CID
JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1 on dc1.CountryID=CM.CountryID
JOIN 
    main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r on r.Id = CM.RegulationID    
LEFT JOIN  
    main.general.bronze_etoro_dictionary_deposittype dept on dept.DepositTypeID=bd.DepositTypeID
LEFT JOIN 
    main.general.bronze_etoro_dictionary_flow DF ON DF.FlowID=bd.FlowID
where 
    bd.ModificationDate >= DATEADD(
    MONTH, 
    DATEDIFF(MONTH, TIMESTAMP '1970-01-01 00:00:00', CURRENT_TIMESTAMP) - 2, 
    TIMESTAMP '1970-01-01 00:00:00'
)
    and bd.PaymentStatusID = 2 -- approved
group by 
    cast(bd.ModificationDate as date), 
    ft.Name,
    dc1.Name,
 DF.Description ,
         dept.Description,
         r.Name