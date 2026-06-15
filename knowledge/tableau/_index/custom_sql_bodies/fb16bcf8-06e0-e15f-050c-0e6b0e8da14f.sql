SELECT ghgc.CID
        ,ISNULL(ghgc.Cash,0) + ISNULL(ghgc.Investment,0) +  ISNULL(ghgc.PnL,0) EquityCopy_StartDate
        ,ParentCID
  FROM general.etoroGeneral_History_GuruCopiers ghgc
  Join #PI p
  ON ghgc.ParentCID = p.CID
  WHERE  ghgc.partition_date = p.start_date