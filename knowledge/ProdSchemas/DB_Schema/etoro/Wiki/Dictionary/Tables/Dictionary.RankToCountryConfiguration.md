# Dictionary.RankToCountryConfiguration

> Configuration table defining 12 deposit/withdrawal restriction rules based on KYC rank and deposit rank combinations — controlling which country ranges are allowed for withdrawals.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Composite (KycRankID, DepositRankID, WithdrawAllowedCountryRangeId) — no PK defined |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Dictionary.RankToCountryConfiguration defines the withdrawal country restrictions for each combination of KYC rank and deposit source rank. This is a compliance matrix: when a customer with KYC rank X makes a deposit from a country at rank Y, the system determines which country range is allowed for withdrawals.

This table works in conjunction with Dictionary.RankToCountry (which assigns ranks to countries). The KYC rank comes from the customer's verified country of residence, while the deposit rank comes from the country associated with the payment method (e.g., the country of the credit card's issuing bank).

---

## 2. Business Logic

### 2.1 KYC-Deposit Rank Matrix

**What**: Each row defines which withdrawal country range is allowed for a specific KYC rank × Deposit rank combination.

**Columns/Parameters Involved**: `KycRankID`, `DepositRankID`, `WithdrawAllowedCountryRangeId`

**Rules**:
- **KycRankID** (1-3): The customer's verified KYC country rank.
- **DepositRankID** (1-3 or NULL): The rank of the deposit source country. NULL means "no deposit rank determined."
- **WithdrawAllowedCountryRangeId** (1, 2, or 4): The withdrawal country restriction level.
  - Range 1: Most permissive — same-rank country withdrawals.
  - Range 2: Moderate — cross-rank but restricted.
  - Range 4: Most restrictive — applied when deposit rank is unknown (NULL).
- When KYC and Deposit ranks match (e.g., KYC=1 + Deposit=1, or KYC=2 + Deposit=2), the most permissive withdrawal range (1) is applied.
- When ranks differ, a more restrictive range (2) applies.
- When deposit rank is unknown (NULL), the most restrictive range (4) applies.

---

## 3. Data Overview

| KycRankID | DepositRankID | WithdrawAllowedCountryRangeId | Meaning |
|---|---|---|---|
| 1 | 1 | 1 | KYC Rank 1 + Deposit Rank 1 → most permissive withdrawals |
| 1 | 2 | 2 | KYC Rank 1 + Deposit Rank 2 → moderate restrictions |
| 1 | NULL | 4 | KYC Rank 1 + unknown deposit → most restrictive |
| 2 | 2 | 1 | KYC Rank 2 + Deposit Rank 2 → most permissive (matched) |
| 3 | NULL | 4 | KYC Rank 3 + unknown deposit → most restrictive |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | KycRankID | int | NO | - | VERIFIED | Customer's KYC country rank (1-3). Determined by their verified country of residence via Dictionary.RankToCountry. |
| 2 | DepositRankID | int | YES | - | VERIFIED | Rank of the deposit source country (1-3). NULL when deposit country rank is unknown or not applicable. |
| 3 | WithdrawAllowedCountryRangeId | int | NO | - | VERIFIED | Withdrawal restriction level. Lower values are more permissive. 1=same-rank allowed, 2=moderate, 4=most restrictive (unknown deposit). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Referenced Object | Element | Relationship Type | Description |
|-------------------|---------|-------------------|-------------|
| Dictionary.RankToCountry | KycRankID, DepositRankID | Implicit | Country rank definitions |

### 5.2 Referenced By (other objects point to this)

No direct FK consumers — read as configuration data by billing procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object references Dictionary.RankToCountry implicitly.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.RankToCountry | Table | Implicit — defines the rank values |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.GetCountryAndRank | Stored Procedure | Reader — resolves withdrawal restrictions |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. This is a heap table.

### 7.2 Constraints

No constraints defined. No PK, no FK, no unique constraints.

---

## 8. Sample Queries

### 8.1 List all rank configuration rules
```sql
SELECT  KycRankID,
        DepositRankID,
        WithdrawAllowedCountryRangeId
FROM    [Dictionary].[RankToCountryConfiguration] WITH (NOLOCK)
ORDER BY KycRankID, DepositRankID;
```

### 8.2 Find withdrawal range for a specific combination
```sql
SELECT  WithdrawAllowedCountryRangeId
FROM    [Dictionary].[RankToCountryConfiguration] WITH (NOLOCK)
WHERE   KycRankID = 1
        AND DepositRankID = 2;
```

### 8.3 Find most restrictive rules (unknown deposit)
```sql
SELECT  KycRankID,
        WithdrawAllowedCountryRangeId
FROM    [Dictionary].[RankToCountryConfiguration] WITH (NOLOCK)
WHERE   DepositRankID IS NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RankToCountryConfiguration | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RankToCountryConfiguration.sql*
