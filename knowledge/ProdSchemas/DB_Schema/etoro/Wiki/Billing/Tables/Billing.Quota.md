# Billing.Quota

> Per-bank minimum/maximum monthly credit card processing volume quota configuration - a legacy table superseded by Billing.QuotaManagement (per-protocol quotas).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | BankID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Billing.Quota stores minimum and maximum monthly credit card processing volume thresholds at the **acquiring bank** level. Each row represents a quota configuration for one bank, defining the minimum amount (MinQuota) that should be routed through that bank in a given month and an optional cap (MaxQuota).

This table exists as part of an early quota management system designed to ensure payment volume was distributed across acquiring banks according to contractual minimums. If a bank had a minimum monthly processing commitment, this table enforced the awareness of that threshold.

In practice, this table is **no longer actively referenced by any stored procedure**. The active quota management system is Billing.QuotaManagement, which tracks quotas at the payment protocol level (ProtocolID) rather than the bank level. All 5 rows have MaxQuota = NULL, meaning the upper bound was never configured, and the majority of the banks listed (CAL, LeumiCard, B&S, GCS) are now inactive in Dictionary.Bank. The table is retained for historical reference and is accessible to the SQL_SecurePay role for auditing.

---

## 2. Business Logic

### 2.1 Bank-Level Volume Quota Threshold

**What**: A minimum monthly processing volume assigned per acquiring bank to meet contractual volume commitments.

**Columns/Parameters Involved**: `BankID`, `MinQuota`, `MaxQuota`

**Rules**:
- Each bank can have at most one quota row (BankID is the PK).
- MinQuota represents the minimum monthly transaction volume (in monetary units) that should flow through the bank.
- MaxQuota is an optional upper cap - all current rows have it NULL, meaning no ceiling was configured.
- The active quota enforcement system (Billing.QuotaManagement, Billing.MonthlyQuota, Billing.GetMonthlyQuota TVF) operates at the ProtocolID level, not BankID level. This table predates that architecture.

**Diagram**:
```
Dictionary.Bank
  BankID (e.g., 2 = WireCard Bank)
       |
       v
Billing.Quota
  BankID | MinQuota  | MaxQuota
  -------|-----------|----------
     2   | 10000000  |   NULL    <- Minimum $10M/month, no upper cap
       |
       v  (conceptually replaced by)
Billing.QuotaManagement
  ProtocolID | QuotaMin | QuotaMax   <- active quota system
```

---

## 3. Data Overview

| BankID | Bank Name | MinQuota | MaxQuota | Meaning |
|--------|-----------|----------|----------|---------|
| 1 | CAL | 10,000,000 | NULL | Monthly minimum processing quota for CAL (Israeli card acquirer). Bank is now inactive - quota is historical. |
| 2 | WireCard Bank | 10,000,000 | NULL | Monthly minimum for WireCard Bank (European acquirer, still active in Dictionary.Bank). No ceiling configured. |
| 7 | LeumiCard | 10,000,000 | NULL | Monthly minimum for LeumiCard (Israeli bank). Bank now inactive. |
| 8 | B&S | 10,000,000 | NULL | Monthly minimum for B&S acquirer. Bank now inactive. |
| 9 | GCS | 10,000,000 | NULL | Monthly minimum for GCS. Bank now inactive. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | BankID | INT | NO | - | CODE-BACKED | Acquiring bank identifier. FK to Dictionary.Bank(BankID). Identifies which bank this quota applies to. Values in this table: 1=CAL (inactive), 2=WireCard Bank (active), 7=LeumiCard (inactive), 8=B&S (inactive), 9=GCS (inactive). |
| 2 | MinQuota | INT | NO | - | NAME-INFERRED | Minimum monthly processing volume (monetary amount) that should be routed through this bank. All current rows = 10,000,000. No stored procedure currently reads this column. |
| 3 | MaxQuota | INT | YES | - | NAME-INFERRED | Maximum monthly processing volume cap for the bank. Always NULL in current data - upper bound was never configured and the column was never populated. Effectively unused/deprecated. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BankID | Dictionary.Bank | FK (FK_DBNK_BQTA) | Each quota row is associated with one acquiring bank. Bank name and active status available via this join. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_SecurePay role | - | Permission (SELECT) | The SQL_SecurePay database role has SELECT permission on this table for auditing purposes. No stored procedure actively reads from it. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Quota (table)
└── Dictionary.Bank (table) [FK: BankID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Bank | Table | FK constraint FK_DBNK_BQTA - BankID references Dictionary.Bank(BankID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_SecurePay | Database Role | SELECT permission granted - read-only audit access |

No stored procedures, views, or functions actively reference this table. The equivalent active quota system is Billing.QuotaManagement.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BQTA | CLUSTERED PK | BankID ASC | - | - | Active |

Index options: PAD_INDEX=OFF, FILLFACTOR=90, OPTIMIZE_FOR_SEQUENTIAL_KEY=OFF.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BQTA | PRIMARY KEY CLUSTERED | BankID must be unique - one quota row per bank |
| FK_DBNK_BQTA | FOREIGN KEY | BankID must exist in Dictionary.Bank(BankID) |

---

## 8. Sample Queries

### 8.1 View all bank quota configurations with bank names

```sql
SELECT
    q.BankID,
    b.Name AS BankName,
    b.IsActive,
    q.MinQuota,
    q.MaxQuota
FROM [Billing].[Quota] q WITH (NOLOCK)
INNER JOIN [Dictionary].[Bank] b WITH (NOLOCK) ON b.BankID = q.BankID
ORDER BY q.BankID
```

### 8.2 Find quota-configured banks that are still active

```sql
SELECT
    q.BankID,
    b.Name AS BankName,
    q.MinQuota,
    q.MaxQuota
FROM [Billing].[Quota] q WITH (NOLOCK)
INNER JOIN [Dictionary].[Bank] b WITH (NOLOCK) ON b.BankID = q.BankID
WHERE b.IsActive = 1
```

### 8.3 Compare legacy bank quotas vs active protocol quotas (QuotaManagement)

```sql
-- Legacy: per-bank quotas (Billing.Quota)
SELECT 'BankLevel' AS QuotaType, b.Name AS EntityName, q.MinQuota, q.MaxQuota
FROM [Billing].[Quota] q WITH (NOLOCK)
INNER JOIN [Dictionary].[Bank] b WITH (NOLOCK) ON b.BankID = q.BankID
UNION ALL
-- Active: per-protocol quotas (Billing.QuotaManagement)
SELECT 'ProtocolLevel', p.Name, qm.QuotaMin, qm.QuotaMax
FROM [Billing].[QuotaManagement] qm WITH (NOLOCK)
INNER JOIN [Dictionary].[Protocol] p WITH (NOLOCK) ON p.ProtocolID = qm.ProtocolID
ORDER BY QuotaType, EntityName
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Integration Database Refresh](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/1632501883) | Confluence | Lists Billing.Quota as a configuration entity in the integration DB - confirms it is a configuration/lookup table (MEDIUM confidence) |

---

*Generated: 2026-03-17 | Enriched: - | Quality: 5.9/10 (Elements: 6.7/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 analyzed (no active procedures) | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.Quota | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.Quota.sql*
