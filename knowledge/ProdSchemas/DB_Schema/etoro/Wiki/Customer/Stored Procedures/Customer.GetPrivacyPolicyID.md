# Customer.GetPrivacyPolicyID

> Returns the ID of the privacy policy version a customer has accepted, by CID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID; returns PrivacyPolicyID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetPrivacyPolicyID retrieves the current privacy policy acceptance version for a specific customer. PrivacyPolicyID records which version of eToro's privacy policy the customer has agreed to, which is required for GDPR compliance and regulatory reporting.

The procedure is a single-column, single-row lookup against Customer.Customer. Callers use it to check whether a customer needs to be presented with an updated privacy policy (if the current system version is higher than the stored ID) or to report on compliance coverage.

---

## 2. Business Logic

### 2.1 Privacy Policy Version Lookup

**What**: Returns the privacy policy version ID for a customer.

**Columns/Parameters Involved**: `@CID`, `PrivacyPolicyID`

**Rules**:
- SELECT PrivacyPolicyID FROM Customer.Customer WHERE CID = @CID
- If CID not found: empty result set (no error)
- PrivacyPolicyID NULL: customer predates privacy policy tracking (or has not yet accepted)
- Non-NULL: the integer ID of the last accepted privacy policy version from Dictionary.PrivacyPolicy

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Input: Customer ID to look up. |
| 2 | PrivacyPolicyID | int (output) | YES | - | VERIFIED | ID of the privacy policy version accepted by the customer. FK to Dictionary.PrivacyPolicy. NULL for customers who predate this field or have not yet accepted. Inherited from Customer.Customer.PrivacyPolicyID: "Privacy policy version accepted by the customer." |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID / PrivacyPolicyID | Customer.Customer | FROM + WHERE filter | Source of PrivacyPolicyID for the given CID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetPrivacyPolicyID (procedure)
└── Customer.Customer (view)
      ├── Customer.CustomerStatic (table)
      └── Customer.CustomerMoney (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | FROM + WHERE CID = @CID - source of PrivacyPolicyID |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get privacy policy version for a customer
```sql
EXEC Customer.GetPrivacyPolicyID @CID = 12345;
```

### 8.2 Direct query equivalent
```sql
SELECT PrivacyPolicyID
FROM Customer.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.3 Find customers who have not accepted the latest privacy policy
```sql
DECLARE @LatestPolicyID INT;
SELECT @LatestPolicyID = MAX(PrivacyPolicyID) FROM Dictionary.PrivacyPolicy WITH (NOLOCK);

SELECT CID, GCID, PrivacyPolicyID
FROM Customer.Customer WITH (NOLOCK)
WHERE IsReal = 1
  AND PlayerStatusID = 1
  AND (PrivacyPolicyID IS NULL OR PrivacyPolicyID < @LatestPolicyID)
ORDER BY CID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetPrivacyPolicyID | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetPrivacyPolicyID.sql*
