# BI_DB_dbo.BI_DB_Airdrop_Data

> **DORMANT -- 0 rows, no writer SP, fully orphaned.** 15-column customer-level crypto airdrop data table designed to track token distribution events with customer demographics (country, EU flag, desk, club membership, regulation), airdrop details (instrument symbol, amount, execution date), and customer financial snapshot (equity, deposits, revenue). ROUND_ROBIN with CLUSTERED INDEX on CID. No stored procedure in Synapse SSDT reads or writes this table. Note: column typo "Revnue" (should be Revenue). Related but separate from BI_DB_Crypto_Airdrop (active, 35 cols, written by SP_BI_DB_Crypto_Airdrop).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown -- no writer SP in SSDT, no references |
| **Refresh** | **DORMANT** -- no active ETL process |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (CID ASC) |
| **Row Count** | 0 |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

`BI_DB_Airdrop_Data` was designed as a **customer-level crypto airdrop tracking table** intended to record individual token distribution events (airdrops) alongside the recipient customer's demographics and financial profile.

Key design characteristics:
- **Customer grain**: Each row = one customer (CID) x airdrop event
- **Customer demographics**: Country, EU membership, desk assignment, eToro Club tier, regulation
- **Airdrop details**: SymbolFull (crypto instrument), Amount (token quantity), ExecutionOccurred (execution date)
- **Financial snapshot**: Equity, Deposited, Revenue (typo: "Revnue"), Deposit -- customer financial state at airdrop time

The table is currently **empty (0 rows)** and **fully orphaned** -- no stored procedure reads or writes it. This was likely an early prototype for crypto airdrop customer analysis that was abandoned in favor of the more comprehensive `BI_DB_Crypto_Airdrop` table (35 columns, written by `SP_BI_DB_Crypto_Airdrop`, which analyzes V3-verified customer post-airdrop trading behavior across 30/60-day windows with detailed position-type breakdowns).

Key differences from BI_DB_Crypto_Airdrop:
- **BI_DB_Airdrop_Data**: Simple customer + airdrop record (15 cols, flat)
- **BI_DB_Crypto_Airdrop**: Complex behavioral analysis (35 cols, multi-stage classification with IsADClient, 30/60-day activity windows, CFD vs Real position tracking)

Note the **typo "Revnue"** (should be "Revenue") -- this persisted because the table was never actively used.

---

## 2. Business Logic

### 2.1 Crypto Airdrop Distribution (Inferred)

**What**: Record of crypto token airdrops to eligible customers.
**Columns Involved**: CID, SymbolFull, Amount, ExecutionOccurred
**Rules**:
- SymbolFull identifies the crypto asset airdropped (e.g., BTC, ETH, specific token symbols)
- Amount (decimal(11,2)) records the token quantity distributed
- ExecutionOccurred records when the airdrop was processed

### 2.2 Customer Financial Profile (Inferred)

**What**: Snapshot of customer financial state at time of airdrop, likely for eligibility/impact analysis.
**Columns Involved**: Equity, Deposited, Revnue, Deposit, FirstDepositDate
**Rules**:
- Equity (decimal(23,4)) = customer portfolio value at time of airdrop
- Deposited (int) = likely total deposited amount or deposit count
- Revnue (money) = likely customer lifetime revenue (note: typo for "Revenue")
- Deposit (money) = likely most recent or total deposit amount
- FirstDepositDate = customer's first deposit, for tenure segmentation

### 2.3 Customer Segmentation (Inferred)

**What**: Customer attributes for airdrop eligibility/cohort analysis.
**Columns Involved**: Country, EU, Desk, Club, Regulation
**Rules**:
- EU (int) = flag for EU membership (1=EU, 0=non-EU), likely for regulatory compliance
- Club (varchar(50)) = eToro Club tier (Silver, Gold, Platinum, Diamond, etc.)
- Regulation = regulatory jurisdiction (CySEC, FCA, ASIC, etc.)
- Desk = sales/support desk assignment

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN -- no natural distribution key for this small reference table
- **Index**: CLUSTERED INDEX on CID -- optimized for customer-level lookups

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Airdrop recipients by crypto asset | `GROUP BY SymbolFull` with `COUNT(DISTINCT CID), SUM(Amount)` |
| Customer equity profile of airdrop recipients | `SELECT CID, Equity, Deposited` with `ORDER BY Equity DESC` |
| Airdrop distribution by regulation | `GROUP BY Regulation` with counts |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| N/A | N/A | Table is dormant with 0 rows -- no active join patterns |

### 3.4 Gotchas

- **0 rows**: Table has never been populated in Synapse -- all queries will return empty
- **Column typo**: "Revnue" should be "Revenue" -- will cause confusion in ad-hoc queries
- **Not BI_DB_Crypto_Airdrop**: This is a SEPARATE, simpler table. The active airdrop analysis uses BI_DB_Crypto_Airdrop (35 cols, SP_BI_DB_Crypto_Airdrop)
- **Ambiguous Amount vs Deposit**: Both Amount (decimal) and Deposit (money) exist -- Amount likely refers to airdrop token quantity while Deposit refers to fiat deposit amount

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki verbatim | Highest -- production-documented |
| Tier 2 | SP code analysis | High -- code is king |
| Tier 3 | Live data evidence | Medium -- empirical |
| Tier 4 | Inferred from column name/type/context | Low -- best guess |
| Tier 5 | ETL metadata (canonical) | Standard ETL columns |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | NO | Customer ID -- unique identifier for a customer account in the eToro platform. Primary lookup key. (Tier 4 -inferred from name) |
| 2 | Country | varchar(50) | YES | Country name where the customer is registered. (Tier 4 -inferred from name) |
| 3 | EU | int | YES | EU membership flag for the customer's country. Expected: 1=EU member state, 0=non-EU. Used for regulatory compliance segmentation. (Tier 4 -inferred from name) |
| 4 | Desk | nvarchar(50) | YES | Internal sales/support desk assignment for the customer. (Tier 4 -inferred from name) |
| 5 | Club | varchar(50) | YES | eToro Club membership tier (e.g., Silver, Gold, Platinum, Diamond). Determines premium features and benefits. (Tier 4 -inferred from name) |
| 6 | Regulation | varchar(50) | YES | Regulatory jurisdiction governing the customer's account (e.g., CySEC, FCA, ASIC, eToro USA). (Tier 4 -inferred from name) |
| 7 | SymbolFull | varchar(100) | YES | Full symbol of the crypto asset airdropped to the customer (e.g., BTC, ETH, DOGE). (Tier 4 -inferred from name) |
| 8 | Amount | decimal(11,2) | NO | Quantity of the airdropped crypto token distributed to the customer. (Tier 4 -inferred from name) |
| 9 | ExecutionOccurred | date | YES | Date when the airdrop was executed/distributed to the customer. (Tier 4 -inferred from name) |
| 10 | FirstDepositDate | date | YES | Date of the customer's first fiat deposit. Used for tenure segmentation and FTD analysis. (Tier 4 -inferred from name) |
| 11 | Equity | decimal(23,4) | YES | Customer portfolio equity value at time of airdrop. High precision (4 decimal places) for accurate financial tracking. (Tier 4 -inferred from name) |
| 12 | Deposited | int | YES | Total deposited amount or deposit count for the customer. (Tier 4 -inferred from name) |
| 13 | Revnue | money | YES | Customer lifetime revenue. **Typo** -- should be "Revenue". (Tier 4 -inferred from name) |
| 14 | Deposit | money | YES | Fiat deposit amount (money type). Distinct from "Deposited" (int) -- this is likely the monetary value while Deposited is a count or flag. (Tier 4 -inferred from name) |
| 15 | UpdateDate | datetime | NO | Timestamp of last row update. (Tier 5 -ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|---------------|-----------|
| All columns | Unknown | Unknown | No writer SP found -- fully orphaned |

### 5.2 ETL Pipeline

```
(Unknown production source -- likely internal crypto airdrop service)
  |-- (No Generic Pipeline mapping found)
  v
BI_DB_dbo.BI_DB_Airdrop_Data (0 rows -- DORMANT)
  |-- (No UC migration -- _Not_Migrated)
  v
(not exported)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer | Customer ID FK (inferred -- no SP to confirm) |
| Country | DWH_dbo.Dim_Country | Country name (inferred) |
| Regulation | DWH_dbo.Dim_Regulation | Regulatory jurisdiction (inferred) |

### 6.2 Referenced By (other objects point to this)

No objects in the Synapse SSDT reference this table.

---

## 7. Sample Queries

### 7.1 Check Table Status

```sql
-- Verify the table is still empty
SELECT COUNT(*) AS row_count
FROM [BI_DB_dbo].[BI_DB_Airdrop_Data];
```

### 7.2 Airdrop Distribution by Crypto Asset (if populated)

```sql
-- Count airdrop recipients per crypto asset
SELECT
    SymbolFull,
    COUNT(DISTINCT CID) AS recipients,
    SUM(Amount) AS total_distributed,
    AVG(Equity) AS avg_equity
FROM [BI_DB_dbo].[BI_DB_Airdrop_Data]
GROUP BY SymbolFull
ORDER BY total_distributed DESC;
```

### 7.3 Airdrop by Regulation and Club Tier (if populated)

```sql
-- Airdrop recipients by regulation and club tier
SELECT
    Regulation,
    Club,
    COUNT(DISTINCT CID) AS recipients,
    SUM(Amount) AS total_distributed
FROM [BI_DB_dbo].[BI_DB_Airdrop_Data]
GROUP BY Regulation, Club
ORDER BY recipients DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this specific table. Crypto airdrop programs may be documented under the Crypto or Product team spaces.

---

*Generated: 2026-04-27 | Quality: 7.0/10 | Phases: 14/14*
*Tiers: 0 T1, 0 T2, 0 T3, 14 T4, 1 T5 | Elements: 15/15, Logic: 6/10, Lineage: 3/10*
*Object: BI_DB_dbo.BI_DB_Airdrop_Data | Type: Table | Production Source: Unknown (dormant)*
