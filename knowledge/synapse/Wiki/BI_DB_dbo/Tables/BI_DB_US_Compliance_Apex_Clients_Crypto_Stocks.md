# BI_DB_dbo.BI_DB_US_Compliance_Apex_Clients_Crypto_Stocks

> 431K-row companion table to `BI_DB_US_Compliance_Apex_Clients` providing daily stock and crypto balance snapshots for all US depositors (CountryID=219, IsValidCustomer=1, IsDepositor=1). Includes realized equity, total liability, available cash, and cash allocated to copy trading. Sourced from `V_Liabilities` at the @Date parameter. Refreshed daily via Steps 05-06 of `SP_US_Compliance_Apex_Clients` (TRUNCATE+INSERT).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.V_Liabilities (via Fact_SnapshotEquity + Fact_CustomerUnrealized_PnL) + Dim_Customer + Dim_AccountStatus + Dim_State_and_Province. Writer SP: `BI_DB_dbo.SP_US_Compliance_Apex_Clients` (Steps 05-06) |
| **Refresh** | Daily — TRUNCATE+INSERT full reload (SB_Daily, Priority 0) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_us_compliance_apex_clients_crypto_stocks` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Generic Pipeline Override) |

---

## 1. Business Meaning

This table provides a daily financial balance snapshot for all US depositor customers. Each row represents one unique CID (431K rows, one-to-one with distinct customers). The population is broader than the parent `BI_DB_US_Compliance_Apex_Clients` table — it includes ALL US depositors (CountryID=219, IsValidCustomer=1, IsDepositor=1) regardless of verification level.

The financial data is sourced from `DWH_dbo.V_Liabilities`, the platform's central view combining `Fact_SnapshotEquity` (balance snapshots) and `Fact_CustomerUnrealized_PnL` (unrealized profit/loss). Each financial column is a MAX aggregation per CID for the given @Date, computed as:
- **StocksBalance**: stock position amount + unrealized stock PnL
- **CryptoBalance**: crypto position amount + unrealized crypto PnL
- **RealizedEquity**: total realized equity (deposits + realized P&L - withdrawals)
- **TotalLiability**: eToro's liability to the customer (V_Liabilities formula: InProcessCashouts + excess over BonusCredit)
- **AvailableCash**: available credit balance
- **CashInCopy**: cash allocated to copy trading (TotalCash - Credit)

The ETL runs as Steps 05-06 of `SP_US_Compliance_Apex_Clients`, executing daily via SB_Daily at Priority 0. Step 05 builds the #depositors temp table; Step 06 does TRUNCATE+INSERT into this table.

---

## 2. Business Logic

### 2.1 US Depositor Population

**What**: Identifies all US depositor customers for balance reporting.
**Columns Involved**: `CID`, `Address_State`, `AccountStatusName`
**Rules**:
- Source: `Dim_Customer` WHERE CountryID=219 AND IsValidCustomer=1 AND IsDepositor=1
- No verification level filter — includes all KYC levels (unlike the parent compliance table which requires VL3)
- GROUP BY CID, State, AccountStatusName with MAX aggregation on financial columns

### 2.2 Balance Computation from V_Liabilities

**What**: Extracts daily balance snapshot at the @Date parameter.
**Columns Involved**: `StocksBalance`, `CryptoBalance`, `RealizedEquity`, `TotalLiability`, `AvailableCash`, `CashInCopy`
**Rules**:
- V_Liabilities is filtered to DateID = CAST(REPLACE(CONVERT(VARCHAR(10), @Date), '-', '') AS INT) — date integer format YYYYMMDD
- LEFT JOIN from Dim_Customer to V_Liabilities — customers without balance data get NULL (converted to 0 via ISNULL)
- All financial columns use MAX aggregation per GROUP BY (CID, State, Status) — effectively a single row per CID since the date filter narrows to one snapshot

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP. Table is 431K rows — any query pattern is performant.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total US depositor equity by state | `SELECT Address_State, SUM(RealizedEquity) FROM ... GROUP BY Address_State` |
| Customers with crypto positions | `WHERE CryptoBalance > 0` |
| Copy trading participation | `WHERE CashInCopy > 0` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_US_Compliance_Apex_Clients | CID = CID | Full compliance profile with Apex status and KYC data |
| DWH_dbo.Dim_Customer | CID = RealCID | Additional customer attributes |

### 3.4 Gotchas

- **Broader population than parent table**: This table includes ALL US depositors (any VL), while `BI_DB_US_Compliance_Apex_Clients` requires VL3 + closed/Reg8 filter
- **Zero values vs NULL**: ISNULL converts NULL balances to 0 — a $0 balance may mean "no positions" or "positions exactly at breakeven"
- **CashInCopy can be negative**: Calculated as TotalCash - Credit; if Credit exceeds TotalCash, result is negative
- **Single-day snapshot**: All financial data is for one specific date (@Date parameter, typically yesterday)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki — description copied verbatim |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from data patterns |
| Tier 4 | Best available knowledge — limited confidence |
| Tier 5 | Standard ETL metadata |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Sourced from Dim_Customer.RealCID. (Tier 1 — Customer.CustomerStatic) |
| 2 | Address_State | varchar(100) | YES | Full human-readable geographic name of the region — state, province, or territory. Examples: "California", "New York", "Ontario". Passthrough from Dim_State_and_Province via RegionID+CountryID. (Tier 2 — SP_Dictionaries_DL_To_Synapse) |
| 3 | AccountStatusName | varchar(50) | YES | Human-readable label for the account state: 'Open', 'Closed', or 'N/A'. Sourced directly from Dictionary.AccountStatus.AccountStatusName. Passthrough from Dim_AccountStatus. (Tier 1 — Dictionary.AccountStatus) |
| 4 | StocksBalance | decimal(19,6) | YES | Stock position value including unrealized PnL. Computed as MAX(ISNULL(V_Liabilities.TotalStockPositionAmount, 0) + ISNULL(V_Liabilities.StocksPositionPnL, 0)) for the @Date snapshot. 0 if customer has no stock positions. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 5 | CryptoBalance | decimal(19,6) | YES | Crypto position value including unrealized PnL. Computed as MAX(ISNULL(V_Liabilities.TotalCryptoPositionAmount, 0) + ISNULL(V_Liabilities.CryptoPositionPnL, 0)) for the @Date snapshot. 0 if customer has no crypto positions. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 6 | RealizedEquity | decimal(19,6) | YES | Total realized equity — deposits + realized P&L - withdrawals. MAX aggregation of V_Liabilities.RealizedEquity for the @Date snapshot. Sourced ultimately from Fact_SnapshotEquity.RealizedEquity. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 7 | TotalLiability | decimal(19,6) | YES | Platform liability to the customer — what eToro owes. MAX aggregation of V_Liabilities.Liabilities for the @Date snapshot. V_Liabilities formula: InProcessCashouts + excess of NetEquity over BonusCredit. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 8 | AvailableCash | decimal(19,6) | YES | Available credit/cash balance. MAX aggregation of V_Liabilities.Credit for the @Date snapshot. Sourced ultimately from Fact_SnapshotEquity.Credit. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 9 | CashInCopy | decimal(19,6) | YES | Cash allocated to copy trading. Computed as MAX(ISNULL(V_Liabilities.TotalCash, 0) - ISNULL(V_Liabilities.Credit, 0)). Can be negative if Credit exceeds TotalCash. (Tier 2 — SP_US_Compliance_Apex_Clients) |
| 10 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-----------------|---------------|-----------|
| CID | Customer.CustomerStatic | CID (as RealCID) | Rename via Dim_Customer |
| Address_State | Dictionary.RegionByIP/RegionName | Name | Dim-lookup via Dim_State_and_Province |
| AccountStatusName | Dictionary.AccountStatus | AccountStatusName | Dim-lookup via Dim_AccountStatus |
| StocksBalance | Fact_SnapshotEquity + Fact_CustomerUnrealized_PnL | TotalStockPositionAmount + StocksPositionPnL | SUM via V_Liabilities, MAX in SP |
| CryptoBalance | Fact_SnapshotEquity + Fact_CustomerUnrealized_PnL | TotalCryptoPositionAmount + CryptoPositionPnL | SUM via V_Liabilities, MAX in SP |
| RealizedEquity | Fact_SnapshotEquity | RealizedEquity | Direct via V_Liabilities, MAX in SP |
| TotalLiability | V_Liabilities (computed) | Liabilities | V_Liabilities formula, MAX in SP |
| AvailableCash | Fact_SnapshotEquity | Credit | Direct via V_Liabilities, MAX in SP |
| CashInCopy | Fact_SnapshotEquity | TotalCash - Credit | Subtraction via V_Liabilities, MAX in SP |

### 5.2 ETL Pipeline

```
Production Sources:
  eToro Trading Engine (equity snapshots, unrealized PnL)
    |-- Generic Pipeline (Bronze export) ---|
    v
  DWH_staging.* (staging tables)
    |-- SP_Fact_SnapshotEquity / SP_Fact_CustomerUnrealized_PnL ---|
    v
  DWH_dbo.Fact_SnapshotEquity + Fact_CustomerUnrealized_PnL
    |-- V_Liabilities (view join) ---|
    v
  DWH_dbo.V_Liabilities
  DWH_dbo.Dim_Customer + Dim_State_and_Province + Dim_AccountStatus
    |-- SP_US_Compliance_Apex_Clients Steps 05-06 (TRUNCATE+INSERT, daily) ---|
    v
  BI_DB_dbo.BI_DB_US_Compliance_Apex_Clients_Crypto_Stocks (431K rows)
    |-- Generic Pipeline (Override, delta) ---|
    v
  dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_us_compliance_apex_clients_crypto_stocks
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer.RealCID | Primary customer dimension |
| AccountStatusName | DWH_dbo.Dim_AccountStatus.AccountStatusName | Account status |

### 6.2 Referenced By (other objects point to this)

| Object | Join Key | Purpose |
|--------|----------|---------|
| BI_DB_dbo.BI_DB_US_Compliance_Apex_Clients | CID | Parent compliance table joins for full client profile |

---

## 7. Sample Queries

### 7.1 US Depositor Balance Summary by State

```sql
SELECT Address_State,
       COUNT(*) AS customers,
       SUM(StocksBalance) AS total_stocks,
       SUM(CryptoBalance) AS total_crypto,
       SUM(RealizedEquity) AS total_equity
FROM [BI_DB_dbo].[BI_DB_US_Compliance_Apex_Clients_Crypto_Stocks]
WHERE AccountStatusName = 'Open'
GROUP BY Address_State
ORDER BY total_equity DESC
```

### 7.2 Compliance Profile with Balances

```sql
SELECT c.CID, c.FullName, c.ApexStatus, cs.StocksBalance, cs.CryptoBalance,
       cs.RealizedEquity, cs.TotalLiability
FROM [BI_DB_dbo].[BI_DB_US_Compliance_Apex_Clients] c
INNER JOIN [BI_DB_dbo].[BI_DB_US_Compliance_Apex_Clients_Crypto_Stocks] cs ON c.CID = cs.CID
WHERE cs.StocksBalance + cs.CryptoBalance > 10000
ORDER BY cs.RealizedEquity DESC
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table.

---

*Generated: 2026-04-27 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 2 T1, 7 T2, 0 T3, 0 T4, 1 T5 | Elements: 10/10, Logic: 8/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_US_Compliance_Apex_Clients_Crypto_Stocks | Type: Table | Production Source: V_Liabilities + Dim_Customer*
