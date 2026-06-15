---
object_fqn: main.bi_db.bronze_etoro_customer_address_masked
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_etoro_customer_address_masked
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 11
row_count: null
generated_at: '2026-05-19T12:12:44Z'
upstreams:
- etoro.Customer.Address
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md
  source_database: etoro
  source_schema: Customer
  source_table: Address
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Customer/Address_masked
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 11
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_etoro_customer_address_masked

> Bronze ingest in `main.bi_db` (1:1 passthrough of `etoro.Customer.Address`). 11 of 11 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_etoro_customer_address_masked` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 11 |
| **Generated** | 2026-05-19 |
| **Created** | Thu Aug 01 07:57:41 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Customer.Address` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md`.

- Lake path: `Bronze/etoro/Customer/Address_masked`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Customer.Address`
- 11 of 11 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | INT | YES | Global Customer ID - part of composite PK. Identifies the customer globally across eToro systems. References the same GCID in Customer.CustomerStatic (Tier 1 — inherited from etoro.Customer.Address). |
| 1 | AddressTypeID | INT | YES | Address classification: 1=Mailing (only current type). FK to Dictionary.AddressType. Designed for future expansion (billing, residential, etc.). See [AddressType](../../Dictionary/Tables/Dictionary.AddressType.md) for full definitions (Tier 1 — inherited from etoro.Customer.Address). |
| 2 | CountryID | INT | YES | Country of the address. FK to Dictionary.Country. Always populated - the minimum required field for tax and KYC purposes. Determines which tax treaty rules apply (Tier 1 — inherited from etoro.Customer.Address). |
| 3 | Address | STRING | YES | Street address line (street name and number). NULL in many records, indicating partial submissions where only Zip was required for the specific KYC workflow (Tier 1 — inherited from etoro.Customer.Address). |
| 4 | City | STRING | YES | City/locality of the address. NULL in many records — optional depending on country-specific KYC requirements (Tier 1 — inherited from etoro.Customer.Address). |
| 5 | Zip | STRING | YES | Postal/ZIP code. The most frequently populated address field — used for country-level verification, mailing zone determination, and tax jurisdiction (Tier 1 — inherited from etoro.Customer.Address). |
| 6 | BuildingNumber | STRING | YES | Building or apartment number, separate from the street address line. NULL in most records. Supports address formats (common in some European countries) where building number is a separate field from street name (Tier 1 — inherited from etoro.Customer.Address). |
| 7 | SubRegionID | INT | YES | Sub-regional geographic division (e.g., US state, Canadian province). FK to Dictionary.SubRegion. NULL for most records; populated for countries where regulatory compliance requires sub-region tracking (Tier 1 — inherited from etoro.Customer.Address). |
| 8 | BeginTime | TIMESTAMP | YES | System-generated temporal period start. Set automatically by SQL Server when the row is created or when a previous version's EndTime closes. Marks when this version of the address became effective (Tier 1 — inherited from etoro.Customer.Address). |
| 9 | EndTime | TIMESTAMP | YES | System-generated temporal period end. Value of '9999-12-31 23:59:59.9999999' indicates the current active version. SQL Server sets this to the actual change time when the row is superseded (Tier 1 — inherited from etoro.Customer.Address). |
| 10 | RegionID | INT | YES | IP-based geographic region. FK to Dictionary.RegionByIP (RegionByIP_ID). Optionally populated to correlate declared address with IP-inferred region for fraud/compliance checks (Tier 1 — inherited from etoro.Customer.Address). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Customer.Address` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Customer.Address
        │
        ▼
main.bi_db.bronze_etoro_customer_address_masked   ←── this object
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
| GCID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.Address) |
| AddressTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.Address) |
| CountryID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.Address) |
| Address | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.Address) |
| City | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.Address) |
| Zip | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.Address) |
| BuildingNumber | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.Address) |
| SubRegionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.Address) |
| BeginTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.Address) |
| EndTime | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.Address) |
| RegionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.Address.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Customer.Address) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 11 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 11/11 | Source: bronze_tier1_inheritance*
