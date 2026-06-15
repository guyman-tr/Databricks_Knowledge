---
object_fqn: main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 36
row_count: null
generated_at: '2026-05-19T12:12:58Z'
upstreams:
- fiktivo.dbo.tblaff_PaymentDetails
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md
  source_database: fiktivo
  source_schema: dbo
  source_table: tblaff_PaymentDetails
  source_repo: ExperianceDBs
  datalake_path: Bronze/fiktivo/dbo/tblaff_PaymentDetails
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

# bronze_fiktivo_dbo_tblaff_paymentdetails

> Bronze ingest in `main.bi_db` (1:1 passthrough of `fiktivo.dbo.tblaff_PaymentDetails`). 36 of 36 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 36 |
| **Generated** | 2026-05-19 |
| **Created** | Sun Jun 09 11:14:33 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `fiktivo.dbo.tblaff_PaymentDetails` (`ExperianceDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md`.

- Lake path: `Bronze/fiktivo/dbo/tblaff_PaymentDetails`
- Copy strategy: `Override`
- Source database: `fiktivo` (`ExperianceDBs`)
- Source schema/table: `dbo.tblaff_PaymentDetails`
- 36 of 36 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PaymentDetailsID | LONG | YES | Primary key. Referenced by tblaff_Affiliates.PaymentDetailsID/PaymentDetails2ID/PaymentDetails3ID and tblaff_PaymentHistory.PaymentDetailsID (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 1 | PaymentMethodID | INT | YES | Payment method selector. See [Payment Methods](../../_glossary.md#payment-methods): 1=None, 2=PayPal, 3=Wire Transfer, 4=eToro Trading Account, 5=Neteller, 6=Skrill, 7=Webmoney, 8=Credit Card, 9=China Union Pay (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 2 | Amount | LONG | YES | Payment amount or limit associated with this payment detail record (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 3 | PayPalAccount | STRING | YES | PayPal email address for PayPal payments (PaymentMethodID=2) (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 4 | WireBeneficiary | STRING | YES | Wire transfer beneficiary name (PaymentMethodID=3) (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 5 | WireBankName | STRING | YES | Wire transfer bank name (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 6 | WireBankAddress | STRING | YES | Wire transfer bank address (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 7 | WireBranchNumber | STRING | YES | Wire transfer branch/routing number (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 8 | WireAccountNumber | STRING | YES | Wire transfer account number (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 9 | WireSwiftCode | STRING | YES | Wire transfer SWIFT/BIC code for international routing (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 10 | WireIBAN | STRING | YES | Wire transfer IBAN (International Bank Account Number) (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 11 | Username | STRING | YES | General username field for e-wallet services. Indexed for lookups (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 12 | NetellerAccount | STRING | YES | Neteller account ID (PaymentMethodID=5) (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 13 | NetellerEmail | STRING | YES | Neteller registered email address (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 14 | MoneybookersAccount | STRING | YES | Skrill (formerly Moneybookers) account ID (PaymentMethodID=6) (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 15 | WebMoneyAccount | STRING | YES | WebMoney account ID (PaymentMethodID=7) (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 16 | WebMoneyPurseID | STRING | YES | WebMoney purse identifier for specific currency wallets (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 17 | CreditCardNumber | STRING | YES | Credit card number (PaymentMethodID=8). MASKED with partial display (all X's) (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 18 | CreditCardExpMonth | STRING | YES | Credit card expiration month (01-12) (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 19 | CreditCardExpYear | STRING | YES | Credit card expiration year (4-digit) (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 20 | PayeeID | STRING | YES | External payee identifier for payment processor integration (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 21 | IntermediaryBankName | STRING | YES | Intermediary/correspondent bank name for international wire transfers. MASKED (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 22 | IntermediaryBankAddress | STRING | YES | Intermediary bank address. MASKED (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 23 | IntermediaryAccountNumber | STRING | YES | Account number at the intermediary bank (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 24 | IntermediarySwiftCode | STRING | YES | SWIFT code of the intermediary bank (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 25 | IntermediaryIBAN | STRING | YES | IBAN at the intermediary bank (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 26 | VerifiedBy | INT | YES | FK to [dbo.tblaff_User](dbo.tblaff_User.md).UserID. Admin user who verified these payment details. NULL = unverified (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 27 | VerifiedOn | TIMESTAMP | YES | Timestamp when payment details were verified. NULL = unverified (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 28 | ChinaUnionPayBeneficiaryFullName | STRING | YES | China UnionPay beneficiary full name (PaymentMethodID=9) (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 29 | ChinaUnionPayBankName | STRING | YES | China UnionPay bank name (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 30 | ChinaUnionPayBankAddress | STRING | YES | China UnionPay bank address (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 31 | ChinaUnionPayBranchNumber | STRING | YES | China UnionPay branch number (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 32 | ChinaUnionPayAccountNumber | STRING | YES | China UnionPay account number (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 33 | WireSortCode | STRING | YES | UK sort code for domestic wire transfers (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 34 | WireBankCountryID | INT | YES | Country of the wire transfer bank. References tblaff_Country for bank location (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |
| 35 | WireRoutingNumber | STRING | YES | US ABA routing number for domestic wire transfers (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `fiktivo.dbo.tblaff_PaymentDetails` | Primary | `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` |

### 4.2 Pipeline ASCII Diagram

```
fiktivo.dbo.tblaff_PaymentDetails
        │
        ▼
main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails   ←── this object
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
| PaymentDetailsID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| PaymentMethodID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| Amount | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| PayPalAccount | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| WireBeneficiary | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| WireBankName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| WireBankAddress | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| WireBranchNumber | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| WireAccountNumber | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| WireSwiftCode | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| WireIBAN | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| Username | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| NetellerAccount | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| NetellerEmail | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| MoneybookersAccount | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| WebMoneyAccount | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| WebMoneyPurseID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| CreditCardNumber | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| CreditCardExpMonth | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| CreditCardExpYear | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| PayeeID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| IntermediaryBankName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| IntermediaryBankAddress | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| IntermediaryAccountNumber | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| IntermediarySwiftCode | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| IntermediaryIBAN | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| VerifiedBy | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| VerifiedOn | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| ChinaUnionPayBeneficiaryFullName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| ChinaUnionPayBankName | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| ChinaUnionPayBankAddress | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| ChinaUnionPayBranchNumber | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| ChinaUnionPayAccountNumber | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| WireSortCode | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| WireBankCountryID | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |
| WireRoutingNumber | upstream wiki `knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md` (bronze passthrough) | 1 | (Tier 1 — inherited from fiktivo.dbo.tblaff_PaymentDetails) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 36 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 36/36 | Source: bronze_tier1_inheritance*
