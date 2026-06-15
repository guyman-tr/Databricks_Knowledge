---
object_fqn: main.bi_db.bronze_moneytransfer_billing_transfers
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.bi_db.bronze_moneytransfer_billing_transfers
schema: bi_db
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 20
row_count: null
generated_at: '2026-05-19T12:13:00Z'
upstreams:
- MoneyTransfer.Billing.Transfers
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md
  source_database: MoneyTransfer
  source_schema: Billing
  source_table: Transfers
  source_repo: PaymentsDBs
  datalake_path: Bronze/MoneyTransfer/Billing/Transfers
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 20
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  tier_null_columns: 0
  unverified_columns: 0
---

# bronze_moneytransfer_billing_transfers

> Bronze ingest in `main.bi_db` (1:1 passthrough of `MoneyTransfer.Billing.Transfers`). 20 of 20 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance (Tier N).

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_db.bronze_moneytransfer_billing_transfers` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 20 |
| **Generated** | 2026-05-19 |
| **Created** | Wed Nov 06 04:14:59 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `MoneyTransfer.Billing.Transfers` (`PaymentsDBs` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md`.

- Lake path: `Bronze/MoneyTransfer/Billing/Transfers`
- Copy strategy: `Override`
- Source database: `MoneyTransfer` (`PaymentsDBs`)
- Source schema/table: `Billing.Transfers`
- 20 of 20 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | TransferID | INT | YES | Auto-incrementing unique identifier for each transfer. NONCLUSTERED PK. Used as a secondary lookup key and in range-based monitoring queries (`GetLastTransfersStatusesInPercentage` scans by TransferID ranges). Current values in the ~4.88M range (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 1 | ReferenceID | STRING | YES | Application-generated GUID serving as the primary business key for each transfer. UNIQUE CLUSTERED index makes it the physical sort order. All UPDATE operations (SaveRoutingInfo, SaveTransferOrigin, UpdateTransferStatus, etc.) locate records by ReferenceID via WHERE clause. More reliable than TransferID for cross-service correlation (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 2 | CID | INT | YES | Customer identifier - the user who initiated or owns the transfer. Used for customer-scoped queries: `GetTransfersByCID`, `GetDepotIdOfLastSuccessfulTransferByCid`, `GetLastSuccessTransferDataByCid`. Indexed for performance (IX_Billing_Transfers_CID). References an external customer system (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 3 | CurrencyID | INT | YES | Currency of the transfer amount. No Dictionary table exists in this database; values are managed externally. Sample data shows 2 (likely EUR) and 3 (likely GBP) as common values. Part of composite index IX_Billing_Transfers_CurrencyID_TransferStatusID_TransferID (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 4 | OriginFundingTypeID | INT | YES | Type classification for the source/origin funding instrument. No lookup table in this database; values managed by the MoneyBus/MoneyBusAdapter application layer. Sample data shows 38 as the dominant value. Paired with DestinationFundingTypeID to define the transfer direction (e.g., bank-to-trading, trading-to-bank) (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 5 | DestinationFundingTypeID | INT | YES | Type classification for the destination funding instrument. No lookup table in this database. Sample data shows 33 as the dominant value. Together with OriginFundingTypeID defines the transfer flow direction (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 6 | Amount | DECIMAL | YES | Transfer amount in the currency specified by CurrencyID. Set at creation time and not modified afterward. Observed range in sample: 50 to 10,000. Stored as SQL Server `money` type (4 decimal places) (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 7 | OriginFundingData | STRING | YES | Masked (Dynamic Data Masking: default()) JSON or structured data containing the origin funding instrument details (bank account number, card details, etc.). Contains PII - masked for non-privileged users. Set by `Billing.SaveTransferOrigin`. NULL until the origin funding data is captured (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 8 | DestinationFundingData | STRING | YES | Masked (Dynamic Data Masking: default()) JSON or structured data containing the destination funding instrument details. Contains PII. Set by `Billing.SaveTransferDestination`. NULL until destination data is captured (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 9 | CreateDate | TIMESTAMP | YES | UTC timestamp of transfer creation. Set automatically on INSERT via DEFAULT constraint. Never modified after creation. Used in monitoring queries to scope transfers by time window (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 10 | ModificationDate | TIMESTAMP | YES | UTC timestamp of the most recent modification. Initialized to GETUTCDATE() on INSERT, then auto-updated by trigger `TR_Transfers_ModificationDate` on every UPDATE operation. The gap between CreateDate and ModificationDate indicates processing duration (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 11 | TransferStatusID | INT | YES | Current lifecycle state of the transfer. Implicit FK to Dictionary.TransferStatus: 0=New, 1=Init, 2=Pending, 4=Technical, 7=Cancel, 8=Fail, 9=Sent, 10=Received. See [Transfer Status](../../_glossary.md#transfer-status) for full business definitions. Set to 0 on INSERT by CreateTransfer; updated by UpdateTransferStatus. Status 10 is a hard terminal state. Part of composite index with CurrencyID and TransferID (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 12 | ExReferenceID | STRING | YES | External reference ID - a provider-facing identifier for the transfer. Prefix pattern observed: "TZ" and "TK" followed by a GUID fragment (lowercase, no hyphens). Set at creation time and can be updated by `SaveExtRefId`. Covered by index IX_Transfer_ExReferenceID_Cover for lookups via `GetTransferByExReference` (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 13 | Trace | STRING | YES | Computed column (not persisted) generating a JSON diagnostic string containing HostName, AppName, SUserName, SPID, DBName, and ObjectName at query time. Formula: `CONCAT('{"HostName": "',host_name(),'","AppName": "',app_name(),...}')`. Used for debugging to identify which connection/process last read the row (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 14 | InitFundingId | INT | YES | Initial funding instrument identifier assigned early in the transfer pipeline, before origin/destination routing is finalized. Set by `SaveTransferInitFundingId`. Often NULL - populated only when the initial funding instrument differs from the final origin/destination (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 15 | OriginFundingId | INT | YES | Provider-assigned numeric identifier for the origin funding instrument (bank account, card, wallet). Set by `SaveTransferOriginFundingId`. NULL in most recent sample data, suggesting it may be populated only for certain transfer types or providers (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 16 | DestinationFundingId | INT | YES | Provider-assigned numeric identifier for the destination funding instrument. Set by `SaveTransferDestinationFundingId`. More frequently populated than OriginFundingId in sample data (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 17 | DepotId | INT | YES | Depot/data center identifier determining which processing infrastructure handles this transfer. Set by `SaveRoutingInfo`. Common values: 104 and 166. Default fallback value is 104 (used by `GetDepotIdOfLastSuccessfulTransferByCid` when DepotId is NULL). Determines routing for regional processing (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 18 | CountryId | INT | YES | Country identifier for the customer or transfer jurisdiction. Set by `SaveRoutingInfo` alongside DepotId. Observed values: 74, 112, 143, 191, 218. References an external country lookup. Used for regional routing and compliance (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |
| 19 | ExtTransactionId | STRING | YES | External transaction identifier from the payment provider. Set by `SaveExtTransactionId`. Can be GUID-format (with hyphens removed) or shorter hex strings, depending on the provider. NULL until the provider assigns a transaction reference. Returned by `GetTransferByReferenceID` (Tier 1 — inherited from MoneyTransfer.Billing.Transfers). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `MoneyTransfer.Billing.Transfers` | Primary | `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` |

### 4.2 Pipeline ASCII Diagram

```
MoneyTransfer.Billing.Transfers
        │
        ▼
main.bi_db.bronze_moneytransfer_billing_transfers   ←── this object
        │
        ▼
main.bi_output.bi_ouput_vg_etoro_emoney
main.bi_output.vg_emoney_openbankingdeposit
main.bi_output.vg_payments_mimo_allplatformddr_genienew
... (1 more downstream)
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
| TransferID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| ReferenceID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| CID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| CurrencyID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| OriginFundingTypeID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| DestinationFundingTypeID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| Amount | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| OriginFundingData | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| DestinationFundingData | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| CreateDate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| ModificationDate | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| TransferStatusID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| ExReferenceID | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| Trace | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| InitFundingId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| OriginFundingId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| DestinationFundingId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| DepotId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| CountryId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |
| ExtTransactionId | upstream wiki `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` (bronze passthrough) | 1 | (Tier 1 — inherited from MoneyTransfer.Billing.Transfers) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — domain-expert / reviewer correction from the `.review-needed.md` sidecar. Absolute override; overrides Tier 1.
- **Tier N** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition). Explicit gap disclosure.

*Generated: 2026-05-19 | Tiers: 20 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 TN, 0 U | Elements: 20/20 | Source: bronze_tier1_inheritance*
