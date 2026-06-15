SELECT
      c.RealCID,
      MAX(CASE WHEN cr.DisplayName = 'AFC AMOP'
               AND ost.DisplayName <> 'Completed'
        THEN 1 ELSE 0 END) AS AMOPGap_Pending
  
  FROM main.bi_db.bronze_compliancestatedb_compliance_customerrequirementsoverviewstatus ros
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked c ON c.GCID = ros.GCID
  JOIN main.compliance.bronze_compliancestatedb_compliance_requirements cr ON cr.RequirementID = ros.RequirementID
  LEFT JOIN main.compliance.bronze_compliancestatedb_dictionary_complianceoverviewstatus ost ON ost.OverviewStatusID = ros.OverviewStatusID
  where cr.DisplayName = 'AFC AMOP'
  group by  c.RealCID