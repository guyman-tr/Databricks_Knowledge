select  cast ([Reporting timestamp] as date)Date,[Trade Party 2 - ID] ,
Case when [Trade Party 2 - ID] = '8IBZUGJ7JPLH368JE346' then 'Goldman Sachs'
     when [Trade Party 2 - ID] = 'BFM8T61CT2L1QCEMIK50' then 'UBS' end as [LP]
,[Action],[Message Type],[Trade Party 1 - Regulatory Action Type 1],[GTR Validation Status], count (1) [COUNT]
From  [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[TR_DTCC_Silver_DTCC_P02501296]
Group By cast ([Reporting timestamp] as date),[Action],[Message Type],[Trade Party 1 - Regulatory Action Type 1],
[Trade Party 2 - ID],[GTR Validation Status]


UNION

select  cast ([Reporting timestamp] as date)Date,[Trade Party 2 - ID] ,
Case when [Trade Party 2 - ID] = '8IBZUGJ7JPLH368JE346' then 'Goldman Sachs'
     when [Trade Party 2 - ID] = 'BFM8T61CT2L1QCEMIK50' then 'UBS' end as [LP]
,[Action],[Message Type],[Trade Party 1 - Regulatory Action Type 1],[GTR Validation Status], count (1) [COUNT]
From  [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[TR_DTCC_Silver_DTCC_P02501359]
Group By cast ([Reporting timestamp] as date),[Action],[Message Type],[Trade Party 1 - Regulatory Action Type 1],
[Trade Party 2 - ID],[GTR Validation Status]


UNION

select  cast ([Reporting timestamp] as date)Date,[Trade Party 2 - ID] ,
Case when [Trade Party 2 - ID] = '8IBZUGJ7JPLH368JE346' then 'Goldman Sachs'
     when [Trade Party 2 - ID] = 'BFM8T61CT2L1QCEMIK50' then 'UBS' end as [LP]
,[Action],[Message Type],[Trade Party 1 - Regulatory Action Type 1],[GTR Validation Status], count (1) [COUNT]
From  [SYNAPSE-DWH-PROD-SERVERLESS].[data_views].[dbo].[TR_DTCC_Silver_DTCC_P02501399]
Group By cast ([Reporting timestamp] as date),[Action],[Message Type],[Trade Party 1 - Regulatory Action Type 1],
[Trade Party 2 - ID],[GTR Validation Status]