# Wallet.GetTransactionTravelRuleInformationIdByCorrelationId

> Resolves the travel rule information record ID for a transaction by looking up its request correlation ID in the TransactionTravelRuleInformation table.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar TransactionTravelRuleInformationId by RequestCorrelationId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure resolves the travel rule information record associated with a transaction, using the business correlation ID as the lookup key. Travel rule compliance (FATF Recommendation 16) requires that crypto transfers above certain thresholds include originator and beneficiary information. Each compliant transaction has a record in `Wallet.TransactionTravelRuleInformation` that stores this regulatory data.

The back-office API uses this to link a business request (identified by its CorrelationId) to its travel rule record for compliance review and audit. The procedure returns a scalar ID value, or NULL if no travel rule information exists for the given correlation.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct scalar lookup on TransactionTravelRuleInformation.RequestCorrelationId with TRY/CATCH error propagation.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestCorrelationId | uniqueidentifier | NO | - | VERIFIED | Business correlation ID linking to Wallet.Requests.CorrelationId. Used to find the travel rule record for this request. |
| 2 | TransactionTravelRuleInformationId (output) | bigint | YES | - | CODE-BACKED | ID of the matching travel rule information record. NULL if no travel rule data exists for this correlation. FK to Wallet.TransactionTravelRuleInformation.Id. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RequestCorrelationId | Wallet.TransactionTravelRuleInformation.RequestCorrelationId | Lookup | Travel rule record resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Back-office compliance review |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetTransactionTravelRuleInformationIdByCorrelationId (procedure)
+-- Wallet.TransactionTravelRuleInformation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleInformation | Table | Scalar lookup by RequestCorrelationId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Find travel rule info for a request
```sql
EXEC Wallet.GetTransactionTravelRuleInformationIdByCorrelationId
    @RequestCorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.2 Direct query equivalent
```sql
SELECT Id AS TransactionTravelRuleInformationId
FROM Wallet.TransactionTravelRuleInformation WITH (NOLOCK)
WHERE RequestCorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.3 Trace full travel rule data for a request
```sql
DECLARE @TravelRuleId BIGINT;
EXEC Wallet.GetTransactionTravelRuleInformationIdByCorrelationId
    @RequestCorrelationId = 'YOUR-GUID';
-- Use returned ID to query full travel rule details
SELECT * FROM Wallet.TransactionTravelRuleInformation WITH (NOLOCK) WHERE Id = @TravelRuleId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetTransactionTravelRuleInformationIdByCorrelationId | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetTransactionTravelRuleInformationIdByCorrelationId.sql*
