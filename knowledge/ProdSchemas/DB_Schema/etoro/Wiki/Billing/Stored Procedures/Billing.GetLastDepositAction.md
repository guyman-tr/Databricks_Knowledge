# Billing.GetLastDepositAction

> Returns all deposit action records for a given deposit, ordered newest first - the full action trail showing every payment provider interaction and status transition for that deposit.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID - returns all action records for this deposit |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetLastDepositAction` retrieves every payment action event recorded for a specific deposit in `History.DepositAction`. Each row in `History.DepositAction` represents one interaction with the payment provider for that deposit - an authorization attempt, a status check, a response, or a status change. By returning all records ordered by DepositActionID DESC (newest first), this procedure gives the full action history for troubleshooting deposit issues.

The procedure was created in 2021 (comment: "Inna 29/08/2021 PAYUS-3661"), indicating it was added to support deposit status investigation tooling or a new service flow. EXECUTE is granted to `DepositUser` - the service role for deposit processing operations.

The name "GetLastDepositAction" is somewhat misleading: unlike `GetLastDepositActionWithResponseCode`, it does NOT apply a TOP 1 - it returns ALL rows. The "Last" in the name likely refers to sorting (newest first) rather than limiting to one record.

---

## 2. Business Logic

### 2.1 Full Action History for a Deposit

**What**: All `History.DepositAction` records for the given deposit, ordered newest-first. Each row represents one point in the deposit's payment processing lifecycle.

**Columns/Parameters Involved**: `@DepositID`, `DepositActionID`, `PaymentStatusID`, `ResponseID`

**Rules**:
- No TOP limit - returns every action row for the deposit
- ORDER BY DepositActionID DESC - most recent action first (DepositActionID is IDENTITY, so DESC = newest first)
- `PaymentStatusID` in DepositAction records the deposit's status at the time of the action
- `ResponseID` is the payment provider's response code (NULL if no provider response recorded for this action)
- `History.DepositAction` is clustered by DepositID - query is efficient even without an explicit index hint

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | The deposit to retrieve action records for. FK to Billing.Deposit.DepositID. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | DepositActionID | int | NO | - | CODE-BACKED | Identity PK of the action record. Also the sort key - higher values = newer actions. |
| 3 | ResponseID | int | YES | NULL | CODE-BACKED | Payment provider response code for this action. NULL if no provider response was captured (e.g., action was a status change without a provider call). |
| 4 | PaymentStatusID | int | NO | - | CODE-BACKED | The deposit's payment status at the time of this action (from Dictionary.PaymentStatus). Tracking this across rows shows how the deposit status evolved over time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| da (FROM) | History.DepositAction | Direct Read | All payment action records for the given deposit, ordered newest first |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositUser (permissions) | EXECUTE grant | Permission | Deposit processing service role. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetLastDepositAction (procedure)
└── History.DepositAction (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.DepositAction | Table | FROM - all action records for @DepositID, ordered by DepositActionID DESC |

### 6.2 Objects That Depend On This

No dependents found in the SQL layer.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all actions for a specific deposit

```sql
EXEC Billing.GetLastDepositAction @DepositID = 7654321
```

### 8.2 Equivalent ad-hoc query with status names

```sql
SELECT da.DepositActionID, da.ResponseID, da.PaymentStatusID
FROM History.DepositAction da WITH (NOLOCK)
WHERE da.DepositID = 7654321
ORDER BY da.DepositActionID DESC
```

### 8.3 Check how many actions a deposit has

```sql
SELECT COUNT(*) AS ActionCount, MAX(DepositActionID) AS LatestActionID
FROM History.DepositAction WITH (NOLOCK)
WHERE DepositID = 7654321
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetLastDepositAction | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetLastDepositAction.sql*
