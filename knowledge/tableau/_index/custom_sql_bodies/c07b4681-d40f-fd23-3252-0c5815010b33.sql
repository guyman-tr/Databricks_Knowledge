SELECT ib.[ClientAccountID],
  ib.[Clients_AmountNOP],
  ib.[Clients_Units],
  ib.[CurrencyPrimary],
  ib.[Date],
  ib.[Exchange],
  ib.[FX_Rate],
  ib.[HedgeServerID],
  ib.[IB-Clients_Units],
  ib.[IB-eToro_Units],
  ib.[IB_AmountUSD],
  ib.[IB_LocalAmount],
  ib.[IB_Rate],
  ib.[IB_Symbol],
  ib.[IB_Units],
  ib.[ISINCode],
  ib.[InstrumentDisplayName],
  ib.[InstrumentID],
  ib.[IsBuy],
  ib.[Reality-Client],
  ib.[Reality-Supposed],
  ib.[UpdateDate],
  ib.[eToro_AmountUSD],
  ib.[eToro_Symbol],
  ib.[eToro_Units],
  'Real' AS [CFD/Real]
FROM [Dealing_dbo].[Dealing_IBRecon_EODHoldings] ib

UNION ALL

SELECT ib.[ClientAccountID],
  ib.[Clients_AmountNOP],
  ib.[Clients_Units],
  ib.[CurrencyPrimary],
  ib.[Date],
  ib.[Exchange],
  ib.[FX_Rate],
  ib.[HedgeServerID],
  ib.[IB-Clients_Units],
  ib.[IB-eToro_Units],
  ib.[IB_AmountUSD],
  ib.[IB_LocalAmount],
  ib.[IB_Rate],
  ib.[IB_Symbol],
  ib.[IB_Units],
  ib.[ISINCode],
  ib.[InstrumentDisplayName],
  ib.[InstrumentID],
  ib.[IsBuy],
  ib.[Reality-Client],
  ib.[Reality-Supposed],
  ib.[UpdateDate],
  ib.[eToro_AmountUSD],
  ib.[eToro_Symbol],
  ib.[eToro_Units],
  'CFD' AS [CFD/Real]
FROM Dealing_dbo.Dealing_IBRecon_EODHoldings_CFD ib