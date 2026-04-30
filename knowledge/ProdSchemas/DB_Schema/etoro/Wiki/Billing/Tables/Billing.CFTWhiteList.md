# Billing.CFTWhiteList

> BIN-level eligibility control list for Card-Funded Transfer (CFT) transactions - 407K card BIN prefixes with an allow/block flag used to determine if a card issuer supports CFT.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY PK) |
| **Partition** | No (PRIMARY filegroup, FILLFACTOR 90) |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

`Billing.CFTWhiteList` is a reference table containing approximately 407,000 card BIN (Bank Identification Number) entries used to determine eligibility for Card-Funded Transfer (CFT) transactions. CFT is a payment mechanism where a debit or credit card is used as the funding source for a transfer - common in peer-to-peer and cross-border payment flows.

Each row stores a card BIN (the first 6-8 digits of a card number, identifying the issuing bank and card product) along with an `IsAllowed` flag. Despite the "WhiteList" name, the table operates primarily as a block list: `IsAllowed = 'N'` explicitly blocks 137,560 BINs (34%), while `IsAllowed = NULL` (66%) means the BIN is implicitly allowed (default pass-through). No `IsAllowed = 'Y'` values exist - the positive case is represented by NULL absence.

The `NOT FOR REPLICATION` flag on the IDENTITY column indicates this table participates in SQL Server replication - the identity seed is not consumed on subscriber inserts, preventing ID conflicts in replicated topologies.

No stored procedure in the SSDT repo directly references this table - it is consumed by application code or the Routing Tool. The newer `Billing.CFTWhiteListForAllProtocols` table is the active protocol-specific successor for CFT BIN lookups.

---

## 2. Business Logic

### 2.1 BIN Eligibility Logic (Inverted Whitelist)

**What**: NULL = allowed (default), 'N' = blocked. The table name is misleading - it functions as a blacklist.

**Columns/Parameters Involved**: `BIN`, `IsAllowed`

**Rules**:
- `IsAllowed = NULL` (270,062 rows, 66%): BIN is allowed for CFT. The absence of a flag means pass-through.
- `IsAllowed = 'N'` (137,560 rows, 34%): BIN is explicitly blocked from CFT transactions.
- `IsAllowed = 'Y'`: Not currently used - the positive state is represented by NULL.
- Application logic: check if a BIN exists in this table and has `IsAllowed = 'N'` - if so, reject CFT. Otherwise allow.

**Diagram**:
```
Card BIN lookup for CFT eligibility
        |
        v
CFTWhiteList WHERE BIN = @CardBIN
        |
        +-- Row found, IsAllowed = 'N'  -> BLOCKED (CFT not allowed for this issuer)
        |
        +-- Row found, IsAllowed = NULL -> ALLOWED (pass-through)
        |
        +-- Row not found              -> ALLOWED (default - BIN not in list)
```

---

## 3. Data Overview

| ID | BIN | IsAllowed | Meaning |
|----|-----|-----------|---------|
| 1 | 2184415 | NULL | A Mastercard-range BIN (starts with 2) allowed for CFT. NULL = pass-through, no restriction. |
| 2 | 222300 | NULL | 6-digit BIN from the Mastercard 2-series range, allowed for CFT. |
| 4 | 22264700 | NULL | 8-digit BIN (extended format, post-2017 expansion), allowed for CFT. |

*Note: 'N' rows not shown in TOP sample; 137,560 exist - represent blocked issuers. No data rows with BINs of blocked cards are shown to avoid exposing operational blocklist details.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Surrogate primary key, auto-incremented. NOT FOR REPLICATION flag means identity values are not consumed on subscriber side in SQL Server replication - prevents ID conflicts in replicated environments. Not a business key. |
| 2 | BIN | bigint | NO | - | CODE-BACKED | Bank Identification Number - the first 6 or 8 digits of a payment card number that identify the card issuer, network, and card product. 6-digit BINs are the traditional format; 8-digit BINs were introduced post-2017. Examples: 222300 (Mastercard), 22264700 (Mastercard 8-digit). Used to determine if a card's issuing bank supports CFT transactions. |
| 3 | IsAllowed | char(1) | YES | - | CODE-BACKED | CFT eligibility flag for this BIN. Observed values: NULL (66%, allowed - default pass-through), 'N' (34%, blocked - CFT not permitted for this issuer). No 'Y' values exist - positive allowance is represented by NULL. Despite the table name "WhiteList", the primary use is as a blocklist: only 'N' entries have operational effect. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. (BIN is a raw numeric value, not a FK to another table.)

### 5.2 Referenced By (other objects point to this)

No SQL stored procedures or views in the SSDT repo reference this table. Consumed by application code (not visible in DB layer). See `Billing.CFTWhiteListForAllProtocols` for the active protocol-specific successor.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT repo. Related table (not a dependent): `Billing.CFTWhiteListForAllProtocols` - the protocol-aware successor for CFT BIN lookups, currently referenced by application code.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingCFTWhiteList | CLUSTERED PK | ID ASC | - | - | Active |

FILLFACTOR=90. PRIMARY filegroup. No index on BIN column - lookups by BIN do a clustered scan (the newer CFTWhiteListForAllProtocols has BIN indexed).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingCFTWhiteList | PRIMARY KEY | ID - unique row identifier |

---

## 8. Sample Queries

### 8.1 Check if a BIN is blocked for CFT

```sql
SELECT ID, BIN, IsAllowed
FROM [Billing].[CFTWhiteList] WITH (NOLOCK)
WHERE BIN = @CardBIN
  AND IsAllowed = 'N';
-- Non-empty result = CFT blocked for this BIN
```

### 8.2 Count BINs by eligibility status

```sql
SELECT
    CASE WHEN IsAllowed IS NULL THEN 'Allowed (NULL)' ELSE 'Blocked (N)' END AS Status,
    COUNT(*) AS BINCount
FROM [Billing].[CFTWhiteList] WITH (NOLOCK)
GROUP BY IsAllowed;
```

### 8.3 Sample blocked BINs

```sql
SELECT TOP 10 ID, BIN, IsAllowed
FROM [Billing].[CFTWhiteList] WITH (NOLOCK)
WHERE IsAllowed = 'N'
ORDER BY ID;
```

---

## 9. Atlassian Knowledge Sources

No direct Atlassian sources found specifically for Billing.CFTWhiteList. Related MIMO Group pages found on Card-Funded Transfers (Methods of Payment, CashOutTool) but content is general and not specific to this table's structure.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 2/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.CFTWhiteList | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.CFTWhiteList.sql*
