SELECT 
    msa.*, 
	 ROW_NUMBER() OVER ( PARTITION BY msa.MasterAccountCID, msa.AlertType  ORDER BY msa.AlertDate ) AS rn,
    CASE 
        WHEN EXISTS (
            SELECT 1
            FROM BI_DB_dbo.BI_DB_AML_BI_Alerts_New an
            WHERE an.CID = msa.CID
              AND (
                    -- Match MA002 to DEP001
                    (msa.AlertType = 'MA002: Lifetime Deposits > = 100K and RC High or Unacceptable (Multiple accounts)' 
                     AND an.AlertType = 'DEP001: Lifetime Gross Deposit >= 100K$ and RiskClassification = High')
					 OR 
					 -- Match MA001 to AML1001
					 (msa.AlertType = 'MA001: Lifetime Deposits > = 50K and RC High or Unacceptable (Multiple accounts)' 
                     AND an.AlertType = 'AML1001: High Risk Score and lifetime Depostits > 50K')

                    -- Match MA001-MA004 to ALL0001
                    OR (
                        msa.AlertType IN (
                            'MA003: Lifetime Depostits > 250K (Multiple accounts)',
                            'MA004: Lifetime Depostits > 500K (Multiple accounts)'
                        )
                        AND an.AlertType = 'ALL0001:All Alerts'
                    )
              )
        )
        THEN 1
        ELSE 0
    END AS Alert_Match_Flag
FROM BI_DB_dbo.BI_DB_AML_BI_Alerts_New_Master_SubAccount msa