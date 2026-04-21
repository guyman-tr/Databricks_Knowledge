# EXW_dbo.EXW_UserCalculatedBalance

> **DEPRECATED** — Historical daily calculated balance per GCID×CryptoId×WalletId, frozen at 2023-12-31. 1.27 billion rows covering 489,107 GCIDs across 1,462 dates (2019-12-31 to 2023-12-31). SP_EXW_UserCalculatedBalance exists but its entire body is commented out (NO-OP). Balance was computed as cumulative ReceivedAmount − SentAmount (− 0.0225 XRP reserve). Superseded by EXW_FinanceReportsBalancesNew (direct snapshot) and EXW_30DayBalanceExtract (rolling 30-day window).

| Property | Value |
|----------|-------|
| **Schema** | EXW_dbo |
| **Object Type** | Table |
| **Production Source** | EXW_dbo.External_WalletDB_Wallet_TransactionsView (historical) |
| **Refresh** | **DEPRECATED** — SP_EXW_UserCalculatedBalance body is entirely commented out. Last updated 2024-01-01. |
| **Row Count** | 1,270,633,954 (1.27 billion; frozen at 2023-12-31) |
| **Data Coverage** | 2019-12-31 to 2023-12-31 (1,462 dates, 489,107 GCIDs) |
| **Synapse Distribution** | HASH (GCID) |
| **Synapse Index** | CLUSTERED COLUMNSTORE |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — Synapse-only historical archive |

---

## 1. Business Meaning

EXW_UserCalculatedBalance was the historical daily balance ledger for every wallet user — computing each GCID's crypto balance on each date as the sum of all received amounts minus all sent amounts from account inception to that date. With 1.27 billion rows, it was the largest EXW_dbo balance table by row count, providing a full daily time series of wallet balances from December 2019 through December 2023.

The table is frozen. SP_EXW_UserCalculatedBalance(@d date) exists in the SSDT repository but its operational logic is entirely wrapped in a comment block — the SP is a NO-OP. The last data write was 2024-01-01 (covering the 2023-12-31 balance date).

**Balance computation method** (archived, from SP comments): Balance = ReceivedAmount − SentAmount − XRP_reserve, where XRP_reserve = 0.0225 for CryptoId=4 (XRP) and 0 for all other cryptos. This is a cumulative lifetime calculation — not a snapshot from WalletDB.

**Superseded by**: EXW_FinanceReportsBalancesNew (uses direct balance snapshot from WalletDB FinanceReport records — preferred for current analysis) and EXW_30DayBalanceExtract (rolling 30-day window of EXW_FinanceReportsBalancesNew, enriched with geographic attributes).

The CCI makes this 1.27B-row archive reasonably efficient for aggregate queries, but always filter on BalanceDateId (int) rather than BalanceDate (datetime) for best performance.

---

## 2. Business Logic

### 2.1 Cumulative Balance Computation (Archived Logic)

**What**: Daily balance computed from lifetime transaction history up to each date. Documented from the commented-out SP body.

**Columns Involved**: Balance, BalanceUSD, SentAmount, RecivedAmount

**Rules**:
- ReceivedAmount: SUM(Amount) for ActionTypeId=2 transactions WHERE TransDate < @EndDate (day after @d)
- SentAmount: SUM(Amount + EtoroFees + RelevantBlockchainFee) for ActionTypeId=1 transactions WHERE TransDate < @EndDate
- Balance = RecivedAmount - SentAmount - (CASE WHEN CryptoId=4 THEN 0.0225 ELSE 0 END)
- BalanceUSD = Balance × EXW_Wallet.EXW_PriceDaily.AvgPrice for CryptoId on BalanceDateId
- Lifetime accumulation — growing computation window as dates advance

### 2.2 Date-Range Customer Snapshot for Country/Regulation

**What**: Country, regulation, player level resolved at each BalanceDate via SCD Type 2 snapshot.

**Columns Involved**: CountryID, Country, RegulationID, Regulation, VerificationLevelID, PlayerLevelID, Club, IsValidCustomer

**Rules**:
- JOIN Fact_SnapshotCustomer ON RealCID
- JOIN Dim_Range ON DateRangeID AND @d_i BETWEEN FromDateID AND ToDateID
- JOIN Dim_Date ON DateKey=@d_i
- Ensures historical country/regulation reflects state at BalanceDate, not current state

### 2.3 EOM Flag

**What**: Marks rows corresponding to month-end snapshots for easier monthly reporting.

**Columns Involved**: EOM

**Rules**:
- CASE WHEN @d = last day of month THEN '1' ELSE '0' END
- Stored as varchar int ('1' or '0'), not bit — treat as string in comparisons
- @eom = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @d) + 1, 0))

### 2.4 XRP Minimum Reserve Deduction

**What**: XRP requires a minimum ledger reserve of 0.0225 XRP that cannot be spent.

**Columns Involved**: Balance (CryptoId=4 only)

**Rules**:
- Balance = RecivedAmount - SentAmount - 0.0225 for CryptoId=4 (XRP) only
- This hardcoded 0.0225 reserve reflects the XRP ledger minimum at time of implementation

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

HASH(GCID), CCI. CCI makes date-range aggregations efficient on this 1.27B-row archive. Always filter on BalanceDateId (int) for maximum CCI segment elimination. Avoid BalanceDate (datetime) in WHERE clauses.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Historical balance trend for a user | `WHERE GCID=@gcid AND BalanceDateId BETWEEN 20220101 AND 20231231` |
| Month-end snapshot (EOM dates only) | `WHERE EOM='1'` |
| Balance distribution at year-end 2023 | `WHERE BalanceDateId=20231231 AND BalanceUSD > 0` |
| **Current balance analysis** | **Use EXW_FinanceReportsBalancesNew or EXW_30DayBalanceExtract** |

### 3.3 Gotchas

- **DEPRECATED — no data after 2023-12-31**: Use EXW_FinanceReportsBalancesNew for current-state queries.
- **1.27 billion rows** — always filter on BalanceDateId first. Full scans are extremely expensive.
- **EOM is varchar '1'/'0'**: Use `WHERE EOM='1'` not `WHERE EOM=1`.
- **RecivedAmount** contains legacy typo (Recived) — preserved for backward compatibility.
- **GCID/RealCID are bigint** — differs from int in EXW_DimUser; implicit casts on JOINs may affect performance.
- **Cumulative balance can be negative** if SentAmount exceeds RecivedAmount — possible due to data timing or fee adjustments.
- **XRP reserve is hardcoded**: The 0.0225 deduction applies only to CryptoId=4 rows; check current XRP ledger minimums before using for current regulatory reporting.

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
| 1 | GCID | bigint | NO | Group Customer ID — cross-product identity key. NOT NULL; bigint (vs int in EXW_DimUser — check implicit cast on JOINs). (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 2 | RealCID | bigint | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. NOT NULL. bigint type. (Tier 1 — Customer.CustomerStatic) |
| 3 | WalletId | uniqueidentifier | NO | Wallet GUID from EXW_Wallet.CustomerWalletsView. NOT NULL. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 4 | CryptoId | int | YES | Crypto asset ID from EXW_Wallet.CustomerWalletsView.CryptoId. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 5 | CryptoName | nvarchar(256) | YES | Crypto asset name from EXW_Wallet.CryptoTypes.Name at time of insert. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 6 | SentAmount | numeric(38,8) | YES | Total sent amount in native crypto units from account inception to BalanceDate: SUM(Amount + EtoroFees + RelevantBlockchainFee) for ActionTypeId=1. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 7 | RecivedAmount | numeric(38,8) | YES | Total received amount from account inception to BalanceDate: SUM(Amount) for ActionTypeId=2. Note: column name contains legacy typo 'Recived'. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 8 | Balance | numeric(38,8) | YES | Calculated balance: RecivedAmount − SentAmount − (0.0225 for XRP CryptoId=4 only). Can be negative due to fee accounting. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 9 | BalanceUSD | numeric(38,8) | YES | USD equivalent: Balance × EXW_PriceDaily.AvgPrice for CryptoId on BalanceDateId. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 10 | EtoroFees | numeric(38,8) | YES | Cumulative eToro fees (conversion/spread) paid on sent transactions up to BalanceDate. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 11 | BlockchainFee | numeric(38,8) | YES | Cumulative total blockchain fees (user + eToro-absorbed) on sent transactions. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 12 | RelevantBlockchainFee | numeric(38,8) | YES | Cumulative user-borne blockchain fees: SUM(BlockchainFee WHERE IsEtoroHandlingFee=0). (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 13 | LastRecivedOccurred | datetime | YES | Latest received transaction occurrence up to BalanceDate. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 14 | LastSentOccurred | datetime | YES | Latest sent transaction occurrence up to BalanceDate. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 15 | BalanceDate | datetime | YES | The snapshot date for which balance was calculated. Filter on BalanceDateId (int) for best CCI performance. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 16 | BalanceDateId | int | YES | YYYYMMDD integer form of BalanceDate. Distribution/partition key — always filter on this column. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 17 | RegulationID | int | YES | Regulation ID from DWH_dbo.Fact_SnapshotCustomer at BalanceDate. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 18 | CountryID | int | YES | Country ID from DWH_dbo.Fact_SnapshotCustomer at BalanceDate. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 19 | IsTestAccount | bigint | YES | Test account flag from EXW_DimUser.IsTestAccount. 1=test user, 0=real user. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 20 | Country | varchar(100) | YES | Country name from DWH_dbo.Dim_Country.Name at BalanceDate. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 21 | Regulation | varchar(100) | YES | Regulation entity name from DWH_dbo.Dim_Regulation.Name at BalanceDate. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 22 | EOM | int | YES | End-of-month flag: 1 if BalanceDate is the last day of its calendar month, 0 otherwise. Stored as int but SP uses varchar '1'/'0' logic — verify data type before filtering. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 23 | UpdateDate | datetime | YES | ETL timestamp — GETDATE() at SP run time (last value: 2024-01-01). (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 24 | IsValidCustomer | int | YES | Valid customer flag from DWH_dbo.Fact_SnapshotCustomer at BalanceDate. 0=eTorian/internal, 1=real customer. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 25 | VerificationLevelID | int | YES | Verification level ID from DWH_dbo.Fact_SnapshotCustomer at BalanceDate. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 26 | PlayerLevelID | int | YES | Player level ID from DWH_dbo.Fact_SnapshotCustomer at BalanceDate. (Tier 2 — SP_EXW_UserCalculatedBalance) |
| 27 | Club | varchar(100) | YES | Player level name (Club tier) from DWH_dbo.Dim_PlayerLevel.Name. (Tier 2 — SP_EXW_UserCalculatedBalance) |

---

## 5. Lineage

### 5.1 Production Sources (Historical — SP body is now commented out)

| Table Column | Source Object | Source Column | Transform |
|-------------|---------------|---------------|-----------|
| GCID | EXW_dbo.EXW_DimUser | GCID | Via #wallets |
| RealCID | EXW_dbo.EXW_DimUser | RealCID | Via #snap |
| WalletId | EXW_Wallet.CustomerWalletsView | Id | JOIN on GCID |
| CryptoId | EXW_Wallet.CustomerWalletsView | CryptoId | Passthrough |
| SentAmount | External_WalletDB_Wallet_TransactionsView | Amount (ActionTypeId=1) | Cumulative SUM |
| RecivedAmount | External_WalletDB_Wallet_TransactionsView | Amount (ActionTypeId=2) | Cumulative SUM |
| Balance | (computed) | — | RecivedAmount-SentAmount-XRP_reserve |
| BalanceUSD | EXW_Wallet.EXW_PriceDaily | AvgPrice | Balance×price |
| Country/Regulation | Fact_SnapshotCustomer+Dim_Range | CountryID/RegulationID | Date-range snapshot |
| EOM | SP parameter | @d | Last-day-of-month CASE |
| UpdateDate | (computed) | — | GETDATE() |

---

## 6. Relationships

### 6.1 References To (Historical)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Transaction data | EXW_dbo.External_WalletDB_Wallet_TransactionsView | Cumulative balance source |
| GCID/RealCID | EXW_dbo.EXW_DimUser | User dimension |
| Country/Regulation at date | DWH_dbo.Fact_SnapshotCustomer + Dim_Range | SCD Type 2 snapshot |

### 6.2 Referenced By

| Object | Usage |
|--------|-------|
| Direct analyst queries | Historical daily balance analysis (pre-2024 only) |
| No SSDT-tracked SP consumers | Leaf node — deprecated, no active downstream consumption |

---

## 7. Sample Queries

### Historical month-end balances for a user

```sql
SELECT
    BalanceDateId,
    CryptoName,
    Balance,
    BalanceUSD,
    Country,
    Regulation
FROM EXW_dbo.EXW_UserCalculatedBalance
WHERE GCID = @gcid
  AND EOM = 1
ORDER BY BalanceDateId DESC;
```

### Total balances at year-end 2023 by crypto

```sql
SELECT
    CryptoName,
    COUNT(DISTINCT GCID) AS Users,
    SUM(Balance) AS TotalBalance,
    SUM(BalanceUSD) AS TotalBalanceUSD
FROM EXW_dbo.EXW_UserCalculatedBalance
WHERE BalanceDateId = 20231231
  AND IsTestAccount = 0
  AND BalanceUSD > 0
GROUP BY CryptoName
ORDER BY TotalBalanceUSD DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. SP code contains only parameter/variable declarations and the fully-commented execution body. No explanation for deprecation was found in SSDT history.

---

*Generated: 2026-04-20 | Quality: 8.3/10 | Phases: 13/14 (DEPRECATED)*
*Tiers: 1 T1, 26 T2, 0 T3, 0 T4, 0 T5 | Elements: 27/27, Logic: 7/10 (SP commented out), Sources: 8/10*
*Object: EXW_dbo.EXW_UserCalculatedBalance | Type: Table | Status: DEPRECATED — frozen 2023-12-31 | 1.27B rows*
