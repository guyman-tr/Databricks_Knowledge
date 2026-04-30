# Dictionary.PhoneVerificationTransactionRecommendation

> Lookup table defining 6 transaction recommendations from phone verification — Block, Flag, Allow, NotApplicable, None, and Other — guiding automated transaction decisions based on phone risk.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RecommendationID (INT, PK) |
| **Partition** | PRIMARY filegroup (PAGE compression) |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.PhoneVerificationTransactionRecommendation stores the transaction-level recommendations returned by phone verification providers. After assessing a phone number's risk, the provider returns a recommendation for how the platform should handle transactions from this customer — block them, flag for review, allow normally, or mark as not applicable.

This table exists because the phone verification system provides actionable recommendations beyond just a risk score. The recommendation directly drives automated transaction decisions: a "Block" recommendation prevents deposits or withdrawals, a "Flag" recommendation routes transactions to manual review, and an "Allow" recommendation permits normal processing.

The recommendation is stored per verification record in Customer.PhoneVerificationDetails and integrated into the transaction processing pipeline.

---

## 2. Business Logic

### 2.1 Transaction Decision Matrix

**What**: Phone verification providers return one of 6 recommendations that drive automated transaction handling.

**Columns/Parameters Involved**: `RecommendationID`, `Recommmendation`

**Rules**:
- **None (0)** — No recommendation provided (provider did not assess transaction risk).
- **Block (1)** — Block all transactions. The phone number is high-risk and transactions should be prevented.
- **Flag (2)** — Flag transactions for manual review. Suspicious but not conclusive — a compliance officer should evaluate.
- **Allow (3)** — Allow transactions normally. The phone number is verified and trustworthy.
- **NotApplicable (4)** — The recommendation system does not apply to this verification type or scenario.
- **Other (2147483647)** — Catch-all for unrecognized recommendations from the provider.

**Diagram**:
```
Transaction Recommendation Flow
    Phone verified → Provider returns recommendation
           │
           ├── 1 = Block    → Prevent all transactions
           ├── 2 = Flag     → Route to manual review
           ├── 3 = Allow    → Process normally
           ├── 0 = None     → No recommendation (use risk level instead)
           ├── 4 = N/A      → Recommendation not applicable
           └── MaxInt=Other  → Unknown (investigate)
```

---

## 3. Data Overview

| RecommendationID | Recommmendation | Meaning |
|---|---|---|
| 0 | None | No transaction recommendation from the provider. The platform falls back to the risk level (PhoneVerificationRiskLevel) for decision-making. |
| 1 | Block | Provider recommends blocking all transactions from this phone number. High-confidence fraud signal — automated enforcement should prevent deposits and withdrawals. |
| 2 | Flag | Provider recommends flagging transactions for manual review. Suspicious patterns detected but not conclusive enough to block. Compliance team must evaluate. |
| 3 | Allow | Provider recommends allowing transactions normally. Phone number is verified clean and trustworthy. Standard processing applies. |
| 2147483647 | Other | Catch-all for unrecognized provider recommendations. Uses INT max value to sort last. Logged for investigation and provider API mapping review. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RecommendationID | int | NO | - | VERIFIED | Primary key identifying the transaction recommendation. 0=None, 1=Block, 2=Flag, 3=Allow, 4=NotApplicable, 2147483647=Other. Stored in Customer.PhoneVerificationDetails. |
| 2 | Recommmendation | varchar(50) | NO | - | VERIFIED | Human-readable recommendation label. Note: column name has a typo (triple 'm') preserved from the original DDL. Used in verification reports and transaction routing dashboards. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.PhoneVerificationDetails | RecommendationID | Implicit | Stores the transaction recommendation per verification record |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.PhoneVerificationDetails | Table | Stores RecommendationID per verification record |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_PhoneVerificationTransactionRecommendation | CLUSTERED PK | RecommendationID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_PhoneVerificationTransactionRecommendation | PRIMARY KEY | Unique recommendation identifier |

---

## 8. Sample Queries

### 8.1 List all recommendations
```sql
SELECT  RecommendationID,
        Recommmendation
FROM    [Dictionary].[PhoneVerificationTransactionRecommendation] WITH (NOLOCK)
ORDER BY RecommendationID;
```

### 8.2 Find actionable recommendations (Block or Flag)
```sql
SELECT  RecommendationID,
        Recommmendation
FROM    [Dictionary].[PhoneVerificationTransactionRecommendation] WITH (NOLOCK)
WHERE   RecommendationID IN (1, 2)
ORDER BY RecommendationID;
```

### 8.3 Map recommendations to enforcement actions
```sql
SELECT  RecommendationID,
        Recommmendation,
        CASE RecommendationID
            WHEN 0 THEN 'Fallback to risk level'
            WHEN 1 THEN 'AUTO-BLOCK transactions'
            WHEN 2 THEN 'MANUAL REVIEW required'
            WHEN 3 THEN 'AUTO-ALLOW (clean)'
            WHEN 4 THEN 'Skip (not applicable)'
            ELSE 'Investigate (unknown)'
        END AS EnforcementAction
FROM    [Dictionary].[PhoneVerificationTransactionRecommendation] WITH (NOLOCK)
ORDER BY RecommendationID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PhoneVerificationTransactionRecommendation | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PhoneVerificationTransactionRecommendation.sql*
