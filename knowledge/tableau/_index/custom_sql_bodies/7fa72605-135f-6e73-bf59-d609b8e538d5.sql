SELECT
    cd.CID,
    tr.TranslationId,
    tr.RequestedAt,
    tr.CompletedAt,
    tr.Status,
    tr.Feedback,
    tr.SavedBy,
    tr.UpdatedAt,
    CAST(tr.RequestedAt AS DATE)                                        AS ReportDate,
    CASE
        WHEN tr.SavedBy IS NOT NULL
         AND tr.SavedBy <> 'None' THEN 1 ELSE 0
    END                                                                 AS IsSaved,
    CASE
        WHEN tr.Feedback IS NOT NULL
         AND tr.Feedback <> 'None' THEN 1 ELSE 0
    END                                                                 AS HasFeedback,
    DATEDIFF(SECOND, tr.RequestedAt, tr.CompletedAt) / 60.0            AS TranslationMinutes,
    t.Id                                                                AS TranslationDetailId,
    t.SourceDocumentId,
    t.DocumentFormat,
    t.SourceLanguage,
    t.DetectedLanguage,
    t.OverallConfidence,
    t.Version,
    t.Error,
CASE
    WHEN t.DetectedLanguage = 'ar'      THEN 'Arabic'
    WHEN t.DetectedLanguage = 'fa'      THEN 'Persian (Farsi)'
    WHEN t.DetectedLanguage = 'ko'      THEN 'Korean'
    WHEN t.DetectedLanguage = 'ms'      THEN 'Malay'
    WHEN t.DetectedLanguage = 'he'      THEN 'Hebrew'
    WHEN t.DetectedLanguage IS NOT NULL THEN t.DetectedLanguage
    WHEN t.SourceLanguage = 'ar'        THEN 'Arabic'
    WHEN t.SourceLanguage = 'fa'        THEN 'Persian (Farsi)'
    WHEN t.SourceLanguage = 'ko'        THEN 'Korean'
    WHEN t.SourceLanguage = 'ms'        THEN 'Malay'
    WHEN t.SourceLanguage = 'he'        THEN 'Hebrew'
    WHEN t.SourceLanguage IS NOT NULL   THEN t.SourceLanguage
    ELSE 'Unknown'
END AS Language,
    dm.FirstName || ' ' || dm.LastName AS RequestedBy
FROM main.bi_db.bronze_edocsdb_translation_translationrequests  tr
LEFT JOIN main.bi_db.bronze_edocsdb_translation_translations     t
    ON t.Id = tr.TranslationId
LEFT JOIN main.billing.bronze_etoro_backoffice_manager dm
    ON CAST(dm.ManagerID AS STRING) = tr.RequestedBy
left join main.billing.bronze_etoro_backoffice_customerdocument cd on cd.DocumentID=t.SourceDocumentId