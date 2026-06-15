SELECT ca.*, CONVERT(VARCHAR(19), created_at, 112) as CreatedDate,
CONVERT(VARCHAR(19), updated_at, 112) as UpdatedCaseDate
FROM [dbo].[BI_DB_ComplyAdvantage_Results] ca
WHERE CONVERT(VARCHAR(19), created_at, 112)>='2024-01-01'