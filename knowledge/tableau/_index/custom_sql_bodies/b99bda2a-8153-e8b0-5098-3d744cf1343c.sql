SELECT subquery.id,subquery.CID__c,subquery.name as ClubLevel
FROM (
    SELECT ass.id, ass.Claimed_Date__c, ass.CID__c, t1.CurrentTier, t1.TierChangeDate,pl.name,
           ROW_NUMBER() OVER (PARTITION BY ass.id, ass.CID__c ORDER BY t1.TierChangeDate DESC) as rn
    FROM main.crm.silver_crm_inventory_asset__c AS ass
    left JOIN bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club t1
    ON ass.CID__c = t1.CID
    left join  `main`.`dwh`.`gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` pl
    on pl.PlayerLevelID = t1.CurrentTier
    WHERE ass.Status__c IN ('Claimed','Claim Cancelled') AND t1.TierChangeDate <= ass.Claimed_Date__c
) AS subquery
where rn=1
ORDER BY CID__c,subquery.id,subquery.Claimed_Date__c