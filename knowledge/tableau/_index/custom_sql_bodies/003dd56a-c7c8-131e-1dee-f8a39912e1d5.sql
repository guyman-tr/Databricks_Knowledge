SELECT
    a.*,
    tot.qmmfvalue_black_rock AS qmmfvalue_black_rock,
    tot.qmmfvalue_jpm        AS qmmfvalue_jpm
FROM
(
    SELECT
        bdcbcln.DateID,
        bdcbcln.IsCreditReportValidCB,
        bdcbcln.CID,
        bdcbcln.Club,
        bdcbcln.Country,
        bdcbcln.PlayerStatus,
        bdcbcln.MifidCategory,
        bdcbcln.AccountType,

        SUM(IFNULL(bdcbcln.AvailableCash, 0) + IFNULL(bdcbcln.CashInCopy, 0)) AS TotalCash,
        SUM(IFNULL(bdcbcln.AvailableCash, 0)) AS AvailableCash,
        SUM(IFNULL(bdcbcln.CashInCopy, 0)) AS CashInCopy,
        SUM(IFNULL(bdcbcln.TotalNegativeLiability, 0)) AS TotalNegativeLiability,
        SUM(IFNULL(bdcbcln.InProcessCashout, 0)) AS InProcessCashout,
        SUM(IFNULL(bdcbcln.actualNWA, 0)) AS actualNWA,

        SUM(
            CASE
                WHEN IFNULL(bdcbcln.AvailableCash, 0) + IFNULL(bdcbcln.CashInCopy, 0) > 0
                THEN IFNULL(bdcbcln.AvailableCash, 0) + IFNULL(bdcbcln.CashInCopy, 0)
                ELSE 0
            END
        ) AS PositiveCashOnly,

        SUM(
            IFNULL(bdcbcln.AvailableCash, 0)
            + IFNULL(bdcbcln.CashInCopy, 0)
            + IFNULL(bdcbcln.InProcessCashout, 0)
            - IFNULL(bdcbcln.TotalNegativeLiability, 0)
        ) AS CMNoNMarginSegValue

    FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new bdcbcln
    WHERE bdcbcln.Regulation = 'FCA'
      AND bdcbcln.IsCreditReportValidCB = 1
      AND bdcbcln.DateID = CAST(date_format(CAST(<[Parameters].[Parameter 2]> AS DATE), 'yyyyMMdd') AS INT)

      /* ✅ ONLY ADDED FILTER */
      AND bdcbcln.CID IN (
          SELECT a.CID
          FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new a
          WHERE a.Regulation = 'FCA'
            AND a.IsCreditReportValidCB = 1
            AND a.DateID = CAST(date_format(CAST(<[Parameters].[Parameter 2]> AS DATE), 'yyyyMMdd') AS INT)
          GROUP BY a.CID
          HAVING
    abs(SUM(IFNULL(a.NOPCrypto, 0)) - SUM(IFNULL(a.NOPCryptoCFD, 0))) +
    abs(SUM(IFNULL(a.TotalRealCrypto, 0)) + SUM(IFNULL(a.PositionPNLCryptoReal, 0))) +
    abs(SUM(IFNULL(a.TotalRealCryptoLoan, 0))) +
    abs(
        (SUM(IFNULL(a.NOPCrypto, 0)) - SUM(IFNULL(a.NOPCryptoCFD, 0))) -
        (SUM(IFNULL(a.TotalRealCrypto, 0)) + SUM(IFNULL(a.PositionPNLCryptoReal, 0)))
    ) +
    abs(SUM(IFNULL(a.NOPStocks, 0)) - SUM(IFNULL(a.NOPStocksCFD, 0))) +
    abs(SUM(IFNULL(a.TotalRealStocks, 0)) + SUM(IFNULL(a.PositionPNLStocksReal, 0))) +
    abs(
        (SUM(IFNULL(a.NOPStocks, 0)) - SUM(IFNULL(a.NOPStocksCFD, 0))) -
        (SUM(IFNULL(a.TotalRealStocks, 0)) + SUM(IFNULL(a.PositionPNLStocksReal, 0)))
    ) +
    abs(SUM(IFNULL(a.CashInCopy, 0)) + SUM(IFNULL(a.AvailableCash, 0))) +
    abs(SUM(IFNULL(a.AvailableCash, 0))) +
    abs(SUM(IFNULL(a.CashInCopy, 0))) +
    abs(
        (SUM(IFNULL(a.PositionAmount, 0)) + SUM(IFNULL(a.PositionPNL, 0))) -
        (SUM(IFNULL(a.TotalRealCrypto, 0)) + SUM(IFNULL(a.PositionPNLCryptoReal, 0))) -
        (SUM(IFNULL(a.TotalRealStocks, 0)) + SUM(IFNULL(a.PositionPNLStocksReal, 0)))
    ) +
    abs(SUM(IFNULL(a.TotalNegativeLiability, 0))) +
    abs(SUM(IFNULL(a.InProcessCashout, 0))) +
    abs(SUM(IFNULL(a.actualNWA, 0))) > 0
      )

    GROUP BY
        bdcbcln.DateID,
        bdcbcln.Regulation,
        bdcbcln.IsCreditReportValidCB,
        bdcbcln.CID,
        bdcbcln.Club,
        bdcbcln.Country,
        bdcbcln.PlayerStatus,
        bdcbcln.MifidCategory,
        bdcbcln.AccountType
) a
CROSS JOIN
(
    SELECT
  MAX(qmmf_value_black_rock) AS qmmfvalue_black_rock,
  MAX(qmmf_value_jpm)        AS qmmfvalue_jpm
FROM sharepoint.silver_sharepoint_qmmf_totalvalue
WHERE date_id = CAST(date_format(CAST(<[Parameters].[Parameter 2]> AS DATE), 'yyyyMMdd') AS INT)
) tot