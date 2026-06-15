-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.positions_for_compliance_v
-- Captured: 2026-05-19T15:17:27Z
-- ==========================================================================

SELECT dp.positionid,
             dp.cid,
             dp.instrumentid,
             dp.amount,
             dp.initialamountcents / 100 AS InitialAmount,
             dp.hedgeserverid,
             dp.leverage,
             dp.isbuy,
             dp.openoccurred,
             dp.closeoccurred,
             dp.parentpositionid,
             dp.origparentpositionid,
             dp.mirrorid,
             dp.isopenopen,
             dp.opendateid,
             dp.closedateid,
             dp.volume,
             dp.regulationidonopen,
             dp.treeid,
             dp.initialunits,
             dp.amountinunitsdecimal     AS Units,
             dp.isdiscounted,
             dp.issettled,
             dp.issettledonopen,
             dp.volumeonclose,
             dp.isairdrop,
             dp.inithedgetype,
             dp.endhedgetype,
             dp.orderid,
             dp.closepositionreasonid,
             di.instrumenttypeid,
             di.instrumenttype,
             di.NAME                     AS Instrument,
             di.buycurrencyid,
             di.sellcurrencyid,
             di.buycurrency,
             di.sellcurrency,
             di.ismajor,
             di.instrumentdisplayname,
             di.industry,
             di.exchange,
             di.isincode,
             di.isincountrycode,
             di.tradable,
             di.symbol,
             di.symbolfull,
             di.cusip,
             di.isfuture,
             dcpr.NAME                   AS ClosePositionReason,
             dp.ispartialclosechild,
             dp.ispartialcloseparent,
             dp.netprofit,
             dp.pnlindollars
FROM   
main.dwh.dim_position dp
       LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument di
              ON dp.instrumentid = di.instrumentid
       LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_closepositionreason dcpr
              ON dp.closepositionreasonid = dcpr.closepositionreasonid 
      LEFT JOIN main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked cfm
              ON dp.cid = cfm.cid
