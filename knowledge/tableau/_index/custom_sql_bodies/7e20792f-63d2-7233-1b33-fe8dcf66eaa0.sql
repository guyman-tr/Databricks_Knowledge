SELECT
    a.*,
    a.PositiveCashOnly * IFNULL(q.QMMFPortion, 0) AS QMMFPortion,

    CASE
        WHEN a.CMNoNMarginSegValue IS NULL OR a.CMNoNMarginSegValue = 0 THEN 0
        ELSE a.PositiveCashOnly * IFNULL(q.QMMFPortion, 0) / a.CMNoNMarginSegValue
    END AS PercheldQMMF,

    1 - CASE
        WHEN a.CMNoNMarginSegValue IS NULL OR a.CMNoNMarginSegValue = 0 THEN 0
        ELSE a.PositiveCashOnly * IFNULL(q.QMMFPortion, 0) / a.CMNoNMarginSegValue
    END AS PercheldByBank

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
      AND bdcbcln.DateID = CAST(date_format(CAST(<[Parameters].[Parameter 2]> AS DATE), 'yyyyMMdd') AS INT)
        AND  COALESCE(TRY_CAST(bdcbcln.OpeningBalance AS DOUBLE), 0)<> 0 
      
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
        CASE
            WHEN denom.PositiveCashSum IS NULL OR denom.PositiveCashSum = 0 THEN 0
            ELSE (IFNULL(tot.qmmfvalue_black_rock, 0)+IFNULL(tot.qmmfvalue_jpm, 0)) / denom.PositiveCashSum
        END AS QMMFPortion
    FROM
    (
        SELECT qmmfvalue_black_rock,qmmfvalue_jpm
        FROM main.bi_db.bronze_fivetran_google_sheets_qmmf_totalvalue
        WHERE date_id = CAST(date_format(CAST(<[Parameters].[Parameter 2]> AS DATE), 'yyyyMMdd') AS INT)
        LIMIT 1
    ) tot
    CROSS JOIN
    (
        SELECT
            SUM(
                CASE
                    WHEN IFNULL(bdcbcln.AvailableCash, 0) + IFNULL(bdcbcln.CashInCopy, 0) > 0
                    THEN IFNULL(bdcbcln.AvailableCash, 0) + IFNULL(bdcbcln.CashInCopy, 0)
                    ELSE 0
                END
            ) AS PositiveCashSum
        FROM main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_client_balance_cid_level_new bdcbcln
        WHERE bdcbcln.Regulation = 'FCA'
          AND bdcbcln.IsCreditReportValidCB = 1
          AND bdcbcln.DateID = CAST(date_format(CAST(<[Parameters].[Parameter 2]> AS DATE), 'yyyyMMdd') AS INT)
        AND  COALESCE(TRY_CAST(bdcbcln.OpeningBalance AS DOUBLE), 0)<> 0 
    ) denom
) q