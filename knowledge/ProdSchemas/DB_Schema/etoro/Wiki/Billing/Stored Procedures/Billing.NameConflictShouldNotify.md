# Billing.NameConflictShouldNotify

> Checks whether a deposit name-conflict notification was already sent for a given customer-funding pair, returning a flag to prevent duplicate alerts.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WasNotified (OUTPUT bit) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.NameConflictShouldNotify` is a notification-deduplication guard for the deposit name-conflict risk flow. When a customer deposits using a payment instrument whose cardholder name does not match their registered name, the system flags this as a `DepositNameConflict` (RiskStatusID=7) in `Billing.FundingCustomerRisk` and sends an alert. This procedure answers one question: has the notification for this specific (customer, funding instrument) pair already been sent?

The procedure exists to prevent duplicate notifications. Without it, a customer who makes multiple deposits with the same conflicting card would receive a separate alert for every deposit. The caller checks `@WasNotified` before dispatching the notification - if 1, the alert is suppressed.

The caller passes a CID and FundingID, receives back `@WasNotified = 1` if a RiskStatusID=7 row exists for that pair in `Billing.FundingCustomerRisk`, or `@WasNotified = 0` if no such row exists. When the notification IS sent, `Billing.FundingCustomerRisk_Add` (or `_AddByDeposit`) inserts the flag row, so future calls to this procedure return 1 for the same pair.

---

## 2. Business Logic

### 2.1 Notification Deduplication Flow

**What**: Idempotent check preventing duplicate DepositNameConflict alerts per customer-funding pair.

**Parameters Involved**: `@CID`, `@FundingID`, `@WasNotified`

**Rules**:
- Returns `@WasNotified = 1` if `Billing.FundingCustomerRisk` contains a row for (CID, FundingID, RiskStatusID=7)
- Returns `@WasNotified = 0` if no such row exists
- RiskStatusID=7 = DepositNameConflict - the only risk status currently active in `Billing.FundingCustomerRisk` (all 1,259 live rows use this value)
- The insert of the flag row (by `Billing.FundingCustomerRisk_Add`) happens OUTSIDE this procedure - in the caller's flow after notification is sent

**Diagram**:
```
Deposit with name mismatch detected
            |
            v
  NameConflictShouldNotify(@CID, @FundingID, @WasNotified OUT)
            |
   EXISTS (CID, FundingID, RiskStatusID=7)?
            |
     YES -> @WasNotified = 1      NO -> @WasNotified = 0
            |                           |
     Caller suppresses alert     Caller sends alert
                                        |
                            FundingCustomerRisk_Add inserts (CID, FundingID, 7)
                            (next call returns WasNotified=1)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID. Identifies the customer whose name-conflict notification status is being checked. Matched against `Billing.FundingCustomerRisk.CID`. |
| 2 | @FundingID | int | NO | - | CODE-BACKED | Funding instrument ID (credit card, e-wallet, etc.). Combined with @CID, identifies the specific customer-payment-method pair being evaluated. Matched against `Billing.FundingCustomerRisk.FundingID`. |
| 3 | @WasNotified | bit | NO | - | CODE-BACKED | OUTPUT flag: 1 = a DepositNameConflict notification was already sent for this (CID, FundingID) pair (RiskStatusID=7 row exists); 0 = no notification has been sent yet. Caller uses this to decide whether to suppress or dispatch the alert. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID + @FundingID + RiskStatusID=7 | [Billing.FundingCustomerRisk](../Tables/Billing.FundingCustomerRisk.md) | Lookup | EXISTS check for the (CID, FundingID, 7) composite key - the notification guard row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application billing service | - | EXEC caller | Called by the payment/deposit processing service before sending DepositNameConflict alerts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.NameConflictShouldNotify (procedure)
└── Billing.FundingCustomerRisk (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [Billing.FundingCustomerRisk](../Tables/Billing.FundingCustomerRisk.md) | Table | EXISTS query - checks for (CID, FundingID, RiskStatusID=7) row |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application billing service (external) | Application | Calls this procedure before dispatching DepositNameConflict notifications |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check if notification was already sent for a customer-card pair

```sql
DECLARE @WasNotified bit;
EXEC Billing.NameConflictShouldNotify
    @CID = 123456,
    @FundingID = 789,
    @WasNotified = @WasNotified OUT;
SELECT @WasNotified AS WasNotified;
```

### 8.2 Find all customer-funding pairs that have been notified (DepositNameConflict)

```sql
SELECT
    fcr.CID,
    fcr.FundingID,
    fcr.RiskStatusID,
    rs.Name AS RiskStatusName
FROM Billing.FundingCustomerRisk fcr WITH (NOLOCK)
INNER JOIN Dictionary.RiskStatus rs WITH (NOLOCK) ON rs.RiskStatusID = fcr.RiskStatusID
WHERE fcr.RiskStatusID = 7
ORDER BY fcr.CID;
```

### 8.3 Verify notification guard state for a specific customer across all their funding instruments

```sql
SELECT
    fcr.CID,
    fcr.FundingID,
    fcr.RiskStatusID,
    rs.Name AS RiskStatus
FROM Billing.FundingCustomerRisk fcr WITH (NOLOCK)
INNER JOIN Dictionary.RiskStatus rs WITH (NOLOCK) ON rs.RiskStatusID = fcr.RiskStatusID
WHERE fcr.CID = 123456
  AND fcr.RiskStatusID = 7;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.NameConflictShouldNotify | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.NameConflictShouldNotify.sql*
