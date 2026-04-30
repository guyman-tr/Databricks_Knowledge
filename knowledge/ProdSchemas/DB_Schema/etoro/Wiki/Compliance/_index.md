# Compliance Schema - Wiki Index

**Database**: etoro
**Schema**: Compliance
**Last Updated**: 2026-03-17
**Wiki Path**: `etoro/Wiki/Compliance/`

## Metrics

| Metric | Value |
|--------|-------|
| **Total Objects** | 12 |
| **Documented** | 12 (100%) |
| **Remaining** | 0 |
| **Enrichment** | Complete (2026-03-17, Phase 12 cross-object pass) |
| **Last Updated** | 2026-03-17 |

## Schema Overview

The Compliance schema contains stored procedures supporting regulatory compliance workflows:
KYC document expiry monitoring, customer restriction auditing, regulation management,
and UK classification gap identification. Most SPs serve scheduled jobs or ops tooling.
Three SPs carry a `_JUNKYulia0325` suffix, indicating deprecated/junk objects retained
for historical reference.

---

## Stored Procedures

| Object | Quality | Status |
|--------|---------|--------|
| [Compliance.AddNewRegulation](Stored%20Procedures/Compliance.AddNewRegulation.md) | 8.0 | Done (Batch 1) |
| [Compliance.GetCountryLongAbbreviation](Stored%20Procedures/Compliance.GetCountryLongAbbreviation.md) | 8.5 | Done (Batch 1) |
| [Compliance.GetCustomerRestrictionDiff](Stored%20Procedures/Compliance.GetCustomerRestrictionDiff.md) | 8.5 | Done (Batch 1) |
| [Compliance.GetCustomerRestrictionException](Stored%20Procedures/Compliance.GetCustomerRestrictionException.md) | 8.8 | Done (Batch 1) |
| [Compliance.GetPOADocumentsExpirationPopulationFor3Years](Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulationFor3Years.md) | 9.0 | Done (Batch 1) |
| [Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325](Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325.md) | 7.5 | Done (Batch 1) - DEPRECATED |
| [Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325](Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325.md) | 7.5 | Done (Batch 1) - DEPRECATED |
| [Compliance.GetPOIDocumentsExpirationPopulation](Stored%20Procedures/Compliance.GetPOIDocumentsExpirationPopulation.md) | 9.0 | Done (Batch 1) |
| [Compliance.GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325](Stored%20Procedures/Compliance.GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325.md) | 7.5 | Done (Batch 1) - DEPRECATED |
| [Compliance.GetQuestionsExpirationPopulation](Stored%20Procedures/Compliance.GetQuestionsExpirationPopulation.md) | 9.2 | Done (Batch 1) |
| [Compliance.GetQuestionsExpirationPopulationNew](Stored%20Procedures/Compliance.GetQuestionsExpirationPopulationNew.md) | 9.0 | Done (Batch 1) |
| [Compliance.GetUkClassificationGapPopulation](Stored%20Procedures/Compliance.GetUkClassificationGapPopulation.md) | 9.0 | Done (Batch 1) |
