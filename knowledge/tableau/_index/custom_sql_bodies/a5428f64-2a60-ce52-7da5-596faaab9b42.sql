WITH base AS (
  SELECT
    h.Id               AS AlertID,
    h.RiskScore,
    h.CreationDate,
    h.ModificationDate,
    d.Name             AS AlertType,
    ds.Name            AS StatusReason,
    dsc.Name           AS Alert_Status_Reason,
    st.Name            AS StatusType,
    ROW_NUMBER() OVER (PARTITION BY h.Id ORDER BY h.ModificationDate DESC) AS RN
  FROM main.billing.bronze_alertservicedb_alert_alert h
  LEFT  JOIN main.billing.bronze_alertservicedb_configuration_alerttemplate      a   ON h.TemplateID = a.Id
  LEFT  JOIN main.billing.bronze_alertservicedb_dictionary_alerttype             d   ON d.Id         = a.AlertTypeID
  LEFT JOIN main.billing.bronze_alertservicedb_configuration_alertstatus        ca  ON h.StatusID   = ca.Id
  LEFT JOIN main.billing.bronze_alertservicedb_dictionary_statustype            st  ON st.Id        = ca.StatusTypeID
  LEFT JOIN main.billing.bronze_alertservicedb_dictionary_statusreason          ds  ON ds.Id        = ca.StatusReasonID
  LEFT  JOIN main.billing.bronze_alertservicedb_configuration_reasontoclassification crs
             ON crs.StatusReasonId = ds.Id AND crs.StatusClassificationId = h.ClassificationID
  LEFT JOIN main.billing.bronze_alertservicedb_dictionary_statusclassification  dsc ON dsc.ID = crs.StatusClassificationId
  WHERE (
    CAST(h.ModificationDate AS DATE) >= '2026-01-01'
    OR CAST(h.CreationDate   AS DATE) >= '2026-01-01'
    OR CAST(h.FollowUpDate   AS DATE) >= '2026-01-01'
  )
)
SELECT * FROM base WHERE RN = 1