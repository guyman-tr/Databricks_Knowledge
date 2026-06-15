Select 
	ISNULL(a.CreateDate,ISNULL(d.ClassificationDate,v.UploadDate)) as Date
	,a.[ATtasks(All)]
	,d.[DocsSentToVendors (All) - #ofCIDs]
	,v.[DocUploads (AT Eligible) - #ofCIDs]
FROM
	#at a
FULL OUTER JOIN
	#docsup d on d.ClassificationDate = a.CreateDate
FULL OUTER JOIN
	#vendors v on COALESCE(a.CreateDate,d.ClassificationDate) = v.UploadDate