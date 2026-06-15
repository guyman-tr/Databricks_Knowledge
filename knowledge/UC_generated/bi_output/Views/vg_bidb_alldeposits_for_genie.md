---
object_fqn: main.bi_output.vg_bidb_alldeposits_for_genie
object_type: VIEW
producer_kind: view_definition
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_output.vg_bidb_alldeposits_for_genie
schema: bi_output
framework: uc-pipeline-doc
table_type: VIEW
format: null
column_count: 38
row_count: null
generated_at: '2026-05-19T15:01:57Z'
upstreams:
- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits
writer:
  kind: view_definition
  path: knowledge/UC_generated/bi_output/_discovery/source_code/vg_bidb_alldeposits_for_genie.sql
  source_code_snapshot: knowledge/UC_generated/bi_output/_discovery/source_code/vg_bidb_alldeposits_for_genie.sql
concept_count: 0
formula_count: 38
tier_breakdown:
  tier1_columns: 8
  tier2_columns: 30
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# vg_bidb_alldeposits_for_genie

> View in `main.bi_output`. 0 business concept(s) in §2; 38 of 38 columns documented from anchored evidence; 0 unverified (see sidecar).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_bidb_alldeposits_for_genie` |
| **Type** | VIEW |
| **Format** | n/a |
| **Owner** | shacharru@etoro.com |
| **Row count** | n/a |
| **Column count** | 38 |
| **Concepts** | 0 (see §2) |
| **Downstream consumers** | _(none tracked)_ |
| **Generated** | 2026-05-19 |
| **Created** | Thu Jan 29 13:40:30 UTC 2026 |

---

## 1. Business Meaning

`vg_bidb_alldeposits_for_genie` is a view in `main.bi_output`. No discriminator concepts were detected in the source — see §2 for the transform pattern breakdown.

Production-to-UC lineage flows: production source → bronze/staging → gold mirror `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` → this object. Canonical upstream documentation: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_AllDeposits.md`.

Of its 38 columns: 8 inherit byte-for-byte from upstream wikis (Tier 1), 30 are formula-assembled from cached source code (Tier 2 — see §4 for the formula and §2 for the named concept), 0 are null-with-provenance (Tier N — terminal-no-wiki upstream).

---

## 2. Business Logic

Pure passthrough from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` (and 0 additional upstream(s) per `.lineage.md`). No derived columns. Refer to upstream wiki for column semantics.

---

## 3. Query Advisory

### 3.1 UC Storage Layout

| Property | Value |
|----------|-------|
| **Type** | VIEW |
| **Format** | n/a |
| **Partitioned by** | (not partitioned) |
| **Materialization** | view_definition (re-runs on every query) |

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| Standard SELECT | No precomputed flags or sign-flips — query columns directly. |

### 3.3 Common JOINs

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered) | — | — |

### 3.4 Gotchas

- No top-level filter blocks or sign flips detected. See `.review-needed.md` for parser warnings and UNVERIFIED columns.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | INT | YES | Customer ID. Identifies the eToro customer who made this deposit. References DWH_dbo.Dim_Customer. Popular Investor (PlayerLevelID=4) CIDs are excluded. (Tier 1 — Fact_BillingDeposit) |
| 1 | DepositID | INT | YES | Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). DELETE/INSERT keyed on this column by SP_AllDeposits. (Tier 1 — Fact_BillingDeposit) |
| 2 | FundingType | STRING | YES | Payment method name resolved from Dim_FundingType. Top values (2026): eToroMoney (58%), CreditCard (30%), PayPal (4%), WireTransfer (3%). (Tier 2 — SP_AllDeposits) |
| 3 | ModificationDate | TIMESTAMP | YES | UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection. (Tier 1 — Fact_BillingDeposit) |
| 4 | AmountOrig | DECIMAL | YES | Arithmetic combination of upstream columns. Formula: `-- ====================== -- Amounts & currency (requested) -- ====================== Amount_In_Orig_Curr`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits`) |
| 5 | AmountUSD | DECIMAL | YES | Direct passthrough from upstream. Formula: `Amount_in_USD`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits`) |
| 6 | Currency | STRING | YES | Currency abbreviation of the deposit amount (e.g., 'USD', 'EUR', 'GBP'). Resolved from Dim_Currency.Abbreviation via Fact_BillingDeposit.CurrencyID. (Tier 2 — SP_AllDeposits) |
| 7 | BaseExchangeRate | DECIMAL | YES | Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate. Added by Adi (19/09/2019). (Tier 1 — Fact_BillingDeposit) |
| 8 | IsFTD | INT | YES | First Time Deposit flag. 1=this was the customer's very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type. ~60.6% of deposits are FTD=1 historically. (Tier 1 — Fact_BillingDeposit) |
| 9 | PaymentStatus | STRING | YES | Deposit status name resolved from Dim_PaymentStatus. Top values (2026): Approved (83%), Decline (6%), DeclineByRRE (2%), Pending (2%), InProcess (2%). See Fact_BillingDeposit wiki §2.1 for full state lifecycle. (Tier 2 — SP_AllDeposits) |
| 10 | PaymentStatusAsInteger | STRING | YES | Direct passthrough from upstream. Formula: `PaymentStatusAsInteger`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits`) |
| 11 | DepositCategory | STRING | YES | Deposit category for marketing attribution. Values: 'FTD' (3.5%), 'REDEPOSIT' (96.5%), 'LEAD' (<0.1%). Logic: IsFTD=1→'FTD'; FirstDepositDate IS NOT NULL→'REDEPOSIT'; ELSE→'LEAD'. (Tier 2 — SP_AllDeposits) |
| 12 | Provider | STRING | YES | Payment provider/gateway name (acquirer). Resolved from Dim_BillingDepot.Name via Fact_BillingDeposit.DepotID. (Tier 2 — SP_AllDeposits) |
| 13 | DepotID | INT | YES | Acquirer/gateway configuration used for this deposit. Validated at insert against DepotToCurrency in production. Numeric ID; use Provider column for the resolved name. (Tier 1 — Fact_BillingDeposit) |
| 14 | PSPCode | STRING | YES | Payment service provider code. Alias of Fact_BillingDeposit.PSPCodeAsString (renamed for readability). Also present as PSPCodeAsString (duplicate for API compatibility). (Tier 1 — Fact_BillingDeposit, PSPCodeAsString) |
| 15 | BINCountry | STRING | YES | Country of card issuance based on BIN (Bank Identification Number). Resolved from Dim_Country.Name WHERE CountryID = BinCountryIDAsInteger. NULL for non-card funding types. (Tier 2 — SP_AllDeposits) |
| 16 | BinCode | LONG | YES | Card BIN (Bank Identification Number, first 6-8 digits). Stored as bigint (implicit cast from BinCodeAsString). NULL for non-card funding types. (Tier 1 — Fact_BillingDeposit, BinCodeAsString) |
| 17 | BinCodeAsString | STRING | YES | Direct passthrough from upstream. Formula: `BinCodeAsString`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits`) |
| 18 | CardType | STRING | YES | Card type name (e.g., 'Visa', 'Mastercard'). Resolved from Dim_CardType.CarTypeName via BinCountryIDAsInteger (CardTypeID). NULL for non-card funding types. (Tier 2 — SP_AllDeposits) |
| 19 | CardSubType | STRING | YES | Card subtype label (e.g., 'Classic', 'Gold', 'Platinum'). Resolved from Dim_CountryBin.CardSubType via BinCodeAsString. NULL for non-card funding types. (Tier 2 — SP_AllDeposits) |
| 20 | CardTypeIDAsInteger | STRING | YES | Direct passthrough from upstream. Formula: `CardTypeIDAsInteger`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits`) |
| 21 | Bank_name_by_Bincode | STRING | YES | Direct passthrough from upstream. Formula: `Bank_name_by_Bincode`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits`) |
| 22 | RiskStatus | STRING | YES | Customer-level risk classification label. Resolved from Dim_RiskStatus.Name via Dim_Customer.RiskStatusID. Reflects the customer's overall risk status at time of ETL, not deposit-specific. (Tier 2 — SP_AllDeposits) |
| 23 | Regulation | STRING | YES | Regulatory entity of the customer's trading account (e.g., 'CySEC', 'FCA', 'ASIC & GAML'). Resolved from Dim_Regulation.Name via Dim_Customer.RegulationID. Distribution (2026): CySEC 66%, FCA 15%, FSA Seychelles 6%, ASIC&GAML 3%, FSRA 3%, BVI 2%, FinCEN+FINRA 2%. (Tier 2 — SP_AllDeposits) |
| 24 | DesignatedRegulation | STRING | YES | Designated (preferred) regulatory entity for the customer. Resolved from Dim_Regulation.Name via Dim_Customer.DesignatedRegulationID. May differ from Regulation when customer trades under a specific entity. (Tier 2 — SP_AllDeposits) |
| 25 | RegistrationCountry | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- ====================== -- Geography / attribution (requested) -- ====================== Country_customer`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits`) |
| 26 | CountryID | STRING | YES | Direct passthrough from upstream. Formula: `CountryIDAsInteger`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits`) |
| 27 | Region | STRING | YES | eToro marketing region name for the customer's country. Resolved from External_etoro_Dictionary_MarketingRegion.Name via Dim_Country.MarketingRegionID. (Tier 2 — SP_AllDeposits) |
| 28 | Funnel | STRING | YES | Marketing funnel name at the time of the deposit. Resolved from Dim_Funnel.Name via Fact_BillingDeposit.FunnelID. (Tier 2 — SP_AllDeposits) |
| 29 | FunnelFrom | STRING | YES | Original acquisition funnel of the customer account. Resolved from Dim_Funnel.Name via Dim_Customer.FunnelFromID. (Tier 2 — SP_AllDeposits) |
| 30 | Affiliate_ID | INT | YES | Direct passthrough from upstream. Formula: `Affiliate_ID`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits`) |
| 31 | Response | STRING | YES | Payment gateway response name for the latest DepositAction on this deposit (e.g., 'Approved', 'Do Not Honor'). Resolved via Synapse_Table_etoro_History_DepositAction → External_etoro_Dictionary_Response.ResponseName. NULL when no DepositAction with ResponseID exists. (Tier 2 — SP_AllDeposits) |
| 32 | DeclineReason | STRING | YES | Direct passthrough from upstream. Formula: `ResponseMessageAsString`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits`) |
| 33 | RREReason | STRING | YES | Direct passthrough from upstream. Formula: `ErrorCodeAsString`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits`) |
| 34 | ThreeDSResponseJson | STRING | YES | Direct passthrough from upstream. Formula: `ThreeDsAsJson`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits`) |
| 35 | GCID | STRING | YES | Arithmetic combination of upstream columns. Formula: `-- ====================== -- GCID / customer linkage (likely needed) -- ====================== CustomerIDAsString`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits`) |
| 36 | MID | STRING | YES | Merchant ID configuration value for payment routing. Resolved from External_etoro_Billing_ProtocolMIDSettings.Value via Fact_BillingDeposit.ProtocolMIDSettingsID. NULL when no MID profile applies. (Tier 2 — SP_AllDeposits) |
| 37 | TransactionIDAsString | STRING | YES | Direct passthrough from upstream. Formula: `TransactionIDAsString`. (Tier 2 — from `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits`) |

---

## 5. Lineage

### 5.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` | Primary | `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_AllDeposits.md` |

### 5.2 Pipeline ASCII Diagram

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits
        │
        ▼
main.bi_output.vg_bidb_alldeposits_for_genie   ←── this object
```

### 5.3 Cross-check vs system.access.column_lineage

`parsed=38 runtime=38 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 6. Relationships

### 6.1 References To (summary — see §5 for full table)

- **Primary upstream**: `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits` (wiki: `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_AllDeposits.md`)

### 6.2 Referenced By (downstream consumers)

- _(no downstream consumers tracked in `_dag.json`)_

---

## 7. Sample Queries

> Sample queries are not auto-generated. Refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage patterns against this object.

---

## 8. Atlassian Knowledge Sources

> No Atlassian sources discovered for this object in the current pipeline. When Confluence pages or Jira tickets are linked to this UC object, they will appear here (run `tools/uc_pipelines/cache_atlassian_for_object.py` if/when that tool exists).

---

## Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough/rename/cast).
- **Tier 2** — column described from a formula in `formulas.json` + an optional named concept from `concepts.json`. The formula is the predicate-explicit, alias-resolved SQL transformation; the concept gives the business name.
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides every other tier including Tier 1 (per DWH semantic-doc framework).
- **Tier N** — null-with-provenance: column points at an upstream that is either terminal-with-no-wiki, or in-scope-but-not-yet-authored. Explicit gap disclosure.
- **Tier U** — unclassifiable: no upstream wiki match, no formula, no source-code snippet. Mechanical disclosure of unclassifiability — see `.review-needed.md`.

*Generated: 2026-05-19 | Concepts: 0 | Formulas: 38 | Tiers: 8 T1, 30 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 38/38 | Source: view_definition*
