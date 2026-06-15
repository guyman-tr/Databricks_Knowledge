--wallet activities --> currently doubling the numbers
WITH w AS (
	SELECT 
			case 
				when 
					eft.ActionTypeID = 1 --sent 
					AND eft.TransactionTypeID = 1 -- CustomerMoneyOut
				then 'Out: wallet-to-external' 
				when 
					eft.ActionTypeID = 2 --received
					 AND eft.IsRedeem = 0 
            		 AND eft.IsConversion = 0 
            		 AND eft.IsPayment = 0 
					 AND COALESCE(eft.ReceivedTransactionTypeID, 0) NOT IN (8, 3)
				then 'In: external-to-wallet' 
			end	AS WalletActivity,
			eft.TranDate,
			eft.TranDateID,
            eft.RealCID,
            COUNT(eft.TranID) AS CountActions_Daily,
            SUM(eft.AmountUSD) AS AmountUSD_Daily
        FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions eft 
        WHERE 
        	eft.GCID > 0
        	AND eft.TranStatusID = 2
        	AND eft.TranDateID >= CAST(DATE_FORMAT(DATE_TRUNC('month', current_date() - INTERVAL '2' YEAR), 'yyyyMMdd') AS INT)
			AND case 
				when 
					eft.ActionTypeID = 1 --sent 
					AND eft.TransactionTypeID = 1 -- CustomerMoneyOut
				then 'Out: wallet-to-external' 
				when 
					eft.ActionTypeID = 2 --received
					 AND eft.IsRedeem = 0 
            		 AND eft.IsConversion = 0 
            		 AND eft.IsPayment = 0 
					 AND COALESCE(eft.ReceivedTransactionTypeID, 0) NOT IN (8, 3)
				then 'In: external-to-wallet' 
			END IS NOT NULL 
        GROUP BY 
            eft.TranDate, eft.TranDateID, eft.RealCID,
			case 
				when 
					eft.ActionTypeID = 1 --sent 
					AND eft.TransactionTypeID = 1 -- CustomerMoneyOut
				then 'Out: wallet-to-external' 
				when 
					eft.ActionTypeID = 2 --received
					 AND eft.IsRedeem = 0 
            		 AND eft.IsConversion = 0 
            		 AND eft.IsPayment = 0 
					 AND COALESCE(eft.ReceivedTransactionTypeID, 0) NOT IN (8, 3)
				then 'In: external-to-wallet' 
			end

        UNION ALL 

        SELECT 
            'In: coin redeem' AS WalletActivity,
            CAST(err.ModificationDate AS DATE) AS TranDate,
			`ModificationDateID` AS TranDateID,
            err.`CID` AS RealCID,
            COUNT(err.RedeemID) AS CountActions_Daily,
            SUM(err.`EtoroAmount`) AS AmountUSD_Daily
        FROM main.wallet.gold_sql_dp_prod_we_exw_dbo_exw_v_redeemreconciliation err 
        --JOIN EXW_dbo.EXW_DimUser edu ON edu.GCID = err.`Wallet - RequestingGCID` AND edu.CountryID = 219
        WHERE 
            err.EntryAppears = 'BothSidesEntry'
            AND err.`EtoroRedeemStatus` = 'TransactionDone'
			AND `ModificationDateID` >= CAST(DATE_FORMAT(DATE_TRUNC('month', current_date() - INTERVAL '2' YEAR), 'yyyyMMdd') AS INT)
			
        GROUP BY 
            CAST(err.`ModificationDate` AS DATE),
			`ModificationDateID`,
            err.`CID`
)


select 
		last_day(w.TranDate) as MonthEndDate,
		WalletActivity,
		dr.Name as Regulation,
		c.StateShortName,
        c.StateName,
		sum(CountActions_Daily) as CountActions,
		sum(AmountUSD_Daily) as AmountUSD
from w 
JOIN bi_output_stg.bi_output_compliance_map_usa_cid_state_regulation_daily  c 
on c.RealCID = w.RealCID
and w.TranDateID between c.FromDateID and c.ToDateID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr
	on c.RegulationID = dr.ID
GROUP BY 		
		last_day(w.TranDate),
		WalletActivity,
		dr.Name,
		c.StateShortName,
        c.StateName