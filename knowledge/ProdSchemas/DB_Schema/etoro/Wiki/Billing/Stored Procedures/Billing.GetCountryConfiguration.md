# Billing.GetCountryConfiguration

> Returns all rows from Dictionary.RankToCountryConfiguration (KycRankID, DepositRankID, WithdrawAllowedCountryRangeId). Provides the per-rank KYC and deposit/withdrawal eligibility configuration table used by the payment routing system.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetCountryConfiguration` retrieves the complete country rank configuration table. Each row in `Dictionary.RankToCountryConfiguration` maps a combination of KYC rank, deposit rank, and withdrawal country range - defining the payment eligibility rules for each country tier. This configuration controls what deposits and withdrawals customers from different country risk levels can make.

---

## 2. Business Logic

### 2.1 Full Configuration Table Read

**What**: Returns all rows from the country configuration table with no filtering.

**Rules**:
- No parameters, no WHERE clause
- Three columns returned: KycRankID, DepositRankID, WithdrawAllowedCountryRangeId
- Used by the routing/payment system to load the full eligibility matrix at startup or on refresh

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Return Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | KycRankID | int | NO | - | VERIFIED | KYC (Know Your Customer) verification rank. Determines verification requirements before deposits/withdrawals are allowed. |
| 2 | DepositRankID | int | NO | - | VERIFIED | Deposit eligibility rank. Controls which deposit methods are available for this country rank. |
| 3 | WithdrawAllowedCountryRangeId | int | NO | - | VERIFIED | Withdrawal country range identifier. Determines which withdrawal destinations/methods are permitted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All columns | Dictionary.RankToCountryConfiguration | Read | Full table scan. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No explicit GRANT EXECUTE found) | - | Internal payment routing system |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetCountryConfiguration (procedure)
└── Dictionary.RankToCountryConfiguration (table)
```

---

## 7. Technical Details

N/A for Stored Procedure.

---

## 8. Sample Queries

```sql
EXEC Billing.GetCountryConfiguration
-- Returns all rank-to-configuration mappings
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.3/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetCountryConfiguration | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetCountryConfiguration.sql*
