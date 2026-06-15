SELECT * 
FROM [AZR-W-REAL-DB-2-BIDBUser].[UserApiDB].[Customer].[ExtendedUserField] aa
JOIN [AZR-W-REAL-DB-2-BIDBUser].[UserApiDB].Dictionary.ExtendedUserValueType euvt 
ON euvt.ValueTypeID = aa.TypeId
-- WHERE FieldId IN (6,7,8)