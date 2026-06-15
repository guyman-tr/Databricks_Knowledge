SELECT
    u.Regulation,
    u.InstrumentType,
    u.DateID,
    u.Metric,
    SUM(u.Metric_Amount) AS Metric_Amount,
	u.[Key]
FROM (
    /* ---------- FEES (InstrumentType = 'All') ---------- */
    SELECT
        f.Regulation,
        'All' AS InstrumentType,
        f.DateID,
        'ClientBalanceCommission' AS Metric,
        SUM(CAST(ISNULL(f.ClientBalanceCommission,0) AS DECIMAL(38,10))) AS Metric_Amount,
		'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

    UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'UnrealizedCommissionChange',
           SUM(CAST(ISNULL(f.UnrealizedCommissionChange,0) AS DECIMAL(38,10))),	'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

    UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'TransferCoinFees',
           SUM(CAST(ISNULL(f.TransferCoinFees,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

    UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'CashoutFee',
           SUM(CAST(ISNULL(f.CashoutFee,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

    UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'UsedBonus',
           SUM(CAST(ISNULL(f.UsedBonus,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

	 UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'Compensation',
           SUM(CAST(ISNULL(f.Compensation,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

	 UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'CompensationPI',
           SUM(CAST(ISNULL(f.CompensationPI,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

	 UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'CompensationToAffiliate',
           SUM(CAST(ISNULL(f.CompensationToAffiliate,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

	 UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'NWAAdjustment',
           SUM(CAST(ISNULL(f.NWAAdjustment,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID


    UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'NegativeRefill',
           SUM(CAST(ISNULL(f.NegativeRefill,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

	 UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'LostDebt',
           SUM(CAST(ISNULL(f.LostDebt,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

	 UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'ChargebackLoss',
           SUM(CAST(ISNULL(f.ChargebackLoss,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

	 UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'OtherNegatives',
           SUM(CAST(ISNULL(f.OtherNegatives,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

	 UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'Foreclosure',
           SUM(CAST(ISNULL(f.Foreclosure,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

	 UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'CompensationPnLAdjustments',
           SUM(CAST(ISNULL(f.CompensationPnLAdjustments,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

	 UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'CompensationDormantFee',
           SUM(CAST(ISNULL(f.CompensationDormantFee,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

	 UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'NetTransfersNWA',
           SUM(CAST(ISNULL(f.NetTransfersNWA,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

	 UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'NetTransfersLiability',
           SUM(CAST(ISNULL(f.NetTransfersLiability,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID

	UNION ALL
    SELECT f.Regulation, 'All', f.DateID, 'NetTransfersUnrealizedPnL',
           SUM(CAST(ISNULL(f.NetTransfersUnrealizedPnL,0) AS DECIMAL(38,10))),'2' AS 'Key'
    FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New f
    WHERE f.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
    GROUP BY f.Regulation, f.DateID


    /* (Add any other fee metrics you need here, following same pattern) */

    /* ---------- TRADING BY INSTRUMENT TYPE ---------- */
    UNION ALL
    SELECT
        t.Regulation,
        t.InstrumentType,
        t.DateID,
        'Real Buy (Without PnL)' AS Metric,
        SUM(t.BuyAmount_Settled) AS Metric_Amount,
		'1' AS 'Key'
    FROM (
        SELECT
            di.InstrumentType,
            dr1.[Name] AS Regulation,
            fca.DateID,
            SUM(CASE WHEN fca.ActionTypeID IN (1,2,3,39) AND fca.IsSettled = 1
                     THEN fca.Amount ELSE 0 END) AS BuyAmount_Settled          
        FROM DWH_dbo.Fact_CustomerAction fca
        JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON fca.RealCID = fsc.RealCID
        JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID
                                  AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
        JOIN DWH_dbo.Dim_Instrument di ON fca.InstrumentID = di.InstrumentID
        JOIN DWH_dbo.Dim_Regulation dr1 ON fsc.RegulationID = dr1.DWHRegulationID
        WHERE fca.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
          AND fca.ActionTypeID IN (1,2,3,39,4,5,6,28,40)
          AND di.InstrumentType <> 'All'
        GROUP BY di.InstrumentType, dr1.[Name], fca.DateID
    ) t
    GROUP BY t.Regulation, t.InstrumentType, t.DateID

    UNION ALL
    SELECT t.Regulation, t.InstrumentType, t.DateID, 'CFD Buy (Without PnL)', SUM(t.BuyAmount_Unsettled),'4' AS 'Key'
    FROM ( SELECT
            di.InstrumentType,
            dr1.[Name] AS Regulation,
            fca.DateID,
            SUM(CASE WHEN fca.ActionTypeID IN (1,2,3,39) AND fca.IsSettled = 0
                     THEN fca.Amount ELSE 0 END) AS BuyAmount_Unsettled
        FROM DWH_dbo.Fact_CustomerAction fca
        JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON fca.RealCID = fsc.RealCID
        JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID
                                  AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
        JOIN DWH_dbo.Dim_Instrument di ON fca.InstrumentID = di.InstrumentID
        JOIN DWH_dbo.Dim_Regulation dr1 ON fsc.RegulationID = dr1.DWHRegulationID
        WHERE fca.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
          AND fca.ActionTypeID IN (1,2,3,39,4,5,6,28,40)
          AND di.InstrumentType <> 'All'
        GROUP BY di.InstrumentType, dr1.[Name], fca.DateID ) t
    GROUP BY t.Regulation, t.InstrumentType, t.DateID

    UNION ALL
    SELECT t.Regulation, t.InstrumentType, t.DateID, 'Real Sell (With PnL)', SUM(t.SellAmount_Settled),'1' AS 'Key'
    FROM (SELECT
            di.InstrumentType,
            dr1.[Name] AS Regulation,
            fca.DateID,
            SUM(CASE WHEN fca.ActionTypeID IN (4,5,6,28,40) AND fca.IsSettled = 1
                     THEN fca.Amount + fca.NetProfit ELSE 0 END) AS SellAmount_Settled
        FROM DWH_dbo.Fact_CustomerAction fca
        JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON fca.RealCID = fsc.RealCID
        JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID
                                  AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
        JOIN DWH_dbo.Dim_Instrument di ON fca.InstrumentID = di.InstrumentID
        JOIN DWH_dbo.Dim_Regulation dr1 ON fsc.RegulationID = dr1.DWHRegulationID
        WHERE fca.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
          AND fca.ActionTypeID IN (1,2,3,39,4,5,6,28,40)
          AND di.InstrumentType <> 'All'
        GROUP BY di.InstrumentType, dr1.[Name], fca.DateID ) t
    GROUP BY t.Regulation, t.InstrumentType, t.DateID

    UNION ALL
    SELECT t.Regulation, t.InstrumentType, t.DateID, 'CFD Sell (With PnL)', SUM(t.SellAmount_Unsettled),'4' AS 'Key'
    FROM ( SELECT
            di.InstrumentType,
            dr1.[Name] AS Regulation,
            fca.DateID,
            SUM(CASE WHEN fca.ActionTypeID IN (4,5,6,28,40) AND fca.IsSettled = 0
                     THEN fca.Amount + fca.NetProfit ELSE 0 END) AS SellAmount_Unsettled        
        FROM DWH_dbo.Fact_CustomerAction fca
        JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON fca.RealCID = fsc.RealCID
        JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID
                                  AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
        JOIN DWH_dbo.Dim_Instrument di ON fca.InstrumentID = di.InstrumentID
        JOIN DWH_dbo.Dim_Regulation dr1 ON fsc.RegulationID = dr1.DWHRegulationID
        WHERE fca.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
          AND fca.ActionTypeID IN (1,2,3,39,4,5,6,28,40)
          AND di.InstrumentType <> 'All'
        GROUP BY di.InstrumentType, dr1.[Name], fca.DateID ) t
    GROUP BY t.Regulation, t.InstrumentType, t.DateID

    UNION ALL
    SELECT t.Regulation, t.InstrumentType, t.DateID, 'CFD PnL Realized Unrealized', SUM(t.CFD_PnL),'3' AS 'Key'
    FROM ( SELECT
            di.InstrumentType,
            dr1.[Name] AS Regulation,
            fca.DateID,
            SUM(CASE WHEN fca.ActionTypeID IN (4,5,6,28,40) AND fca.IsSettled = 0
                     THEN fca.NetProfit ELSE 0 END) AS CFD_PnL
        FROM DWH_dbo.Fact_CustomerAction fca
        JOIN DWH_dbo.Fact_SnapshotCustomer fsc ON fca.RealCID = fsc.RealCID
        JOIN DWH_dbo.Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID
                                  AND fca.DateID BETWEEN dr.FromDateID AND dr.ToDateID
        JOIN DWH_dbo.Dim_Instrument di ON fca.InstrumentID = di.InstrumentID
        JOIN DWH_dbo.Dim_Regulation dr1 ON fsc.RegulationID = dr1.DWHRegulationID
        WHERE fca.DateID BETWEEN CAST(FORMAT(CAST( <[Parameters].[Parameter 5]> AS DATE),'yyyyMMdd') as INT) AND CAST(FORMAT(CAST(<[Parameters].[Parameter 4]> AS DATE),'yyyyMMdd') as INT)
          AND fca.ActionTypeID IN (1,2,3,39,4,5,6,28,40)
          AND di.InstrumentType <> 'All'
        GROUP BY di.InstrumentType, dr1.[Name], fca.DateID ) t
    GROUP BY t.Regulation, t.InstrumentType, t.DateID
) u
GROUP BY u.Regulation, u.InstrumentType, u.DateID, u.Metric,u.[Key]