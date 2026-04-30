# Wallet.AddTransactionTravelRuleStatus

> Appends a new status entry to a Travel Rule information record, tracking the compliance workflow progression (e.g., initiated, pending, approved, rejected).

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | New row in Wallet.TransactionTravelRuleStatuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records status transitions in the Travel Rule compliance workflow. After a Travel Rule information record is created (via AddTransactionTravelRuleInformation), the compliance process progresses through multiple states - message sent to counterparty VASP, response received, approved, rejected, etc. Each state change is recorded as a new status entry with optional JSON details.

Without this procedure, the system could not track the Travel Rule compliance lifecycle, making it impossible to determine which transactions are awaiting counterparty response, which have been approved, or which need manual intervention.

The procedure uses TRY/CATCH with THROW for clean error propagation, consistent with the Travel Rule procedure family.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple append-only status INSERT. The DetailsJson parameter captures context-specific information for each status transition (e.g., rejection reason, provider response payload). See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TransactionTravelRuleInformationId | bigint | NO | - | CODE-BACKED | The Travel Rule information record to update. Obtained from Wallet.AddTransactionTravelRuleInformation's return value. |
| 2 | @TravelRuleStatusId | tinyint | NO | - | CODE-BACKED | The new status to assign. References the Travel Rule status lookup in Wallet.TransactionTravelRuleStatuses (e.g., initiated, pending counterparty, approved, rejected, expired). |
| 3 | @DetailsJson | varchar(MAX) | YES | NULL | CODE-BACKED | Optional JSON payload with status-specific details (e.g., rejection reason, provider response, counterparty VASP information). NULL for simple status transitions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TransactionTravelRuleInformationId | Wallet.TransactionTravelRuleInformation | FK | Parent Travel Rule record |
| INSERT target | Wallet.TransactionTravelRuleStatuses | Writer | Appends status history |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by application compliance services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddTransactionTravelRuleStatus (procedure)
  └── Wallet.TransactionTravelRuleStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleStatuses | Table | INSERT target |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses TRY/CATCH with THROW for error propagation
- SET NOCOUNT ON for performance

---

## 8. Sample Queries

### 8.1 View status history for a Travel Rule record
```sql
SELECT Id, TransactionTravelRuleInformationId, TravelRuleStatusId, DetailsJson, Created
FROM Wallet.TransactionTravelRuleStatuses WITH (NOLOCK)
WHERE TransactionTravelRuleInformationId = 12345
ORDER BY Id
```

### 8.2 Find Travel Rule records in a specific status
```sql
SELECT tri.Id, tri.RequestId, tri.CounterpartyAddress, trs.TravelRuleStatusId
FROM Wallet.TransactionTravelRuleInformation tri WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 TravelRuleStatusId FROM Wallet.TransactionTravelRuleStatuses WITH (NOLOCK)
    WHERE TransactionTravelRuleInformationId = tri.Id ORDER BY Id DESC
) trs
WHERE trs.TravelRuleStatusId = 2
```

### 8.3 Count Travel Rule records by latest status
```sql
SELECT trs.TravelRuleStatusId, COUNT(*) AS Cnt
FROM Wallet.TransactionTravelRuleInformation tri WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 TravelRuleStatusId FROM Wallet.TransactionTravelRuleStatuses WITH (NOLOCK)
    WHERE TransactionTravelRuleInformationId = tri.Id ORDER BY Id DESC
) trs
GROUP BY trs.TravelRuleStatusId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddTransactionTravelRuleStatus | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddTransactionTravelRuleStatus.sql*
