SELECT
dc.*,
vl.vl3_first_ts as VerificationLevel3Date,
vl2_first_ts as VerificationLevel2Date, dc2.VerificationLevelID
FROM
  6m_cohort dc
  left join verification_vl3vl2_ts vl on dc.RealCID=vl.CID
  join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc2 on dc2.RealCID=dc.RealCID
WHERE
dc.IsDepositor=1 AND vl2_first_ts IS NOT NULL
  AND dc.FirstDepositDate >= vl.vl2_first_ts
  AND (
   vl.vl3_first_ts IS NULL
    OR dc.FirstDepositDate < vl.vl3_first_ts
  )
  and dc2.PlayerStatusID not in (2,4)
  and dc2.IsValidCustomer=1