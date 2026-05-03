# EXW_Wallet.AmlValidations

> 2.8M-row Anti-Money Laundering validation results table recording every AML screening outcome for crypto wallet transfers (send and receive) from 2018-07-31 to present. Sourced from `WalletDB.Wallet.AmlValidations` via Generic Pipeline (parquet, 10-minute refresh). Each row represents one AML provider check against a blockchain address/transaction, capturing provider risk rating, decision outcome, and detailed JSON response.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.AmlValidations (Generic Pipeline bronze import) |
| **Refresh** | Every 10 minutes via Generic Pipeline (parquet, copy_strategy=parquet) |
| **Synapse Distribution** | HASH(CorrelationId) |
| **Synapse Index** | HEAP |
| **UC Target** | `Bronze/WalletDB/Wallet/AmlValidations/` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (Generic Pipeline) |

---

## 1. Business Meaning

`EXW_Wallet.AmlValidations` stores the results of Anti-Money Laundering (AML) screenings performed on every inbound and outbound cryptocurrency transfer in the eToro crypto wallet system. Each row represents a single validation check by an AML provider (e.g., Chainalysis) against a blockchain address or transaction hash.

The table contains ~2.8M rows spanning from July 2018 to present. Three AML providers are active: provider 1 (Chainalysis, ~1.17M checks), provider 4 (~1.02M checks), and provider 3 (~570K checks). Approximately 57% of records are receive-side validations (`IsSend=False`) and 43% are send-side (`IsSend=True`).

Risk outcomes are encoded in `ProviderStatus`: Green (50%), Amber (28%), NA (20%), Error (<1%), Red (<1%), InvalidAddress (<1%). The `IsPositiveDecision` flag indicates whether the transfer was ultimately approved (98.4% positive, 1.6% negative).

The table is loaded directly from `WalletDB.Wallet.AmlValidations` via the Generic Pipeline with no intermediate stored procedure. It is consumed downstream by `EXW_dbo.SP_EXW_Fact_Transactions`, which joins AML results to crypto transactions using `CorrelationId` and `BlockchainTransactionId`/`WalletId`, applying ROW_NUMBER to pick the most recent validation per correlation and per received transaction.

---

## 2. Business Logic

### 2.1 AML Provider Risk Rating

**What**: Each crypto transfer is screened by an AML provider that returns a risk status.
**Columns Involved**: AmlProviderId, ProviderStatus, IsPositiveDecision
**Rules**:
- ProviderStatus values: Green (safe), Amber (medium risk), Red (high risk), NA (not assessed/legacy provider), Error (provider failure), InvalidAddress (malformed address), 0 (legacy/unknown).
- IsPositiveDecision=True means the transfer passed the AML check and was approved. False means it was blocked or flagged.
- AmlProviderId identifies the screening provider: 1 (Chainalysis), 3 (legacy provider), 4 (additional provider).

### 2.2 Transaction Direction

**What**: Each validation is associated with either a send or receive crypto transfer.
**Columns Involved**: IsSend, Address, WalletId
**Rules**:
- IsSend=True: outbound transfer from eToro wallet to external address.
- IsSend=False: inbound transfer from external address to eToro wallet.
- Address contains the external blockchain address involved in the transfer.

### 2.3 Downstream Consumption in SP_EXW_Fact_Transactions

**What**: The fact transactions SP picks the latest AML validation per transfer.
**Columns Involved**: CorrelationId, CryptoId, IsSend, WalletId, BlockchainTransactionId, ProviderStatus, IsPositiveDecision
**Rules**:
- For send-side: ROW_NUMBER partitioned by (CorrelationId, CryptoId) ordered by Created DESC — latest validation wins.
- For receive-side: ROW_NUMBER partitioned by (BlockchainTransactionId, WalletId) ordered by Created DESC — latest validation wins.
- Only the Rn=1 or RnReceived=1 row is used in downstream joins.

### 2.4 CategoryId Sparsity

**What**: CategoryId is populated for less than 1.1% of rows.
**Columns Involved**: CategoryId
**Rules**:
- 98.9% of rows have NULL CategoryId.
- When populated, contains AML risk category codes (e.g., 46, 21, 16, 9) — likely Chainalysis entity category identifiers.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- Distributed by HASH(CorrelationId) — queries filtering or joining on CorrelationId avoid data movement.
- HEAP (no clustered index) — full table scans for non-CorrelationId predicates. Consider filtering by partition_date or Created for time-bounded queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| How many transfers were flagged as high risk? | `WHERE ProviderStatus = 'Red' AND IsPositiveDecision = 0` |
| What is the AML pass rate over time? | `GROUP BY CAST(Created AS DATE), IsPositiveDecision` with `COUNT(*)` |
| Which provider has the most Amber ratings? | `GROUP BY AmlProviderId, ProviderStatus` |
| Get latest validation for a correlation | `ROW_NUMBER() OVER (PARTITION BY CorrelationId ORDER BY Created DESC) = 1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| EXW_Wallet.SentTransactions | `st.CorrelationId = av.CorrelationId` | Link AML result to sent transaction details |
| EXW_dbo.External_WalletDB_Wallet_TransactionsView | Via SP_EXW_Fact_Transactions temp tables on CorrelationId / BlockchainTransactionId+WalletId | Enrich transaction facts with AML outcome |

### 3.4 Gotchas

- **Multiple validations per transfer**: A single CorrelationId can have multiple AML checks (re-checks, different providers). Always use ROW_NUMBER to pick the latest.
- **ProviderStatus '0' and 'NA'**: Legacy values from older provider integrations. Do not treat as equivalent to NULL.
- **etr_y/etr_ym/etr_ymd columns**: Appear unpopulated in sampled data — may be deprecated or only filled for specific partitions. Use `partition_date` or `Created` for time filtering instead.
- **DetailsJson structure varies by provider**: Provider 1 returns `{Asset, TransferReference, Cluster, Rating}` JSON. Other providers may return different structures or empty JSON.
- **CategoryId mostly NULL**: Only ~29K of 2.8M rows have a value. Do not use as a primary filter without understanding the provider-specific semantics.
- **Address column contains PII-adjacent data**: Blockchain addresses are pseudo-anonymous but may be linkable. Handle with care in exports.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | ETL-computed or framework-added column |
| Tier 3 | No upstream wiki; description grounded in DDL, sample data, and SP reader code |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | int | YES | Primary key identifier for the AML validation record. Auto-incremented in the production system. (Tier 3 — WalletDB.Wallet.AmlValidations, no upstream wiki located) |
| 2 | AmlProviderId | int | YES | Identifier of the AML screening provider that performed the validation. Observed values: 1=Chainalysis, 3=legacy provider, 4=additional provider. (Tier 3 — WalletDB.Wallet.AmlValidations, no upstream wiki located) |
| 3 | IsSend | bit | YES | Direction flag for the crypto transfer being validated. 1=outbound send from eToro wallet to external address, 0=inbound receive from external address to eToro wallet. (Tier 3 — WalletDB.Wallet.AmlValidations, no upstream wiki located) |
| 4 | Address | varchar(max) | YES | Blockchain address involved in the transfer. For sends, the destination address; for receives, the source address. Format varies by blockchain (e.g., Bitcoin bc1/1/3 prefixes, Ethereum 0x prefix, XRP r prefix, Cardano addr1 prefix). (Tier 3 — WalletDB.Wallet.AmlValidations, no upstream wiki located) |
| 5 | WalletId | uniqueidentifier | YES | GUID identifying the eToro crypto wallet involved in the transfer. Links to the wallet subsystem for customer-level resolution. (Tier 3 — WalletDB.Wallet.AmlValidations, no upstream wiki located) |
| 6 | Amount | numeric(36,18) | YES | Crypto amount involved in the transfer, expressed in the native cryptocurrency unit (e.g., BTC, ETH, XRP). High precision (18 decimal places) to handle fractional crypto amounts. (Tier 3 — WalletDB.Wallet.AmlValidations, no upstream wiki located) |
| 7 | ProviderStatus | varchar(max) | YES | AML risk rating returned by the screening provider. Observed values: Green (safe, 50%), Amber (medium risk, 28%), NA (not assessed/legacy, 20%), Error (provider failure, <1%), Red (high risk, <1%), InvalidAddress (malformed address, <1%), 0 (legacy/unknown, <0.01%). (Tier 3 — WalletDB.Wallet.AmlValidations, no upstream wiki located) |
| 8 | IsPositiveDecision | bit | YES | Final AML decision outcome. 1=transfer approved/passed AML check, 0=transfer blocked or flagged for manual review. 98.4% of records are positive. (Tier 3 — WalletDB.Wallet.AmlValidations, no upstream wiki located) |
| 9 | CorrelationId | uniqueidentifier | YES | GUID correlating this AML validation to the originating crypto transfer request. Distribution key for this table. Used downstream by SP_EXW_Fact_Transactions to join AML results to transactions. (Tier 3 — WalletDB.Wallet.AmlValidations, no upstream wiki located) |
| 10 | Created | datetime2(7) | YES | Timestamp when this AML validation record was created (i.e., when the provider returned the screening result). Range: 2018-07-31 to present. (Tier 3 — WalletDB.Wallet.AmlValidations, no upstream wiki located) |
| 11 | BlockchainTransactionId | varchar(max) | YES | Blockchain transaction hash associated with this validation. Used for receive-side AML lookups. NULL for some send-side validations where the transaction has not yet been broadcast. (Tier 3 — WalletDB.Wallet.AmlValidations, no upstream wiki located) |
| 12 | DetailsJson | varchar(max) | YES | Raw JSON response from the AML provider. Structure varies by provider. Provider 1 (Chainalysis) returns: `{Asset, TransferReference, Cluster:{Name,Category}, Rating}`. Other providers may return `{alerts:[]}` or empty string. (Tier 3 — WalletDB.Wallet.AmlValidations, no upstream wiki located) |
| 13 | CryptoId | int | YES | Identifier for the cryptocurrency being transferred. Observed values include: 1=BTC, 2=ETH, 4=XRP, 18=ADA. Maps to the crypto asset dictionary in the wallet system. (Tier 3 — WalletDB.Wallet.AmlValidations, no upstream wiki located) |
| 14 | etr_y | varchar(max) | YES | Generic Pipeline ETL partition column — year component. Appears unpopulated in sampled data. (Tier 2 — Generic Pipeline) |
| 15 | etr_ym | varchar(max) | YES | Generic Pipeline ETL partition column — year-month component. Appears unpopulated in sampled data. (Tier 2 — Generic Pipeline) |
| 16 | etr_ymd | varchar(max) | YES | Generic Pipeline ETL partition column — year-month-day component. Appears unpopulated in sampled data. (Tier 2 — Generic Pipeline) |
| 17 | SynapseUpdateDate | datetime | YES | Timestamp of the last Generic Pipeline ingestion that touched this row in Synapse. Used for ETL bookkeeping and incremental load tracking. (Tier 2 — Generic Pipeline) |
| 18 | partition_date | date | YES | Date-level partition column added by the Generic Pipeline for data organization. Aligns with the Created date of the AML validation. (Tier 2 — Generic Pipeline) |
| 19 | CategoryId | int | YES | AML risk category identifier from the screening provider. Populated for <1.1% of rows. When present, encodes entity category codes (e.g., sanctions list, darknet, ransomware). NULL for the majority of records. (Tier 3 — WalletDB.Wallet.AmlValidations, no upstream wiki located) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Id | WalletDB.Wallet.AmlValidations | Id | Passthrough |
| AmlProviderId | WalletDB.Wallet.AmlValidations | AmlProviderId | Passthrough |
| IsSend | WalletDB.Wallet.AmlValidations | IsSend | Passthrough |
| Address | WalletDB.Wallet.AmlValidations | Address | Passthrough |
| WalletId | WalletDB.Wallet.AmlValidations | WalletId | Passthrough |
| Amount | WalletDB.Wallet.AmlValidations | Amount | Passthrough |
| ProviderStatus | WalletDB.Wallet.AmlValidations | ProviderStatus | Passthrough |
| IsPositiveDecision | WalletDB.Wallet.AmlValidations | IsPositiveDecision | Passthrough |
| CorrelationId | WalletDB.Wallet.AmlValidations | CorrelationId | Passthrough |
| Created | WalletDB.Wallet.AmlValidations | Created | Passthrough |
| BlockchainTransactionId | WalletDB.Wallet.AmlValidations | BlockchainTransactionId | Passthrough |
| DetailsJson | WalletDB.Wallet.AmlValidations | DetailsJson | Passthrough |
| CryptoId | WalletDB.Wallet.AmlValidations | CryptoId | Passthrough |
| etr_y | Generic Pipeline | — | ETL-added partition column |
| etr_ym | Generic Pipeline | — | ETL-added partition column |
| etr_ymd | Generic Pipeline | — | ETL-added partition column |
| SynapseUpdateDate | Generic Pipeline | — | ETL-added ingestion timestamp |
| partition_date | Generic Pipeline | — | ETL-added partition date |
| CategoryId | WalletDB.Wallet.AmlValidations | CategoryId | Passthrough |

### 5.2 ETL Pipeline

```
WalletDB.Wallet.AmlValidations (production, WalletDB)
  |-- Generic Pipeline (parquet, 10-min refresh, generic_id=719) --|
  v
EXW_Wallet_tmp.AmlValidations_tmp (staging)
  |-- Generic Pipeline swap --|
  v
EXW_Wallet.AmlValidations (2.8M rows, Synapse)
  |-- Read by SP_EXW_Fact_Transactions --|
  v
EXW_dbo.Fact_Transactions (downstream consumer)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| WalletId | WalletDB.Wallet.Wallets | Links to the eToro crypto wallet record |
| CryptoId | WalletDB crypto asset dictionary | Identifies the cryptocurrency involved |
| AmlProviderId | WalletDB AML provider config | Identifies the screening provider |
| CategoryId | AML category dictionary | Risk category classification from provider |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CorrelationId, CryptoId, IsSend | EXW_dbo.SP_EXW_Fact_Transactions | Joins AML results to send-side transactions via CorrelationId |
| BlockchainTransactionId, WalletId | EXW_dbo.SP_EXW_Fact_Transactions | Joins AML results to receive-side transactions via BlockchainTransactionId+WalletId |

---

## 7. Sample Queries

### 7.1 AML Risk Distribution by Provider

```sql
SELECT
    AmlProviderId,
    ProviderStatus,
    COUNT(*) AS validation_count,
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY AmlProviderId) AS DECIMAL(5,2)) AS pct
FROM [EXW_Wallet].[AmlValidations]
GROUP BY AmlProviderId, ProviderStatus
ORDER BY AmlProviderId, validation_count DESC;
```

### 7.2 Daily AML Block Rate (Red or Negative Decision)

```sql
SELECT
    CAST(Created AS DATE) AS validation_date,
    COUNT(*) AS total_checks,
    SUM(CASE WHEN IsPositiveDecision = 0 THEN 1 ELSE 0 END) AS blocked,
    CAST(SUM(CASE WHEN IsPositiveDecision = 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS block_rate_pct
FROM [EXW_Wallet].[AmlValidations]
WHERE Created >= '2026-01-01'
GROUP BY CAST(Created AS DATE)
ORDER BY validation_date DESC;
```

### 7.3 Latest AML Validation per CorrelationId (Send-Side Pattern)

```sql
SELECT *
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY CorrelationId, CryptoId ORDER BY Created DESC) AS rn
    FROM [EXW_Wallet].[AmlValidations]
    WHERE IsSend = 1
      AND partition_date >= '2026-04-01'
) sub
WHERE rn = 1;
```

---

## 8. Atlassian Knowledge Sources

- [AML Wallet Alerts](https://etoro-jira.atlassian.net/wiki/spaces/OTS/pages/13861650438/AML+Wallet+Alerts) — Describes real-time AML checks via Chainalysis on every crypto transfer.
- [Crypto Wallet - Full System Documentation](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/12068978715/Crypto+Wallet+-+Full+System+Documentation) — Architecture overview including AML service component.
- [Travel Rule - SEND - VASP to VASP - HLD](https://etoro-jira.atlassian.net/wiki/spaces/BG/pages/12569772051/Travel+Rule+-+SEND+-+VASP+to+VASP+-+HLD) — References AML tables in WalletDB including AmlValidations.
- [AML High-Value Transactions Monitoring Script](https://etoro-jira.atlassian.net/wiki/spaces/SRE/pages/13306593354/AML+High-Value+Transactions+Monitoring+Script) — Monitoring script that queries WalletDB AML data.

---

*Generated: 2026-04-30 | Quality: 7.0/10 | Phases: 11/14*
*Tiers: 0 T1, 5 T2, 14 T3, 0 T4, 0 T5 | Elements: 19/19, Logic: 7/10, Lineage: 8/10*
*Object: EXW_Wallet.AmlValidations | Type: Table | Production Source: WalletDB.Wallet.AmlValidations (Generic Pipeline)*
