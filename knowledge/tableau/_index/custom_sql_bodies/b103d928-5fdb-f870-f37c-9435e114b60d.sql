SELECT
 cd.RequestDate,
 cd.ModificationDate,
 cd.CID,
 cd.WithdrawID,
 cd.Club,
 cd.Country,
 cd.GuruStatusName,
 cd.Amount_Withdraw,
 cd.CashoutReason,
 CASE WHEN cd.Club  NOT IN ('Platinum', 'Platinum Plus','Diamond') THEN 0 ELSE 1 END AS 'Club Ind',
case when cd.Country NOT IN ('United States') THEN 0 ELSE 1 END AS 'USA Ind',
 case WHEN GuruStatusName NOT IN ('Rising Star' ,'Champion' ,'Elite','Elite Pro') THEN 0 ELSE 1 END 'PI Ind',
 MAX(Amount_Withdraw) AS 'MaxAmountWithdraw',
 max(Fee) as 'CashoutFee'

 FROM (
		 SELECT fbw.*,
		dpl.Name 'Club',
		dc.Name 'Country',
		dgs.GuruStatusName,
		cr.Name as 'CashoutReason'
		FROM  DWH..Fact_BillingWithdraw fbw
		INNER JOIN DWH..Fact_SnapshotCustomer fsc ON fsc.RealCID=fbw.CID and fsc.IsValidCustomer=1
		INNER JOIN DWH..Dim_Date dd ON dd.FullDate=CAST(fbw.RequestDate AS DATE)
		INNER JOIN DWH..Dim_Range dr ON fsc.DateRangeID = dr.DateRangeID AND dd.DateKey BETWEEN dr.FromDateID AND dr.ToDateID
		INNER JOIN DWH..Dim_PlayerLevel dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
		INNER JOIN DWH..Dim_Country dc ON fsc.CountryID = dc.CountryID
		INNER JOIN DWH..Dim_GuruStatus dgs ON dgs.GuruStatusID=fsc.GuruStatusID
                inner join DWH..Dim_CashoutReason cr on cr.CashoutReasonID=fbw.CashoutReasonID
		WHERE CashoutStatusID_Withdraw=3
		 AND CAST(fbw.RequestDate AS DATE)>=<[Parameters].[Parameter 1]> and CAST(fbw.RequestDate AS DATE)<=<[Parameters].[Parameter 2]>
 ) cd
 GROUP BY cd.RequestDate,
 cd.ModificationDate,
 cd.CID,
 cd.WithdrawID,
 cd.Club,
 cd.Country,
 cd.GuruStatusName,
 cd.Amount_Withdraw,
 cd.CashoutReason,
 CASE WHEN cd.Club  NOT IN ('Platinum', 'Platinum Plus','Diamond') THEN 1 ELSE 0 END,
case when cd.Country NOT IN ('United States') THEN 1 ELSE 0 END,
case WHEN GuruStatusName NOT IN ('Rising Star' ,'Champion' ,'Elite','Elite Pro') THEN 0 ELSE 1 end
 HAVING  MAX(Amount_Withdraw)>=30 and max(Fee)=0