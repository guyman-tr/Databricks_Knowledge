# Compare — `BI_DB_dbo.BI_DB_Failed_Verification_MA`

**Bucket**: `random`

**Verdict**: **BETTER**  (score delta +4.1; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 5.0 | 9.1 | 4.1 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
| Element rows | 10 | 10 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 7 | +7 |
| T2 count | 9 | 3 | -6 |
| T3 count | 0 | 0 | +0 |
| T4 count | 0 | 0 | +0 |
| T5 count | 1 | 0 | -1 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 10 |
| completeness | 8 | 8 |
| data_evidence | 8 | 8 |
| shape_fidelity | 8 | 9 |
| tier_accuracy | 1 | 10 |
| upstream_fidelity | 1 | 9 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `8` | 0.097 | 2 | 1 | Reason for non-verification. Always 'Docs not Approved' in this table (filter condition). (Tier 2 — SP_Failed_Verification_MA) | Reason why a VL2 customer has not reached VL3. CASE logic: 'Docs not Approved', 'Missing Docs', 'User Screening Issue', 'Phone Not Verified', 'Others', 'Not Relevant'. Only meaningful for VL2 customer |
| `5` | 0.123 | 2 | 1 | Customer's current regulatory jurisdiction. Values: BVI, CySEC, FCA, ASIC, FSA Seychelles, eToroUS, FINRAONLY, etc. Passthrough from source. (Tier 2 — SP_Failed_Verification_MA) | Current regulation name for the customer (via Dim_Customer.RegulationID -> Dim_Regulation.Name). May differ from DesignatedRegulation if customer's regulation changed after registration. Passthrough f |
| `9` | 0.152 | 2 | 1 | Electronic verification match status. Never 'Verified' (filter condition). 4 values: blank (64%), NotVerified (27%), PartiallyVerified (9%), None (<1%). (Tier 2 — SP_Failed_Verification_MA) | Human-readable EV match status label (None, PartiallyVerified, Verified, NotVerified). Resolved via Dim_EvMatchStatus. DWH note: in this table, 'Verified' is excluded by the WHERE filter; observed val |
| `3` | 0.22 | 2 | 2 | Rejection reason display text. Mapped name from 22-code lookup when matched; otherwise raw RejectionReasonPOI or RejectionReasonPOA text. COALESCE(POI match name, POA match name, raw POI, raw POA). (T | Resolved rejection reason label. COALESCE priority: mapped POI reason name, mapped POA reason name, raw RejectionReasonPOI, raw RejectionReasonPOA. When ReasonNumber > 0, this is the standardised labe |
| `2` | 0.337 | 2 | 2 | Standardized rejection reason code. 1-22 = mapped to predefined POI/POA categories; 0 = unmatched reason text. COALESCE(POI match, POA match, 0). Top values: 11=POA cannot be accepted (31%), 10=POA mi | Numeric rejection reason code mapped from a hardcoded 22-row lookup in SP_Failed_Verification_MA. COALESCE(POI match, POA match, 0). Codes 1-7 = POI reasons, 8-13 = POA reasons, 14 = POI+POA combined, |
| `1` | 0.382 | 2 | 1 | Global Customer ID — cross-platform identifier. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs. FK to Dim_Customer. (Tier 2 — SP_Failed_Verification_MA) | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from BI_DB_Operations_Onboarding |
| `7` | 0.406 | 2 | 1 | Raw Proof of Identity rejection reason text from source. NULL if only POA was rejected. Used as input to ReasonNumber/RejectReasonName mapping. (Tier 2 — SP_Failed_Verification_MA) | Rejection reason text for the POI document. NULL if POI was approved or not submitted. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs. (Tier 1 — BI_DB_Operations_Onboarding_Flow_UserKPIs) |
| `6` | 0.407 | 2 | 1 | Raw Proof of Address rejection reason text from source. NULL if only POI was rejected. Used as input to ReasonNumber/RejectReasonName mapping. (Tier 2 — SP_Failed_Verification_MA) | Rejection reason text for the POA document. NULL if POA was approved or not submitted. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs. (Tier 1 — BI_DB_Operations_Onboarding_Flow_UserKPIs) |
| `10` | 0.494 | 5 | 2 | ETL metadata: timestamp when this row was inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — ETL metadata) | ETL execution timestamp. Set to GETDATE() at SP run time. Not a business date. (Tier 2 — SP_Failed_Verification_MA) |
| `4` | 0.679 | 2 | 1 | Customer's registered country name. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs. (Tier 2 — SP_Failed_Verification_MA) | Full country name in English. Unique per country. Passthrough from BI_DB_Operations_Onboarding_Flow_UserKPIs. (Tier 1 — Dictionary.Country) |

## Top issues — regen wiki (per judge)

- [medium] `GCID` — DDL defines GCID as NOT NULL but the inherited upstream description states 'NULL for older accounts predating GCID introduction'. Writer added DWH notes for NonVerificationReason and EV_MatchStatus but omitted one for this DDL/description contradiction. Should add a DWH note explaining the NOT NULL constraint.
- [low] `Section 1` — No explicit date range stated. The 3-day rolling window is described conceptually but no concrete date bounds are given (e.g., 'covering the 3-day window ending at last SP execution').
- [low] `Footer / Phase Gate` — No explicit Phase Gate Checklist section with [x] marks for P2/P3. Footer says 'Phases: 11/14' but doesn't enumerate which phases were completed. Data evidence appears genuine but the audit trail is incomplete.
- [low] `Section 8` — No Jira or Confluence sources searched due to regen harness mode. Business context validation relies entirely on SP code and upstream wiki.
- [low] `Section 3.4 (@Date parameter)` — Gotcha correctly notes the unused @Date parameter but doesn't flag the implication: if an orchestrator passes a date expecting historical replay, the SP silently ignores it and always uses GETDATE().
