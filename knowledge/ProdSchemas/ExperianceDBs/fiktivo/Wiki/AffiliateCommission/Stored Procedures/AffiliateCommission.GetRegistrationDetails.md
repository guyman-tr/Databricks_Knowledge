# AffiliateCommission.GetRegistrationDetails

> Retrieves the registration tracking date for a customer, used for anti-fraud timing validation in the commission processing pipeline.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TrackingDate from Registration |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetRegistrationDetails retrieves the TrackingDate from the Registration table for a specific customer. The TrackingDate records when the registration was first tracked by the commission system. This timestamp is used in anti-fraud validation to detect suspicious timing patterns, such as a customer registering and making a first deposit suspiciously quickly, which may indicate fraudulent affiliate activity.

This procedure was specifically created (September 2022) to support fraud prevention. The DDL comment explicitly states "fetch the TrackingDate of Registration to avoid fraud." The commission engine compares the TrackingDate against credit/deposit dates to validate the timing of affiliate-attributed actions.

---

## 2. Business Logic

### 2.1 Registration Timing Lookup

**What**: Simple lookup of when a customer's registration was tracked.

**Columns/Parameters Involved**: `@CID`, `TrackingDate`

**Rules**:
- Looks up Registration by CID
- Returns TrackingDate (when the registration entered the commission tracking system)
- Used by the commission engine to validate that deposits/trades occurred at a reasonable time after registration
- Returns empty result set if CID not found (customer not registered in commission system)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | bigint (IN) | NO | - | CODE-BACKED | Customer ID to look up. Matched against Registration.CID. |

**Return columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | TrackingDate | datetime | - | - | CODE-BACKED | When the customer's registration was first tracked by the commission system. Used for anti-fraud timing validation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | AffiliateCommission.Registration | READ (SELECT) | Retrieves TrackingDate by CID |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission engine for fraud timing validation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.GetRegistrationDetails (procedure)
+-- AffiliateCommission.Registration (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.Registration | Table | SELECT TrackingDate WHERE CID = @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission engine) | External | Anti-fraud timing validation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get registration tracking date for customer 12345
```sql
EXEC [AffiliateCommission].[GetRegistrationDetails] @CID = 12345
```

### 8.2 Find recent registrations with their tracking dates
```sql
SELECT CID, TrackingDate
FROM [AffiliateCommission].[Registration] WITH (NOLOCK)
ORDER BY TrackingDate DESC
```

### 8.3 Find registrations with suspicious timing (registered and deposited within 1 minute)
```sql
SELECT r.CID, r.TrackingDate, MIN(c.CreditDate) AS FirstDepositDate,
       DATEDIFF(SECOND, r.TrackingDate, MIN(c.CreditDate)) AS SecondsToFirstDeposit
FROM [AffiliateCommission].[Registration] AS r WITH (NOLOCK)
JOIN [AffiliateCommission].[Credit] AS c WITH (NOLOCK) ON r.CID = c.CID
WHERE c.IsFirstDeposit = 1
GROUP BY r.CID, r.TrackingDate
HAVING DATEDIFF(SECOND, r.TrackingDate, MIN(c.CreditDate)) < 60
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- Created to fetch TrackingDate for fraud avoidance (2022-09-28, Gil)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.GetRegistrationDetails | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.GetRegistrationDetails.sql*
