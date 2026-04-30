# Wallet.GetMustBouncebackTransactions

> Retrieves received crypto transactions for a customer that must be bounced back (returned to sender) due to travel rule compliance failure (TravelRuleStatusId=5, MustCancel).

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns received transactions requiring bounceback with amounts and travel rule context |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure identifies incoming crypto transactions that failed travel rule compliance and must be returned to the sender ("bounced back"). Under regulations like the FATF Travel Rule, crypto transfers above certain thresholds require originator/beneficiary identification. When this verification fails or is rejected (TravelRuleStatusId=5), the received funds must be sent back to the originating address.

This is a compliance-critical procedure. Failing to bounceback non-compliant transactions could result in regulatory violations. The procedure provides the execution service with all details needed to construct the return transaction: original sender address, received amount, crypto type, and the fiat equivalent for reporting.

The procedure uses four CTEs to efficiently gather the data: (1) anchor customer's receive requests, (2) get latest travel rule status per request, (3) aggregate received amounts per request correlation, (4) pick one representative received transaction per request. Only transactions with TravelRuleStatusId=5 (MustCancel) are returned, limited by @Limit.

---

## 2. Business Logic

### 2.1 Travel Rule Compliance Failure Detection

**What**: Identifies received transactions where travel rule verification resulted in MustCancel status.

**Columns/Parameters Involved**: `TravelRuleStatusId`, `RequestTypeId`, `@Gcid`

**Rules**:
- Only Receive requests (RequestTypeId=8) for the specified customer
- Latest travel rule status per request is determined via ROW_NUMBER (ORDER BY trts.Id DESC)
- TravelRuleStatusId=5 = MustCancel (compliance failure requiring bounceback)
- All qualifying transactions are returned with Status='MustCancel' hardcoded label
- Results limited by @Limit (default 10) and ordered by Occurred DESC (most recent first)

**Diagram**:
```
Requests (Gcid=@Gcid, RequestTypeId=8 Receive)
    |
    +-- TransactionTravelRuleInformation -> latest TravelRuleStatuses
    |     -> Filter: TravelRuleStatusId = 5 (MustCancel)
    |
    +-- ReceivedTransactions (aggregate amounts per CorrelationId)
    +-- ReceivedTransactions (representative row per CorrelationId)
    |
    v
TOP @Limit: Transaction details + TotalAmount + FiatAmount + 'MustCancel' status
```

### 2.2 Amount Aggregation

**What**: Sums all received transaction amounts per request correlation, as a single request may produce multiple received transactions.

**Columns/Parameters Involved**: `ReceiveRequestCorrelationId`, `Amount`

**Rules**:
- SUM(rt.Amount) aggregated by ReceiveRequestCorrelationId gives TotalAmount
- A representative row (latest by Occurred, then Id DESC) provides transaction details (addresses, crypto, etc.)
- FiatAmount and FiatSymbol come from the travel rule information, representing the fiat-equivalent value at time of receipt

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | BIGINT | NO | - | CODE-BACKED | Global Customer ID. Identifies the customer whose bounceback-eligible transactions are retrieved. |
| 2 | @Limit | INT | YES | 10 | CODE-BACKED | Maximum number of bounceback transactions to return. Default 10. Controls batch size for the bounceback processing service. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | Id | BIGINT | NO | - | CODE-BACKED | ReceivedTransactions record ID. Identifies the representative received transaction for this request. |
| 4 | Gcid | BIGINT | NO | - | CODE-BACKED | Customer's Global ID (echoed from @Gcid parameter). |
| 5 | Occurred | DATETIME2 | NO | - | CODE-BACKED | Timestamp when the received transaction was recorded. Used for ordering (most recent first). |
| 6 | WalletId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | The receiving wallet ID. Identifies which customer wallet received the funds that must be returned. |
| 7 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency of the received transaction. FK to Wallet.CryptoTypes. Determines which blockchain the bounceback must be sent on. |
| 8 | FromAddress | NVARCHAR | YES | - | CODE-BACKED | Sender's blockchain address (aliased from SenderAddress). The bounceback transaction sends funds back to this address. |
| 9 | ToAddress | NVARCHAR | YES | - | CODE-BACKED | Receiver's blockchain address (aliased from ReceiverAddress). The eToro wallet that received the non-compliant funds. |
| 10 | Amount | DECIMAL | NO | - | CODE-BACKED | Total received crypto amount across all received transactions for this request correlation. This is the amount to return. |
| 11 | FiatAmount | DECIMAL | YES | - | CODE-BACKED | Fiat-equivalent value of the transaction at time of receipt. From TransactionTravelRuleInformation. Used for compliance reporting. |
| 12 | RequestCorrelationId | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Correlation ID linking this travel rule information to the original receive request. From TransactionTravelRuleInformation. |
| 13 | FiatSymbol | VARCHAR | YES | - | CODE-BACKED | Fiat currency symbol for the FiatAmount (e.g., USD, EUR). From TransactionTravelRuleInformation. |
| 14 | ProviderTransactionId | NVARCHAR | YES | - | CODE-BACKED | The custody provider's transaction identifier. Used to reference the original transaction in the provider system. |
| 15 | Status | VARCHAR | NO | - | CODE-BACKED | Hardcoded value 'MustCancel'. Indicates this transaction requires a bounceback. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid, RequestTypeId | Wallet.Requests | CTE | Anchors customer's receive requests |
| RequestId | Wallet.TransactionTravelRuleInformation | JOIN | Travel rule details per request |
| TransactionTravelRuleInformationId | Wallet.TransactionTravelRuleStatuses | JOIN | Latest travel rule status per request |
| ReceiveRequestCorrelationId | Wallet.ReceivedTransactions | JOIN | Received transaction amounts and details |

### 5.2 Referenced By (other objects point to this)

GRANT EXECUTE to EligibilityUser indicates this is called by the eligibility/compliance service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetMustBouncebackTransactions (procedure)
+-- Wallet.Requests (table)
+-- Wallet.TransactionTravelRuleInformation (table)
+-- Wallet.TransactionTravelRuleStatuses (table)
+-- Wallet.ReceivedTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | CTE - anchor receive requests for customer |
| Wallet.TransactionTravelRuleInformation | Table | JOIN - travel rule details |
| Wallet.TransactionTravelRuleStatuses | Table | JOIN - travel rule status (filter StatusId=5) |
| Wallet.ReceivedTransactions | Table | JOIN - transaction amounts and details |

### 6.2 Objects That Depend On This

No SQL dependents. Called by EligibilityUser service.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get bounceback transactions for a customer
```sql
EXEC Wallet.GetMustBouncebackTransactions @Gcid = 12345, @Limit = 5;
```

### 8.2 Count transactions per travel rule status for a customer
```sql
SELECT trts.TravelRuleStatusId, COUNT(*) AS TxCount
FROM Wallet.Requests r WITH (NOLOCK)
JOIN Wallet.TransactionTravelRuleInformation tri WITH (NOLOCK) ON tri.RequestId = r.Id
JOIN Wallet.TransactionTravelRuleStatuses trts WITH (NOLOCK) ON trts.TransactionTravelRuleInformationId = tri.Id
WHERE r.Gcid = 12345 AND r.RequestTypeId = 8
GROUP BY trts.TravelRuleStatusId;
```

### 8.3 Check all MustCancel transactions system-wide
```sql
SELECT TOP 20 r.Gcid, tri.FiatAmount, tri.FiatSymbol, trts.TravelRuleStatusId
FROM Wallet.Requests r WITH (NOLOCK)
JOIN Wallet.TransactionTravelRuleInformation tri WITH (NOLOCK) ON tri.RequestId = r.Id
JOIN Wallet.TransactionTravelRuleStatuses trts WITH (NOLOCK) ON trts.TransactionTravelRuleInformationId = tri.Id
WHERE r.RequestTypeId = 8 AND trts.TravelRuleStatusId = 5
ORDER BY tri.Id DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetMustBouncebackTransactions | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetMustBouncebackTransactions.sql*
