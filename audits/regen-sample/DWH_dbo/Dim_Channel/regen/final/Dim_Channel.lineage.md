# Lineage: DWH_dbo.Dim_Channel

## Source Objects

| # | Source Object | Source Type | Relationship | Evidence |
|---|--------------|-------------|-------------|----------|
| 1 | DWH_dbo.Ext_Dim_SubChannel_UnifyCode | External Table | Direct source — SP reads all rows via SELECT DISTINCT | SP_Dim_Channel: `FROM [DWH_dbo].Ext_Dim_SubChannel_UnifyCode` |
| 2 | DWH_dbo.SP_Dim_Channel | Stored Procedure | Writer SP — truncate-and-reload | SP body: `TRUNCATE TABLE [DWH_dbo].[Dim_Channel]; INSERT INTO ...` |
| 3 | DWH_dbo.SP_Dictionaries_DL_To_Synapse | Stored Procedure | Orchestrator — calls SP_Dim_Channel | `Exec [DWH_dbo].[SP_Dim_Channel]` at line 452 |

## Column Lineage

| # | DWH Column | Source Object | Source Column | Transform | Tier |
|---|-----------|--------------|--------------|-----------|------|
| 1 | SubChannelID | Ext_Dim_SubChannel_UnifyCode | SubChannelID | Passthrough (SELECT DISTINCT) | Tier 2 — SP_Dim_Channel |
| 2 | Channel | Ext_Dim_SubChannel_UnifyCode | Channel | Passthrough (SELECT DISTINCT) | Tier 2 — SP_Dim_Channel |
| 3 | SubChannel | Ext_Dim_SubChannel_UnifyCode | SubChannel | Passthrough (SELECT DISTINCT) | Tier 2 — SP_Dim_Channel |
| 4 | Organic/Paid | — (computed) | — | CASE: Channel IN ('Friend Referral','Direct','SEO') → 'Organic'; SubChannel = 'Google Brand' → 'Organic'; ELSE 'Paid' | Tier 2 — SP_Dim_Channel |
| 5 | InsertDate | — (computed) | — | GETDATE() at load time | Tier 2 — SP_Dim_Channel |
| 6 | UpdateDate | — (computed) | — | GETDATE() at load time | Tier 2 — SP_Dim_Channel |
