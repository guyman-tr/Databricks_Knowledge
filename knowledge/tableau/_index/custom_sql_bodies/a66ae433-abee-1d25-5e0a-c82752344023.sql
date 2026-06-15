SELECT
    distinct c.RealCID,
    cr.DisplayName as GapName,
    ost.DisplayName as GapStatus,
    ros.Occurred,
    ros.OccurredEnd,
    sr.StatusReason,
    row_number() OVER (PARTITION BY ros.GCID ORDER BY ros.Occurred DESC) AS RowNumDESC
  FROM
    main.bi_db.bronze_compliancestatedb_compliance_customerrequirementsoverviewstatus ros
    join  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked c on c.GCID=ros.GCID
    JOIN main.compliance.bronze_compliancestatedb_compliance_requirements cr ON cr.RequirementID = ros.RequirementID
    left join main.compliance.bronze_compliancestatedb_dictionary_complianceoverviewstatus ost on ost.OverviewStatusID=ros.OverviewStatusID
    left  join main.compliance.bronze_compliancestatedb_dictionary_compliancestatusreason sr on sr.StatusReasonID=ros.StatusReasonID