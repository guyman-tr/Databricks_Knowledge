SELECT DISTINCT rsk.ParameterID
	           ,rsk.Parameter
	           ,rsk.ParameterDescription
	           ,rsk.ParameterWeight
FROM( 
SELECT CAST([parameter_id] AS INT) AS 'ParameterID'
      ,CAST([parameter] AS VARCHAR(30)) AS 'Parameter'
      ,CAST([parameter_description] AS VARCHAR(255)) AS 'ParameterDescription'
	  ,CAST([parameter_weight] AS FLOAT) AS 'ParameterWeight'
FROM [eMoney_dbo].[emoney_customer_risk_assessment_classification_table]) rsk