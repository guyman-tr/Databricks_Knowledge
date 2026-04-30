# Wallet.tempResult_FinanceReportsBalances

> Static snapshot table holding one row per customer (Gcid) with the last reconciliation occurrence date, bulk-loaded once for a data migration or analysis task.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Gcid (BIGINT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Wallet.tempResult_FinanceReportsBalances is a static snapshot table that stores one row per customer (Gcid), recording the last time that customer appeared in a balance reconciliation run (Occurred) and when the snapshot was created (CreateDate). Despite the "temp" prefix suggesting a temporary staging table, it persists as a permanent object in the schema.

This table was bulk-loaded once on 2023-02-20 with 191,314 rows covering reconciliation data from April 2019 through February 2023. No stored procedures in the current codebase reference this table, indicating it was likely created for a one-time data migration, partitioning preparation, or historical analysis. The data has not been updated since the initial load.

The table appears to have been created to capture a per-customer "last seen in reconciliation" summary from the legacy Wallet.FinanceReportsBalances data, possibly to support the later migration from the non-partitioned FinanceReportsBalances_old table to the partitioned FinanceReportsBalances table, or for operational reporting on customer reconciliation coverage.

---

## 2. Business Logic

### 2.1 Per-Customer Reconciliation Snapshot

**What**: A denormalized summary providing the most recent reconciliation occurrence for each customer.

**Columns/Parameters Involved**: `Gcid`, `Occurred`, `CreateDate`

**Rules**:
- One row per Gcid (customer) -- the PK enforces uniqueness
- Occurred captures the last time this customer's wallets were included in a reconciliation run
- All 191,314 rows have the same CreateDate (2023-02-20 11:39:01), confirming a single bulk INSERT operation
- Negative Gcid values (-3, -2, -1) and zero (0) represent system or test accounts
- The data is frozen -- no procedures write to this table, making it a historical artifact

---

## 3. Data Overview

| Gcid | Occurred | CreateDate | Meaning |
|------|----------|------------|---------|
| -3 | 2019-05-28 11:36:02 | 2023-02-20 11:39:01 | System/test account with negative ID. Last appeared in reconciliation May 2019 -- likely used for internal testing during early system setup. |
| -1 | 2019-04-04 05:40:36 | 2023-02-20 11:39:01 | System account last seen in the very first reconciliation run (April 2019). Never reconciled again, suggesting it was an initialization-only account. |
| 0 | 2019-04-04 05:40:36 | 2023-02-20 11:39:01 | Edge case Gcid=0 -- likely a placeholder or default customer ID. Last occurred in the first-ever run. |
| 6851 | 2019-05-13 11:13:19 | 2023-02-20 11:39:01 | Real customer who was last reconciled in May 2019. Early adopter whose wallets stopped being active before the snapshot date. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID -- uniquely identifies a customer across the eToro platform. Serves as the primary key, enforcing one snapshot row per customer. Includes system/test accounts with negative values (-3, -2, -1) and a placeholder zero value. Corresponds to the Gcid column in Wallet.FinanceReportRecords and Wallet.FinanceReportsBalances. |
| 2 | Occurred | datetime2(7) | NO | - | CODE-BACKED | The last reconciliation timestamp for this customer -- when their wallets were most recently included in a balance comparison run. Values range from 2019-04-04 (first reconciliation) to 2023-02-20 (snapshot date). Likely derived from MAX(Occurred) or MAX(Created) grouped by Gcid from the source reconciliation table. |
| 3 | CreateDate | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this snapshot row was created. All 191,314 rows share the identical value 2023-02-20 11:39:01.130, confirming a single bulk INSERT operation rather than incremental population. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Gcid | (external - customer system) | Implicit | References the Global Customer ID from the eToro customer platform |

### 5.2 Referenced By (other objects point to this)

No objects in the current codebase reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found. No stored procedures, views, or functions reference this table.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_tempResult_FinanceReportsBalances | CLUSTERED PK | Gcid ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_tempResult_FinanceReportsBalances | PRIMARY KEY | Clustered on Gcid. DATA_COMPRESSION = PAGE. Enforces one snapshot row per customer. |

---

## 8. Sample Queries

### 8.1 Count customers by year of last reconciliation
```sql
SELECT YEAR(Occurred) AS LastReconcYear, COUNT(*) AS CustomerCount
FROM Wallet.tempResult_FinanceReportsBalances WITH (NOLOCK)
GROUP BY YEAR(Occurred)
ORDER BY LastReconcYear;
```

### 8.2 Find system/test accounts (negative or zero Gcid)
```sql
SELECT Gcid, Occurred, CreateDate
FROM Wallet.tempResult_FinanceReportsBalances WITH (NOLOCK)
WHERE Gcid <= 0
ORDER BY Gcid;
```

### 8.3 Customers whose last reconciliation was more than a year before the snapshot
```sql
SELECT COUNT(*) AS StaleCustomers
FROM Wallet.tempResult_FinanceReportsBalances WITH (NOLOCK)
WHERE DATEDIFF(DAY, Occurred, CreateDate) > 365;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: - | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.tempResult_FinanceReportsBalances | Type: Table | Source: WalletBalancesReportDB/Wallet/Tables/Wallet.tempResult_FinanceReportsBalances.sql*
