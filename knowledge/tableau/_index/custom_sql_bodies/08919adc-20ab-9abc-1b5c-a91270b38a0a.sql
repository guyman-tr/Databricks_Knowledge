SELECT ib.[Buy/Sell],
  ib.[Clients_Amount],
  ib.[Clients_Units],
  ib.[CurrencyPrimary],
  ib.[Date],
  ib.[Exchange],
  ib.[HedgeServerID],
  ib.[IB-Clients_AmountUSD],
  ib.[IB-Clients_Amount],
  ib.[IB-Clients_Units],
  ib.[IB-eToro_AmountUSD],
  ib.[IB-eToro_Amount],
  ib.[IB-eToro_Rate],
  ib.[IB-eToro_Units],
  ib.[IB_AmountUSD],
  ib.[IB_LocalAmount],
  ib.[IB_Rate],
  ib.[IB_Units],
  ib.[ISINCode],
  ib.[InstrumentDisplayName],
  ib.[InstrumentID],
  ib.[UpdateDate],
  ib.[eToro_AmountUSD],
  ib.[eToro_Amount],
  ib.[eToro_Rate],
  ib.[eToro_Units],
  'Real' AS [CFD/Real]
FROM [Dealing_dbo].[Dealing_IBRecon_Trades] ib

UNION ALL

SELECT ib.[Buy/Sell],
  ib.[Clients_Amount],
  ib.[Clients_Units],
  ib.[CurrencyPrimary],
  ib.[Date],
  ib.[Exchange],
  ib.[HedgeServerID],
  ib.[IB-Clients_AmountUSD],
  ib.[IB-Clients_Amount],
  ib.[IB-Clients_Units],
  ib.[IB-eToro_AmountUSD],
  ib.[IB-eToro_Amount],
  ib.[IB-eToro_Rate],
  ib.[IB-eToro_Units],
  ib.[IB_AmountUSD],
  ib.[IB_LocalAmount],
  ib.[IB_Rate],
  ib.[IB_Units],
  ib.[ISINCode],
  ib.[InstrumentDisplayName],
  ib.[InstrumentID],
  ib.[UpdateDate],
  ib.[eToro_AmountUSD],
  ib.[eToro_Amount],
  ib.[eToro_Rate],
  ib.[eToro_Units],
  'CFD' AS [CFD/Real]
FROM Dealing_dbo.Dealing_IBRecon_Trades_CFD ib