select *
from BI_DB_dbo.BI_DB_M_ESMA_ProfitableClients_CFD_Last12Months
where StartDate=<[Parameters].[Parameter 1]>
and EndDate=<[Parameters].[Parameter 3]>