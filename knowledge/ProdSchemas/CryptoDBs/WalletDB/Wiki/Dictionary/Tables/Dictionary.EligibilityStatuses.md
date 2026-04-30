# Dictionary.EligibilityStatuses

> Lookup table defining the crypto feature access levels that can be granted to customers, from fully blocked to all operations allowed.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | Id (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

This table defines the tiers of access a customer has to cryptocurrency features on the platform. Eligibility is a regulatory and business control mechanism - customers may have different levels of crypto access based on their KYC status, jurisdiction, account age, or compliance actions.

The eligibility system enables the platform to comply with per-jurisdiction regulations while maintaining a single global customer base. A customer in a restrictive jurisdiction might be limited to read-only access, while a fully verified customer in a permissive jurisdiction gets full trading capabilities.

The values are consumed by eligibility-related tables and application logic that gate crypto operations per customer.

---

## 2. Business Logic

### 2.1 Access Tier Hierarchy

**What**: Four-level access control hierarchy for crypto features.

**Columns/Parameters Involved**: `Id`, `Name`

**Rules**:
- `BlockedFromAccess` (0): Customer has no access to crypto features. Cannot view balances, trade, or interact with crypto in any way. Used for banned accounts or jurisdictions that prohibit crypto entirely.
- `ReadOnly` (1): Customer can view crypto information but cannot execute any transactions. Used for partially restricted jurisdictions or accounts pending additional verification.
- `AllOperations` (2): Full crypto access for all customers, including new sign-ups. Buy, sell, send, receive, convert - all operations permitted.
- `AllOperationsForExistingUsersOnly` (3): Full crypto access but only for customers who already have crypto positions. New customers cannot initiate crypto operations. Used during regulatory transitions where existing users are grandfathered in.

**Diagram**:
```
Access Level:  BlockedFromAccess (0) < ReadOnly (1) < AllOperations (2)
                                                         |
                                          AllOperationsForExistingUsersOnly (3)
                                          [Same access, restricted to existing users]
```

---

## 3. Data Overview

| Id | Name | Meaning |
|---|---|---|
| 0 | BlockedFromAccess | Complete crypto lockout. The customer cannot access any cryptocurrency features. Applied to banned accounts, sanctioned jurisdictions, or customers who have failed compliance checks. |
| 1 | ReadOnly | View-only crypto access. Customer can see crypto prices, their portfolio value, and market data, but cannot execute any buy, sell, send, or receive operations. Typical for jurisdictions with viewing-only permissions or accounts pending verification upgrades. |
| 2 | AllOperations | Full unrestricted crypto access. All operations are permitted: buy, sell, send, receive, convert, stake. The standard tier for fully verified customers in permissive jurisdictions. |
| 3 | AllOperationsForExistingUsersOnly | Full crypto access limited to customers who already hold crypto positions. New customers or customers without existing crypto exposure cannot initiate operations. Used during regulatory transitions to grandfather existing users while blocking new crypto adoption. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | tinyint | NO | - | CODE-BACKED | Unique identifier for the eligibility tier. Values: 0=BlockedFromAccess, 1=ReadOnly, 2=AllOperations, 3=AllOperationsForExistingUsersOnly. Used by application logic to gate crypto operations per customer. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Descriptive label for the eligibility tier. Used in back-office tools, compliance dashboards, and customer support interfaces. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Eligibility.CustomerValues | NewValue | FK | The new eligibility tier assigned after a change event |
| Eligibility.CustomerValues | OldValue | FK | The previous eligibility tier before a change event |
| Eligibility.StatusMap | GroupValue | FK | Group-level eligibility status in the resolution matrix |
| Eligibility.StatusMap | CustomerValue | FK | Customer-level eligibility status in the resolution matrix |
| Eligibility.StatusMap | Status | FK | Resolved eligibility status output |
| Eligibility.AllowedUpdateStatusMap | AllowedUpdateCustomerValue | FK | Permitted target status for customer-level updates |

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
| PK_EligibilityStatuses | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

None beyond the primary key.

---

## 8. Sample Queries

### 8.1 List all eligibility statuses
```sql
SELECT Id, Name FROM Dictionary.EligibilityStatuses WITH (NOLOCK) ORDER BY Id
```

### 8.2 Determine access level for display
```sql
SELECT Id, Name,
  CASE WHEN Id >= 2 THEN 'Full Access' WHEN Id = 1 THEN 'View Only' ELSE 'Blocked' END AS AccessLevel
FROM Dictionary.EligibilityStatuses WITH (NOLOCK)
ORDER BY Id
```

### 8.3 Resolve eligibility status by ID
```sql
SELECT Name FROM Dictionary.EligibilityStatuses WITH (NOLOCK) WHERE Id = 3
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 3.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.EligibilityStatuses | Type: Table | Source: WalletDB/Dictionary/Tables/Dictionary.EligibilityStatuses.sql*
