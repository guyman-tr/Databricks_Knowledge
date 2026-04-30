# Trade.InternalLeveragesWhiteList

> Whitelist of Global Customer IDs (GCIDs) authorized to access internal/privileged leverage options that are not available to regular retail customers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Row Count** | 2 (MCP verified) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Trade.InternalLeveragesWhiteList is a small configuration table that grants specific customers access to internal leverage multipliers beyond what is available to standard retail users. Retail leverage is capped by regulators (e.g., ESMA limits: 30x for major forex, 2x for crypto), but certain privileged accounts (internal testing, institutional, or special-access accounts) need higher or unrestricted leverage options.

Without this table, all customers would be subject to standard leverage restrictions. The whitelist provides a mechanism to selectively bypass those limits for approved accounts.

Trade.GetInternalLeveragesWhiteList reads this table and returns the full set of leverage options (from Trade.GetLeverages) along with the list of whitelisted GCIDs. The calling application can then determine if a specific customer should see the internal leverage options by checking if their GCID appears in the whitelist results.

---

## 2. Business Logic

### 2.1 Internal Leverage Access Control

**What**: Determines which customers can access unrestricted leverage options.

**Columns/Parameters Involved**: `GCID`

**Rules**:
- Only GCIDs present in this table are eligible for internal leverage options
- Trade.GetInternalLeveragesWhiteList accepts an optional @GCID parameter: if provided, returns only that GCID (if whitelisted); if NULL, returns all whitelisted GCIDs
- The procedure also returns the full leverage catalog from Trade.GetLeverages as a separate result set
- Currently only 2 customers are whitelisted, suggesting this is used for internal testing or a very limited privilege

**Diagram**:
```
Customer requests leverage options
       |
       v
Trade.GetInternalLeveragesWhiteList(@GCID)
       |
       +-- Result Set 1: All leverage values (from Trade.GetLeverages)
       |     1x, 2x, 5x, 10x, 20x, 25x, 30x, 50x, 100x, ...
       |
       +-- Result Set 2: Whitelisted GCIDs (from this table)
       |     GCID in whitelist? --> Show internal leverages
       |     GCID NOT in whitelist? --> Show standard regulated leverages
```

---

## 3. Data Overview

| GCID | Meaning |
|---|---|
| 4275563 | Whitelisted for internal leverage access - likely an internal test or privileged account |
| 4275567 | Whitelisted for internal leverage access - likely an internal test or privileged account |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Global Customer ID identifying a customer authorized for internal leverage access. PK. Implicitly references Customer.Customer.GCID (no declared FK). Queried by Trade.GetInternalLeveragesWhiteList to determine if a customer can see internal leverage options. Currently only 2 GCIDs are whitelisted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID | Customer.Customer | Implicit (no declared FK) | References the global customer ID whose leverage access is being elevated |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInternalLeveragesWhiteList | GCID | SELECT | Returns whitelisted GCIDs for leverage access control |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInternalLeveragesWhiteList | Stored Procedure | Reader - returns whitelisted GCIDs alongside leverage catalog |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_GCID | CLUSTERED PK | GCID ASC | - | - | Active (FILLFACTOR=95) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_GCID | PRIMARY KEY | Unique global customer identifier per whitelist entry |

---

## 8. Sample Queries

### 8.1 List all whitelisted customers
```sql
SELECT  GCID
FROM    Trade.InternalLeveragesWhiteList WITH (NOLOCK)
ORDER BY GCID;
```

### 8.2 Check if a specific customer is whitelisted
```sql
SELECT  CASE WHEN EXISTS (
            SELECT 1
            FROM   Trade.InternalLeveragesWhiteList WITH (NOLOCK)
            WHERE  GCID = 4275563
        ) THEN 'Whitelisted' ELSE 'Standard' END AS LeverageAccess;
```

### 8.3 Show whitelisted customers with their account details
```sql
SELECT  ilw.GCID,
        cc.CID,
        cc.PlayerLevelID
FROM    Trade.InternalLeveragesWhiteList ilw WITH (NOLOCK)
JOIN    Customer.Customer cc WITH (NOLOCK)
        ON ilw.GCID = cc.GCID
ORDER BY ilw.GCID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from procedure logic analysis (Trade.GetInternalLeveragesWhiteList) and the documented Trade.GetLeverages view.

---

*Generated: 2026-03-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InternalLeveragesWhiteList | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.InternalLeveragesWhiteList.sql*
