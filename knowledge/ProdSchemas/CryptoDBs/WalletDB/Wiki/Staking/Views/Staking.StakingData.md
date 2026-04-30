# Staking.StakingData

> Denormalized reporting view combining staking operations with their latest status, transaction fees, and customer identity for ETH staking operations only.

| Property | Value |
|----------|-------|
| **Schema** | Staking |
| **Object Type** | View |
| **Key Identifier** | Id (from Staking.Staking) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Staking.StakingData is a denormalized reporting view that flattens the normalized staking schema into a single queryable surface for BI tools and back-office reporting. It combines the core staking record (Staking.Staking) with the latest status (from StakingStatuses + Dictionary.StakingStatuses via ROW_NUMBER), transaction fees (from StakingTransactions), and the customer's GCID (from Wallet.CustomerWalletsView).

The view is **hardcoded to ETH only** (WHERE CryptoId = 2), reflecting that ETH was the only staking-enabled crypto in this database when the view was created. It provides date-dimension columns (Staking_Date, Staking_DateID) formatted for BI date joins and dashboard filtering.

No stored procedures in the SSDT project reference this view directly - it is consumed by external reporting systems (Tableau, BI pipelines, ad-hoc queries). The LEFT JOINs ensure rows are returned even when status or transaction records are missing (e.g., a staking operation still being processed).

---

## 2. Business Logic

### 2.1 Latest Status Extraction

**What**: The view resolves each staking operation to its single most recent status using a ROW_NUMBER window pattern.

**Columns/Parameters Involved**: `StatusID`, `Status_Name`, `Status_DateTime`, `Status_Date`

**Rules**:
- Uses ROW_NUMBER() OVER (PARTITION BY StakingId ORDER BY Occurred DESC) to identify the latest status event per staking
- Joins to Dictionary.StakingStatuses to resolve StatusID to Status_Name (Pending/Failed/Completed)
- LEFT JOIN means stakings without any status row will show NULL for all status columns

### 2.2 ETH-Only Filter

**What**: The view is restricted to Ethereum staking operations only.

**Columns/Parameters Involved**: `CryptoId`

**Rules**:
- WHERE sts.CryptoId = 2 in the base query
- CustomerWalletsView subquery also filters by CryptoId = 2
- To support additional cryptos, the view would need modification to remove or parameterize this filter

### 2.3 Date Dimension Columns

**What**: Provides BI-friendly date representations for dashboard integration.

**Columns/Parameters Involved**: `Staking_DateTime`, `Staking_Date`, `Staking_DateID`

**Rules**:
- Staking_DateTime: raw datetime2 from Staking.Staking.Occurred
- Staking_Date: date-only (CAST AS DATE) for daily grouping
- Staking_DateID: YYYYMMDD integer (via CONVERT(CHAR(8), ..., 112)) for date dimension table joins in data warehouse

---

## 3. Data Overview

| Id | GCID | Amount | Status_Name | Staking_DateID | EtoroFee | Meaning |
|----|------|--------|-------------|----------------|----------|---------|
| 2181 | 14509456 | 1.35 ETH | Completed | 20230405 | 0 | Latest staking transfer - 1.35 ETH successfully staked, customer identified by GCID for BI cross-reference |
| 2180 | 15698665 | 30.43 ETH | Completed | 20230404 | 0 | High-value 30+ ETH stake - GCID enables joining to customer data in downstream BI |
| 2179 | 23569041 | 4.59 ETH | Completed | 20230404 | 0 | Mid-range stake - DateID 20230404 enables date dimension join for daily aggregation |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | VERIFIED | Staking operation ID. From Staking.Staking.Id. Unique identifier per staking operation. |
| 2 | WalletId | uniqueidentifier | NO | - | VERIFIED | Customer wallet that initiated the stake. From Staking.Staking.WalletId. FK to Wallet.Wallets.WalletId. |
| 3 | Amount | decimal(36,18) | NO | - | VERIFIED | Quantity of ETH staked. From Staking.Staking.Amount. In native crypto units (e.g., 1.345547 ETH). |
| 4 | CorrelationId | uniqueidentifier | NO | - | VERIFIED | Idempotency key for the staking operation. From Staking.Staking.CorrelationId. Links to Wallet.TransactionsView for cross-schema transaction tracing. |
| 5 | CryptoId | int | NO | - | VERIFIED | Always 2 (ETH) due to the view's WHERE filter. From Staking.Staking.CryptoId. |
| 6 | GCID | bigint | YES | - | VERIFIED | Global Customer ID of the wallet owner. From Wallet.CustomerWalletsView.Gcid. Enables BI joins to customer-level dimensions. NULL if the wallet is not found in CustomerWalletsView. |
| 7 | Staking_DateTime | datetime2(7) | NO | - | VERIFIED | Computed in view: aliased from Staking.Staking.Occurred. Full timestamp of the staking initiation for precise time-based analysis. |
| 8 | Staking_Date | date | NO | - | VERIFIED | Computed in view: CAST(Occurred AS DATE). Date-only representation for daily grouping and calendar joins. |
| 9 | Staking_DateID | int | NO | - | VERIFIED | Computed in view: CAST(CONVERT(CHAR(8), Occurred, 112) AS INT). YYYYMMDD integer format (e.g., 20230405) for date dimension table foreign key joins in data warehouses. |
| 10 | EtoroFee | decimal(36,18) | YES | - | VERIFIED | eToro's service fee for the staking transfer. From Staking.StakingTransactions.EtoroFee. NULL if no transaction record exists. Currently 0 across all records. |
| 11 | BlockchainEstFee | decimal(36,18) | YES | - | VERIFIED | Estimated blockchain network fee. From Staking.StakingTransactions.BlockchainEstFee. NULL if no transaction record. Currently 0 across all records. |
| 12 | StatusID | tinyint | YES | - | VERIFIED | Latest status ID for this staking operation. From the ROW_NUMBER subquery on Staking.StakingStatuses. Values: 1=Pending, 2=Failed, 3=Completed. See [Staking Status](../../_glossary.md#staking-status). NULL if no status recorded. |
| 13 | Status_Name | varchar(64) | YES | - | VERIFIED | Human-readable status label. From Dictionary.StakingStatuses.Name via JOIN in the ROW_NUMBER subquery. NULL if no status recorded. |
| 14 | Status_DateTime | datetime2(7) | YES | - | VERIFIED | Computed in subquery: Staking.StakingStatuses.Occurred for the latest status. Shows when the current status was applied. Time delta from Staking_DateTime indicates processing duration. |
| 15 | Status_Date | date | YES | - | VERIFIED | Computed in subquery: CAST(Occurred AS DATE) for the latest status. Date-only for daily status-change analysis. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Id, WalletId, Amount, CorrelationId, CryptoId, Occurred | Staking.Staking | FROM | Base table - all staking operations |
| StakingStatusId, Occurred (status) | Staking.StakingStatuses | LEFT JOIN (subquery) | Latest status per staking via ROW_NUMBER |
| Status_Name | Dictionary.StakingStatuses | LEFT JOIN | Resolves status ID to human-readable name |
| EtoroFee, BlockchainEstFee | Staking.StakingTransactions | LEFT JOIN | Transaction fee details |
| GCID | Wallet.CustomerWalletsView | LEFT JOIN | Customer identity resolution from wallet |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views in the SSDT project reference this view. Consumed by external BI/reporting systems.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Staking.StakingData (view)
+-- Staking.Staking (table)
+-- Staking.StakingStatuses (table)
+-- Dictionary.StakingStatuses (table)
+-- Staking.StakingTransactions (table)
+-- Wallet.CustomerWalletsView (view)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Staking.Staking | Table | FROM - base table for all staking records |
| Staking.StakingStatuses | Table | LEFT JOIN subquery - latest status per staking |
| Dictionary.StakingStatuses | Table | LEFT JOIN - status name resolution |
| Staking.StakingTransactions | Table | LEFT JOIN - fee details |
| Wallet.CustomerWalletsView | View | LEFT JOIN subquery - GCID resolution (filtered to CryptoId=2) |

### 6.2 Objects That Depend On This

No dependents found in the SSDT project. Used by external reporting.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view.

---

## 8. Sample Queries

### 8.1 Daily staking summary
```sql
SELECT Staking_Date, COUNT(*) AS Operations, SUM(Amount) AS TotalStaked
FROM Staking.StakingData WITH (NOLOCK)
WHERE Status_Name = 'Completed'
GROUP BY Staking_Date
ORDER BY Staking_Date DESC
```

### 8.2 Customer staking history
```sql
SELECT Id, Amount, Status_Name, Staking_DateTime, Status_DateTime, EtoroFee
FROM Staking.StakingData WITH (NOLOCK)
WHERE GCID = @Gcid
ORDER BY Staking_DateTime DESC
```

### 8.3 Failed staking operations for investigation
```sql
SELECT Id, GCID, Amount, Staking_DateTime, Status_DateTime
FROM Staking.StakingData WITH (NOLOCK)
WHERE Status_Name = 'Failed'
ORDER BY Staking_DateTime DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Staking](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/2022637656/Staking) | Confluence | Staking operations have Pending/Failed/Completed lifecycle; rewards distributed monthly; Tableau reports used for staking investigation by CS agents |

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.3/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 15 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Staking.StakingData | Type: View | Source: WalletDB/Staking/Views/Staking.StakingData.sql*
