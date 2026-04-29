# Review Needed: DWH_dbo.Dim_Channel

## Items for Human Review

### 1. No Upstream Wiki Available

No upstream wiki was found for `Ext_Dim_SubChannel_UnifyCode` or the production source `fiktivo.dbo.tblaff_Affiliates`. All 6 columns are Tier 2 (grounded in SP code). If an upstream wiki is created for the affiliate system source tables, column descriptions should be upgraded to Tier 1 with verbatim inheritance.

### 2. Social Organic Classification Anomaly

SubChannelID=49 ("Social Organic") is classified as "Paid" despite its name suggesting organic. This is because the SP_Dim_Channel CASE logic only checks Channel-level values ('Friend Referral', 'Direct', 'SEO') and the specific SubChannel='Google Brand' — it does not check for "Social Organic" as a SubChannel name. Confirm with the marketing team whether this is intentional or a classification gap.

### 3. ETL Chain Upstream Traceability

The resolution summary lists `DWH_staging.fiktivo_dbo_tblaff_Affiliates` as an unresolved upstream reference. The actual SP code reads from `Ext_Dim_SubChannel_UnifyCode`, which is populated by `SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse`. The full chain from fiktivo production to the external table could not be fully traced in the SSDT repo. A reviewer with affiliate-system knowledge should validate the complete lineage path.

### 4. Alerting Mechanism — Email SP Commented Out

The SP_Dim_Channel email alerting block (`EXEC msdb.dbo.sp_send_dbmail`) is commented out in the current SSDT code. Confirm whether channel unmapped alerts are still operational via a different mechanism or if this monitoring has been retired.

### 5. Phase 10 (Atlassian) Skipped

Jira/Confluence search was not performed (regen harness mode). If business context exists in Atlassian for the channel/sub-channel mapping taxonomy, it should be incorporated in a future revision.
