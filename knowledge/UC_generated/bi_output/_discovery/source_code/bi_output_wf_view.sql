-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_wf_view
-- Captured: 2026-06-19T14:31:36Z
-- ==========================================================================

select
  gcid as GCID,
  ClientId AS ClientID,
  contractNo AS ContractNumber,
  productCode AS ProductCode,
  productName AS ProductName,
  subscriptionDate AS SubscriptionDate,
  contractStatus AS ContractStatus,
  referenceCurrency AS ReferenceCurrency,
  savingsValue AS SavingValue,
  ((Bid+Ask)/2) * savingsValue AS SavingValueInDollar,
  savingsValueDate AS SavingsValueDate,
  isin AS ISIN,
  percent AS Percent,
  amount AS Amount,
  ((Bid+Ask)/2) * amount AS AmountInDollar,
  numberOfShares AS NumberOfShares,
  currency AS Currency,
  ((Bid+Ask)/2) AS ExchangeRate
from
  (
    SELECT
      COALESCE(data.cliendId, data.clientId) ClientId,
      COALESCE(data.contractId, data.contractNo) contractNo,
      data.productCode,
      data.productName,
      data.subscriptionDate,
      data.contractStatus,
      data.referenceCurrency,
      data.savingsValue,
      data.savingsValueDate,
      vehicles.isin,
      vehicles.percent,
      vehicles.amount,
      vehicles.numberOfShares,
      vehicles.currency
    FROM
      bi_db.bronze_wealth_france_wealth_france_users_data
      LATERAL VIEW
        EXPLODE(
          from_json(
            json_text,
            'array<struct<
      cliendId: string,
      clientId: string,
      contractId: string,
      contractNo: string,
      productCode: string,
      productName: string,
      subscriptionDate: date,
      contractStatus: string,
      referenceCurrency: string,
      savingsValue: float,
      savingsValueDate: date,
      vehicles: array<struct<
          isin: string, 
          amount: float, 
          percent: float, 
          currency: string, 
          numberOfShares: float
      >>
  >>'
          )
        ) AS data
      LATERAL VIEW OUTER EXPLODE(data.vehicles) AS vehicles
      group by all
  ) q0
    left join bi_db.bronze_sub_accounts_accounts ac
    on q0.ClientId = ac.accountId
    left join main.dealing.bronze_pricelog_candles_currencypricemaxdatewithsplit cws
    on q0.savingsValueDate = cws.etr_ymd
    and cws.InstrumentID = 1
