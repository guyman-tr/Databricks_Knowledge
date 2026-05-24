# Cluster 24 brief — `BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel`

_Size: 2, intra-cluster weight: 10.0_
_Schema mix: {'BI_DB_dbo': 1, 'dbo': 1}_
_Edge sources: {'wiki': 10}_

## Top members (ranked by intra-cluster weight)

- `BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel` — w 10.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel.md)
- `dbo.V_CustomerAnswers` — w 10.0 (no wiki)

## Wiki §3.3 Common JOINs (top members)

### `BI_DB_dbo.UserApiDB_dbo_V_CustomerAnswers_Range_KYC_Panel`

| Join To | Join Condition | Purpose |
|---|---|---|
| BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data | GCID, QuestionId | Merge new answers into the persistent row-level KYC store |
| DWH_dbo.Dim_Customer | GCID | Enrich with customer demographics for the KYC Panel |

## KPI views in this cluster

## Genie spaces overlapping this cluster

## Out-cluster neighbors (likely cross-domain candidates)

- `BI_DB_dbo.BI_DB_KYC_Questions_Answers_Row_Data` — outflow weight 1.0
- `DWH_dbo.Dim_Customer` — outflow weight 1.0
- `Dim_Customer.GCID` — outflow weight 1.0
