-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.vg_payments_mimo_basedonddrallplatfrommimo_for_genie
-- Captured: 2026-05-19T15:00:22Z
-- ==========================================================================

SELECT
    aa.Ind                               AS MIMO_Ind,
    aa.TransactionID,
    aa.RealCID,
    aa.MarketingRegionManualName,
    aa.Country,
    aa.Club,
    aa.Regulation,
    aa.Date_MIMO,
    aa.EOM_MIMO,
    aa.MIMOPlatform,
    last_day(dc.FirstDepositDate)        AS EOM_FTD,
    last_day(dc.RegisteredReal)          AS EOM_Reg,
    aa.IsInternalTransfer,
    aa.IsTradeFromIBAN,
    aa.Currency,
    aa.MOP,
    aa.IsFTD,
    aa.AmountUSD                         AS AmountUSD_MIMO,
    row_number() over (
        partition by aa.RealCID
        order by aa.AmountUSD DESC
    )                                   AS Rank_Amount
FROM
(
    /* =========================
       Deposit
       ========================= */
    SELECT
        'Deposit'                        AS Ind,
        bddfmap.TransactionID,
        bddfmap.RealCID,
        dc.Name                          AS Country,
        dpl.Name                         AS Club,
        dr1.Name                         AS Regulation,
        bddfmap.Date                     AS Date_MIMO,
        last_day(bddfmap.Date)           AS EOM_MIMO,
        bddfmap.MIMOPlatform,
        bddfmap.IsInternalTransfer,
        bddfmap.IsTradeFromIBAN,
        dc2.Abbreviation                 AS Currency,
        CASE
            WHEN bddfmap.MIMOPlatform = 'eMoney'
             AND bddfmap.IsInternalTransfer = 0
             AND bddfmap.IsTradeFromIBAN = 0
                THEN o.Fundingtype_Txtype_7
            ELSE dft.Name
        END                              AS MOP,
        bddfmap.IsPlatformFTD            AS IsFTD,
        dc.MarketingRegionManualName,
        SUM(coalesce(bddfmap.AmountUSD,0)) AS AmountUSD
    FROM
        bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms bddfmap

        INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
            ON bddfmap.RealCID = fsc.RealCID
           AND fsc.IsValidCustomer = 1

        INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
            ON fsc.DateRangeID = dr.DateRangeID
           AND bddfmap.DateID BETWEEN dr.FromDateID AND dr.ToDateID

        INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
            ON fsc.CountryID = dc.CountryID

        LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency dc2
            ON bddfmap.CurrencyID = dc2.CurrencyID

        LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
            ON fsc.PlayerLevelID = dpl.PlayerLevelID

        LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr1
            ON dr1.DWHRegulationID = fsc.RegulationID

        LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype dft
            ON bddfmap.FundingTypeID = dft.FundingTypeID

        LEFT JOIN (
            SELECT
                mdt.TransactionID,
                CASE
                    WHEN p.CID IS NOT NULL THEN 'OpenBanking'
                    ELSE 'WireTransfer'
                END AS Fundingtype_Txtype_7
            FROM
                bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction mdt
                LEFT JOIN bi_db.bronze_moneytransfer_billing_transfers p
                    ON lower(p.ExReferenceID) = lower(mdt.ReferenceNumber)
                   AND p.TransferStatusID = 10
            WHERE
                mdt.TxCreatedDateID >= 20240101
        ) o
            ON o.TransactionID = bddfmap.TransactionID

    WHERE
        bddfmap.DateID >= 20240101
        AND bddfmap.MIMOAction = 'Deposit'

    GROUP BY
        bddfmap.TransactionID,
        bddfmap.RealCID,
        dc.Name,
        dpl.Name,
        dr1.Name,
        bddfmap.Date,
        last_day(bddfmap.Date),
        bddfmap.MIMOPlatform,
        bddfmap.IsInternalTransfer,
        bddfmap.IsTradeFromIBAN,
        dc2.Abbreviation,
        CASE
            WHEN bddfmap.MIMOPlatform = 'eMoney'
             AND bddfmap.IsInternalTransfer = 0
             AND bddfmap.IsTradeFromIBAN = 0
                THEN o.Fundingtype_Txtype_7
            ELSE dft.Name
        END,
        bddfmap.IsPlatformFTD,
        dc.MarketingRegionManualName

    UNION ALL

    /* =========================
       Withdraw
       ========================= */
    SELECT
        'CO'                             AS Ind,
        bddfmap.TransactionID,
        bddfmap.RealCID,
        dc.Name                          AS Country,
        dpl.Name                         AS Club,
        dr1.Name                         AS Regulation,
        bddfmap.Date                     AS Date_MIMO,
        last_day(bddfmap.Date)           AS EOM_MIMO,
        bddfmap.MIMOPlatform,
        bddfmap.IsInternalTransfer,
        bddfmap.IsTradeFromIBAN,
        dc2.Abbreviation                 AS Currency,
        CASE
            WHEN bddfmap.MIMOPlatform = 'eMoney'
             AND bddfmap.IsInternalTransfer = 0
             AND bddfmap.IsTradeFromIBAN = 0
                THEN 'WireTransfer'
            ELSE dft.Name
        END                              AS MOP,
        bddfmap.IsPlatformFTD            AS IsFTD,
        dc.MarketingRegionManualName,
        SUM(coalesce(bddfmap.AmountUSD,0)) AS AmountUSD
    FROM
        bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms bddfmap

        INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
            ON bddfmap.RealCID = fsc.RealCID
           AND fsc.IsValidCustomer = 1

        INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
            ON fsc.DateRangeID = dr.DateRangeID
           AND bddfmap.DateID BETWEEN dr.FromDateID AND dr.ToDateID

        INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc
            ON fsc.CountryID = dc.CountryID

        LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency dc2
            ON bddfmap.CurrencyID = dc2.CurrencyID

        LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl
            ON fsc.PlayerLevelID = dpl.PlayerLevelID

        LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr1
            ON dr1.DWHRegulationID = fsc.RegulationID

        LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype dft
            ON bddfmap.FundingTypeID = dft.FundingTypeID

    WHERE
        bddfmap.DateID >= 20240101
        AND bddfmap.MIMOAction = 'Withdraw'

    GROUP BY
        bddfmap.TransactionID,
        bddfmap.RealCID,
        dc.Name,
        dpl.Name,
        dr1.Name,
        bddfmap.Date,
        last_day(bddfmap.Date),
        bddfmap.MIMOPlatform,
        bddfmap.IsInternalTransfer,
        bddfmap.IsTradeFromIBAN,
        dc2.Abbreviation,
        CASE
            WHEN bddfmap.MIMOPlatform = 'eMoney'
             AND bddfmap.IsInternalTransfer = 0
             AND bddfmap.IsTradeFromIBAN = 0
                THEN 'WireTransfer'
            ELSE dft.Name
        END,
        bddfmap.IsPlatformFTD,
        dc.MarketingRegionManualName
) aa

LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    ON aa.RealCID = dc.RealCID
