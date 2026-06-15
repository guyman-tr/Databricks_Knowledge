select
    count(distinct bd.DepositID) as NoOfDeposits,
    cast(bd.ModificationDate as date) as Date,
    sum(bd.Amount * bd.ExchangeRate) as AmountUSD,
    ft.Name as FundingType,
    dc1.Name as Country,
    case when bd.DepositTypeID=4 then 'Yes' else 'No' end as InternalTransfer
    ,ps.Name as PaymentStatus
    ,de.Name as Depot
    ,dwf.MIDValue
    ,cc.Abbreviation as Currency
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
LEFT JOIN
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus ps on ps.PaymentStatusID = bd.PaymentStatusID
LEFT JOIN
    billing.bronze_etoro_billing_depot de on de.DepotID = bd.DepotID
LEFT JOIN 
  main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee dwf on bd.DepositID = dwf.DepositID
LEFT JOIN 
  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency cc on cc.CurrencyID = bd.CurrencyID
where 
    bd.ModificationDate >= DATEADD(DAY, -15, CURRENT_DATE())
    and bd.PaymentStatusID in (2,6,3,35,1,13,4)
    and bf.FundingTypeID in (1,33,42,11,34,8,6,3,32,35,36,43,28)
group by 
    cast(bd.ModificationDate as date), 
    ft.Name,
    dc1.Name,
    case when bd.DepositTypeID=4 then 'Yes' else 'No' end
    ,ps.Name
    ,de.Name
    ,dwf.MIDValue
    ,cc.Abbreviation