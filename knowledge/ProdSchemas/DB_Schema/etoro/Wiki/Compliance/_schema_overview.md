# Compliance Schema - Overview

**Database**: etoro
**Schema**: Compliance
**Generated**: 2026-03-17
**Objects**: 12 Stored Procedures (100% documented)

---

## Purpose

The Compliance schema contains stored procedures supporting eToro's regulatory compliance workflows. All objects serve one of four distinct compliance domains:

1. **Document Expiry Monitoring** - Identify customers whose KYC verification documents (POA/POI) are approaching expiry and need re-submission
2. **KYC Reconfirmation** - Identify customers whose questionnaire answers have aged past their TTL and must re-confirm their trading profile
3. **Trading Restriction Monitoring** - Detect CFD restriction violations and cross-system data drift
4. **Regulation Administration** - Extend the regulation dictionary when eToro enters new regulated markets

Most SPs in this schema serve scheduled jobs run by the `SQL_Compliance` service or compliance operations tooling. None contain complex transactional logic — they are query/report generators or simple inserts.

---

## Object Inventory

### Active Stored Procedures (9)

| SP | Quality | Domain | Caller |
|----|---------|--------|--------|
| [AddNewRegulation](Stored%20Procedures/Compliance.AddNewRegulation.md) | 8.0 | Regulation Administration | Ops tooling (external) |
| [GetCountryLongAbbreviation](Stored%20Procedures/Compliance.GetCountryLongAbbreviation.md) | 8.5 | WorldCheck Integration | SQL_Compliance service |
| [GetCustomerRestrictionDiff](Stored%20Procedures/Compliance.GetCustomerRestrictionDiff.md) | 8.5 | Restriction Monitoring | Compliance ops reporting |
| [GetCustomerRestrictionException](Stored%20Procedures/Compliance.GetCustomerRestrictionException.md) | 8.8 | Restriction Monitoring | Scheduled monitoring job |
| [GetPOADocumentsExpirationPopulationFor3Years](Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulationFor3Years.md) | 9.0 | Document Expiry | SQL_Compliance service |
| [GetPOIDocumentsExpirationPopulation](Stored%20Procedures/Compliance.GetPOIDocumentsExpirationPopulation.md) | 9.0 | Document Expiry | SQL_Compliance service, PROD_BIadmins |
| [GetQuestionsExpirationPopulation](Stored%20Procedures/Compliance.GetQuestionsExpirationPopulation.md) | 9.2 | KYC Reconfirmation | SQL_Compliance, PROD_SQL_Compliance, PROD_BIadmins |
| [GetQuestionsExpirationPopulationNew](Stored%20Procedures/Compliance.GetQuestionsExpirationPopulationNew.md) | 9.0 | KYC Reconfirmation | SQL_Compliance, PROD_BIadmins (has @questions bug) |
| [GetUkClassificationGapPopulation](Stored%20Procedures/Compliance.GetUkClassificationGapPopulation.md) | 9.0 | UK Classification | SQL_Compliance (inferred) |

### Deprecated / Junk Stored Procedures (3)

These carry the `_JUNKYulia0325` suffix and should NOT be called in production.

| SP | Quality | Issue |
|----|---------|-------|
| [GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325](Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325.md) | 7.5 | RUNTIME ERROR: INSERT into missing table. Replace with GetPOADocumentsExpirationPopulationFor3Years |
| [GetPOADocumentsExpirationPopulation_JUNKYulia0325](Stored%20Procedures/Compliance.GetPOADocumentsExpirationPopulation_JUNKYulia0325.md) | 7.5 | Executable but legacy 1-year expiry. Replace with GetPOADocumentsExpirationPopulationFor3Years |
| [GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325](Stored%20Procedures/Compliance.GetPOIDocumentsExpirationPopulationGCID_JUNKYulia0325.md) | 7.5 | Near-identical to active POI SP. Replace with GetPOIDocumentsExpirationPopulation |

---

## Architecture Patterns

### Common Eligibility Filters

All document expiry and KYC reconfirmation SPs share a consistent customer eligibility pattern:

| Filter | Active POA SP | Active POI SP | KYC Reconfirmation SPs |
|--------|--------------|--------------|----------------------|
| Verification level | IN (2,3) | = 3 only | = 3 only |
| Block exclusion | IsBlocked=1 excluded | IsBlocked=1 excluded | (via Customer.Customer) |
| Deposit requirement | IsFTD=1 | PaymentStatusID=2 | None |
| Account type | NOT IN (2,4) | NOT IN (2,4) | None |
| EV exclusion | EvMatchStatus != 2 | EvMatchStatus != 2 | None |
| Internal employees | @IsInternal flag | @IsInternal flag | @IsInternal flag |

### Duplicate Prevention Patterns

All population SPs protect against duplicate notifications:
- **Document expiry**: `ROW_NUMBER() OVER (PARTITION BY CID ORDER BY ExpiryDate DESC)` - latest document wins
- **KYC reconfirmation**: Excludes GCIDs in active WorkFlowID=5 (not in terminal StateTypeID=5)
- **UK Classification**: Excludes GCIDs with open RequirementID=23 (OverviewStatusID=1)

### Cross-Database Architecture

The Compliance schema is a thin query layer over multiple source systems:

```
etoro (this schema)
  |-- Dictionary (regulation, country, player status, document type lookups)
  |-- BackOffice (customer documents, verification data)
  |-- Customer (customer identities, static data)
  |-- Trade (position data for restriction violation checks)
  |-- Billing (deposit data for funding eligibility)
  |-- ComplianceStateDB [via synonyms] (restriction state, workflow state, requirement tracking)
  |-- SettingsAzureDB [via synonyms] (settings distribution copy of restrictions)
  +-- UserApiDB [via synonyms] (KYC questionnaire data)
```

### @IsInternal Pattern

All document expiry and KYC reconfirmation SPs accept `@IsInternal BIT`:
- `@IsInternal=0`: Returns external/regular customers (typically `PlayerLevelID != 4`)
- `@IsInternal=1`: Returns internal eToro employees only (`PlayerLevelID = 4`)
- Callers run the SP twice (once for each) to produce separate notification batches

---

## Key Business Concepts

- **[KYC Reconfirmation](../_glossary.md#kyc-reconfirmation)**: TTL-based expiry of questionnaire answers; workflow exclusion to prevent duplicates
- **[Document Expiration Campaign](../_glossary.md#document-expiration-campaign)**: POA (3yr/1mo window) and POI (stored ExpiryDate/15-day window) notification populations
- **[Document Type](../_glossary.md#document-type)**: DocumentTypeID=1 (POA), DocumentTypeID=2 (POI)
- **[Regulation](../_glossary.md#regulation)**: Scopes KYC reconfirmation populations to specific regulatory jurisdictions
- **[Player Status](../_glossary.md#player-status)**: IsBlocked=1 statuses are excluded from all notification campaigns

---

## Known Issues

| Issue | SP | Severity | Recommendation |
|-------|-----|----------|---------------|
| Runtime error on call | GetPOADocumentsExpirationPopulationGCID_JUNKYulia0325 | HIGH | Do not call. INSERT target table missing. |
| @questions column bug (CID vs ID) | GetQuestionsExpirationPopulationNew | HIGH | Use GetQuestionsExpirationPopulation instead until fixed. |
| Fixed PK constraint name (concurrency risk) | GetQuestionsExpirationPopulationNew | MEDIUM | Risk of failure under concurrent execution. |
| Dead @MaxAllowedProcessingRowsPerCycle parameter | GetPOADocumentsExpirationPopulation_JUNKYulia0325, GetPOIDocumentsExpirationPopulation | LOW | Cosmetic. Does not affect results. |
| POI SP uses Customer.Customer (older table) | GetPOIDocumentsExpirationPopulation | LOW | Active POA SP uses Customer.CustomerStatic. Consider alignment. |

---

*Generated: 2026-03-17 | Schema: Compliance | Database: etoro | Objects: 12/12 documented*
