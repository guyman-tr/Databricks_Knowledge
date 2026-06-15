with cids AS (
select
  dc.CID AS RealCID,
  dc.Group,
  CASE WHEN cm.PlayerStatusID IN (2,4) or 
  cm.PendingClosureStatusID in (2,3) or 
  dc.`Acc closed/Out of scope` in ('Outside of scope','Acc closed') then 1 else 0 end as AccClosedOutofScope
from  main.bi_output.edd_groups  dc
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked cm on cm.RealCID=dc.CID
),

 ProofOfIncome AS (
SELECT
  p.RealCID, 
  CASE 
    WHEN cdt.DocumentTypeID IS NULL THEN 'Undefined'
    WHEN dtype.Name = 'Not Accepted' THEN 'Rejected'
    WHEN (dtype.Name = 'Proof of Income'  AND dtype1.Name in ('Bank Statement','Bank Statement','Tax Declaration','PaySlip','Inheritance','Other','Financial Statements'))
 or ( dtype.Name in ('Proof of MOP') AND dtype1.Name in ('Bank Statement','Bank Statement','Tax Declaration','PaySlip','Inheritance','Other','Financial Statements'))THEN 'Accepted'
    ELSE 'OtherDocType' END AS ProofOfIncomeResults
FROM cids p
JOIN main.billing.bronze_etoro_backoffice_customerdocument cd ON cd.CID = p.RealCID
LEFT JOIN main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype cdt ON cdt.DocumentID = cd.DocumentID
LEFT JOIN main.general.bronze_etoro_dictionary_documenttype dtype ON dtype.DocumentTypeID = cdt.DocumentTypeID
LEFT JOIN main.general.bronze_etoro_dictionary_documentclassification dtype1 ON dtype1.DocumentClassificationID = cdt.DocumentClassificationID
WHERE cd.SuggestedDocumentTypeID IN (7) -- Proof of Income
or cd.SuggestedDocumentTypeID=8 
--AND cd.DateAdded >>= '2025-01-27'
),

PivotedResultsPOI AS (
SELECT 
    p.RealCID,
    -- ProofOfIncome counts
    COUNT(CASE WHEN p.ProofOfIncomeResults = 'Accepted' THEN 1 END) AS ProofOfIncome_Accepted,
    COUNT(CASE WHEN p.ProofOfIncomeResults = 'Rejected' THEN 1 END) AS ProofOfIncome_Rejected,
    COUNT(CASE WHEN p.ProofOfIncomeResults = 'Undefined' THEN 1 END) AS ProofOfIncome_Undefined,
    COUNT(CASE WHEN p.ProofOfIncomeResults = 'OtherDocType' THEN 1 END) AS ProofOfIncome_Other,
     COUNT(p.RealCID) AS  ProofOfIncome_TotalUploads
FROM ProofOfIncome p
GROUP BY p.RealCID),

SelfieLiveliness AS (
SELECT
  DISTINCT p.RealCID,
   CASE 
    WHEN cdt.DocumentTypeID IS NULL THEN 'Undefined'
    WHEN dtype.Name = 'Not Accepted' THEN 'Rejected'
    WHEN dtype.Name IN ('Selfie Motion','Selfie', 'SelfieLiveliness') THEN 'Accepted'
    ELSE 'OtherDocType' 
  END AS SelfieLivelinessResults
FROM cids p
JOIN main.billing.bronze_etoro_backoffice_customerdocument cd ON cd.CID = p.RealCID
LEFT JOIN main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype cdt ON cdt.DocumentID = cd.DocumentID
LEFT JOIN main.general.bronze_etoro_dictionary_documenttype dtype ON dtype.DocumentTypeID = cdt.DocumentTypeID
WHERE cd.SuggestedDocumentTypeID in (15,18,23) -- SelfieLiveliness
--AND cd.DateAdded >>= '2025-01-27'
),

PivotedResultsSelfiliveliness AS (
SELECT 
    p.RealCID,
    -- SelfieLiveliness counts
    COUNT(CASE WHEN p.SelfieLivelinessResults = 'Accepted' THEN 1 END) AS SelfieLiveliness_Accepted,
    COUNT(CASE WHEN p.SelfieLivelinessResults = 'Rejected' THEN 1 END) AS SelfieLiveliness_Rejected,
    COUNT(CASE WHEN p.SelfieLivelinessResults = 'Undefined' THEN 1 END) AS SelfieLiveliness_Undefined,
    COUNT(CASE WHEN p.SelfieLivelinessResults = 'OtherDocType' THEN 1 END) AS SelfieLiveliness_Other,
    COUNT(p.RealCID) AS SelfieLiveliness_TotalUploads
FROM SelfieLiveliness p
GROUP BY p.RealCID)


SELECT
  cids.*,
  s.ProofOfIncome_TotalUploads,
  s.ProofOfIncome_Accepted,
  s.ProofOfIncome_Rejected,
  s.ProofOfIncome_Undefined,
  s.ProofOfIncome_Other,
  p.SelfieLiveliness_TotalUploads,
  p.SelfieLiveliness_Accepted,
  p.SelfieLiveliness_Rejected,
  p.SelfieLiveliness_Undefined,
  p.SelfieLiveliness_Other,
  CASE 
    WHEN SelfieLiveliness_Accepted > 0 AND ProofOfIncome_Accepted > 0 THEN 1 
    ELSE 0 
  END AS EDDCompleted
FROM cids cids
LEFT JOIN PivotedResultsPOI s ON s.RealCID = cids.RealCID
LEFT JOIN PivotedResultsSelfiliveliness p ON p.RealCID = cids.RealCID