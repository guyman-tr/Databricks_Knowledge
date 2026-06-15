SELECT last_day(fca.Occurred) LoginMonth, count(DISTINCT fca.RealCID) Mau_by_login
	--fca.RealCID, dr.FromDateID, dr.ToDateID
FROM main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc ON fca.RealCID = fsc.RealCID 
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc ON dc.CountryID=fsc.CountryID AND dc.MarketingRegionManualName='USA'
    --AND fsc.CountryID in (219,166,214) 

JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr ON fsc.DateRangeID = dr.DateRangeID AND (fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID) 
WHERE fca.ActionTypeID = 14
	AND fca.DateID BETWEEN date_format(date_add(last_day(date_trunc('month', current_date) - interval 14 months), 1), 'yyyyMMdd') 
        AND date_format(last_day(add_months(current_date, -1)), 'yyyyMMdd')
    AND fsc.RegulationID IN (6,7,8,12) 
    AND fsc.DesignatedRegulationID  IN (7,8,12) 
    AND fsc.IsValidCustomer=1
group by last_day(fca.Occurred)