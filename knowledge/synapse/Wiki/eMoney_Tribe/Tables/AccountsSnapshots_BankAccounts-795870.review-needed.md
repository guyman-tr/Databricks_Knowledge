# Review Needed: eMoney_Tribe.AccountsSnapshots_BankAccounts-795870

## Summary

All 8 columns are Tier 3 — no upstream wiki exists for the Tribe Platform API source. The `_no_upstream_found.txt` marker is present. Every column description is grounded in DDL structure, SP code analysis (SP_eMoney_Reconciliation_ETLs), and live data sampling.

## Items for Human Review

### 1. Production Source Confirmation

- **Question**: Is the Tribe Platform API the correct production source designation? The table appears to be loaded via an API-to-Lake-to-Synapse pipeline, but the exact Tribe entity endpoint and data contract are not documented in any accessible wiki.
- **Impact**: Tier 3 descriptions reference "Tribe Platform API" as the source; if a more specific source exists, descriptions should be updated.

### 2. etr_ Column Purpose

- **Observation**: The `etr_y`, `etr_ym`, `etr_ymd` columns are populated only for early data (Dec 2023 / Jan 2024) and are empty strings for all subsequent records.
- **Question**: Were these columns deprecated or is the population logic conditional? Should they be documented as deprecated?

### 3. @Id / Parent FK Redundancy

- **Observation**: `@Id` and `@AccountsSnapshots_AccountSnapshot@Id-956050` are always identical in live data (100% match verified on 2026 Q1 data, 231.8M rows).
- **Question**: Is this by design (1:1 relationship with parent), or is there a scenario where these IDs diverge? The Tribe schema convention suggests the parent FK *could* differ if one snapshot had multiple bank account association records.

### 4. Table Growth Rate

- **Observation**: 1.52B rows is very large for a bridge table with no business attributes.
- **Question**: Is there a retention policy or archival strategy for this table? Daily snapshots accumulating since Dec 2023 at this volume may indicate unbounded growth.

### 5. Downstream Consumer Completeness

- **Known consumer**: SP_eMoney_Reconciliation_ETLs (Reconciliation Table 05 — Account Snapshot section)
- **Question**: Are there other consumers (reports, dashboards, ad-hoc queries) that read this table directly?

## Tier Distribution

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — |
| Tier 2 | 0 | — |
| Tier 3 | 8 | @Id, @AccountsSnapshots_AccountSnapshot@Id-956050, etr_y, etr_ym, etr_ymd, SynapseUpdateDate, Created, partition_date |
| Tier 4 | 0 | — |
