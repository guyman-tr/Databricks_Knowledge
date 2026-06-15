SELECT * 
FROM BI_DB_dbo.External_UserApiDB_Customer_ExtendedUserField aa
JOIN BI_DB_dbo.External_UserApiDB_Dictionary_ExtendedUserValueType euvt 
ON euvt.ValueTypeID = aa.TypeId
-- WHERE FieldId IN (6,7,8)