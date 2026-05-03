# Lineage: BI_DB_dbo.BI_DB_Social_Activity

## Source Objects

| # | Source Object | Source Type | Schema | Database | Relationship |
|---|--------------|-------------|--------|----------|-------------|
| 1 | Streams_dbo_Entries_Social_Activity_Daily | External Table | BI_DB_dbo | sql_dp_prod_we | Primary data source — social feed entries from Streams microservice |
| 2 | Dim_Customer | Table | DWH_dbo | sql_dp_prod_we | Customer identity lookup — resolves Username to RealCID |
| 3 | SP_Social_Activity | Stored Procedure | BI_DB_dbo | sql_dp_prod_we | Writer SP — daily DELETE+INSERT ETL |
| 4 | SP_Create_External_Streams_dbo_Entries_Range | Stored Procedure | BI_DB_dbo | sql_dp_prod_we | Helper — creates external table for date-ranged Streams data |
| 5 | BI_DB_Social_Activity_Type | Table | BI_DB_dbo | sql_dp_prod_we | Lookup — ActionTypeID to ActionName mapping |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|--------|--------------|---------------|-----------|------|
| 1 | ActionTypeID | Streams_dbo_Entries_Social_Activity_Daily | TypeName | CASE: Discussion→1, Comment→2 (hardcoded), Like→3 (hardcoded), Share→4 (hardcoded), else→5 | Tier 2 |
| 2 | ActionDate | Streams_dbo_Entries_Social_Activity_Daily | OccurredAt | Passthrough (renamed) | Tier 2 |
| 3 | PostID | Streams_dbo_Entries_Social_Activity_Daily | Id / RootId / SharedEntryId | Posts→Id, Comments/Likes→RootId, Shares→SharedEntryId | Tier 2 |
| 4 | CommentID | Streams_dbo_Entries_Social_Activity_Daily | Id / ParentId | Comments→Id, Likes on comments→ParentId, else NULL | Tier 2 |
| 5 | Username | Streams_dbo_Entries_Social_Activity_Daily | Username | SUBSTRING([Username], 2, 50) — strips leading character | Tier 2 |
| 6 | RealCID | DWH_dbo.Dim_Customer | RealCID | Dim-lookup passthrough via Username JOIN | Tier 1 |
| 7 | MessageText | Streams_dbo_Entries_Social_Activity_Daily | MessageBody | Passthrough (renamed); NULL for Likes and Shares | Tier 2 |
| 8 | MessageSize | Streams_dbo_Entries_Social_Activity_Daily | MessageBody | LEN(MessageBody); NULL for Likes and Shares | Tier 2 |
| 9 | MessageWordNum | Streams_dbo_Entries_Social_Activity_Daily | MessageBody | LEN(MessageBody) - LEN(REPLACE(MessageBody, ' ', '')) + 1; NULL for Likes and Shares | Tier 2 |
| 10 | ActionDateID | SP_Social_Activity | @dt parameter | CAST(CONVERT(varchar, @dt, 112) AS INT) — integer date key | Tier 2 |
| 11 | UpdateDate | SP_Social_Activity | — | GETDATE() — ETL execution timestamp | Tier 2 |
| 12 | ParentID | Streams_dbo_Entries_Social_Activity_Daily | ParentId | Passthrough (renamed) | Tier 2 |
| 13 | SubTypeName | Streams_dbo_Entries_Social_Activity_Daily | TypeName | Passthrough (renamed) | Tier 2 |
| 14 | MediaTypeID | Streams_dbo_Entries_Social_Activity_Daily | RichMediaScrapDataType | Passthrough (renamed) | Tier 2 |
| 15 | ActionID | — | — | IDENTITY(1,1) — auto-generated surrogate key | Tier 2 |
