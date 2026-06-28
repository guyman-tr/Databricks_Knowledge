-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.positive_nmi
-- Captured: 2026-06-19T14:32:43Z
-- ==========================================================================

SELECT
  SymbolFull,
  InstrumentDisplayName,
  CAST(MoneyIn AS Decimal(12, 2)) AS MoneyIn,
  CAST(MoneyOut AS Decimal(12, 2)) MoneyOut,
  CAST((MoneyIn + MoneyOut) AS Decimal(12, 2)) AS NetMoneyIn
FROM
  (
    SELECT
      imd.InstrumentDisplayName,
      imd.SymbolFull,
      SUM(
        CASE
          WHEN hm.CreditTypeID = 3 THEN hm.Payment * -1
          ELSE 0
        END
      ) AS MoneyIn,
      SUM(
        CASE
          WHEN hm.CreditTypeID = 4 THEN hm.Payment * -1
          ELSE 0
        END
      ) AS MoneyOut
    FROM
      main.general.bronze_etoro_history_credit hm
        JOIN (
          select
            PositionID,
            InstrumentID
          from
            main.trading.bronze_etoro_history_position_datafactory hp
          where
            etr_ymd >= current_Date()
          union all
          select
            PositionID,
            InstrumentID
          from
            main.trading.silver_etoro_trade_position tp
          where
            tp.Occurred >= timestamp(current_Date())
        ) P0
          ON hm.PositionID = P0.PositionID
        JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument imd
          ON P0.InstrumentID = imd.InstrumentID
    WHERE
      hm.CreditTypeID IN (3, 4)
      AND hm.MirrorID = 0
      AND hm.etr_ymd >= DATEADD(current_Date(), -1)
      AND imd.InstrumentTypeID IN (5, 6)
    GROUP BY
      imd.InstrumentDisplayName,
      imd.SymbolFull
  ) Q0
ORDER BY
  NetMoneyIn DESC
limit 20
