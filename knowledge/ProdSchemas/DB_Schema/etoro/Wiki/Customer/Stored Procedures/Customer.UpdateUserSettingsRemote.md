# Customer.UpdateUserSettingsRemote

> Updates a customer's privacy policy acceptance and GDPR opt-out reason on the Customer view (CustomerStatic base), with conditional opt-out logic: resetting opt-out when the default/null policy is set, recording the reason when a specific policy is assigned.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates Customer.Customer (CustomerStatic) by GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateUserSettingsRemote handles the privacy policy and GDPR opt-out portion of customer settings. It updates two tightly coupled fields in Customer.Customer (which writes through to Customer.CustomerStatic via the view): PrivacyPolicyID (the version of the privacy policy the customer has accepted) and OptOutReasonID (the reason why they opted out of marketing or data processing).

This procedure is not typically called directly - it is invoked by Customer.UpdateUserSettings, which wraps both the privacy settings (this procedure) and the social display settings (dbo.General_UpdateSettings in UserApiDB). The "Remote" suffix indicates this is the etoro-DB half of a split operation - the social settings live in UserApiDB.

The conditional logic between PrivacyPolicyID and OptOutReasonID encodes a GDPR workflow rule: when the policy is the null/default state (value 1 or NULL), the opt-out reason is cleared (0 = no active opt-out); when a specific non-default policy is assigned, the opt-out reason is either the one provided by the caller or 1 as a safe default.

Data flows: called by Customer.UpdateUserSettings (which first resolves GCID->CID via CustomerStatic), then performs the actual UPDATE here. The GetAggregatedInfo API endpoint exposes both privacyPolicyId and optOutReasonId as part of the userSettings response block.

---

## 2. Business Logic

### 2.1 Conditional OptOutReasonID Derivation

**What**: OptOutReasonID is not set independently - it is conditionally derived from PrivacyPolicyID in a single UPDATE statement, coupling privacy policy assignment with opt-out reason tracking.

**Columns/Parameters Involved**: `@privacyPolicyId`, `@OptOutReasonID`, `PrivacyPolicyID`, `OptOutReasonID`

**Rules**:
- Condition: `ISNULL(@privacyPolicyId, 1) = 1`
  - TRUE when @privacyPolicyId IS NULL OR @privacyPolicyId = 1 (the null/default policy) -> OptOutReasonID = 0 (reset - no active opt-out)
  - FALSE when @privacyPolicyId is any other specific value -> OptOutReasonID = ISNULL(@OptOutReasonID, 1) (use provided reason, or default to reason 1)
- Neither PrivacyPolicyID nor OptOutReasonID can be updated independently through this procedure - they are always set together
- Added 2017-07-23 by Yitzchak Wahnon to track opt-out reasons alongside policy changes

**Diagram**:
```
ISNULL(@privacyPolicyId, 1) = 1?
          |
     YES  |  NO
(NULL or 1)  (specific policy id, e.g. 2, 3, ...)
     |         |
OptOutReasonID = 0    OptOutReasonID = ISNULL(@OptOutReasonID, 1)
(no opt-out,           (caller's reason, or reason 1 as default)
 policy reset)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | INT | NO | - | VERIFIED | Group Customer ID identifying which customer's privacy settings to update. Used in WHERE clause for the Customer.Customer update. Matches CustomerStatic.GCID (indexed via IDX_Customer_Customer_GCID). |
| 2 | @privacyPolicyId | INT | YES | NULL | VERIFIED | The privacy policy version the customer is accepting. NULL or 1 = default/no specific policy - triggers reset of opt-out (OptOutReasonID = 0). Any other value = a specific GDPR/marketing policy being assigned - triggers opt-out reason tracking. FK to Dictionary.PrivacyPolicy in CustomerStatic. Per GetAggregatedInfo API docs (2025): this is the `privacyPolicyId` in the userSettings response. |
| 3 | @OptOutReasonID | SMALLINT | YES | NULL | VERIFIED | The reason why the customer is opting out (used only when @privacyPolicyId is a specific non-default value). NULL defaults to reason 1 via ISNULL. When @privacyPolicyId is NULL or 1 this parameter is ignored. Per GetAggregatedInfo API docs (2025): this is the `optOutReasonId` in the userSettings response. Added 2017-07-23 by Yitzchak Wahnon. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.Customer (view) | MODIFIER | Updates PrivacyPolicyID and OptOutReasonID via the Customer view (which writes to CustomerStatic) |
| @privacyPolicyId | Dictionary.PrivacyPolicy | Lookup (via CustomerStatic FK) | FK for the privacy policy version being assigned |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.UpdateUserSettings | @gcid, @privacyPolicyId, @OptOutReasonID | Caller | Orchestrates the full settings update - calls this for privacy/opt-out, then dbo.General_UpdateSettings for social display settings |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateUserSettingsRemote (procedure)
└── Customer.Customer (view)
      ├── Customer.CustomerStatic (table)
      └── Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | UPDATE target for PrivacyPolicyID and OptOutReasonID (writes through to CustomerStatic) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.UpdateUserSettings | Stored Procedure | Caller - invokes this for the privacy policy portion of the combined settings update |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Accept a specific privacy policy (triggers opt-out tracking)

```sql
EXEC Customer.UpdateUserSettingsRemote
    @gcid = 12345678,
    @privacyPolicyId = 3,
    @OptOutReasonID = 2;
-- Sets PrivacyPolicyID=3, OptOutReasonID=2 on CustomerStatic for GCID=12345678
```

### 8.2 Reset privacy policy to default (clears opt-out)

```sql
EXEC Customer.UpdateUserSettingsRemote
    @gcid = 12345678,
    @privacyPolicyId = NULL,
    @OptOutReasonID = NULL;
-- Sets PrivacyPolicyID=NULL, OptOutReasonID=0 (ISNULL(NULL,1)=1 -> OptOutReasonID=0)
```

### 8.3 Verify current privacy settings for a customer

```sql
SELECT
    cs.GCID,
    cs.CID,
    cs.PrivacyPolicyID,
    cs.OptOutReasonID
FROM Customer.Customer cs WITH (NOLOCK)
WHERE cs.GCID = 12345678;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [GetAggregatedInfo API Documentation](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/13140426755/GetAggregatedInfo+API+Documentation) | Confluence (CR) | userSettings response block confirms privacyPolicyId and optOutReasonId are the two fields managed by this procedure; confirms these are part of the User-API/UserApiDB settings surface |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.UpdateUserSettingsRemote | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.UpdateUserSettingsRemote.sql*
