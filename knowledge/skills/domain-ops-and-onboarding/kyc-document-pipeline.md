---
name: domain-ops-and-onboarding
description: "KYC document pipeline ג€” every step from customer file upload through AI-vendor classification through BackOffice manager decision through final approval / rejection. Anchors on five layers: (1) main.bi_output_stg.bi_output_operations_documentanalysis (5.55M rows, 37 cols ג€” the gold analytical layer with one row per uploaded document carrying upload_date / definition_date / document_type / suggested_document_type / vendor / vendor_reason / rejection_reason / is_rejected / minutes_to_definition / definition_sla_bucket / DocumentClassification / ManagerID / DesignatedRegulation / verification_level_id / ev_match_status_name / screening_status / client_age / region / country / language); (2) main.bi_output_stg.bi_output_operations_ops_ai_doc_verification_checks (5,702 rows, 7 cols ג€” joined via DocumentID, carrying AI_Outcome Approved/Rejected/Escalated + AI_Reason + CheckCodes comma-separated check codes + AI_DocumentType POI/POA + AI_ProcessedAt); (3) main.bi_output_stg.bi_output_operations_edocs_poa_poi_base (5,702 rows ג€” the proof-of-identity / proof-of-address checks base) + _edocs_poa_poi_checks_classified (11,145 rows ג€” same checks classified by check-code category); (4) the alert-history pair main.bi_output_stg.bi_output_operations_ai_doc_checking_alert_history (AI-doc check alert audit log) and main.bi_output_stg.bi_output_operations_docs_investigation_alert_history (manual-investigation alert audit log); (5) the OLTP-source pair main.billing.bronze_etoro_backoffice_customerdocument (8.78M active / 13.4M issued lifetime ג€” the actual file ledger, ManagerID = 0 = customer self-uploaded, partition columns etr_y INT / etr_ym STRING / etr_ymd DATE different from dashed-string convention elsewhere) + main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype (the BackOffice-confirmed document type that may override the AI's SuggestedDocumentTypeID). Plus the KYC-questionnaire layer at main.bi_output_stg.bi_output_operations_ops_kyc_answers (475M rows at Q-A grain ג€” one row per KYC question-answer pair, NOT per customer) + _ops_kyc_investigation_alert_history + the alternate source main.compliance.bronze_userapidb_kyc_answers. Document-vendor inventory (live April 2026): Onfido (228k / month, avg 85 min to definition ג€” dominant fast-lane), Sumsub (125k / month, avg 138 min), Au10tix and IDnow (small <200 / month), internal AI (~1.3k / month, sub-10-min), and EMPTY vendor (~287k / month = in-house KYC team manual handling ג€” empty does NOT mean missing data). Document types (live values): Proof of Identity, W-8BEN Form, Not Accepted (an explicit reject bucket), Proof of address (lowercase 'address'), TaxReport, Selfie Motion / SelfieLiveliness / Selfie (anti-spoofing), W9, Proof of Income (distinct from Proof of Identity), Client Forms, Translation, Credit Card, Proof of MOP, Corporate doc. SLA bucket values (live): 'ג‰₪ 1 hour' ~88% of definitions, '1ג€“4 hours', '4ג€“24 hours', '1ג€“3 days', '4ג€“7 days', '8+ days'."
triggers:
  - documentanalysis
  - bi_output_operations_documentanalysis
  - bi_output.bi_output_operations_documentanalysis
  - ops_ai_doc_verification_checks
  - ai_doc_verification_checks
  - ai_doc_checking_alert_history
  - docs_investigation_alert_history
  - edocs_poa_poi_base
  - edocs_poa_poi_checks_classified
  - ops_kyc_answers
  - kyc_answers
  - ops_kyc_investigation_alert_history
  - bronze_userapidb_kyc_answers
  - bronze_etoro_backoffice_customerdocument
  - bronze_etoro_backoffice_customerdocumenttodocumenttype
  - customerdocument
  - customerdocumenttodocumenttype
  - DocumentID
  - SuggestedDocumentTypeID
  - SuggestedDocumentSubTypeID
  - DocumentClassification
  - DocumentSizeActionTypeID
  - StorageID
  - SessionID
  - AiCheckID
  - AiReasoning
  - AI_Outcome
  - AI_Reason
  - CheckCodes
  - AI_DocumentType
  - definition_sla_bucket
  - minutes_to_definition
  - days_to_rejection
  - is_rejected
  - rejection_reason
  - vendor_reason
  - VendorProofOfIdentity
  - VendorProofOfAddress
  - ManagerID
  - ProofOfIdentity_Manager
  - ProofOfAddress_Manager
  - DesignatedRegulation
  - DesignatedRegulationID
  - Proof of Identity
  - Proof of address
  - W-8BEN Form
  - W-8BEN
  - W9
  - W-9
  - TaxReport
  - Proof of Income
  - Selfie Motion
  - SelfieLiveliness
  - Selfie
  - Not Accepted
  - Client Forms
  - Corporate doc
  - Proof of MOP
  - POI
  - POA
  - SOF
  - Au10tix
  - Onfido
  - Sumsub
  - IDnow
  - Obsolete
  - Accounting flag
  - upload_date
  - definition_date
  - DocumentType
  - SuggestedDocumentType
sample_questions:
  - "How many POI documents were uploaded last week?"
  - "Average minutes-to-definition by vendor in April 2026"
  - "Top 10 rejection reasons for POA documents"
  - "What % of documents went to ג‰₪ 1 hour SLA bucket last month?"
  - "How many docs did the AI escalate to a manager last week?"
  - "Which managers approved the most POI documents in Q1?"
  - "Show me the AI check codes for a specific DocumentID"
  - "What does 'Not Accepted' document type mean ג€” is it a reject bucket?"
  - "Why is `vendor` empty on 50% of rows ג€” is the data missing?"
  - "How many active documents (non-Obsolete) per customer (top 20)?"
  - "What's the difference between SuggestedDocumentTypeID and DocumentClassification?"
  - "Show me POA rejection rate by country in last 30 days"
  - "How big is kyc_answers at the Q-A grain ג€” and how do I count distinct customers from it?"
  - "How do I find documents where the AI was wrong and a manager re-classified the type?"
required_tables:
  - main.bi_output_stg.bi_output_operations_documentanalysis
  - main.bi_output.bi_output_operations_documentanalysis
  - main.bi_output_stg.bi_output_operations_ops_ai_doc_verification_checks
  - main.bi_output_stg.bi_output_operations_ai_doc_checking_alert_history
  - main.bi_output_stg.bi_output_operations_docs_investigation_alert_history
  - main.bi_output_stg.bi_output_operations_edocs_poa_poi_base
  - main.bi_output_stg.bi_output_operations_edocs_poa_poi_checks_classified
  - main.bi_output_stg.bi_output_operations_ops_kyc_answers
  - main.bi_output_stg.bi_output_operations_ops_kyc_investigation_alert_history
  - main.compliance.bronze_userapidb_kyc_answers
  - main.billing.bronze_etoro_backoffice_customerdocument
  - main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype
domain_tags:
  - kyc
  - documents
  - poi
  - poa
  - sof
  - ops
  - sla
  - ai-verification
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-28"
---

# KYC document pipeline

Every customer document ג€” passport, utility bill, W-8BEN, selfie ג€” flows through the same pipeline: customer uploads, AI vendor classifies + checks, BackOffice manager confirms or overrides, decision date stamped, SLA bucket assigned, rejection-reason recorded (if rejected). `documentanalysis` is the analytical denormalisation; the source-of-truth is `billing.bronze_etoro_backoffice_customerdocument`.

## When to Use

Load for questions about:

- Document upload counts / decision times / SLA buckets
- AI-vendor outcomes vs BackOffice manager overrides
- Vendor-by-vendor performance (Onfido vs Sumsub vs in-house)
- Rejection reasons / reject rate by country / regulation / vendor
- Per-DocumentID drill-down ("why was document X rejected?")
- KYC questionnaire responses (`kyc_answers` at Q-A grain)
- Document-investigation alert audit (`docs_investigation_alert_history`)

Do NOT load for:

- VL0ג†’VL3 onboarding timing ג€” see [`electronic-verification-and-registration-funnel.md`](electronic-verification-and-registration-funnel.md)
- Risk alert queue / OPS pending tickets ג€” see [`ops-portal-and-alerts.md`](ops-portal-and-alerts.md)
- AML sanctions screening methodology ג€” `../domain-compliance-and-aml/SKILL.md`
- Customer master-record attributes ג€” `../domain-customer-and-identity/customer-master-record.md`

## Scope

In scope: the 7-table document analytical / decision layer plus the 2 OLTP-source customerdocument tables plus the 3-table KYC-answers Q-A layer; the document-vendor inventory (Onfido / Sumsub / Au10tix / IDnow / internal AI / in-house empty); document types (POI, POA, SOF, W-8BEN, W9, TaxReport, Selfie, Selfie Motion, SelfieLiveliness, Proof of Income, Client Forms, Translation, Credit Card, Proof of MOP, Corporate doc, Not Accepted); SLA bucket scheme; the SuggestedDocumentTypeID-vs-DocumentClassification dual; the ManagerID = 0 self-upload convention; the Obsolete soft-delete; the Accounting unused-flag; partition convention on `billing.bronze_etoro_backoffice_customerdocument` (etr_y INT / etr_ym STRING / etr_ymd DATE).

Out of scope: AML sanctions / PEP screening methodology; EV vendor routing (Trulioo / GBG / etc. live in EV cohort table); the customer master record beyond what's denormalised onto these tables; OPS alert queue management; CS-case prioritisation.

Last verified: 2026-05-28

## Critical Warnings

1. **Tier 1 ג€” Two parallel document-type fields with different semantics.** `SuggestedDocumentTypeID` on `bronze_etoro_backoffice_customerdocument` = AI-vendor's classification at upload time. `DocumentClassification` on `documentanalysis` (joined via `CustomerDocumentToDocumentType`) = BackOffice-confirmed final classification. They diverge on ~5-15% of documents where the AI was wrong. For "how many POI uploads" use SuggestedDocumentTypeID; for "how many POIs in our records" use DocumentClassification.

2. **Tier 1 ג€” `vendor IS NULL` (or empty string) on `documentanalysis` means in-house KYC team handled the document ג€” NOT missing data.** April 2026 sample: 287k documents (~46%) have empty `vendor`. This is the in-house KYC operations team manually reviewing ג€” typically more complex cases, manager-uploaded docs, or escalations. The `vendor IS NULL` cohort has the SLOWEST avg `minutes_to_definition` (~445 min vs Onfido's 85 min) which reflects the complexity, not a vendor performance issue.

3. **Tier 1 ג€” `kyc_answers` is 475M rows at the question-answer grain.** One customer typically has dozens of Q-A pairs (one per KYC question on the form). For "how many customers answered the income question" you must `COUNT(DISTINCT CID) WHERE KycQuestionId = <income_q_id>`. For per-customer rollups, JOIN to `registrationfunnel` (one row per customer) and avoid the explode.

4. **Tier 1 ג€” `Not Accepted` is a `document_type` value, not a status.** April 2026: 135k documents have `document_type = 'Not Accepted'`. This is a residual bucket for documents that couldn't be classified into a real type ג€” typically blank pages, irrelevant files, or mis-uploads. Filter it out when answering "how many real documents" but include it when answering "how many uploads".

5. **Tier 2 ג€” `is_rejected = 1` and `rejection_reason IS NOT NULL` are the rejection signals on documentanalysis.** `vendor_reason` is the EXTERNAL vendor's rejection text (Onfido / Sumsub's own taxonomy); `rejection_reason` is the BackOffice agent's reason (eToro's internal taxonomy). They may differ on the same document. For internal reporting prefer `rejection_reason`; for vendor-vs-vendor benchmarking use `vendor_reason`.

6. **Tier 2 ג€” `days_to_rejection` is NULL for non-rejected documents, NOT 0.** Use `WHERE is_rejected = 1` before averaging `days_to_rejection`. The corresponding "time to approval" is computed from `minutes_to_definition` for any document regardless of outcome.

7. **Tier 2 ג€” `Obsolete = 1` is a soft-delete on `bronze_etoro_backoffice_customerdocument` (superseded, fraudulent, or invalidated).** Only 249 of 8.78M docs are obsolete. For "current state of documents" filter `WHERE Obsolete = 0 OR Obsolete IS NULL`. The `Accounting` flag is a planned-but-never-activated feature (0 on all 8.78M rows) ג€” ignore it.

8. **Tier 2 ג€” `ManagerID` ambiguity.** On `bronze_etoro_backoffice_customerdocument` and `documentanalysis`, `ManagerID = 0` means customer self-uploaded (via portal / API); `> 0` means a BackOffice agent uploaded (rare, ~0.1% of modern docs ג€” from fax / email / Zendesk). Not to be confused with `ProofOfIdentity_Manager` / `ProofOfAddress_Manager` on `registrationfunnel`, which name the agent who APPROVED, not uploaded.

9. **Tier 2 ג€” `bronze_etoro_backoffice_customerdocument` partition columns differ from other UC tables.** `etr_y` is INT (not STRING), `etr_ym` is STRING, `etr_ymd` is DATE (not STRING). Filter pattern: `WHERE etr_y = 2026 AND etr_ymd = DATE'2026-05-27'`. String-format `WHERE etr_y = '2026'` works via implicit cast; numeric `WHERE etr_ymd > 20260501` does NOT.

10. **Tier 2 ג€” `IsDocumentApprovalAutomatic` on `registrationfunnel` is 1 when AI auto-approved without manager review.** Most POIs from Onfido in EV-eligible countries auto-approve. Manual-review POIs always have it 0. Useful for "what % of POIs needed a human?" ג€” but the actual approval-time SLA is captured in `ProofOfIdentity_SLAMinutes`, not in the auto-approve flag.

11. **Tier 3 ג€” `definition_sla_bucket` values use special Unicode characters: `ג‰₪ 1 hour` (less-than-or-equal sign), `1ג€“4 hours` / `4ג€“24 hours` / `1ג€“3 days` / `4ג€“7 days` (en-dash, not hyphen-minus).** When writing query filters, copy the exact value or use `LIKE`:  `WHERE definition_sla_bucket LIKE '%1 hour%'`. Don't hand-type the special chars.

12. **Tier 3 ג€” `bi_output_stg.bi_output_operations_documentanalysis` is the dev/staging table; `bi_output.bi_output_operations_documentanalysis` is the published copy.** They usually match, but if you see drift, the `bi_output` one (no `_stg` suffix) is the consumer-facing version.

13. **Tier 3 ג€” `ops_ai_doc_verification_checks` only has 5,702 rows ג€” it's the LATEST AI verdict per recent document, not historical.** For full AI-check history use `ai_doc_checking_alert_history`. For point-in-time AI verdict snapshots, prefer joining via DocumentID from `bronze_etoro_backoffice_customerdocument.AiCheckID`.

## Canonical query patterns

```sql
-- Decision SLA distribution last month
SELECT definition_sla_bucket, COUNT(*) AS n
FROM main.bi_output_stg.bi_output_operations_documentanalysis
WHERE upload_date >= TIMESTAMP'2026-04-01'
  AND upload_date < TIMESTAMP'2026-05-01'
GROUP BY definition_sla_bucket
ORDER BY n DESC;

-- Vendor performance comparison (excludes in-house empty-vendor rows)
SELECT vendor, COUNT(*) AS uploads,
       AVG(minutes_to_definition) AS avg_min_to_def,
       SUM(is_rejected) * 1.0 / COUNT(*) AS reject_rate
FROM main.bi_output_stg.bi_output_operations_documentanalysis
WHERE upload_date >= TIMESTAMP'2026-04-01'
  AND vendor IS NOT NULL AND vendor <> ''
GROUP BY vendor
ORDER BY uploads DESC;

-- Where did the AI disagree with BackOffice classification?
WITH ai AS (
  SELECT cd.DocumentID, cd.GCID, cd.SuggestedDocumentTypeID
  FROM main.billing.bronze_etoro_backoffice_customerdocument cd
  WHERE cd.etr_y = 2026 AND cd.etr_ym >= '2026-04'
    AND (cd.Obsolete = 0 OR cd.Obsolete IS NULL)
)
SELECT a.GCID, a.DocumentID, a.SuggestedDocumentTypeID,
       da.DocumentClassification AS bo_classification, da.ManagerID,
       da.vendor, da.rejection_reason
FROM ai a
JOIN main.bi_output_stg.bi_output_operations_documentanalysis da
  ON a.DocumentID = da.document_id
WHERE a.SuggestedDocumentTypeID = 2  -- AI said POI
  AND da.DocumentClassification <> 'Proof of Identity';

-- Per-customer KYC completion via kyc_answers (CORRECT: DISTINCT on CID)
SELECT COUNT(DISTINCT CID) AS customers_with_kyc_answers
FROM main.bi_output_stg.bi_output_operations_ops_kyc_answers
WHERE etr_y = 2026; -- adjust partition predicate based on table layout
```

## Skill provenance

- **Primary sources.** UC live probes on 2026-05-28: `documentanalysis` 5.55M rows / 37 cols / business-commented schema confirmed; live `definition_sla_bucket` and `document_type` and `vendor` distributions for April 2026 (320k docs ג‰₪ 1 hour SLA, Onfido dominant at 228k/month avg 85 min, ~46% empty vendor for in-house, "Not Accepted" 135k/month as explicit reject-bucket); `bronze_etoro_backoffice_customerdocument` 8.78M / 13.4M lifetime / partition cols etr_y INT / etr_ym STRING / etr_ymd DATE / business-commented schema; `ops_ai_doc_verification_checks` 5,702 rows / 7 cols.
- **Usage data.** Class C in `_usage_trigger_xref_20260525T155320Z`: `documentanalysis` 278q / 7-day, `customerdocument` 78q, `customerdocumenttodocumenttype` 71q. Genie space "OPS - Documents & Verification" 313 q/w.
- **Federation.** `../_shared/valid-users-filter-contract.md` for per-CID rollups; [`electronic-verification-and-registration-funnel.md`](electronic-verification-and-registration-funnel.md) for the registrationfunnel side; [`ops-portal-and-alerts.md`](ops-portal-and-alerts.md) for the alert-queue side; `../domain-compliance-and-aml/SKILL.md` for screening methodology.
