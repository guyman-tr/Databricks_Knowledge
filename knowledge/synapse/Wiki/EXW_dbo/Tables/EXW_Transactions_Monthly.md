# EXW_dbo.EXW_Transactions_Monthly

> **DEPRECATED** — Historical monthly wallet transaction summary per GCID×CryptoId×WalletId, frozen at 2023-12-31. 50.1M rows covering 489,135 GCIDs across 69 months (2018-04-30 to 2023-12-31). SP_EXW_Transactions_Monthly exists but its entire body is commented out (NO-OP). This table is no longer updated. Use EXW_FactTransactions for current transaction data or EXW_30DayBalanceExtract for recent balance snapshots.

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | EXW_dbo.External_WalletDB_Wallet_TransactionsView (historical) |
| **Refresh** | **DEPRECATED** — SP_EXW_Transactions_Monthly body is entirely commented out. Last updated 2024-01-01. |
| **Row Count** | 50,127,679 (frozen at 2023-12-31) |
| **Data Coverage** | 2018-04-30 to 2023-12-31 (69 months, 489,135 GCIDs) |
| **Synapse Distribution** | HASH (GCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only historical archive |

---

## 1. Business Meaning

EXW_Transactions_Monthly was the historical monthly aggregation of wallet transaction activity per GCID×CryptoId×WalletId, providing end-of-month summaries of sent amounts, received amounts, and fees for each wallet. With 50.1M rows across 489,135 unique users and 69 months (Apr 2018 – Dec 2023), it served as a pre-aggregated source for monthly financial reporting.

The table is frozen. SP_EXW_Transactions_Monthly(@d date) exists in the SSDT repository but its operational logic is entirely wrapped in a comment block — the SP is a NO-OP. The last data write was 2024-01-01 (covering the December 2023 EOM date). No equivalent replacement has been identified in the current EXW_dbo schema.

**For current monthly analysis**, analysts should aggregate directly from EXW_FactTransactions using the External_WalletDB_Wallet_TransactionsView as the source, or use EXW_30DayBalanceExtract for rolling recent-period balance data.

EOMDate is the last day of the calendar month containing @d — data was organized by end-of-month snapshots. The CCI makes historical aggregation queries reasonably efficient despite the table being frozen.

---

## 2. Business Logic

### 2.1 Monthly Aggregation (Archived Logic)

**What**: Monthly aggregation of all wallet sent/received transactions per GCID×CryptoId×WalletId. Documented from the commented-out SP body — this logic ran until December 2023.

**Columns Involved**: SentAmount, RecivedAmount, Amount, AmountUSD, EtoroFees, BlockchainFee, RelevantBlockchainFee, EffectiveBlockchainFee, EOMDate, EOMDateID

**Rules** (from commented SP code):
- Source: EXW_dbo.External_WalletDB_Wallet_TransactionsView, filter: TransStatusId IN (1,2), TransDate within calendar month
- SentAmount: ROUND(SUM(Amount + EtoroFees + RelevantBlockchainFee), 8, 1) for ActionTypeId=1 (sent) transactions
- RecivedAmount: ROUND(SUM(Amount), 8, 1) for ActionTypeId=2 (received) transactions
- Amount: RecivedAmount - SentAmount (net monthly flow)
- AmountUSD: USD equivalent of Amount via EXW_Price.AvgPrice
- RelevantBlockchainFee: SUM(BlockchainFee WHERE IsEtoroHandlingFee=0) — user-borne fee only
- DELETE existing data for EOMDateID, then INSERT new monthly summary

### 2.2 EOM Date Derivation

**What**: EOMDate marks the last calendar day of the month, used as the date key for monthly organization.

**Columns Involved**: EOMDate, EOMDateID

**Rules**:
- @eom = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @d) + 1, 0)) — last day of month containing @d
- @eom_i = YYYYMMDD integer of @eom
- All rows for a given month share the same EOMDate (e.g., 2023-12-31 for December 2023)

### 2.3 RelevantBlockchainFee vs BlockchainFee

**What**: Distinguishes user-borne blockchain fees from eToro-absorbed fees.

**Columns Involved**: RelevantBlockchainFee, RelevantBlockchainFeeUSD, BlockchainFee, BlockchainFeeUSD

**Rules**:
- RelevantBlockchainFee: SUM(BlockchainFee WHERE CryptoTypes.IsEtoroHandlingFee=0) — fees paid by the user
- BlockchainFee: SUM(ALL BlockchainFee) — includes both user and eToro-paid fees
- Same pattern as in EXW_FactTransactions (see EXW_FactTransactions.md for full IsEtoroHandlingFee context)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID), CCI. CCI makes monthly-range aggregation queries efficient. Distribution on GCID is optimal for per-user queries. Data is frozen — no new writes since 2024-01-01.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly net flow by crypto (historical) | `GROUP BY EOMDate, CryptoName SUM(Amount)` |
| Historical fee burden by GCID | `WHERE GCID=@gcid ORDER BY EOMDate` |
| Monthly active users (>0 volume) | `WHERE ABS(Amount)>0 GROUP BY EOMDate COUNT(DISTINCT GCID)` |
| Current period analysis | **Use EXW_FactTransactions — this table ends Dec 2023** |

### 3.3 Gotchas

- **DEPRECATED — no data after 2023-12-31**: Any analysis requiring post-2023 data must use EXW_FactTransactions directly.
- **RecivedAmount** contains a typo (Recived, not Received) — preserved from the original SP code for backward compatibility.
- **Amount = net flow** (RecivedAmount - SentAmount): can be negative for net-sender users in a given month.
- **EOMDate, not a transaction date**: All rows for a month share the same EOMDate (last day of the month). Do not use EOMDate as an event timestamp.
- **No CryptoName for historical rows where CryptoTypes changed**: CryptoName was looked up at insert time; if a crypto was renamed after 2023, historical names won't match.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production DB wiki |
| Tier 2 | Derived from SP code (source-to-target mapping confirmed in code) |
| Tier 3 | Inferred from column name, type, and surrounding context |
| Tier 4 | Best available — limited lineage confidence |
| Tier 5 | Glossary or domain knowledge only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | GCID | int | NO | Group Customer ID — cross-product identity key. NOT NULL; distribution column. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 2 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Source: EXW_DimUser.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 3 | WalletId | uniqueidentifier | NO | Wallet GUID from EXW_Wallet.CustomerWalletsView. NOT NULL; identifies the specific wallet (GCID × CryptoId pair). (Tier 2 — SP_EXW_Transactions_Monthly) |
| 4 | CryptoId | int | YES | Crypto asset ID from EXW_Wallet.CustomerWalletsView.CryptoId. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 5 | CryptoName | nvarchar(256) | YES | Crypto asset name from EXW_Wallet.CryptoTypes.Name at time of insert. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 6 | SentAmount | numeric(38,8) | YES | Total sent amount in native crypto units for the month: SUM(Amount + EtoroFees + RelevantBlockchainFee) for ActionTypeId=1 transactions. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 7 | SentAmountUSD | numeric(38,8) | YES | USD equivalent of sent amount at monthly average price. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 8 | RecivedAmount | numeric(38,8) | YES | Total received amount in native crypto units for the month. Note: column name contains legacy typo 'Recived' (not Received). (Tier 2 — SP_EXW_Transactions_Monthly) |
| 9 | RecivedAmountUSD | numeric(38,8) | YES | USD equivalent of received amount at monthly average price. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 10 | Amount | numeric(38,8) | YES | Net monthly crypto flow: RecivedAmount - SentAmount. Negative = net sender for the month. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 11 | AmountUSD | numeric(38,8) | YES | USD equivalent of net monthly flow. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 12 | RelevantBlockchainFee | numeric(38,8) | YES | User-borne blockchain fee: SUM(BlockchainFee WHERE CryptoTypes.IsEtoroHandlingFee=0). (Tier 2 — SP_EXW_Transactions_Monthly) |
| 13 | RelevantBlockchainFeeUSD | numeric(38,8) | YES | USD equivalent of user-borne blockchain fees. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 14 | EtoroFees | numeric(38,8) | YES | eToro conversion/spread fees for sent transactions. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 15 | EtoroFeesUSD | numeric(38,8) | YES | USD equivalent of eToro fees. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 16 | BlockchainFee | numeric(38,8) | YES | Total blockchain fees (both user-borne and eToro-absorbed) for sent transactions. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 17 | BlockchainFeeUSD | numeric(38,8) | YES | USD equivalent of total blockchain fees. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 18 | EffectiveBlockchainFee | numeric(38,8) | YES | Effective blockchain fee from EXW_Wallet.External_WalletDB_Wallet_TransactionsView.EffectiveBlockchainFee — post-adjustment fee accounting. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 19 | EffectiveBlockchainFeeUSD | numeric(38,8) | YES | USD equivalent of effective blockchain fees. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 20 | LastRecivedOccurred | datetime | YES | Latest received transaction occurrence time within the month. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 21 | LastSentOccurred | datetime | YES | Latest sent transaction occurrence time within the month. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 22 | EOMDate | date | YES | End-of-month date (last calendar day of the month). All rows for a given month share this value. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 23 | EOMDateID | int | YES | YYYYMMDD integer form of EOMDate. (Tier 2 — SP_EXW_Transactions_Monthly) |
| 24 | UpdateDate | datetime | YES | ETL timestamp — GETDATE() at SP run time (last value: 2024-01-01). (Tier 2 — SP_EXW_Transactions_Monthly) |

---

## 5. Lineage

### 5.1 Production Sources (Historical — SP body is now commented out)

| Table Column | Source Object | Source Column | Transform |
|-------------|---------------|---------------|-----------|
| GCID | EXW_dbo.External_WalletDB_Wallet_TransactionsView | gcid | Passthrough |
| RealCID | EXW_dbo.EXW_DimUser | RealCID | JOIN on GCID |
| WalletId | EXW_Wallet.CustomerWalletsView | Id | JOIN on GCID+CryptoId |
| CryptoId | EXW_dbo.External_WalletDB_Wallet_TransactionsView | CryptoId | Passthrough |
| CryptoName | EXW_Wallet.CryptoTypes | Name | JOIN on CryptoID |
| SentAmount | External_WalletDB_Wallet_TransactionsView | Amount, EtoroFees, RelevantBlockchainFee | SUM grouped by month |
| RecivedAmount | External_WalletDB_Wallet_TransactionsView | Amount (ActionTypeId=2) | SUM grouped by month |
| Amount | (computed) | — | RecivedAmount - SentAmount |
| EOMDate | SP parameter | @d | Last day of month containing @d |
| UpdateDate | (computed) | — | GETDATE() |

---

## 6. Relationships

### 6.1 References To (Historical)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Transaction data | EXW_dbo.External_WalletDB_Wallet_TransactionsView | Monthly aggregation source |
| RealCID | EXW_dbo.EXW_DimUser | Customer ID lookup |
| CryptoName | EXW_Wallet.CryptoTypes | Crypto name at insert time |

### 6.2 Referenced By

| Object | Usage |
|--------|-------|
| Direct analyst queries | Historical monthly transaction analysis (pre-2024 only) |
| No SSDT-tracked SP consumers | Leaf node in the EXW_dbo dependency graph |

---

## 7. Sample Queries

### Historical monthly net flow by crypto (pre-2024)

```sql
SELECT
    EOMDate,
    CryptoName,
    COUNT(DISTINCT GCID) AS ActiveUsers,
    SUM(Amount) AS NetFlowCrypto,
    SUM(AmountUSD) AS NetFlowUSD
FROM EXW_dbo.EXW_Transactions_Monthly
WHERE EOMDate BETWEEN '2023-01-31' AND '2023-12-31'
GROUP BY EOMDate, CryptoName
ORDER BY EOMDate, NetFlowUSD DESC;
```

### Per-user historical monthly activity

```sql
SELECT
    EOMDate,
    CryptoName,
    SentAmount,
    RecivedAmount,
    Amount AS NetAmount,
    RelevantBlockchainFee
FROM EXW_dbo.EXW_Transactions_Monthly
WHERE GCID = @gcid
ORDER BY EOMDate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. SP code comments indicate the entire logic was wrapped in a comment block without explanation — likely a deliberate decommission rather than an accidental change. The table remains available for historical analysis but receives no new data.

---

*Generated: 2026-04-20 | Quality: 8.3/10 | Phases: 13/14 (DEPRECATED)*
*Tiers: 1 T1, 23 T2, 0 T3, 0 T4, 0 T5 | Elements: 24/24, Logic: 7/10 (SP commented out), Sources: 8/10*
*Object: EXW_dbo.EXW_Transactions_Monthly | Type: Table | Status: DEPRECATED — frozen 2023-12-31*
