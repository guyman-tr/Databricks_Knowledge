---
object_fqn: main.billing.bronze_etoro_billing_redeem
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_redeem
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 24
row_count: null
generated_at: '2026-05-18T10:58:37Z'
upstreams:
- etoro.Billing.Redeem
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md
  source_database: etoro
  source_schema: Billing
  source_table: Redeem
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/Redeem
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 24
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_billing_redeem

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.Redeem`). 24 of 24 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_redeem` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 24 |
| **Generated** | 2026-05-18 |
| **Created** | Mon Mar 11 09:37:14 UTC 2024 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.Redeem` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md`.

- Lake path: `Bronze/etoro/Billing/Redeem`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.Redeem`
- 24 of 24 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | RedeemID | INT | YES | Surrogate PK, auto-increment. Output parameter in Billing.Redeem_Add (SET @RedeemID = SCOPE_IDENTITY()) (Tier 1 — inherited from etoro.Billing.Redeem). |
| 1 | CID | INT | YES | Customer ID. No FK constraint but standard eToro CID referencing the customer who submitted the redemption request (Tier 1 — inherited from etoro.Billing.Redeem). |
| 2 | PositionID | LONG | YES | The trading position being redeemed. No FK constraint (BIGINT, references Trade.PositionTbl). Indexed with RedeemID (IX_PositionID_RedeemID). Used in idempotency guard: only one active redeem allowed per PositionID (Tier 1 — inherited from etoro.Billing.Redeem). |
| 3 | RedeemStatusID | INT | YES | Current state in the redemption state machine. FK to Dictionary.RedeemStatus. Transitions validated by Dictionary.RedeemStatusStateMachine in RedeemStatusUpdate. Values: 1=PositionPending, 2=Rejected, 3=Approved, 4=ReadyToRedeem, 5=PositionClosing, 6=PositionClosed, 7=TransactionInProcess, 8=TransactionDone, 20=Terminated, 21=FailedToCancel, 25=TransferNegativeBalance, 100=New. Distribution: 20=Terminated (60%), 1=PositionPending (32%) (Tier 1 — inherited from etoro.Billing.Redeem). |
| 4 | RedeemReasonID | INT | YES | Reason code for non-success outcomes. FK to Dictionary.RedeemReason. Set by RedeemStatusUpdate when redemption fails or is cancelled. Values: 1=RreTradeBlocked, 2=RreFundingBlocked, 7=RejectedByOps, 8=FailedByTrading, 9=FailedByWallet, 10=CanceledByOps, 11-14=ServerErrors, 15=CanceledByUser, etc. NULL for successfully completed redemptions (status=8) (Tier 1 — inherited from etoro.Billing.Redeem). |
| 5 | Units | DECIMAL | YES | Crypto quantity to redeem (decimal precision for crypto amounts). Set on INSERT via @Units. May be updated to actual closed amount when status=6: `Units = IIF(@RedeemStatusID = 6, ISNULL(@Units, Units), Units)` in RedeemStatusUpdate (Tier 1 — inherited from etoro.Billing.Redeem). |
| 6 | RedeemFee | DECIMAL | YES | eToro platform fee on the redemption. Set on INSERT via @Fee (maps to column RedeemFee). Approximately 2% of the redemption amount based on observed data (Tier 1 — inherited from etoro.Billing.Redeem). |
| 7 | WalletFee | DECIMAL | YES | Fee for the crypto wallet service. Currently always NULL in production data - either not charged separately, deducted from AmountOnClose, or reserved for future use (Tier 1 — inherited from etoro.Billing.Redeem). |
| 8 | BlockchainFee | DECIMAL | YES | On-chain network fee (gas fee) for the blockchain transfer. Populated for Bitcoin (e.g., 0.000256 BTC) and certain other instruments. NULL for instruments where blockchain fees are absorbed or not applicable (Tier 1 — inherited from etoro.Billing.Redeem). |
| 9 | AmountOnRequest | DECIMAL | YES | Fiat value of the redemption as calculated when the customer submitted the request. Set on INSERT via @Amount. Reflects the crypto price at request time. May differ from AmountOnClose if price moves before the position closes (Tier 1 — inherited from etoro.Billing.Redeem). |
| 10 | AmountOnClose | DECIMAL | YES | Fiat value realized when the position was actually closed. Set by RedeemStatusUpdate when status transitions to 6 (PositionClosed): `AmountOnClose = IIF(@RedeemStatusID = 6, @Amount, AmountOnClose)`. NULL until PositionClosed state is reached (Tier 1 — inherited from etoro.Billing.Redeem). |
| 11 | FundingID | INT | YES | The payment method funding record. FK to Billing.Funding(FundingID). Indexed (IX_BillingRedeem_FundingID). Identifies which funding method will receive the fiat payout. Set on INSERT (Tier 1 — inherited from etoro.Billing.Redeem). |
| 12 | InstrumentID | INT | YES | The trading instrument being redeemed. FK to Trade.InstrumentMetaData(InstrumentID). Examples: 100001=Bitcoin, 100017=another crypto. Used by multiple procedures for instrument-specific business logic (Tier 2 — inherited from etoro.Billing.Redeem). |
| 13 | RequestDate | TIMESTAMP | YES | UTC timestamp when the customer submitted the redemption request. Set to GETUTCDATE() on INSERT by Billing.Redeem_Add (Tier 1 — inherited from etoro.Billing.Redeem). |
| 14 | LastModificationDate | TIMESTAMP | YES | UTC timestamp of the most recent status change or update. Set to GETUTCDATE() on INSERT and updated on every status change by RedeemStatusUpdate. Part of covering index (ix_BillingRedeem_Covering) (Tier 1 — inherited from etoro.Billing.Redeem). |
| 15 | WithdrawToFundingID | INT | YES | Link to the withdrawal record. FK to Billing.WithdrawToFunding(ID). Set when the redemption payout is linked to a specific withdrawal-to-funding process (Tier 1 — inherited from etoro.Billing.Redeem). |
| 16 | ManagerOpsID | INT | YES | Operations team staff member ID who handled this redemption. Set by RedeemStatusUpdate via @ManagerOpsId. NULL for automated redemptions (Tier 1 — inherited from etoro.Billing.Redeem). |
| 17 | ManagerID | INT | YES | Manager staff member ID. Set by RedeemStatusUpdate via @ManagerID. NULL for automated redemptions (Tier 1 — inherited from etoro.Billing.Redeem). |
| 18 | Remark | STRING | YES | Free-text note added by operations staff. Set by RedeemStatusUpdate via @Remark. Preserved across updates (ISNULL(@Remark, Remark) pattern) (Tier 1 — inherited from etoro.Billing.Redeem). |
| 19 | CryptoID | INT | YES | Crypto-wallet-system identifier for the crypto asset. Set on INSERT. Distinct from InstrumentID: CryptoID is the wallet/exchange identifier (e.g., 2=Bitcoin, 18=another asset) while InstrumentID is the trading system identifier (Tier 1 — inherited from etoro.Billing.Redeem). |
| 20 | IPAddress | STRING | YES | Client IP address at the time the redemption was submitted. Set on INSERT via @IPAddress. Used for fraud/compliance audit (Tier 1 — inherited from etoro.Billing.Redeem). |
| 21 | NetProfit | DECIMAL | YES | Net profit on the redemption after fees. Default=0. Populated by the settlement process (Tier 1 — inherited from etoro.Billing.Redeem). |
| 22 | RedeemTypeID | INT | YES | Redemption type: 0=Standard crypto-to-fiat (DEFAULT, 99.9% of records), 1=Special type (21 rows, appears to be NFT or internal transfer per procedures GetNFTRedeemDetailsByOperationID). Added in PTL-76 (June 2022) (Tier 1 — inherited from etoro.Billing.Redeem). |
| 23 | OperationID | STRING | YES | External operation reference GUID. Added in PTL-76 alongside RedeemTypeID. Used for NFT redemptions and cross-system operation tracking (Tier 1 — inherited from etoro.Billing.Redeem). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.Redeem` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.Redeem
        │
        ▼
main.billing.bronze_etoro_billing_redeem   ←── this object
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
| RedeemID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| CID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| PositionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| RedeemStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| RedeemReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| Units | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| RedeemFee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| WalletFee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| BlockchainFee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| AmountOnRequest | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| AmountOnClose | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| FundingID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| InstrumentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| RequestDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| LastModificationDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| WithdrawToFundingID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| ManagerOpsID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| Remark | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| CryptoID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| IPAddress | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| NetProfit | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| RedeemTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |
| OperationID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Redeem.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Redeem) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 24 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 24/24 | Source: bronze_tier1_inheritance*
