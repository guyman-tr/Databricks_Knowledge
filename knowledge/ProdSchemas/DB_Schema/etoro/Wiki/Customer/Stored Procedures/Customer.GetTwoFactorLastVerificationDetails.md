# Customer.GetTwoFactorLastVerificationDetails

> Returns the most recent two-factor authentication (2FA) verification record for a customer by GCID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid; returns TOP 1 by VerificationDate DESC |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetTwoFactorLastVerificationDetails retrieves the last two-factor authentication event for a customer. It is used to check whether a customer recently completed a 2FA challenge, how many tries it took, and what the verification reference was.

Typical use cases include:
- Security audit: when did the customer last pass 2FA?
- Support: diagnosing 2FA failures (high VerificationTries count indicates the customer struggled)
- Login flow: confirming recent 2FA success before allowing sensitive operations

**Change history (from DDL comments)**:
- 01/12/2015: Created (FogBugz 32336) - Geri Reshef
- 11/04/2015: Related changes (FogBugz 35846) - Eitan Lipovetsky

---

## 2. Business Logic

### 2.1 Latest 2FA Event Retrieval

**What**: Returns only the single most recent 2FA verification record.

**Columns/Parameters Involved**: `@gcid`, `GCID`, `ReferenceID`, `VerificationDate`, `VerificationTries`

**Rules**:
- `SELECT TOP 1 ... FROM Customer.TwoFactorVerificationDetails WHERE GCID=@gcid ORDER BY VerificationDate DESC`
- Returns 0 rows if the customer has never completed a 2FA challenge
- Returns exactly 1 row if any 2FA records exist
- VerificationDate ordering ensures the true latest event is returned (not the highest ID)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | INT | NO | - | CODE-BACKED | Input: Group Customer ID of the customer to query. |
| 2 | GCID | int (output) | NO | - | CODE-BACKED | Group Customer ID (echoed from the table row). |
| 3 | ReferenceID | varchar/int (output) | YES | - | CODE-BACKED | Reference identifier for this 2FA challenge (e.g., session ID, transaction reference, or phone number reference used for the OTP). |
| 4 | VerificationDate | datetime (output) | NO | - | CODE-BACKED | Date and time when the 2FA verification occurred. Used for ORDER BY to select the most recent record. |
| 5 | VerificationTries | int (output) | YES | - | CODE-BACKED | Number of attempts the customer made before successfully verifying. High values indicate the customer had difficulty completing the challenge. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @gcid | Customer.TwoFactorVerificationDetails | FROM + WHERE GCID | Source of 2FA verification history |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. A related SP `Customer.GetLatestTwoFactorVerificationDetails` exists (documented in an earlier batch) that may serve the same purpose via a different access path.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetTwoFactorLastVerificationDetails (procedure)
`-- Customer.TwoFactorVerificationDetails (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.TwoFactorVerificationDetails | Table | FROM - 2FA event history, filtered by GCID, TOP 1 by VerificationDate DESC |

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

### 8.1 Get last 2FA event for a customer
```sql
EXEC Customer.GetTwoFactorLastVerificationDetails @gcid = 1983785;
```

### 8.2 Direct query equivalent
```sql
SELECT TOP 1 GCID, ReferenceID, VerificationDate, VerificationTries
FROM Customer.TwoFactorVerificationDetails WITH (NOLOCK)
WHERE GCID = 1983785
ORDER BY VerificationDate DESC;
```

### 8.3 Check how long ago the last 2FA was
```sql
SELECT TOP 1 GCID, VerificationDate,
       DATEDIFF(HOUR, VerificationDate, GETUTCDATE()) AS HoursSinceLastVerification
FROM Customer.TwoFactorVerificationDetails WITH (NOLOCK)
WHERE GCID = 1983785
ORDER BY VerificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| FogBugz 32336 | Work item | Original creation of this SP (01/12/2015) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 9/10, Logic: 5/10, Relationships: 5/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Work items: 1 from DDL comments | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.GetTwoFactorLastVerificationDetails | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.GetTwoFactorLastVerificationDetails.sql*
