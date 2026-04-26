# BI_DB_AMLPeriodicReview — Review Notes

**Generated**: 2026-04-23
**Reviewer**: —

## Items Needing Human Verification

1. **LastEPUpdateDate = KYC_LastUpdateDate (duplicate)**: The SP assigns `kyc.KYC_LastUpdateDate` to BOTH KYC_LastUpdateDate and LastEPUpdateDate. Confirm whether LastEPUpdateDate is intentionally a duplicate of KYC_LastUpdateDate or whether it should represent a different date (e.g., last date the economic profile was reviewed/approved by the AML team).

2. **PlayerStatusID NOT IN (2, 4)**: Confirm exact names for status IDs 2 and 4 in Dictionary.PlayerStatus. Sample data shows 'Normal' and various active statuses passing through — these exclusions likely correspond to 'Blocked'/'Banned' or 'Demo' statuses.

3. **PendingClosureStatusID NOT IN (2, 3)**: Confirm meaning of closure status IDs 2 and 3 (likely 'Suggested for Closure' and 'Approved for Closure').

4. **RiskClassificationID semantics**: SP filters `RiskClassificationID=1` for GROUP A (Medium) and `RiskClassificationID=0` for GROUP C (High). Confirm this mapping: ID 0 = High, ID 1 = Medium? The sample showed NULL RiskClassification for some GROUP C rows — investigate if this means RiskClassificationID=0 resolves to NULL or empty in Dim_RiskClassification.

5. **Group C WHERE clause**: Line 276: `WHERE (a.RiskClassificationID <> a.Previous_RiskClassificationID AND a.RiskClassificationID = 0) or (a.RiskClassificationID=0)` — the second OR clause (`a.RiskClassificationID=0`) without the change check means ALL High Risk customers appear regardless of change. Confirm this is intentional (annual review for all high-risk customers) and is the design intent.

6. **EEA list definition**: The SP references `#EEA` temp table in MIMO and Rank 1/2 country checks. Confirm the exact list of EEA countries in this temp table — they are excluded from MaterialChangeMIMO and MaterialChangeLogins alerts.

7. **POA expiry policy**: As of 2025-10-30, POA_ExpiryDate uses CustomerDocument IssueDate < 1 year ago AND customer is in FlaggedCustomers. Previous logic used Dim_Customer.IsAddressProofExpiryDate. Confirm the current policy is correctly reflected.

8. **573,216 row count**: This is cumulative historical data. Confirm the earliest Review_Due_Date in the table to understand the historical depth. Growing daily.

9. **APU_Gaps_Summary**: Sourced from External_ComplianceStateDB_Compliance_CustomerInteractions. Confirm this external table is reliably populated and what 'APU' stands for in this context.

10. **Downstream consumers**: Only post-review table and AML analyst queues identified. Confirm whether any Salesforce integrations, Power BI dashboards, or compliance reports query this table directly.

## Quality Score

8.5/10 — 70-column complex AML workbook. 17 columns Tier 1 from DWH_dbo.Dim_Customer wiki. 52 columns Tier 2 from SP logic thoroughly documented. Business meaning strong (4-group AML periodic review + 6 alert dimensions). Data evidence: 573,216 rows confirmed. Notable finding: LastEPUpdateDate = duplicate of KYC_LastUpdateDate. Minor deductions: 25+ source table complexity; some alert logic has subtle nuances requiring business confirmation; no Confluence documentation found.
