SELECT
aa.StrategyName,
aa.HedgeServerID,
bb.LiquidityAccountID,
bb.LiquidityAccountName
FROM main.general.bronze_etoro_trade_hedgeserver aa
JOIN main.bi_db.bronze_etoro_hedge_gethedgeserveraccountmapping bb
ON aa.HedgeServerID = bb.HedgeServerID
WHERE bb.LiquidityAccountID IS NOT NULL