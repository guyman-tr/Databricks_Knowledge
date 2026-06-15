SELECT DISTINCT CID, dpl.Name Club, ModificationDate, ModificationDateID,PaymentDate, DepositID,  BinCodeAsString, bd.DepotID, dbd.Name Depot,
bd.CurrencyID, c.Abbreviation,  AmountUSD ,
bd.PaymentStatusID, ps.Name PaymentStatus,
FundingID,  bd.FundingTypeID, ft.Name FundingType,
cb.CountryID, con.Name Country, con.Region,  cb.IssuingBank, bd.BankName,
cb.CardTypeID, ct.CarTypeName CardTypeName, bd.CardCategory,
CASE WHEN BinCodeAsString IN ('523642','547074','405911','540445','541684','527434','510021','405433','432328') THEN 'B Test Group'
     WHEN BinCodeAsString IN ('476663','476361','416081','476664','459985','459996','516499','516907','528287','434596','487145','525678','474844','401367',
                              '520353','527669','542550','526729','549138','549949','484810','550989','523945','463225','559998','438675','428332','496623',
							  '549186','484281','436500','552115') THEN 'A Test Group'  END ExerementGroup ,
CASE WHEN BinCodeAsString IN ('476663','476361','416081','476664','459985','459996','516499','528287','525678','474844','401367','484810','550989','523945','463225','559998','438675',
                              '428332','523642','405911','540445','527434','510021','405433','432328') THEN 'Checkout'
     WHEN BinCodeAsString IN ('516907','434596','487145','520353','527669','542550','526729','549138','549949','496623','549186','484281','436500','552115','547074','541684') THEN 'WorldPay'
	 ELSE 'Random' END NewAcquire
FROM DWH.dbo.Fact_BillingDeposit bd
LEFT JOIN DWH.dbo.Dim_PaymentStatus ps
ON ps.PaymentStatusID = bd.PaymentStatusID
LEFT JOIN DWH.dbo.Dim_Currency c
ON c.CurrencyID = bd.CurrencyID
LEFT JOIN DWH.dbo.Dim_FundingType ft
ON ft.FundingTypeID = bd.FundingTypeID
LEFT JOIN DWH.dbo.Dim_CountryBin cb
ON cb.BinCode=CAST(bd.BinCodeAsString AS INT)
LEFT JOIN DWH.dbo.Dim_Country con	
ON cb.CountryID=con.CountryID
LEFT JOIN DWH.dbo.Dim_CardType ct
ON ct.CardTypeID = cb.CardTypeID
LEFT JOIN DWH.dbo.Dim_BillingDepot dbd
ON dbd.DepotID = bd.DepotID
LEFT JOIN DWH.dbo.Fact_SnapshotCustomer fsc
ON bd.CID=fsc.RealCID
LEFT JOIN DWH.dbo.Dim_Range dr
ON dr.DateRangeID = fsc.DateRangeID
LEFT JOIN DWH.dbo.Dim_PlayerLevel dpl
ON dpl.PlayerLevelID = fsc.PlayerLevelID
WHERE CAST(bd.PaymentDate AS DATE)>=dateadd(mm, -6, DATEADD(dd, +1, eomonth(getdate())))
AND CONVERT(CHAR(8),PaymentDate,112) BETWEEN dr.FromDateID AND dr.ToDateID
AND dr.ToDateID>=convert(int,convert(varchar,cast(dateadd(mm, -6, DATEADD(dd, +1, eomonth(getdate()-1))) as date),112))
AND bd.DepotID IN (87,92)