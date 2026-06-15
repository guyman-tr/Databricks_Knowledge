SELECT 
    mdt.TxStatusModificationDate, 
    mdt.TxStatusModificationTime, 
    mdt.TxStatusModificationDateID, 
    mdt.CID, 
    f.PlayerLevelID AS PlayerLevelID_At_Tx_Date,
    dpl.Name AS ClubAtTxDate, 
    mdt.AccountSubProgram, 
    mdt.USDAmountApprox, 
    mdt.AccountProgramID,
mdt.AccountSubProgramID, 
	mdt.TxTypeID
FROM eMoney_dbo.eMoney_Dim_Transaction mdt
JOIN (
    SELECT  
        dr.FromDateID, 
        dr.ToDateID, 
        fsc.DateRangeID, 
        fsc.RealCID, 
        fsc.PlayerLevelID
    FROM DWH_dbo.Fact_SnapshotCustomer fsc
    INNER JOIN DWH_dbo.Dim_Range dr
        ON fsc.DateRangeID = dr.DateRangeID
) f 
    ON mdt.CID = f.RealCID 
    AND mdt.TxStatusModificationDateID BETWEEN f.FromDateID AND f.ToDateID
JOIN DWH_dbo.Dim_PlayerLevel dpl 
    ON f.PlayerLevelID = dpl.PlayerLevelID
WHERE mdt.IsValidETM = 1 
  AND mdt.IsTxSettled = 1 
  AND mdt.TxTypeID IN (1, 2, 3, 4)
  AND mdt.USDAmountApprox<>0 
  AND mdt.TxStatusModificationDateID >= 20240601