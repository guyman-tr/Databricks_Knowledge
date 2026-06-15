Select gc.CID, dc.UserName, gc.ParentCID, gc.ParentUserName, gc.StartCopy
From BI_DB.dbo.BI_DB_Guru_Copiers gc
Join DWH.dbo.Dim_Customer dc
on gc.CID = dc.RealCID
Where Timestamp = Cast(DateAdd(Day,-1,GetDate()) As Date)