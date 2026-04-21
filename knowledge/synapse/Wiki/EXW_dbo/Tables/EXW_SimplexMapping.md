# EXW_dbo.EXW_SimplexMapping

> 103,356-row snapshot of Simplex payment provider transaction data for eToro Wallet crypto purchases via card, covering 2019-07-08 to 2022-09-19 — each row represents a single Simplex payment attempt with its terminal status, funnel drop stage, card details, and reason. Table is frozen (no new data since September 2022; Simplex decommissioned as primary buy provider).

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | Simplex external payment provider API (external feed, not in DB_Schema) |
| **Refresh** | Frozen — last ETL sync 2024-04-09; data stops 2022-09-19 (Simplex decommissioned) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

EXW_SimplexMapping is a staging/reporting table for Simplex-facilitated crypto purchase transactions initiated through the eToro Wallet platform. Simplex was a third-party payment processor that enabled users to buy cryptocurrency using credit/debit cards. Each row represents one payment attempt (whether completed, cancelled, or declined), including the transaction amounts in both fiat and crypto, the funnel stage where the transaction terminated, and enriched card metadata (bank name, BIN country, card type).

The table contains 103,356 rows spanning 2019-07-08 to 2022-09-19. Of these: 76% were cancelled, 22% approved, 2% declined, and a small number refunded. BTC dominates (72% of crypto purchases), followed by ETH (14%), LTC (5%), XLM (4%), XRP (3%), and BCH (2%). Fiat currencies are EUR and GBP only. The single `partner` value is "eToro Wallet" (84% populated, 16% empty records from early data).

**Important**: Simplex was decommissioned as eToro Wallet's primary card-buy provider around late 2022. This table is now a historical archive. No new data will be loaded. The `card_debit_or_credit` column contains noisy mixed values (proper DEBIT/CREDIT labels alongside system error messages like "card bin is blacklisted!") reflecting raw API output without sanitization.

---

## 2. Business Logic

### 2.1 Transaction Funnel — stage_drop

**What**: Simplex's proprietary payment funnel staging — indicates at which step a transaction was last active or terminated.  
**Columns Involved**: stage_drop, status  
**Rules**:
- Stage codes follow a numeric prefix pattern: `00` = initiate, `01` = form entry, `02` = billing/email entry, `03` = verification, `04` = validation, `05`–`09` = policy/auth/KYC stages, `10`–`12` = selfie/approved, `15`–`17` = terminal states
- 35+ distinct stage values observed — this column is a categorical funnel marker, not an ordered integer
- `12 approved` and `11/17 approved` are success states; `15 cancelled` is a terminal cancel
- `99 unexpected value` indicates Simplex processing anomalies

### 2.2 Card Metadata Quality

**What**: Card type and bank details are populated by Simplex's BIN lookup service but contain data quality issues.  
**Columns Involved**: card_debit_or_credit, bin_country, bank_name  
**Rules**:
- Primary valid values for `card_debit_or_credit`: DEBIT, CREDIT, CHARGE CARD, debit (lowercase variant), credit (lowercase variant)
- System messages embedded in `card_debit_or_credit`: "card bin is blacklisted!", "card blacklisted!", "Re-enter transaction", "email is blacklisted!", "domain is blacklisted!", "first used", "Pickup if possible" — these are Simplex risk engine messages accidentally stored in this column
- `bin_country` = ISO-2 country code of card-issuing bank; "Unknown" when BIN lookup fails; "-" for early records

### 2.3 Currency Scope

**What**: All transactions are card-to-crypto purchases in EUR or GBP only.  
**Columns Involved**: currency, total_amount_usd, total_amount, crypto_currency  
**Rules**:
- `currency` = fiat currency of the card charge (EUR or GBP)
- `total_amount` = amount charged in `currency`
- `total_amount_usd` = USD equivalent at time of transaction (both stored as nvarchar despite being numeric values)
- `crypto_currency` = target crypto asset; values: BTC, ETH, LTC, XLM, XRP, BCH

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP index — this table has no natural distribution key (no CID/GCID), so data is spread evenly. HEAP allows fast bulk loads. For analytics, full scans are expected; partition by `processed_at_utc` year would improve query performance if table grows (moot given frozen status).

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| How many Simplex buys were approved by month? | `GROUP BY status, YEAR(CAST(processed_at_utc AS date)), MONTH(CAST(processed_at_utc AS date))` |
| What is the cancellation rate by country? | `GROUP BY country, status` — filter out `country = '-'` (unknown) |
| Which crypto assets had the highest buy volume? | `GROUP BY crypto_currency, SUM(CAST(total_amount_usd AS float))` |
| Which banks had the most declined transactions? | `WHERE status = 'declined' GROUP BY bank_name ORDER BY COUNT(*) DESC` |
| What was the funnel drop-off by stage? | `GROUP BY stage_drop ORDER BY cnt DESC` — 35 stages; "02 bi_cc_page" is the largest single drop point |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_dbo.EXW_PaymentReconciliation | `EXW_PaymentReconciliation.UTI = EXW_SimplexMapping.uti` | Reconcile Simplex transactions with internal payment records |
| EXW_dbo.EXW_SimplexChargebacks | `EXW_SimplexChargebacks.Payment_ID ~ EXW_SimplexMapping.long_id` | Match chargebacks to original Simplex transactions |

### 3.4 Gotchas

- **processed_at_utc stored as nvarchar** — despite the name, it's a string "MM/DD/YYYY HH:MM:SS" format; cast explicitly: `CAST(processed_at_utc AS datetime2)` or parse with CONVERT
- **total_amount_usd and total_amount are nvarchar** — stored as strings despite being numeric; `CAST(total_amount_usd AS float)` required for arithmetic
- **card_debit_or_credit is not a clean enum** — treat anything not in {DEBIT, CREDIT, CHARGE CARD} as a system message, not a card type
- **last_4_digits is nvarchar** — stored as string; mostly empty (blanks); do not expect numeric values
- **uti field is mostly "-"** — UTI (Unique Transaction Identifier) is only populated for approved transactions; cancelled records show "-"
- **Table is frozen** — do not expect new data; UpdateDate 2024-04-09 reflects last ETL metadata sync, not new payment records

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description copied verbatim from upstream production wiki |
| Tier 2 | Derived from SP/ETL code analysis |
| Tier 3 | Inferred from column name, type, and data samples |
| Tier 4 | Best-available inference — no upstream wiki, external source |
| Tier 5 | Placeholder — domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | partner | nvarchar(256) | YES | Payment partner identifier. In this dataset: "eToro Wallet" (84%) or empty (16% early records with no partner tag). (Tier 4 — Simplex API) |
| 2 | processed_at_utc | nvarchar(256) | YES | UTC timestamp when the payment was processed by Simplex, stored as string in format MM/DD/YYYY HH:MM:SS. Range: 2019-07-08 to 2022-09-19. Use CAST to datetime2 for date operations. (Tier 4 — Simplex API) |
| 3 | country | nvarchar(256) | YES | ISO-2 country code of the cardholder. "-" indicates unknown/not captured in early records. Top markets: GB, AU, GR, CH and others. (Tier 4 — Simplex API) |
| 4 | currency | nvarchar(256) | YES | Fiat currency of the card charge. Values: EUR, GBP only in this dataset. (Tier 4 — Simplex API) |
| 5 | total_amount_usd | nvarchar(256) | YES | USD-equivalent amount of the payment at time of transaction, stored as nvarchar despite being numeric. Cast to float for arithmetic. (Tier 4 — Simplex API) |
| 6 | crypto_currency | nvarchar(256) | YES | Target cryptocurrency the user intended to purchase. Values: BTC (72%), ETH (14%), LTC (5%), XLM (4%), XRP (3%), BCH (2%). (Tier 4 — Simplex API) |
| 7 | total_amount | nvarchar(256) | YES | Amount charged in the fiat currency (see `currency`), stored as nvarchar. Represents the card charge amount before crypto conversion. (Tier 4 — Simplex API) |
| 8 | long_id | nvarchar(256) | YES | Simplex internal transaction GUID — primary transaction identifier within the Simplex system. Used for reconciliation against chargebacks. (Tier 4 — Simplex API) |
| 9 | uti | nvarchar(256) | YES | Unique Transaction Identifier (UTI) assigned by Simplex upon successful completion. Populated only for approved transactions; "-" for cancelled/declined. Used for reconciliation with EXW_PaymentReconciliation.UTI. (Tier 4 — Simplex API) |
| 10 | status | nvarchar(256) | YES | Terminal status of the Simplex transaction. Values: cancelled (76%), approved (22%), declined (2%), refunded (<0.1%). (Tier 4 — Simplex API) |
| 11 | UpdateDate | datetime | YES | ETL-managed load timestamp indicating when this record was last synced to Synapse. Not the transaction date — use processed_at_utc for business date. Max = 2024-04-09. (Tier 2 — external ETL) |
| 12 | reason | nvarchar(256) | YES | Human-readable reason for the transaction outcome. Examples: "User discontinues", "partner policy", "Bank", "approved", "Do not honour". Populated for all statuses. (Tier 4 — Simplex API) |
| 13 | stage_drop | nvarchar(256) | YES | Simplex payment funnel stage where the transaction last progressed or terminated. 35+ distinct values using a numeric prefix coding scheme (00=initiate, 12=approved, etc.). Key drop points: "02 bi_cc_page" (billing page, 29%), "12 approved" (15%), "08 auth" (13%). (Tier 4 — Simplex API) |
| 14 | bank_further_reason | nvarchar(256) | YES | Issuing bank's supplemental decline reason message, as returned by Simplex. Examples: "Do not honour", "-" (not applicable or not provided). (Tier 4 — Simplex API) |
| 15 | card_debit_or_credit | nvarchar(256) | YES | Card type as determined by BIN lookup. Primary values: DEBIT, CREDIT, CHARGE CARD. Also contains system risk-engine messages (e.g., "card bin is blacklisted!", "Re-enter transaction") stored in this field — treat non-{DEBIT,CREDIT,CHARGE CARD} values as system flags, not card types. (Tier 4 — Simplex API) |
| 16 | bin_country | nvarchar(256) | YES | ISO-2 country code of the card-issuing bank, determined by BIN lookup. "Unknown" when BIN resolution fails; "-" for early records without BIN data. (Tier 4 — Simplex API) |
| 17 | bank_name | nvarchar(256) | YES | Name of the card-issuing bank as returned by BIN lookup. Examples: "MONZO BANK LIMITED", "HSBC UK BANK PLC", "NATIONAL BANK OF GREECE S.A.". "-" when BIN data unavailable. (Tier 4 — Simplex API) |
| 18 | last_4_digits | nvarchar(256) | YES | Last 4 digits of the payment card used, stored as nvarchar. Mostly empty in this dataset. Used for fraud/chargeback investigation. (Tier 4 — Simplex API) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| All 17 data columns | Simplex API (external provider) | API response fields | Passthrough, no transformation |
| UpdateDate | ETL pipeline | — | Load timestamp |

### 5.2 ETL Pipeline

```
Simplex Payment Provider API (external, third-party)
  |-- External pipeline (Fivetran / ADF) — no SSDT SP ---|
  v
EXW_dbo.EXW_SimplexMapping (103K rows, ROUND_ROBIN, HEAP)
  |-- Data frozen 2022-09-19 — Simplex decommissioned ---|
  v
No UC Generic Pipeline mapping (not in bronze_opsdb_dbo_vw_unitycatalog_mapping_tables)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| uti | EXW_dbo.EXW_PaymentReconciliation.UTI | Simplex UTI links to internal payment reconciliation records |
| long_id | EXW_dbo.EXW_SimplexChargebacks.Payment_ID | Simplex transaction GUID links to chargeback tracking |

### 6.2 Referenced By

| Object | Column | Description |
|--------|--------|-------------|
| EXW_dbo.EXW_PaymentReconciliation | SimplexCurr, SimplexAmountCurr, SimplexAmountUSD | Aggregated Simplex transaction data joined during payment reconciliation |

---

## 7. Sample Queries

### Simplex Approval Rate by Crypto Asset

```sql
SELECT
    crypto_currency,
    COUNT(*) AS total_attempts,
    SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) AS approved,
    CAST(SUM(CASE WHEN status = 'approved' THEN 1 ELSE 0 END) AS float)
        / COUNT(*) * 100 AS approval_pct
FROM [EXW_dbo].[EXW_SimplexMapping]
WHERE crypto_currency IS NOT NULL AND crypto_currency != ''
GROUP BY crypto_currency
ORDER BY total_attempts DESC;
```

### Funnel Drop Analysis — Where Did Users Abandon?

```sql
SELECT
    stage_drop,
    status,
    COUNT(*) AS cnt,
    CAST(COUNT(*) AS float) / SUM(COUNT(*)) OVER () * 100 AS pct
FROM [EXW_dbo].[EXW_SimplexMapping]
GROUP BY stage_drop, status
ORDER BY cnt DESC;
```

### Top Banks by Decline Rate (BIN Country = GB)

```sql
SELECT
    bank_name,
    COUNT(*) AS total,
    SUM(CASE WHEN status = 'declined' THEN 1 ELSE 0 END) AS declined,
    CAST(SUM(CASE WHEN status = 'declined' THEN 1 ELSE 0 END) AS float)
        / NULLIF(COUNT(*), 0) * 100 AS decline_pct
FROM [EXW_dbo].[EXW_SimplexMapping]
WHERE bin_country = 'GB'
    AND bank_name != '-'
GROUP BY bank_name
HAVING COUNT(*) > 50
ORDER BY decline_pct DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian (Confluence/Jira) sources found for EXW_SimplexMapping. This table reflects raw third-party provider data; business context is captured in payment operations runbooks rather than eToro-internal Confluence.

---

*Generated: 2026-04-20 | Quality: 8.2/10 | Phases: 11/14*  
*Tiers: 0 T1, 1 T2, 0 T3, 17 T4, 0 T5 | Elements: 18/18, Logic: 3/10, Data Evidence: P2+P3 PASS*  
*Object: EXW_dbo.EXW_SimplexMapping | Type: Table | Production Source: Simplex API (external)*
