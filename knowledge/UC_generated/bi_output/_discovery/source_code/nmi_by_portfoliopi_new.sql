-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.nmi_by_portfoliopi_new
-- Captured: 2026-05-19T14:53:38Z
-- ==========================================================================

SELECT
  mirror.ParentCID,
  CopyType,
  mirror.ParentUserName AS UserName,
  dc.Region AS Region,
  CAST (MoneyIn AS Decimal (12, 2)) MoneyIn,
  CAST (MoneyOut AS Decimal (12, 2)) MoneyOut,
  CAST ((MoneyIn + MoneyOut) AS Decimal (12, 2)) NetMoneyIn
FROM
  (
    SELECT
      ParentCID,
      hm.ParentUserName,case
        when AccountTypeID = 9 then 'Portfolio'
        else 'PI'
      END AS CopyType,
      SUM (
        CASE
          WHEN (
            (MirrorOperationID = 1)
            OR (
              MirrorOperationID = 3
              AND Amount > 0
            )
          ) THEN Amount
          ELSE 0
        END
      ) MoneyIn,
      SUM (
        CASE
          WHEN MirrorOperationID = 2 THEN Amount * -1
          WHEN (
            MirrorOperationID = 3
            AND Amount < 0
          ) THEN Amount
          ELSE 0
        END
      ) MoneyOut
    FROM
      main.bi_db.bronze_etoro_dwh_v_historymirrorhourly hm
      INNER JOIN main.general.bronze_etoro_backoffice_customer bc on hm.ParentCID = bc.CID
      and (
        AccountTypeID = 9
        or GuruStatusID >= 2
      )
    WHERE
      MirrorOperationID in (1, 2, 3) -- open/close/add or remove funds
      AND ModificationDate >= timestamp(current_Date())
    GROUP BY
      ParentCID,case
        when AccountTypeID = 9 then 'Portfolio'
        else 'PI'
      END,
      hm.ParentUserName
  ) mirror
  inner join main.general.bronze_etoro_customer_customer_masked cc ON mirror.ParentCID = cc.CID
  Inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc ON dc.CountryID = cc.CountryID
  Inner JOIN main.general.bronze_etoro_backoffice_customer bc ON bc.CID = cc.CID
  Inner JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager bm ON bc.ManagerID = bm.ManagerID
WHERE
  (
    (
      cc.PlayerLevelID <> 4
      and bc.GuruStatusID >= 2
    )
    or AccountTypeID = 9
  )
