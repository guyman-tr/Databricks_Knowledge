# Billing.GetPayoutProcessMessageByID

> Returns the full payout request message record from Billing.PayoutRequestMessages by RequestID, providing the payout service and SecurePay with the execution state and parameters for a specific withdrawal payout request.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single row from Billing.PayoutRequestMessages for the given @RequestID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetPayoutProcessMessageByID` is the read endpoint for the new payout service's message queue table (`Billing.PayoutRequestMessages`). It retrieves the full payout request record - including amount, currency, payment identifiers, processing parameters (ProtocolParameters, DepotParameters), step progress (LastSuccessStep), and current status - for a given RequestID.

The procedure exists to give the payout service (PayoutUser) and SecurePay (SQL_SecurePay) a clean read interface to the PayoutRequestMessages table. Rather than reading the table directly, the service calls this procedure to retrieve its execution context for a specific payout request. Created under PAYUS-1560.

Data flows: the payout service inserts a row into Billing.PayoutRequestMessages when it picks up a withdrawal for processing. During and after processing, it reads back the record via this procedure to check progress, resume from the LastSuccessStep after failures, or verify the final StatusID.

---

## 2. Business Logic

### 2.1 Single-Row Lookup by RequestID

**What**: Simple primary key lookup - returns exactly one row or zero rows.

**Rules**:
- WHERE [RequestID] = @RequestID - matches the PK/clustered index
- No status filter - returns the record regardless of its StatusID
- Returns all 18 columns from PayoutRequestMessages

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestID | INTEGER | NO | - | CODE-BACKED | PK of `Billing.PayoutRequestMessages`. Uniquely identifies the payout request message to retrieve. |

**Return columns (all from Billing.PayoutRequestMessages):**

| # | Column | Confidence | Description |
|---|--------|------------|-------------|
| 2 | RequestID | CODE-BACKED | PK - the payout request message identifier. |
| 3 | PayoutID | CODE-BACKED | The payout batch/process ID linking this message to the parent payout operation. FK to Billing.PayoutProcess. |
| 4 | WithdrawID | CODE-BACKED | Parent withdrawal request ID. FK to Billing.Withdraw. |
| 5 | FundingID | CODE-BACKED | Payment instrument ID. FK to Billing.Funding. |
| 6 | Amount | CODE-BACKED | Payout amount (in processing currency units). |
| 7 | Currency | CODE-BACKED | Currency abbreviation string (e.g., "USD"). Denormalized for the payout service. |
| 8 | CurrencyID | CODE-BACKED | Currency ID. FK to Dictionary.Currency. |
| 9 | FundingTypeID | CODE-BACKED | Payment method type. FK to Dictionary.FundingType. |
| 10 | MassCorrelationID | CODE-BACKED | Batch correlation ID for grouping multiple payout requests in a single mass payout operation. |
| 11 | CorrelationID | CODE-BACKED | Individual payout correlation ID for end-to-end request tracing. |
| 12 | ManagerID | CODE-BACKED | BackOffice manager who authorized or processed this payout. |
| 13 | Created | CODE-BACKED | Timestamp when this payout request message was created. |
| 14 | Modified | CODE-BACKED | Timestamp of last status update on this message. |
| 15 | PayoutTypeID | CODE-BACKED | Payout type classification. FK to Dictionary.PayoutType. |
| 16 | StatusID | CODE-BACKED | Execution status: 0=Pending, 1=Processing, 2=Failed, 3=Completed. Controls whether the payout service picks this up. |
| 17 | ProtocolParameters | CODE-BACKED | JSON/XML blob containing payment provider protocol-specific parameters needed to submit the payout. |
| 18 | DepotParameters | CODE-BACKED | JSON/XML blob containing depot-specific routing parameters for the payout. |
| 19 | HandleCount | CODE-BACKED | Number of times this message has been attempted. Used for retry limiting. |
| 20 | LastSuccessStep | CODE-BACKED | Last successfully completed processing step. Enables the payout service to resume from a checkpoint after failure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @RequestID | Billing.PayoutRequestMessages.RequestID | Lookup | PK lookup - retrieves the payout request message |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL_SecurePay | GRANT EXECUTE | Permission | SecurePay service reads payout messages for processing |
| PayoutUser | GRANT EXECUTE | Permission | Payout service reads messages for execution and status checking |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetPayoutProcessMessageByID (procedure)
└── Billing.PayoutRequestMessages (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.PayoutRequestMessages | Table | Single-row PK lookup; returns all 18 columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL_SecurePay | DB Security Principal | EXECUTE permission - payout message reading |
| PayoutUser | DB Security Principal | EXECUTE permission - payout service execution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

**Notable**: Uses fully-qualified three-part name `[etoro].[Billing].[PayoutRequestMessages]` in the FROM clause (database.schema.table) - unusual practice that ties this procedure to the `etoro` database name. Created under PAYUS-1560.

---

## 8. Sample Queries

### 8.1 Get a specific payout request message
```sql
EXEC [Billing].[GetPayoutProcessMessageByID] @RequestID = 100001
```

### 8.2 Find recent payout request messages to use as test input
```sql
SELECT TOP 10 RequestID, WithdrawID, StatusID, HandleCount, LastSuccessStep, Created
FROM Billing.PayoutRequestMessages WITH (NOLOCK)
ORDER BY Created DESC
```

### 8.3 Check payout message status distribution
```sql
SELECT StatusID, COUNT(*) AS MessageCount, MAX(Created) AS MostRecent
FROM Billing.PayoutRequestMessages WITH (NOLOCK)
GROUP BY StatusID
ORDER BY StatusID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| PAYUS-1560 (referenced in code comment) | Jira | Initial creation of this procedure for the new payout service (PayoutUser/SQL_SecurePay integration) |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.6/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 19 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira (PAYUS-1560 in DDL comment) | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetPayoutProcessMessageByID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetPayoutProcessMessageByID.sql*
