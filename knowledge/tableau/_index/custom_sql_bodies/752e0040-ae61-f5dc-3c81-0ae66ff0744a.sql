select dc.RealCID
       ,CASE WHEN dc.CountryID=191 AND dc.RegisteredReal>='20250320' THEN 'Futures' ELSE 'CFD' END Product_Type
from DWH_dbo.Dim_Customer dc