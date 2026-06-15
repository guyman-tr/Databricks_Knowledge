SELECT cc.Id,Dropped_Skills__c,  DATEADD(HOUR, 2, CreatedDate) AS CreatedDate FROM crm.silver_crm_livechattranscript cc
where Dropped_Skills__c is not null