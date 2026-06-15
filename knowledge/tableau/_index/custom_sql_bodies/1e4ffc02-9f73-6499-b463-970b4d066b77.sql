SELECT dtb.[CID],
  dtb.[Client Name],
  dtb.[Cusip or ISIN],
  dtb.[DateID],
  dtb.[EntryID],
  dtb.[Executed QTY],
  dtb.[Executing Broker],
  dtb.[Fees],
  dtb.[Gross Price (QTY x Share Price)],
  dtb.[IsCopy],
  dtb.[Net Commission],
  dtb.[Order Creation Time],
  dtb.[Order Routed Time],
  dtb.[OrderID],
  dtb.[Qty: Shares Requested],
  dtb.[Settlement Date],
  dtb.[Side],
  dtb.[Symbol],
  dtb.[Time Order Executed or Cancelled],
  dtb.[TradeDate],
  dtb.[Unit Price/share],
  dtb.[UpdateDate]
FROM Dealing_dbo.Dealing_US_DailyTradeBlotter dtb
JOIN DWH_dbo.Dim_Customer dc
ON dtb.CID= dc.RealCID
WHERE dc.IsValidCustomer=1
AND RegulationID= 8