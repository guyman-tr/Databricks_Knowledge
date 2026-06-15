SELECT
a.AlertID,
a.CID,
a.CreationDate as AlertCreationDate,
d.ModificationDate as DepositModificationDate,
r.RequestDate as RedeemRequestDate,
a.AlertType,
a.StatusType as AlertStatusType,
d.FundingTypeCalculated as 'DepositMOP',
r.RedeemReasonName
,r.RedeemStatus
,a.ResourceIdentifier
,d.DepositID
,r.RedeemID
,r.AmountOnRequest
,r.AmountOnClose

FROM #alert a
left join #deposit d ON d.AlertID = a.AlertID AND d.CID = a.CID AND d.RN_Closest = 1
left join #redeem r on r.AlertID = a.AlertID  and r.CID = a.CID and r.RN_Closest = 1
Where 
	d.FundingTypeCalculated = 'PWMB'