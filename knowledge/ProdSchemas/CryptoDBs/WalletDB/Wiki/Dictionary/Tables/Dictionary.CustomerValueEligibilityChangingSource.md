# Dictionary.CustomerValueEligibilityChangingSource

> Lookup table identifying the source system that changed a customer's eligibility for value-based crypto features (e.g., tier upgrades, premium access).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table tracks which internal system or team triggered a change to a customer's value-based eligibility status for cryptocurrency features. Customer eligibility may be adjusted based on account value thresholds, compliance actions, or manual back-office decisions, and this table records the origin of each change.

Knowing the source of eligibility changes is essential for audit trails and dispute resolution. If a customer's crypto access changes unexpectedly, support teams need to identify whether it was triggered by an automated banking system, a manual back-office action, a crypto-specific rule, or is of unknown origin.

The values are consumed by eligibility-related tables and procedures in the Wallet schema.

---

## 2. Business Logic

### 2.1 Change Source Attribution

**What**: Four sources can trigger customer eligibility changes.

**Columns/Parameters Involved**: `Id`, `ChangingSource`

**Rules**:
- `Unknown` (0): Source not determined - legacy records or edge cases where the triggering system was not recorded
- `BackOffice` (1): Manual change by back-office staff (compliance, support, or operations team)
- `Banking` (2): Automated change triggered by the banking/fiat system based on account value thresholds or banking events
- `Crypto` (3): Automated change triggered by crypto-specific business rules (e.g., portfolio value crossing a tier threshold)

---

## 3. Data Overview

| Id | ChangingSource | Meaning |
|---|---|---|
| 0 | Unknown | Eligibility change source was not recorded. Typically for legacy records created before source tracking was implemented, or edge cases where the triggering system did not identify itself. |
| 1 | BackOffice | Change initiated manually by eToro back-office staff. Used for compliance-driven restrictions, support escalations, or manual tier adjustments. Provides accountability for human-initiated changes. |
| 2 | Banking | Change triggered by the fiat banking system. Automated based on account value thresholds, deposit patterns, or banking compliance rules. Reflects the customer's financial activity on the traditional finance side. |
| 3 | Crypto | Change triggered by crypto-specific business logic. Automated based on crypto portfolio value, staking activity, or crypto-specific tier rules. Reflects the customer's activity in the crypto ecosystem. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the change source. Values: 0=Unknown, 1=BackOffice, 2=Banking, 3=Crypto. |
| 2 | ChangingSource | varchar(50) | NO | - | CODE-BACKED | Name of the system or team that triggered the eligibility change. Used in audit logs and customer support investigations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Eligibility.CustomerValues | ValueChangingSourceId | FK | Records which system triggered each eligibility change event |

---

## 6. Dependencies

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No direct dependents found in the Wallet schema SSDT.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerValueEligibilityChangingSource | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all eligibility change sources
```sql
SELECT Id, ChangingSource FROM Dictionary.CustomerValueEligibilityChangingSource WITH (NOLOCK) ORDER BY Id
```

### 8.2 Resolve a change source ID
```sql
SELECT ChangingSource FROM Dictionary.CustomerValueEligibilityChangingSource WITH (NOLOCK) WHERE Id = 1
```

### 8.3 All change sources with descriptions
```sql
SELECT Id, ChangingSource,
  CASE Id
    WHEN 0 THEN 'Legacy/unrecorded source'
    WHEN 1 THEN 'Manual back-office action'
    WHEN 2 THEN 'Automated banking system'
    WHEN 3 THEN 'Automated crypto rules'
  END AS Description
FROM Dictionary.CustomerValueEligibilityChangingSource WITH (NOLOCK)
ORDER BY Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 3.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CustomerValueEligibilityChangingSource | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.CustomerValueEligibilityChangingSource.sql*
