# Wallet.GetTransactionTravelRuleInformationIdByRequestId

> Resolves the travel rule information record ID for a transaction by looking up its internal request ID in the TransactionTravelRuleInformation table.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TransactionTravelRuleInformationId by RequestId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the RequestId-based counterpart to `Wallet.GetTransactionTravelRuleInformationIdByCorrelationId`. While the sibling procedure uses the business-level CorrelationId (GUID), this one uses the internal numeric RequestId from `Wallet.Requests`. Both resolve to the same travel rule information record in `Wallet.TransactionTravelRuleInformation`.

The back-office API uses this when the internal RequestId is available (e.g., from a request status query result) rather than the CorrelationId. The procedure returns the travel rule record ID or an empty result set if no travel rule information exists for the request.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct lookup on TransactionTravelRuleInformation.RequestId with TRY/CATCH error propagation.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestId | bigint | NO | - | VERIFIED | Internal request ID from Wallet.Requests.Id. Used to find the travel rule record for this request. |
| 2 | TransactionTravelRuleInformationId (output) | bigint | YES | - | CODE-BACKED | ID of the matching travel rule information record. Empty result set if none exists. FK to Wallet.TransactionTravelRuleInformation.Id. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RequestId | Wallet.TransactionTravelRuleInformation.RequestId | Lookup | Travel rule record resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Back-office compliance review |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetTransactionTravelRuleInformationIdByRequestId (procedure)
+-- Wallet.TransactionTravelRuleInformation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleInformation | Table | Lookup by RequestId |

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

### 8.1 Find travel rule info by request ID
```sql
EXEC Wallet.GetTransactionTravelRuleInformationIdByRequestId @RequestId = 4990706;
```

### 8.2 Direct query equivalent
```sql
SELECT Id AS TransactionTravelRuleInformationId
FROM Wallet.TransactionTravelRuleInformation WITH (NOLOCK)
WHERE RequestId = 4990706;
```

### 8.3 Compare the two lookup methods
```sql
-- By CorrelationId (sibling SP):
EXEC Wallet.GetTransactionTravelRuleInformationIdByCorrelationId @RequestCorrelationId = 'YOUR-GUID';
-- By RequestId (this SP):
EXEC Wallet.GetTransactionTravelRuleInformationIdByRequestId @RequestId = 4990706;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetTransactionTravelRuleInformationIdByRequestId | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetTransactionTravelRuleInformationIdByRequestId.sql*
