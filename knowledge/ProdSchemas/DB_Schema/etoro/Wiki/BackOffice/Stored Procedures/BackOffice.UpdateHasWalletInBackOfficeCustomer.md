# BackOffice.UpdateHasWalletInBackOfficeCustomer

> Scheduled maintenance job that sets HasWallet=1 on BackOffice.Customer records for customers who have had wallet activity in the past 2 days, syncing the eToro Money wallet presence flag.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - scheduled maintenance job |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.UpdateHasWalletInBackOfficeCustomer` is a scheduled synchronization job that detects customers with an active eToro Money wallet and marks them in the BackOffice.Customer table. The `HasWallet` flag enables back-office operations to quickly identify which customers have linked an eToro Money wallet account (as opposed to trading-only accounts), which affects certain withdrawal workflows and risk assessments.

The procedure uses a 2-day lookback window into `dbo.WalletCustomerWallets.Occurred` to find customers with recent wallet activity. It only sets `HasWallet=1` - it does not clear it back to 0 once set (intentionally: once a customer has a wallet, they always "have a wallet" even if temporarily inactive). The temp table with a clustered index on GCID is used for efficient JOIN performance given potentially large wallet activity volumes.

The procedure exists because wallet enrollment data lives in an external system (`dbo.WalletCustomerWallets`), separate from the main customer database. The `HasWallet` flag on BackOffice.Customer provides a local cached indicator that avoids cross-database queries in back-office workflows.

---

## 2. Business Logic

### 2.1 Wallet Presence Sync via 2-Day Lookback

**What**: Identifies customers with wallet activity in the last 2 days and marks them as wallet holders in BackOffice.Customer.

**Columns/Parameters Involved**: `BackOffice.Customer.HasWallet`, `dbo.WalletCustomerWallets.Occurred`, `Customer.CustomerStatic.GCID`

**Rules**:
- Source: `dbo.WalletCustomerWallets WHERE Occurred >= DATEADD(day, -2, GETDATE())` - recent wallet activity (2-day rolling window).
- Bridge: GCID links wallet records to Customer.CustomerStatic to find the CID for the BackOffice.Customer UPDATE.
- Target condition: `WHERE HasWallet <> 1 OR HasWallet IS NULL` - only updates customers not yet flagged (avoids unnecessary writes for already-flagged customers).
- Once HasWallet=1 is set, it is never cleared by this procedure (intentional: wallet presence is permanent once established).
- Performance optimization: temp table `#Customers` with clustered index on GCID for efficient JOIN.

**Diagram**:
```
dbo.WalletCustomerWallets (Occurred >= today-2 days)
         |
         | SELECT distinct GCID -> #Customers (temp, clustered on GCID)
         |
         | JOIN Customer.CustomerStatic ON GCID
         | -> get CID
         v
BackOffice.Customer: SET HasWallet=1 WHERE HasWallet<>1 OR HasWallet IS NULL
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | - | This procedure takes no input. It operates as a scheduled job on a fixed 2-day lookback window. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID | dbo.WalletCustomerWallets | SELECT source | Identifies customers with recent wallet activity (last 2 days) |
| GCID | Customer.CustomerStatic | JOIN bridge | Translates GCID to CID for BackOffice.Customer update |
| CID | [BackOffice.Customer](../Tables/BackOffice.Customer.md) | UPDATE target | Sets HasWallet=1 for identified customers |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Scheduled SQL Agent job | - | Caller | Executed on a recurring schedule (daily or more frequently) to keep HasWallet flag current. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.UpdateHasWalletInBackOfficeCustomer (procedure)
+-- dbo.WalletCustomerWallets (table) [SELECT source - external wallet system]
+-- Customer.CustomerStatic (table) [JOIN bridge: GCID -> CID]
+-- BackOffice.Customer (table) [UPDATE target: HasWallet flag]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.WalletCustomerWallets | Table (external) | SELECT distinct GCID WHERE Occurred >= today-2 days |
| Customer.CustomerStatic | Table | JOIN ON GCID to resolve CID for BackOffice.Customer update |
| [BackOffice.Customer](../Tables/BackOffice.Customer.md) | Table | UPDATE target: sets HasWallet=1 for matching CIDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in repo. | - | Invoked by scheduled SQL Agent job. HasWallet flag is consumed by back-office workflows. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Internal temp table `#Customers(GCID)` uses a clustered index created at runtime for JOIN performance.

### 7.2 Constraints

None. Uses `WHERE Occurred >= DATEADD(day,-2,GETDATE())` as the data scope fence.

---

## 8. Sample Queries

### 8.1 Execute the wallet sync job manually

```sql
EXEC BackOffice.UpdateHasWalletInBackOfficeCustomer;
-- Sets HasWallet=1 for all customers with wallet activity in the last 2 days.
```

### 8.2 Preview customers that would be updated

```sql
SELECT DISTINCT cc.CID
FROM dbo.WalletCustomerWallets wcw WITH (NOLOCK)
JOIN Customer.CustomerStatic cc WITH (NOLOCK) ON cc.GCID = wcw.Gcid
JOIN BackOffice.Customer boc WITH (NOLOCK) ON boc.CID = cc.CID
WHERE wcw.Occurred >= DATEADD(day, -2, GETDATE())
  AND (boc.HasWallet <> 1 OR boc.HasWallet IS NULL);
```

### 8.3 Count customers with HasWallet flag in BackOffice

```sql
SELECT
    SUM(CASE WHEN HasWallet = 1 THEN 1 ELSE 0 END) AS WithWallet,
    SUM(CASE WHEN HasWallet IS NULL OR HasWallet = 0 THEN 1 ELSE 0 END) AS WithoutWallet,
    COUNT(*) AS Total
FROM BackOffice.Customer WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Dependency Inheritance, Caller Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched | Corrections: 0 applied*
*Object: BackOffice.UpdateHasWalletInBackOfficeCustomer | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.UpdateHasWalletInBackOfficeCustomer.sql*
