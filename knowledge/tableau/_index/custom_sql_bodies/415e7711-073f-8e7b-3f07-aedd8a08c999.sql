SELECT tt.ID 
      ,ff.CID
      ,ff.ActivitySubType
      ,ff.CreatedDate
      ,ff.etr_ym
      ,ff.HasAttachment
      ,ff.HasMentions
      ,ff.HasTags
      ,ff.Text_message  
       ,INT(CASE WHEN UPPER(ff.LanguageCode) IN ('zh-CN','zh-TW','zh-tw','zh-cn') THEN LENGTH(REPLACE(ff.Text_message, ' ', ''))*2/3
                ELSE (LENGTH(ff.Text_message) - LENGTH(REPLACE(ff.Text_message, ' ', '')) + 1) END) AS MessageWordNum    
      ,CONCAT_WS(', ', 
        CASE WHEN res2['educational'] = '1' THEN 'educational' ELSE NULL END,
        CASE WHEN res2['fundamental_or_macro_analysis'] = '1' THEN 'fundamental_or_macro_analysis' ELSE NULL END,
        CASE WHEN res2['informative'] = '1' THEN 'informative' ELSE NULL END,
        CASE WHEN res2['pop_weighted_avg_rel'] = '1' THEN 'pop_weighted_avg_rel' ELSE NULL END,
        CASE WHEN res2['self_promotion'] = '1' THEN 'self_promotion' ELSE NULL END,
        CASE WHEN res2['support'] = '1' THEN 'support' ELSE NULL END,
        CASE WHEN res2['technical_analysis'] = '1' THEN 'technical_analysis' ELSE NULL END
    ) AS Feed_Rate
FROM ml.ml_output_models_feed_gpt_all_tags14 tt
JOIN main.bi_output.bi_output_customer_social_social_feed ff  ON tt.ID = ff.ID
inner join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON dc.RealCID = ff.CID AND dc.IsValidCustomer =1
LATERAL VIEW inline(array(tt.res2)) res2 
where ff.ActivityType = 'Post'
AND ff.IsLast =1