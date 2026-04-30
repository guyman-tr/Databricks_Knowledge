# Wallet.InsertTransactionTravelRuleDoneStatusBySenderAddress

> Bulk-inserts 'Done' travel rule status for all eligible receive transactions from a specific sender address for a customer, returning the affected request metadata for downstream notification processing.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Bulk INSERT into TransactionTravelRuleStatuses by Gcid + FromAddress |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the most complex travel rule procedure. When a sender address is verified as compliant (e.g., confirmed via a travel rule provider), ALL pending receive transactions from that address for a customer should be marked as 'Done'. This procedure finds all eligible TransactionTravelRuleInformation records (RequestTypeId=8 ReceiveTransaction, matching CounterpartyAddress, no existing Done/Failed status), atomically inserts Done status for all of them within a transaction, and returns the affected CorrelationIds and RequestIds for the back-office API to trigger downstream notifications.

The procedure uses OUTPUT clause to capture inserted IDs, temp table staging for eligible records, and table variables for return data - a sophisticated multi-step transactional pattern.

---

## 2. Business Logic

### 2.1 Bulk Eligible Transaction Discovery

**What**: Finds all receive transactions from a sender address that need travel rule completion.

**Columns/Parameters Involved**: `@Gcid`, `@FromAddress`, `TransactionTravelRuleInformation.CounterpartyAddress`

**Rules**:
- Requests WHERE Gcid = @Gcid AND RequestTypeId = 8 (ReceiveTransaction)
- JOIN to TransactionTravelRuleInformation WHERE CounterpartyAddress = @FromAddress
- NOT EXISTS TransactionTravelRuleStatuses WHERE TravelRuleStatusId IN (1=Done, 2=Failed)
- Only transactions without a terminal travel rule status are affected

### 2.2 Transactional Bulk Status Insert with OUTPUT

**What**: Atomically inserts Done status for all eligible records and captures results.

**Rules**:
- TravelRuleStatusId = 1 (Done)
- OUTPUT INSERTED.TransactionTravelRuleInformationId INTO @InsertedInformation
- JOINs back to staging table to build return result with CorrelationId, RequestId, CryptoId
- Transaction: all inserts succeed or all roll back
- Returns affected requests for notification processing

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Customer whose receive transactions to complete. |
| 2 | @FromAddress | nvarchar(512) | NO | - | VERIFIED | Sender address that has been verified. Matched against CounterpartyAddress. |
| 3 | @DetailsJson | varchar(max) | YES | - | CODE-BACKED | JSON details for the status records (e.g., verification source). |
| 4 | CorrelationId (output) | uniqueidentifier | NO | - | CODE-BACKED | Correlation IDs of affected requests. |
| 5 | RequestId (output) | bigint | NO | - | CODE-BACKED | Request IDs of affected requests. |
| 6 | CryptoId (output) | int | NO | - | CODE-BACKED | Crypto IDs of affected requests. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid + RequestTypeId=8 | Wallet.Requests | JOIN | Receive transaction requests |
| RequestCorrelationId | Wallet.TransactionTravelRuleInformation | JOIN | Travel rule info by address |
| - | Wallet.TransactionTravelRuleStatuses | NOT EXISTS + INSERT | Eligibility check + status insert |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Bulk travel rule completion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertTransactionTravelRuleDoneStatusBySenderAddress (procedure)
+-- Wallet.Requests (table)
+-- Wallet.TransactionTravelRuleInformation (table)
+-- Wallet.TransactionTravelRuleStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | Receive transaction lookup |
| Wallet.TransactionTravelRuleInformation | Table | Address matching |
| Wallet.TransactionTravelRuleStatuses | Table | Eligibility check + INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses temp table + table variables + OUTPUT clause.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Complete travel rule for a sender address
```sql
EXEC Wallet.InsertTransactionTravelRuleDoneStatusBySenderAddress @Gcid=30351701, @FromAddress='1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa', @DetailsJson='{"source":"manual_verification"}';
```

### 8.2 Check pending travel rule transactions for an address
```sql
SELECT ttri.Id, r.CorrelationId, ttri.CounterpartyAddress
FROM Wallet.Requests r WITH (NOLOCK)
    JOIN Wallet.TransactionTravelRuleInformation ttri WITH (NOLOCK) ON r.CorrelationId = ttri.RequestCorrelationId
WHERE r.Gcid = 30351701 AND r.RequestTypeId = 8 AND ttri.CounterpartyAddress = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'
    AND NOT EXISTS (SELECT 1 FROM Wallet.TransactionTravelRuleStatuses ttrs WITH (NOLOCK) WHERE ttrs.TransactionTravelRuleInformationId = ttri.Id AND ttrs.TravelRuleStatusId IN (1,2));
```

### 8.3 Check travel rule status history
```sql
SELECT ttrs.* FROM Wallet.TransactionTravelRuleStatuses ttrs WITH (NOLOCK)
    JOIN Wallet.TransactionTravelRuleInformation ttri WITH (NOLOCK) ON ttri.Id = ttrs.TransactionTravelRuleInformationId
WHERE ttri.CounterpartyAddress = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa' ORDER BY ttrs.Occurred;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertTransactionTravelRuleDoneStatusBySenderAddress | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertTransactionTravelRuleDoneStatusBySenderAddress.sql*
