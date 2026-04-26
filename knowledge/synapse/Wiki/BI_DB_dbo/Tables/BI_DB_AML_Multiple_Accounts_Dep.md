# BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep

> 116K-row AML (Anti-Money Laundering) detection table identifying deposit funding entities (FundingIDs) shared by 2 or more distinct verified eToro customers. Each row represents one shared FundingID group — a potential AML signal for coordinated deposit activity or linked account networks. Part of the Multiple Accounts detection suite written by SP_AML_Multiple_Accounts.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `DWH_dbo.Fact_BillingDeposit` (FundingID-level aggregation) + `External_etoro_Billing_Funding` (IsBlocked flag) |
| **Refresh** | On-demand — SP_AML_Multiple_Accounts is not in the standard OpsDB SB_Daily schedule |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| | |
| **UC Target** | Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`BI_DB_AML_Multiple_Accounts_Dep` is the **summary-level** output of the deposit-based multiple accounts AML detection. It answers: "Which deposit funding entities (FundingIDs) have been used by 2 or more distinct verified eToro customers?" This pattern — multiple people sharing the same deposit payment entity — is a potential indicator of linked accounts, account farming, bonus abuse, or coordinated money movement.

A FundingID maps to a specific funding entity in `etoro.Billing.Funding` — typically a specific bank account, credit card, or e-wallet. When two or more verified customers deposit using the same FundingID, it can signal that the accounts are controlled by the same person or organization.

The table filters for quality: it excludes internal/test FundingIDs (1-7), includes only verified customers (VerificationLevelID ≥ 2, IsValidCustomer=1, IsDepositor=1), and requires the group to have at least 2 distinct CIDs. Each row provides the group size classification, total deposit volume, and whether the funding entity is currently blocked in Billing.

This table serves as the **input driver** for `BI_DB_AML_Multiple_Accounts_Dep_fulldata`, which expands each FundingID group to per-customer detail rows.

The SP was authored by Lior Ben Dor (2023-11-13, migrated to Synapse) and runs on-demand (not in the standard daily ETL schedule). Current population: 116,477 FundingID groups.

---

## 2. Business Logic

### 2.1 FundingID Sharing Detection

**What**: A FundingID is flagged when 2 or more distinct verified customers have deposited through it.

**Columns Involved**: `FundingID`, `Total_Users`

**Rules**:
- Source: `DWH_dbo.Fact_BillingDeposit` grouped by FundingID
- Filters applied before grouping:
  - `FundingID NOT IN (1,2,3,4,5,6,7)` — exclude internal eToro funding entity IDs used for test/internal deposits
  - `IsValidCustomer = 1` — exclude invalid/test accounts
  - `IsDepositor = 1` — only accounts with at least one approved deposit
  - `VerificationLevelID >= 2` — only Verified (2) or Enhanced KYC (3) customers
- `HAVING COUNT(DISTINCT CID) >= 2` — the minimum threshold that makes a FundingID a "multiple accounts" signal

### 2.2 Group Size Classification

**What**: FundingID groups are classified by the number of unique customers sharing them.

**Columns Involved**: `Group_Type`, `Total_Users`

**Rules**:
- `'5 to 20'`: 5-20 unique customers — suspicious but could be a legitimate family/household situation
- `'21 to 50'`: 21-50 unique customers — high risk, likely coordinated or commercial use
- `'51 to 500'`: 51-500 unique customers — very high risk, possible large-scale fraud ring
- `'above 500'`: 500+ unique customers — extreme risk, may indicate a payment aggregator or systematic fraud

**Distribution** (current): 5 to 20 = 87,028 (75%), 21 to 50 = 19,108 (16%), 51 to 500 = 8,282 (7%), above 500 = 2,059 (2%)

> Note: Groups with 2-4 shared CIDs satisfy the `HAVING COUNT >= 2` filter but no Group_Type label covers them. Check whether your analysis requires these small groups — they appear as NULL or default in Group_Type.

### 2.3 Billing Block Status

**What**: Identifies whether the funding entity is currently blocked in the eToro Billing system.

**Columns Involved**: `IsBlocked`

**Rules**:
- Source: `External_etoro_Billing_Funding` (live Billing system data)
- `IsBlocked = 1`: Billing has flagged and blocked this funding entity — no further deposits or withdrawals permitted via this FundingID
- `IsBlocked = 0`: Entity is currently active
- Distribution (current): 0 = 108,225 (93%), 1 = 8,252 (7%)

### 2.4 Deposit Aggregates

**What**: Summary statistics for the deposit activity through each FundingID.

**Columns Involved**: `Last_Deposit_Date`, `Total_Approved_Deposit`, `Num_Approved_Deposit`

**Rules**:
- `Last_Deposit_Date` = MAX(DepositDate) — most recent deposit via this FundingID
- `Total_Approved_Deposit` = SUM of approved deposit amounts (USD)
- `Num_Approved_Deposit` = COUNT of approved deposit transactions

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP with 116K rows. Fast for full-table scans. No distribution key — JOIN with other tables should use HASH-distributed keys (e.g., CID) in the target, not FundingID.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| High-risk groups only | `WHERE Group_Type IN ('51 to 500', 'above 500')` |
| Blocked entities only | `WHERE IsBlocked = 1` |
| High-volume, multi-user deposit entities | `ORDER BY Total_Approved_Deposit DESC` |
| Recent sharing activity | `WHERE Last_Deposit_Date >= '2024-01-01'` |
| Expand to customer detail | JOIN BI_DB_AML_Multiple_Accounts_Dep_fulldata ON FundingID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep_fulldata | ON FundingID | Expand to individual customer rows |
| DWH_dbo.Fact_BillingDeposit | ON FundingID | Additional deposit detail (do not re-aggregate) |

### 3.4 Gotchas

- **Not in daily ETL**: SP_AML_Multiple_Accounts is not in the OpsDB SB_Daily schedule. Data may be stale relative to the current date — always check UpdateDate.
- **Minimum 2 CIDs required**: FundingIDs shared by only 1 customer are excluded by the HAVING filter.
- **FundingID 1-7 excluded**: Internal eToro test/system funding entities are not in this table.
- **Group_Type NULL gap**: The CASE expression maps 5-20/21-50/51-500/500+ but not 2-4 CID groups. Rows with Total_Users in 2-4 may have NULL or unexpected Group_Type.

---

## 4. Elements

| Column | Type | Description | Source | Notes |
|--------|------|-------------|--------|-------|
| FundingID | int | The shared deposit funding entity ID — maps to etoro.Billing.Funding (a specific bank account, card, or e-wallet) | DWH_dbo.Fact_BillingDeposit | Excluded: internal IDs 1-7 |
| IsBlocked | int | Whether this FundingID entity is currently blocked in the Billing system (0=Active, 1=Blocked) | External_etoro_Billing_Funding | 93% unblocked (0), 7% blocked (1) |
| Total_Users | int | Number of distinct verified customers (VerificationLevelID≥2) who deposited via this FundingID | DWH_dbo.Fact_BillingDeposit | COUNT(DISTINCT CID); minimum 2 |
| Group_Type | nvarchar(250) | Size classification of the sharing group: '5 to 20', '21 to 50', '51 to 500', 'above 500' | ETL-computed | CASE expression on Total_Users; see gotcha about 2-4 range |
| Last_Deposit_Date | datetime | Most recent deposit date using this FundingID across all sharing customers | DWH_dbo.Fact_BillingDeposit | MAX(DepositDate) per FundingID |
| Total_Approved_Deposit | int | Total approved deposit amount (USD) via this FundingID across all sharing customers | DWH_dbo.Fact_BillingDeposit | SUM of approved deposits |
| Num_Approved_Deposit | int | Number of approved deposit transactions via this FundingID across all sharing customers | DWH_dbo.Fact_BillingDeposit | COUNT of approved deposits |
| UpdateDate | datetime | ETL metadata: timestamp when this row was last updated by the ETL pipeline | ETL | GETDATE() at SP execution time |

---

## 5. Lineage

```
DWH_dbo.Fact_BillingDeposit
    │  GROUP BY FundingID
    │  HAVING COUNT(DISTINCT CID) >= 2
    │  [filters: FundingID NOT IN (1-7), IsValidCustomer=1, IsDepositor=1, VerificationLevelID>=2]
    │
    ├── LEFT JOIN External_etoro_Billing_Funding → IsBlocked
    └─ SP_AML_Multiple_Accounts (Step 11) → BI_DB_AML_Multiple_Accounts_Dep
```

See full column lineage: `BI_DB_AML_Multiple_Accounts_Dep.lineage.md`

**UC**: Not_Migrated.

---

## 6. Relationships

| Related Table | Join Condition | Relationship |
|--------------|----------------|--------------|
| BI_DB_dbo.BI_DB_AML_Multiple_Accounts_Dep_fulldata | ON FundingID | Expand summary rows to per-customer detail |
| DWH_dbo.Fact_BillingDeposit | ON FundingID | Source deposit transaction data |
| External_etoro_Billing_Funding | ON FundingID | Billing block status |

---

## 7. Sample Queries

```sql
-- High-risk large groups (>50 customers sharing a deposit entity)
SELECT FundingID, IsBlocked, Total_Users, Group_Type,
       Last_Deposit_Date, Total_Approved_Deposit, Num_Approved_Deposit
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Dep]
WHERE Group_Type IN ('51 to 500', 'above 500')
ORDER BY Total_Users DESC

-- Blocked funding entities with large groups
SELECT FundingID, Total_Users, Group_Type, Total_Approved_Deposit
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Dep]
WHERE IsBlocked = 1
ORDER BY Total_Approved_Deposit DESC

-- Expand a specific FundingID to customer detail
SELECT dep.FundingID, dep.Group_Type, dep.Total_Users,
       full.CID, full.UserName, full.Country, full.Regulation, full.PlayerStatus
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Dep] dep
JOIN [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Dep_fulldata] full
  ON dep.FundingID = full.FundingID
WHERE dep.Group_Type = 'above 500'
ORDER BY dep.FundingID, full.CID

-- Group size distribution
SELECT Group_Type, COUNT(*) AS num_funding_ids, SUM(Total_Users) AS total_customers
FROM [BI_DB_dbo].[BI_DB_AML_Multiple_Accounts_Dep]
GROUP BY Group_Type
ORDER BY 2 DESC
```

---

## 8. Atlassian

No Confluence pages found specifically for this table. The Multiple Accounts detection suite is part of the AML/Compliance monitoring platform. SP authored by Lior Ben Dor (2023-11-13). For process documentation, contact the AML Analytics team.
