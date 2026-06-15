SELECT 1 AS unique_index,
  *,
SUM(TotalCash) OVER () AS GrandTotalCash
FROM (
  -- Subquery 2: This is the logic of FCA_CB_Pop_Final, which aggregates the results
  SELECT
    a.DateID,
    a.Date,
    a.Regulation,
    a.IsCreditReportValidCB,
    a.CID,
    CASE
      WHEN abs(a.NOPRealCrypto) + abs(a.EquityRealCrypto) + abs(a.TotalRealCryptoLoan) + abs(a.GapRealCrypto) + abs(a.NOPRealStocks) + abs(a.EquityRealStocks) + abs(a.GapRealStocks) + abs(a.TotalCash) + abs(a.AvailableCash) + abs(a.CashInCopy) + abs(a.EquityCFD) + abs(a.TotalNegativeLiability) + abs(a.InProcessCashout) + abs(a.actualNWA) > 0 THEN 1
      ELSE 0
    END Is_CID_Releavnt,
    SUM(a.TotalCash) AS TotalCash,
    SUM(a.AvailableCash) AS AvailableCash,
    SUM(a.CashInCopy) AS CashInCopy,
    SUM(a.EquityCFD) AS EquityCFD,
    SUM(a.TotalNegativeLiability) AS TotalNegativeLiability,
    SUM(a.InProcessCashout) AS InProcessCashout,
    SUM(a.actualNWA) AS actualNWA
  FROM (
    -- Subquery 1: This is the logic of FCA_CB_Pop, selecting and calculating columns
    SELECT
      a.DateID,
      a.Date,
      a.CID,
      a.Regulation,
      a.IsCreditReportValidCB,
      ISNULL(a.NOPCrypto, 0) - ISNULL(a.NOPCryptoCFD, 0) AS NOPRealCrypto,
      ISNULL(a.TotalRealCrypto, 0) + ISNULL(a.PositionPNLCryptoReal, 0) AS EquityRealCrypto,
      ISNULL(a.TotalRealCryptoLoan, 0) AS TotalRealCryptoLoan,
      (ISNULL(a.NOPCrypto, 0) - ISNULL(a.NOPCryptoCFD, 0)) - (ISNULL(a.TotalRealCrypto, 0) + ISNULL(a.PositionPNLCryptoReal, 0)) AS GapRealCrypto,
      ISNULL(a.NOPStocks, 0) - ISNULL(a.NOPStocksCFD, 0) AS NOPRealStocks,
      ISNULL(a.TotalRealStocks, 0) + ISNULL(a.PositionPNLStocksReal, 0) AS EquityRealStocks,
      (ISNULL(a.NOPStocks, 0) - ISNULL(a.NOPStocksCFD, 0)) - (ISNULL(a.TotalRealStocks, 0) + ISNULL(a.PositionPNLStocksReal, 0)) AS GapRealStocks,
      ISNULL(a.CashInCopy, 0) + ISNULL(a.AvailableCash, 0) AS TotalCash,
      ISNULL(a.AvailableCash, 0) AS AvailableCash,
      ISNULL(a.CashInCopy, 0) AS CashInCopy,
      (ISNULL(a.PositionAmount, 0) + ISNULL(a.PositionPNL, 0)) - (ISNULL(a.TotalRealCrypto, 0) + ISNULL(a.PositionPNLCryptoReal, 0)) - (ISNULL(a.TotalRealStocks, 0) + ISNULL(a.PositionPNLStocksReal, 0)) AS EquityCFD,
      ISNULL(a.TotalNegativeLiability, 0) AS TotalNegativeLiability,
      ISNULL(a.InProcessCashout, 0) AS InProcessCashout,
      ISNULL(a.actualNWA, 0) AS actualNWA
    FROM
      BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New a
    WHERE
      a.DateID >= CONVERT(INT, CONVERT(VARCHAR(8), GETDATE(), 112)) - 1
      AND a.Regulation = 'FCA'
      AND a.IsCreditReportValidCB = 1
  ) a
  GROUP BY
	a.DateID,
    a.Date,
    a.Regulation,
    a.IsCreditReportValidCB,
    a.CID,
    CASE
      WHEN abs(a.NOPRealCrypto) + abs(a.EquityRealCrypto) + abs(a.TotalRealCryptoLoan) + abs(a.GapRealCrypto) + abs(a.NOPRealStocks) + abs(a.EquityRealStocks) + abs(a.GapRealStocks) + abs(a.TotalCash) + abs(a.AvailableCash) + abs(a.CashInCopy) + abs(a.EquityCFD) + abs(a.TotalNegativeLiability) + abs(a.InProcessCashout) + abs(a.actualNWA) > 0 THEN 1
      ELSE 0
    END
) FCA_CB_Pop_Final
where TotalCash > 0