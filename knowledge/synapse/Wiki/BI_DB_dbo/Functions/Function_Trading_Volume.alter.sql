-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.Function_Trading_Volume
-- Generated: 2026-04-12 | recreate_views_with_col_comments.py
-- UC Target: main.etoro_kpi_prep.v_trading_volume_and_amount
-- Col comments: 20 added, 9 preserved (existing), 3 unmatched
-- NOTE: Column comments on views require CREATE OR REPLACE VIEW (not ALTER COLUMN).
-- =============================================================================

-- ---- Full CREATE OR REPLACE VIEW (idempotent — safe to re-run) ----
CREATE OR REPLACE VIEW main.etoro_kpi_prep.v_trading_volume_and_amount (
  CID COMMENT 'Customer ID — the account that owns this position. References the customer entity. Nonclustered index supports CID-based queries.',
  PositionID COMMENT 'Unique position identifier. System-generated. Also serves as the root TreeID for independent (non-copy-trade) positions. HASH distribution key for this table.',
  InstrumentID COMMENT 'Financial instrument being traded (stock, forex, crypto, ETF, commodity, index). References Dim_Instrument. Drives settlement rules, fees, hedge routing, PnL conversion.',
  Amount COMMENT 'Customer invested amount in USD. Updated proportionally on partial close. Gross notional = Amount × Leverage.',
  Leverage COMMENT 'Leverage multiplier (e.g., 1=no leverage/real ownership, 5=5x). Leverage=1 + IsSettled=1 → REAL settlement. Gross notional = Amount × Leverage.',
  DateID COMMENT 'Open date as YYYYMMDD int. DWH-computed from OpenOccurred. Indexed.',
  VolumeOpen COMMENT 'SUM(CAST(VolumeOpen AS BIGINT)) where each open row has VolumeOpen = ISNULL(CAST(Volume AS BIGINT),0) and OpenDateID BETWEEN @sdateInt AND @edateInt. Source: DWH_dbo.Dim_Position.Volume. (T2 — Function_Trading_Volume)',
  VolumeClose COMMENT 'SUM(CAST(VolumeClose AS BIGINT)) where each close row has VolumeClose = ISNULL(CAST(VolumeOnClose AS BIGINT),0) and CloseDateID BETWEEN @sdateInt AND @edateInt. Source: DWH_dbo.Dim_Position.VolumeOnClose. (T2 — Function_Trading_Volume)',
  InvestedAmountOpen COMMENT 'SUM(InvestedAmountOpen) with CASE WHEN IsPartialCloseChild=1 THEN 0 ELSE InitialAmountCents/100 END on open rows only. Source: DWH_dbo.Dim_Position.InitialAmountCents. (T2 — Function_Trading_Volume)',
  InvestedAmountClosed COMMENT 'SUM(Amount) on close rows only (CloseDateID in range). Source: DWH_dbo.Dim_Position.Amount. (T2 — Function_Trading_Volume)',
  TotalVolume COMMENT 'Row-level ISNULL(VolumeOpen,0)+ISNULL(VolumeClose,0) in CTE; output SUM(CAST(TotalVolume AS BIGINT)) by group. Source: DWH_dbo.Dim_Position.Volume, VolumeOnClose. (T2 — Function_Trading_Volume)',
  NetInvestedAmount COMMENT 'Row-level InvestedAmountOpen - InvestedAmountClosed in CTE; output SUM(NetInvestedAmount). Source: DWH_dbo.Dim_Position. (T2 — Function_Trading_Volume)',
  CountOpenTransactions COMMENT 'SUM(CountOpenTransactions) where open rows use CASE WHEN IsPartialCloseChild=1 THEN 0 ELSE 1 END (excludes partial-close child opens). Source: DWH_dbo.Dim_Position.IsPartialCloseChild. (T2 — Function_Trading_Volume)',
  CountCloseTransactions COMMENT 'SUM(CountCloseTransactions) — 1 on each close row, 0 on opens. Source: DWH_dbo.Dim_Position. (T2 — Function_Trading_Volume)',
  CountTotalTransactions COMMENT 'SUM(CountTotalTransactions) where CTE sets CountOpenTransactions + CountCloseTransactions per row. Source: DWH_dbo.Dim_Position. (T2 — Function_Trading_Volume)',
  IsSettled COMMENT 'Legacy real-ownership flag: 1=Real (owns shares), 0=CFD. Predates SettlementTypeID. Fallback: ISNULL(SettlementTypeID, CAST(IsSettled AS tinyint)).',
  IsAirDrop COMMENT 'Airdrop flag: 1=eToro opened position on behalf of customer (staking, promotions, compensations — not just crypto). Set from Trade.PositionAirdropLog. NULL=not airdrop.',
  IsBuy COMMENT 'GROUP BY. Source: DWH_dbo.Dim_Position.IsBuy. (T1 — Function_Trading_Volume)',
  SettlementTypeID COMMENT 'Authoritative settlement: 0=CFD,1=REAL,2=TRS,3=CMT(Crypto settled),4=REAL_FUTURES,5=MARGIN_TRADE. NULL=legacy, use ISNULL(SettlementTypeID,CAST(IsSettled AS tinyint)).',
  ComputedVolumeOpen,
  ComputedVolumeClose,
  IsCopy COMMENT 'CASE WHEN MirrorID > 0 THEN 1 ELSE 0 END; GROUP BY. Source: DWH_dbo.Dim_Position.MirrorID. (T2 — Function_Trading_Volume)',
  IsMarginTrade COMMENT 'CASE WHEN SettlementTypeID = 5 THEN 1 ELSE 0 END; ISNULL; GROUP BY. Source: DWH_dbo.Dim_Position.SettlementTypeID. (T2 — Function_Trading_Volume)',
  InstrumentTypeID COMMENT 'JOIN; GROUP BY. Source: DWH_dbo.Dim_Instrument.InstrumentTypeID. (T1 — Function_Trading_Volume)',
  IsFuture COMMENT 'GROUP BY. Source: DWH_dbo.Dim_Instrument.IsFuture. (T1 — Function_Trading_Volume)',
  IsSQF COMMENT 'Instrument in SQF subset at @edateInt; GROUP BY. Source: BI_DB_dbo.Function_Instrument_Snapshot_Enriched. (T2 — Function_Trading_Volume)',
  IsC2P COMMENT 'CASE WHEN PositionID matched THEN 1 ELSE 0 END. Source: BI_DB_dbo.V_C2P_Positions. (T2 — Function_Trading_Volume)',
  IsCopyFund COMMENT 'CASE WHEN PositionID matched THEN 1 ELSE 0 END. Source: BI_DB_dbo.BI_DB_CopyFund_Positions. (T2 — Function_Trading_Volume)',
  IsRecurring COMMENT 'CASE WHEN PositionID matched THEN 1 ELSE 0 END. Source: BI_DB_dbo.BI_DB_RecurringInvestment_Positions. (T2 — Function_Trading_Volume)',
  IsOpenedFromIBAN COMMENT 'CASE WHEN PositionID matched THEN 1 ELSE 0 END. Source: BI_DB_dbo.BI_DB_Positions_Opened_From_IBAN. (T2 — Function_Trading_Volume)',
  IsClosedToIBAN COMMENT 'CASE WHEN PositionID matched THEN 1 ELSE 0 END. Source: BI_DB_dbo.BI_DB_Positions_Closed_To_IBAN. (T2 — Function_Trading_Volume)',
  IsValidCustomer
)
COMMENT 'BI_DB_dbo.Function_Trading_Volume > Builds two legs from DWH_dbo.Dim_Position over the inclusive YYYYMMDD range [@sdateInt, @edateInt]: opens where OpenDateID is in range (uses persisted Volume, InitialAmountCents, open counters), and closes where CloseDateID is in range (uses VolumeOnClose, Amount as closed invested, close counter). The legs are UNION ALL’d; each row gets TotalVolume = ISNULL(VolumeOpen,0) + ISNULL(VolumeClose,0) and NetInvestedAmount = InvestedAmountOpen - InvestedAmountClosed before the final GROUP BY on customer and product attributes. Joins Fact_SnapshotCustomer + Dim_Range (as-of snapshot for the event DateID), Dim_Instrument, SQF and C2P flags, then left-joins copy-fund / recurring / IBAN helper tables on PositionID for reporting dimensions.'
TBLPROPERTIES (
  'comment' = 'BI_DB_dbo.Function_Trading_Volume > Builds two legs from DWH_dbo.Dim_Position over the inclusive YYYYMMDD range [@sdateInt, @edateInt]: opens where OpenDateID is in range (uses persisted Volume, InitialAmountCents, open counters), and closes where CloseDateID is in range (uses VolumeOnClose, Amount as closed invested, close counter). The legs are UNION ALL’d; each row gets TotalVolume = ISNULL(VolumeOpen,0) + ISNULL(VolumeClose,0) and NetInvestedAmount = InvestedAmountOpen - InvestedAmountClosed before the final GROUP BY on customer and product attributes. Joins Fact_SnapshotCustomer + Dim_Range (as-of snapshot for the event DateID), Dim_Instrument, SQF and C2P flags, then left-joins copy-fund / recurring / IBAN helper tables on PositionID for reporting dimensions.')
WITH SCHEMA COMPENSATION
AS WITH volume_open AS (
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

;
