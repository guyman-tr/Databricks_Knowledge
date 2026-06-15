SELECT 
    aa.billing_transfer_cid, 
	aa.Platform_,
    SUM(CASE WHEN billing_transfer_trans_status_id = 10 THEN 1 ELSE 0 END) AS num_success_OB_deposit,
    SUM(CASE WHEN billing_transfer_trans_status_id IN (1,2,3,4,5,6,7,8,9) THEN 1 ELSE 0 END) AS num_un_success_OB_attemp,
    MAX(aa.Country) AS Country
FROM (
    SELECT 
        mdt.AccountID,
        p.CID AS billing_transfer_cid,
        mdt.ClubTxDate AS Club,
        mda.Country AS Country,
        p.ModificationDate AS billing_transfer_modification_date,
        p.CreateDate AS billing_transfer_create_date,
        p.TransferStatusID AS billing_transfer_trans_status_id,
        CASE 
            WHEN LEFT(p.ExReferenceID, 2) = 'TZ' THEN 'Volt'
            WHEN LEFT(p.ExReferenceID, 2) = 'TK' THEN 'Tink'
            ELSE 'Other'
        END AS Platform_
    FROM 
        eMoney_dbo.eMoney_Dim_Account mda WITH (NOLOCK)
        INNER JOIN BI_DB_dbo.External_MoneyTransfer_Billing_Transfers p 
            ON mda.CID = p.CID
        LEFT JOIN eMoney_dbo.eMoney_Dim_Transaction mdt WITH (NOLOCK)
            ON LOWER(p.ExReferenceID) = LOWER(mdt.ReferenceNumber)
            AND mdt.TxStatusID = 2
            AND mdt.TxTypeID = 7
            AND mdt.HolderAmount <> 0
    WHERE 
        mda.IsValidETM = 1 
        AND mda.GCID_Unique_Count = 1
and mda.Region IN  ('Spain', 'North Europe', 'Russian', 'German', 'UK', 'French', 'Eastern Europe', 'Italian')
) aa 
GROUP BY 
    aa.billing_transfer_cid, aa.Platform_