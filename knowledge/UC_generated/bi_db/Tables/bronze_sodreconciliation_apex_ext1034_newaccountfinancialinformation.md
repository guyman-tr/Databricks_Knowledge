---
object_fqn: main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 36
row_count: null
generated_at: '2026-05-19T12:13:01Z'
upstreams:
- Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md
  source_database: Sodreconciliation
  source_schema: apex
  source_table: EXT1034_NewAccountFinancialInformation
  source_repo: DB_Schema
  datalake_path: Bronze/Sodreconciliation/apex/EXT1034_NewAccountFinancialInformation
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 36
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation

> Bronze ingest in `main.bi_db` (1:1 passthrough of `Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation`). 36 of 36 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 36 |
| **Generated** | 2026-05-19 |
| **Created** | Mon Sep 18 19:14:47 UTC 2023 |

---

## 1. What it is

Bronze ingest table populated from production source `Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md`.

- Lake path: `Bronze/Sodreconciliation/apex/EXT1034_NewAccountFinancialInformation`
- Copy strategy: `Override`
- Source database: `Sodreconciliation` (`DB_Schema`)
- Source schema/table: `apex.EXT1034_NewAccountFinancialInformation`
- 36 of 36 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | STRING | YES | Primary key. Auto-generated sequential GUID for each row (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 1 | SodFileId | STRING | YES | FK to apex.SodFiles. Links this row to the specific EXT1034 file import. CASCADE DELETE (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 2 | Correspondent | STRING | YES | Correspondent firm identifier/name (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 3 | Branch | STRING | YES | Branch/office code (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 4 | RepCode | STRING | YES | Registered representative code (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 5 | AccountNumber | STRING | YES | Apex customer account number. MASKED (PII) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 6 | TaxIDNumber | STRING | YES | Federal tax identification number (SSN or EIN). MASKED (PII) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 7 | CustomerCode | INT | YES | Apex customer classification code (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 8 | CodeDescription | STRING | YES | Description of the customer code (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 9 | AccountType | STRING | YES | Account type classification (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 10 | OpenDate | TIMESTAMP | YES | Date the account was opened (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 11 | DateOfBirth | TIMESTAMP | YES | Account holder's date of birth. MASKED (PII) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 12 | AccountName1 | STRING | YES | Account holder name. MASKED (PII) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 13 | AddressLine1 | STRING | YES | Primary address line. MASKED (PII) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 14 | AddressLine2 | STRING | YES | Secondary address line. MASKED (PII) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 15 | City | STRING | YES | City. MASKED (PII) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 16 | State | STRING | YES | State code (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 17 | ZipCode | STRING | YES | ZIP code. MASKED (PII) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 18 | LegalAddressindicator | STRING | YES | Indicator for whether the address is the legal/mailing address (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 19 | CountryCode | STRING | YES | Country code for the address (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 20 | EmailAddress | STRING | YES | Email address. MASKED (PII) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 21 | AnnualIncome | STRING | YES | Self-reported annual income range or amount (stored as string) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 22 | NetWorth | STRING | YES | Self-reported total net worth range or amount (stored as string) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 23 | LiquidNetWorth | STRING | YES | Self-reported liquid net worth range or amount (stored as string) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 24 | InvestmentExperience | STRING | YES | Level of investment experience (none, limited, good, extensive) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 25 | InvestmentObjective | STRING | YES | Primary investment objective (income, growth, speculation, etc.) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 26 | RiskTolerance | STRING | YES | Risk tolerance level (low, medium, high) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 27 | LiquidityNeeds | STRING | YES | Liquidity needs (very important, somewhat important, not important) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 28 | TimeHorizon | STRING | YES | Investment time horizon (short, medium, long) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 29 | AffiliatedPerson | STRING | YES | Affiliated person disclosure (broker-dealer affiliation) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 30 | AffiliatedPersonDetail | STRING | YES | Details about the affiliated person relationship (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 31 | AffiliatedApprovalSnapIDs | STRING | YES | Reference ID for affiliated person approval snapshots (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 32 | ControlPerson | STRING | YES | Control person disclosure (officer, director, 10%+ shareholder) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 33 | ControlPersonCompany | STRING | YES | Company name for which the account holder is a control person (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 34 | Employer | STRING | YES | Account holder's employer name (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |
| 35 | EmploymentStatus | STRING | YES | Employment status (employed, self-employed, retired, student, etc.) (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation` | Primary | `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` |

### 4.2 Pipeline ASCII Diagram

```
Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation
        │
        ▼
main.bi_db.bronze_sodreconciliation_apex_ext1034_newaccountfinancialinformation   ←── this object
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=0 runtime=0 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 5. Sample Queries & Common JOINs

### 5.1 Sample queries

> Sample queries are not auto-generated in this pack; refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage.

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered from upstream JOINs in `.lineage.md`) | — | — |

### 5.3 Gotchas

- See `.review-needed.md` for parser warnings, UNVERIFIED columns, and any Tier-4 sample-only candidates.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| Id | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| SodFileId | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| Correspondent | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| Branch | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| RepCode | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| AccountNumber | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| TaxIDNumber | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| CustomerCode | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| CodeDescription | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| AccountType | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| OpenDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| DateOfBirth | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| AccountName1 | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| AddressLine1 | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| AddressLine2 | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| City | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| State | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| ZipCode | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| LegalAddressindicator | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| CountryCode | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| EmailAddress | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| AnnualIncome | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| NetWorth | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| LiquidNetWorth | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| InvestmentExperience | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| InvestmentObjective | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| RiskTolerance | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| LiquidityNeeds | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| TimeHorizon | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| AffiliatedPerson | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| AffiliatedPersonDetail | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| AffiliatedApprovalSnapIDs | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| ControlPerson | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| ControlPersonCompany | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| Employer | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |
| EmploymentStatus | upstream wiki `knowledge/ProdSchemas/DB_Schema/Sodreconciliation/Wiki/apex/Tables/apex.EXT1034_NewAccountFinancialInformation.md` (bronze passthrough) | 1 | (Tier 1 — inherited from Sodreconciliation.apex.EXT1034_NewAccountFinancialInformation) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 36 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 36/36 | Source: bronze_tier1_inheritance*
