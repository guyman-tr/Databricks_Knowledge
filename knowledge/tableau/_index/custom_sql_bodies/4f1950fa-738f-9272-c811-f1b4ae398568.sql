SELECT
  c.date,
  c.Source_Name,
  c.account_name,
  c.sub_account_name,
  c.coin,
  c.balance,
  c.Pending_Rewards_Amount
FROM (
  SELECT
    CAST(gold.etr_ymd AS DATE)                             AS date,
    'Flat Report'                                          AS Source_Name,
    gold.`Column`                                          AS account_name,
    gold.Account                                           AS sub_account_name,
    gold.Coin_Asset_Code                                   AS coin,
    gold.Balance_Amount                                    AS balance,
    CAST(NULL AS DOUBLE)                                   AS Pending_Rewards_Amount
  FROM main.general.gold_lukka_flat_custom_report AS gold
  WHERE gold.etr_ymd = <[Parameters].[Parameter 1]>

  UNION ALL

  SELECT
    CAST(ii.etr_ymd AS DATE)                               AS date,
    'Pending Report'                                       AS Source_Name,
    ii.Account_Name                                        AS account_name,
    ii.Sub_Account_Name                                    AS sub_account_name,
    ii.Base_Asset_Code                                     AS coin,
    CAST(REPLACE(ii.Base_Amount, ',', '') AS DOUBLE)        AS balance,
    CAST(NULL AS DOUBLE)                                   AS Pending_Rewards_Amount
  FROM main.general.gold_lukka_pending_tr_transfers_custom_report AS ii
  WHERE ii.etr_ymd = <[Parameters].[Parameter 1]>

  UNION ALL

  SELECT
    CAST(pr.etr_ymd AS DATE)                               AS date,
    'Pending Rewards'                                      AS Source_Name,
    pr.Account_Name                                        AS account_name,
    pr.Sub_Account_Name                                    AS sub_account_name,
    pr.Asset_Code                                          AS coin,
    0                                                      AS balance,
    CAST(REPLACE(pr.Pending_Rewards_Amount, ',', '') AS DOUBLE)
                                                           AS Pending_Rewards_Amount
  FROM main.general.gold_lukka_latest_snapshot_with_pending_rewards AS pr
  WHERE pr.etr_ymd = <[Parameters].[Parameter 1]>

  UNION ALL

  SELECT
    hl.snapshot_date                                        AS date,
    'Hyperliquid Spot'                                     AS Source_Name,
    'Hyperliquid'                                          AS account_name,
    hl.wallet_address                                      AS sub_account_name,
    hl.coin                                                AS coin,
    hl.total                                               AS balance,
    CAST(NULL AS DOUBLE)                                   AS Pending_Rewards_Amount
  FROM main.finance.hyperliquid_spot_balances hl
  WHERE hl.snapshot_date =  DATE_ADD(<[Parameters].[Parameter 1]>, -1)
) c