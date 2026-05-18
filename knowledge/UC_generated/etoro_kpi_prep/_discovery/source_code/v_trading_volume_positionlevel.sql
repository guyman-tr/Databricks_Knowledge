-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi_prep.v_trading_volume_positionlevel
-- Captured: 2026-05-18T08:15:05Z
-- ==========================================================================

WITH volume_open AS (
    SELECT
        fca.CID,
        fca.InstrumentID,
        fca.Amount,
        fca.Leverage,
        fca.PositionID,
        fca.OpenDateID AS DateID,
        COALESCE(CAST(fca.Volume AS BIGINT), CAST(0 AS BIGINT)) AS VolumeOpen,
        CAST(0 AS BIGINT) AS VolumeClose,
        CASE WHEN COALESCE(fca.IsPartialCloseChild, 0) = 1 THEN 0 ELSE 1 END AS CountOpenTransactions,
        0 AS CountCloseTransactions,
        CASE WHEN COALESCE(fca.IsPartialCloseChild, 0) = 1 THEN 0 ELSE CAST(fca.InitialAmountCents / 100.0 AS DOUBLE) END AS InvestedAmountOpen,
        CAST(0.0 AS DOUBLE) AS InvestedAmountClosed,
        fca.IsSettled,
        fca.MirrorID,
        fca.IsAirDrop,
        CAST(COALESCE(fca.IsBuy, false) AS INT) AS IsBuy,
        fca.SettlementTypeID,
        CASE
            WHEN COALESCE(fca.IsPartialCloseChild, 0) = 1 THEN CAST(0.0 AS DOUBLE)
            ELSE CAST(
                fca.InitialUnits * fca.InitForexRate * COALESCE(
                    fca.InitForex_USDConversionRate,
                    fca.InitConversionRate,
                    fca.LastOpConversionRate,
                    CAST(1 AS DOUBLE)
                ) AS DOUBLE
            )
        END AS ComputedVolumeOpen,
        CAST(0.0 AS DOUBLE) AS ComputedVolumeClose
    FROM main.dwh.dim_position fca
    WHERE fca.OpenDateID > 0
),
volume_close AS (
    SELECT
        fca.CID,
        fca.InstrumentID,
        fca.Amount,
        fca.Leverage,
        fca.PositionID,
        fca.CloseDateID AS DateID,
        CAST(0 AS BIGINT) AS VolumeOpen,
        COALESCE(CAST(fca.VolumeOnClose AS BIGINT), CAST(0 AS BIGINT)) AS VolumeClose,
        0 AS CountOpenTransactions,
        1 AS CountCloseTransactions,
        CAST(0.0 AS DOUBLE) AS InvestedAmountOpen,
        CAST(fca.Amount AS DOUBLE) AS InvestedAmountClosed,
        fca.IsSettled,
        fca.MirrorID,
        fca.IsAirDrop,
        CAST(COALESCE(fca.IsBuy, false) AS INT) AS IsBuy,
        fca.SettlementTypeID,
        CAST(0.0 AS DOUBLE) AS ComputedVolumeOpen,
        CAST(
            fca.AmountInUnitsDecimal * fca.EndForexRate * COALESCE(fca.LastOpConversionRate, CAST(1 AS DOUBLE)) AS DOUBLE
        ) AS ComputedVolumeClose
    FROM main.dwh.dim_position fca
    WHERE fca.CloseDateID > 0
),
all_volumes AS (
    SELECT
        CID,
        PositionID,
        InstrumentID,
        Amount,
        Leverage,
        DateID,
        VolumeOpen,
        VolumeClose,
        InvestedAmountOpen,
        InvestedAmountClosed,
        (COALESCE(VolumeOpen, 0) + COALESCE(VolumeClose, 0)) AS TotalVolume,
        (COALESCE(InvestedAmountOpen, 0) - COALESCE(InvestedAmountClosed, 0)) AS NetInvestedAmount,
        CountOpenTransactions,
        CountCloseTransactions,
        (CountOpenTransactions + CountCloseTransactions) AS CountTotalTransactions,
        IsSettled,
        MirrorID,
        IsAirDrop,
        IsBuy,
        SettlementTypeID,
        ComputedVolumeOpen,
        ComputedVolumeClose
    FROM (
        SELECT * FROM volume_open
        UNION ALL
        SELECT * FROM volume_close
    ) a
),
c2p AS (
    SELECT DISTINCT PositionID
    FROM main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2p_e2e
    WHERE PositionID IS NOT NULL
),
sqf AS (
    SELECT DISTINCT InstrumentID
    FROM main.etoro_kpi_prep.v_dim_instrument_enriched
    WHERE COALESCE(IsSQF, 0) = 1
)
SELECT
    v.CID,
    v.PositionID,
    v.InstrumentID,
    v.Amount,
    v.Leverage,
    v.DateID,
    v.VolumeOpen,
    v.VolumeClose,
    v.InvestedAmountOpen,
    v.InvestedAmountClosed,
    v.TotalVolume,
    v.NetInvestedAmount,
    v.CountOpenTransactions,
    v.CountCloseTransactions,
    v.CountTotalTransactions,
    v.IsSettled,
    v.IsAirDrop,
    v.IsBuy,
    v.SettlementTypeID,
    v.ComputedVolumeOpen,
    v.ComputedVolumeClose,
    CASE WHEN v.MirrorID > 0 THEN 1 ELSE 0 END AS IsCopy,
    CASE WHEN v.SettlementTypeID = 5 THEN 1 ELSE 0 END AS IsMarginTrade,
    di.InstrumentTypeID,
    di.IsFuture,
    CASE WHEN sqf.InstrumentID IS NOT NULL THEN 1 ELSE 0 END AS IsSQF,
    CASE WHEN c2p.PositionID IS NOT NULL THEN 1 ELSE 0 END AS IsC2P,
    CASE WHEN bdcfp.PositionID IS NOT NULL THEN 1 ELSE 0 END AS IsCopyFund,
    CAST(0 AS INT) AS IsRecurring,
    CASE WHEN bdpofi.PositionID IS NOT NULL THEN 1 ELSE 0 END AS IsOpenedFromIBAN,
    CASE WHEN bdpcti.PositionID IS NOT NULL THEN 1 ELSE 0 END AS IsClosedToIBAN,
    fsc.IsValidCustomer
FROM all_volumes v
INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    ON v.CID = fsc.RealCID
INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr
    ON fsc.DateRangeID = dr.DateRangeID
    AND v.DateID BETWEEN dr.FromDateID AND dr.ToDateID
INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
    ON v.InstrumentID = di.InstrumentID
LEFT JOIN sqf
    ON v.InstrumentID = sqf.InstrumentID
LEFT JOIN c2p
    ON v.PositionID = c2p.PositionID
LEFT JOIN main.etoro_kpi_prep.v_copyfund_positions bdcfp
    ON v.PositionID = bdcfp.PositionID
LEFT JOIN main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_opened_from_iban bdpofi
    ON v.PositionID = bdpofi.PositionID
LEFT JOIN main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_positions_closed_to_iban bdpcti
    ON v.PositionID = bdpcti.PositionID
