Select    
    a.ExecutionID as ExecutionID_userexecution,
    a.ID as ID_userexecution,
    a.GCID AS GCID_userexecution,
    a.CID AS CID_userexecution,
    a.ExecutionTypeID AS ExecutionTypeID_userexecution,
    f_a.name as ExcecutionType_userexecution,
    a.ExecutionStatusID as ExecutionStatusID_userexecution,
    e_a.name as executionStatus_userexecution,
    a.ExecutionStatusReasonID as ExecutionStatusReasonID_userexecution,
    d_a.name as executionStatusReason_userexecution,
    g_a.name as EndProcessStatus_userexecution,
    a.CreatedDate as CreatedDate_userexecution,
    a.UpdatedDate as updatedDate_userexecution,
    a.BeginTime as BeginTime_userexecution,
    b.ProcessID as ProcessID_processexecution,       
    b.ProcessExecutionStatusID as ProcessExceutionStatusID_processexecution,
    e_b.name as ProcessExcecutionStatus_processexecution,
    b.ProcessExecutionStatusReasonID as ProcessExecutionStatusReasonID_processexecution,
    d_b.name as ProcessExecutionStatusReason_processexecution,
    b.ProcessExecutionOwnerID as processExecutionOwnerID_processexecution,
    b.CreatedDate as CreatedDate_processexecution,
    b.UpdateDate as updatedDate_processexecution,
    b.RetryCount as retryCount_processexecution,
    C.ConfigurationName as configurationName_processconfiguration,
    C.ProcessName as ProcessName_processconfiguration,
    C.ProcessExecutionTypeID as ProcessExecutionTypeID_processconfiguration,
    f_c.name as ProcessExecutionType_processconfiguration,
    pl.name as ClubLevel,
    pc.name as Country,
    dr.name as Regulation
From    
data.bronze_gdpr_gdpr_userexecution a
Inner Join data.bronze_gdpr_gdpr_processexecution b
        On a.ExecutionID=b.ExecutionID
Inner Join data.bronze_gdpr_gdpr_processconfiguration c
        On b.ProcessID=c.ProcessID
join main.experience.bronze_gdpr_dictionary_processexecutionstatusreason d_a
    on a.ExecutionStatusReasonID = d_a.ProcessExecutionStatusReasonID
join main.experience.bronze_gdpr_dictionary_processexecutiontype f_a
    on a.ExecutionTypeID = f_a.ProcessExecutionTypeID
join main.experience.bronze_gdpr_dictionary_processexecutionstatus e_a
    on a.ExecutionStatusID = e_a.ProcessExecutionStatusID
join main.experience.bronze_gdpr_dictionary_endprocessstatus g_a
    on a.EndProcessStatusID = g_a.EndProcessStatusID
join main.experience.bronze_gdpr_dictionary_processexecutionstatusreason d_b
    on b.ProcessExecutionStatusReasonID =d_b.ProcessExecutionStatusReasonID
join main.experience.bronze_gdpr_dictionary_processexecutionstatus e_b
    on b.ProcessExecutionStatusID = e_b.ProcessExecutionStatusID
join main.experience.bronze_gdpr_dictionary_processexecutiontype f_c
    on c.ProcessExecutionTypeID = f_c.ProcessExecutionTypeID
join main.general.bronze_etoro_customer_customer_masked cm
    on a.GCID = cm.gcid
join main.general.bronze_etoro_dictionary_playerlevel pl
    on cm.PlayerLevelID = pl.PlayerLevelID
join main.general.bronze_etoro_dictionary_country pc
    on cm.CountryID = pc.CountryID
join main.general.bronze_etoro_backoffice_customer boc
    on boc.cid = cm.CID
join main.general.bronze_etoro_dictionary_regulation dr
    on boc.RegulationID = dr.ID