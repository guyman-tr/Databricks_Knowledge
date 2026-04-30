# Customer.SetPrivacyPolicyID

> Updates a customer's data-sharing privacy policy choice and associated opt-out reason on Customer.Customer, with defaulting logic for callers who do not supply an explicit reason.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer to update; @PrivacyPolicyID - privacy choice |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SetPrivacyPolicyID records a customer's data privacy consent decision. eToro presents customers with a choice of whether to allow their trading data and profile to be shared (PrivacyPolicyID=1, "Share") or not (PrivacyPolicyID=2, "Don't Share"). This procedure is the write-path for that choice, updating both the privacy decision (PrivacyPolicyID) and the reason for opting out (OptOutReasonID) on the customer's record in Customer.Customer.

The procedure exists to enforce business rules about the OptOutReasonID default: when a customer opts out (PrivacyPolicyID=2) without specifying a reason, the system defaults the reason to 1. When a customer opts in (PrivacyPolicyID=1) without a reason, the reason is cleared to 0. This prevents invalid combinations (e.g., a "share" customer having a non-zero opt-out reason).

Data flow: called from the customer privacy settings UI or Terms & Conditions acceptance flows when the customer makes a consent decision. Added by developer Yitzchak Wahnon (2017-07-23) when OptOutReasonID was introduced to track WHY a customer chose not to share.

---

## 2. Business Logic

### 2.1 Privacy Policy + Opt-Out Reason Defaulting

**What**: Ensures OptOutReasonID is always set to a meaningful value regardless of whether the caller provides one, using PrivacyPolicyID to determine the correct default.

**Columns/Parameters Involved**: `@PrivacyPolicyID`, `@OptOutReasonID`

**Rules**:
- WHEN @PrivacyPolicyID = 2 ("Don't Share") AND @OptOutReasonID IS NULL -> OptOutReasonID = 1 (default opt-out reason)
- WHEN @PrivacyPolicyID = 1 ("Share") AND @OptOutReasonID IS NULL -> OptOutReasonID = 0 (no reason - customer is sharing)
- ELSE -> OptOutReasonID = @PrivacyPolicyID (NOTE: this ELSE branch triggers when @OptOutReasonID IS NOT NULL; the code sets OptOutReasonID = @PrivacyPolicyID rather than @OptOutReasonID, which appears to be a code defect. Callers providing an explicit @OptOutReasonID should be aware that the ELSE branch does not use their value.)
- Both PrivacyPolicyID and OptOutReasonID are updated in a single UPDATE statement

**Diagram**:
```
@PrivacyPolicyID = 2 AND @OptOutReasonID IS NULL?
  YES -> OptOutReasonID = 1 (default: "unspecified opt-out")

@PrivacyPolicyID = 1 AND @OptOutReasonID IS NULL?
  YES -> OptOutReasonID = 0 (no reason needed for sharing)

ELSE (when @OptOutReasonID IS NOT NULL):
  -> OptOutReasonID = @PrivacyPolicyID (NOTE: likely a code defect;
     appears to ignore the explicitly passed @OptOutReasonID)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer identifier. The customer whose PrivacyPolicyID and OptOutReasonID will be updated in Customer.Customer. |
| 2 | @PrivacyPolicyID | int | NO | - | CODE-BACKED | Privacy consent choice: 1 = "Share" (opt-in to data sharing), 2 = "Don't Share" (opt-out). Drives both the PrivacyPolicyID column update and the default OptOutReasonID logic. |
| 3 | @OptOutReasonID | smallint | YES | NULL | CODE-BACKED | Optional opt-out reason code. When NULL and @PrivacyPolicyID=2, defaults to 1. When NULL and @PrivacyPolicyID=1, defaults to 0. When explicitly provided, the ELSE branch of the CASE uses @PrivacyPolicyID instead of this parameter (apparent code defect). Added 2017-07-23. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | Modifier | Updates PrivacyPolicyID and OptOutReasonID columns |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external caller) | - | - | No intra-DB callers found; called from account settings UI / TnC service |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetPrivacyPolicyID (procedure)
└── Customer.Customer (view - UPDATE target)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | UPDATE target for PrivacyPolicyID and OptOutReasonID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No intra-DB callers found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OptOutReasonID CASE | Business rule | Defaults OptOutReasonID based on PrivacyPolicyID value when caller passes NULL; see Business Logic 2.1 for full logic |

---

## 8. Sample Queries

### 8.1 Set customer to "Don't Share" with default opt-out reason
```sql
EXEC Customer.SetPrivacyPolicyID @CID = 12345, @PrivacyPolicyID = 2;
-- Results in: PrivacyPolicyID = 2, OptOutReasonID = 1
```

### 8.2 Set customer to "Share" (opt-in)
```sql
EXEC Customer.SetPrivacyPolicyID @CID = 12345, @PrivacyPolicyID = 1;
-- Results in: PrivacyPolicyID = 1, OptOutReasonID = 0
```

### 8.3 Check current privacy settings for a customer
```sql
SELECT CID, PrivacyPolicyID, OptOutReasonID
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetPrivacyPolicyID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetPrivacyPolicyID.sql*
