# Billing.RiskAffiliateMultiAccountEx

> Exclusion list of affiliate IDs exempted from the automated multi-account risk detection job that flags affiliates registering more than 10 new customers per day.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | AffiliateID (INT, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup) |
| **Indexes** | 1 (PK only) |
| **Temporal** | No |

---

## 1. Business Meaning

Billing.RiskAffiliateMultiAccountEx is a small exclusion (allowlist) table used by the automated affiliate multi-account fraud detection system. The risk job `Maintenance.JOB_AffiliateMultipleAccounts` runs periodically and flags any affiliate that has registered more than 10 new customers in the past 24 hours as a potential multi-account fraud risk (RiskStatusID=10 "Affiliate Multiple Accounts").

However, some legitimate affiliates - such as large marketing networks or institutional partners - regularly bring many new customers in a short window without any fraudulent intent. Affiliates in this table are explicitly excluded from the risk detection logic, preventing false positives for known high-volume partners.

The table has a single column (AffiliateID) and serves purely as an exception list. **11 rows** currently (AffiliateID 3 through 22397).

---

## 2. Business Logic

### 2.1 Multi-Account Risk Detection Exclusion

**What**: The fraud detection job excludes affiliates in this table from the automated RiskStatus elevation to "Affiliate Multiple Accounts" (RiskStatusID=10).

**Columns/Parameters Involved**: `AffiliateID`

**Rules**:
- `Maintenance.JOB_AffiliateMultipleAccounts` runs daily to find suspicious affiliates
- Detection criteria: `COUNT(new customers registered in last 24h) > 10 AND RiskStatusID = 1 (Normal)`
- Exclusion: `AND BA.AffiliateID NOT IN (SELECT AffiliateID FROM Billing.RiskAffiliateMultiAccountEx)`
- If NOT excluded and meets criteria -> the affiliate's customer CID gets RiskStatusID = 10 in BackOffice.Customer
- Affiliates in this table are completely skipped from this check, regardless of how many new accounts they bring

**Diagram**:
```
Maintenance.JOB_AffiliateMultipleAccounts
        |
        SELECT affiliates with > 10 new customers in last 24h
        WHERE RiskStatusID = 1 (Normal)
        AND AffiliateID NOT IN (Billing.RiskAffiliateMultiAccountEx)  <- excluded
        |
        For each suspicious affiliate:
          UPDATE BackOffice.Customer SET RiskStatusID = 10 (Affiliate Multiple Accounts)
          INSERT INTO History.RiskStatus (audit trail)
```

---

## 3. Data Overview

| AffiliateID | Meaning |
|-------------|---------|
| 3 | Low-numbered affiliate ID - likely a very early/primary partner |
| 11 | Early affiliate - excluded from multi-account detection |
| 79 | Affiliate with known high-volume registration pattern |
| 2875 - 22397 | Later affiliates (9 more) explicitly added to the exclusion list |

Total: 11 rows. These represent affiliates that have been manually whitelisted because their high new-customer-per-day volume is known to be legitimate business activity.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliateID | INT | NO | - | CODE-BACKED | The affiliate identifier to exclude from the multi-account risk detection job. FK to BackOffice.Affiliate(AffiliateID) - no DDL constraint defined. Used in `NOT IN (SELECT AffiliateID FROM Billing.RiskAffiliateMultiAccountEx)` in the Maintenance job. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AffiliateID | BackOffice.Affiliate | Implicit FK (no DDL constraint) | Each row exempts one affiliate from the multi-account risk check. No DDL FK enforced. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Maintenance.JOB_AffiliateMultipleAccounts | AffiliateID | READER (NOT IN exclusion) | Reads this table to exclude listed affiliates from the fraud detection logic. The only consumer. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.RiskAffiliateMultiAccountEx (table)
└-- BackOffice.Affiliate (implicit - no DDL FK)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Affiliate | Table | Implicit FK - AffiliateIDs are affiliate partner records |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.JOB_AffiliateMultipleAccounts | Stored Procedure | READER - exclusion list for multi-account affiliate risk detection |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BRAMAE | CLUSTERED PK | AffiliateID ASC | - | - | Active |

Index options: FILLFACTOR=90, OPTIMIZE_FOR_SEQUENTIAL_KEY=OFF.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BRAMAE | PRIMARY KEY CLUSTERED | AffiliateID must be unique - each affiliate can only be excluded once |

---

## 8. Sample Queries

### 8.1 View all excluded affiliates

```sql
SELECT
    e.AffiliateID,
    a.Name AS AffiliateName
FROM [Billing].[RiskAffiliateMultiAccountEx] e WITH (NOLOCK)
LEFT JOIN [BackOffice].[Affiliate] a WITH (NOLOCK) ON a.AffiliateID = e.AffiliateID
ORDER BY e.AffiliateID
```

### 8.2 Check if a specific affiliate is excluded

```sql
DECLARE @AffiliateID INT = 3

SELECT
    CASE WHEN EXISTS (
        SELECT 1 FROM [Billing].[RiskAffiliateMultiAccountEx] WITH (NOLOCK)
        WHERE AffiliateID = @AffiliateID
    ) THEN 'Excluded from multi-account risk check'
    ELSE 'Subject to multi-account risk detection'
    END AS ExclusionStatus
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources directly reference this table.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 7.8/10 (Elements: 8.0/10, Logic: 8.5/10, Relationships: 7.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.RiskAffiliateMultiAccountEx | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.RiskAffiliateMultiAccountEx.sql*
