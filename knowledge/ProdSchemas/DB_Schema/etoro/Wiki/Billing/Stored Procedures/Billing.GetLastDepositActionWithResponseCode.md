# Billing.GetLastDepositActionWithResponseCode

> Returns the single most recent deposit action that has a payment provider response code - TOP 1 WHERE ResponseID IS NOT NULL - for diagnosing the last provider response on a deposit.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepositID - returns the latest action with a provider response |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.GetLastDepositActionWithResponseCode` finds the most recent deposit action where the payment provider returned a response code. Not every `History.DepositAction` row has a `ResponseID` - internal status changes, admin actions, and retries without provider contact leave `ResponseID` as NULL. This procedure skips those and returns only the last action where the provider actually responded.

The primary use case is deposit status diagnosis: when a deposit is stuck or failed, this procedure tells you what the payment provider last said (`ResponseID`) and what status the deposit was in at that point (`PaymentStatusID`). Combined with `GetLastDepositAction` (all rows) and `GetLastDepositActionForLog` (latest action + log entry), it forms a three-procedure diagnostic family for deposit troubleshooting.

Created by Elrom B. 08/10/2024 (PAYIL-8999 "GetDepositStatus") - the most recent of the three, added to support the GetDepositStatus service flow. EXECUTE is granted to `DepositUser`.

---

## 2. Business Logic

### 2.1 Latest Provider Response for a Deposit

**What**: The most recent action row where the payment provider issued a response code - skipping internal/admin actions with NULL ResponseID.

**Columns/Parameters Involved**: `@DepositID`, `DepositActionID`, `ResponseID`, `PaymentStatusID`

**Rules**:
- TOP 1 - exactly one row
- WHERE `da.DepositID = @DepositID AND da.ResponseID IS NOT NULL` - filters to provider-contacted actions only
- ORDER BY DepositActionID DESC - most recent provider response first
- Returns NULL result set (empty) if no action with a ResponseID exists for this deposit
- `ResponseID` maps to a payment provider response code (likely in Dictionary.PaymentResponse or similar)
- `PaymentStatusID` is the deposit status at the time of this provider response (from Dictionary.PaymentStatus)

**Diagram**:
```
@DepositID -> History.DepositAction (clustered by DepositID)
              WHERE ResponseID IS NOT NULL   <- provider responded
              ORDER BY DepositActionID DESC  <- most recent first
              TOP 1

Returns: { DepositActionID, ResponseID, PaymentStatusID }
         OR empty set if no provider responses recorded
```

### 2.2 Comparison with Sister Procedures

**What**: Three procedures share `@DepositID` input and `History.DepositAction` source but serve different purposes.

| Procedure | TOP | Filter | Output |
|-----------|-----|--------|--------|
| `GetLastDepositAction` | None (all rows) | None | DepositActionID, ResponseID, PaymentStatusID |
| `GetLastDepositActionForLog` | TOP(1) | None | DepositActionID, DepositLogID (cross-DB log) |
| `GetLastDepositActionWithResponseCode` | TOP 1 | ResponseID IS NOT NULL | DepositActionID, ResponseID, PaymentStatusID |

`GetLastDepositActionWithResponseCode` is the focused provider-response variant: it answers "what did the payment provider last say about this deposit?"

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepositID | INT | NO | - | CODE-BACKED | The deposit to retrieve the latest provider response for. FK to Billing.Deposit.DepositID. |

### Output Result Set

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | DepositActionID | int | NO | - | CODE-BACKED | Identity PK of the most recent action that has a provider response. Also serves as a sort key - higher values = newer actions. |
| 3 | ResponseID | int | NO | - | CODE-BACKED | Payment provider response code for this action. Guaranteed non-NULL by the WHERE filter. Maps to a provider response code dictionary. Indicates what the provider responded (approved, declined, error, etc.). |
| 4 | PaymentStatusID | int | NO | - | CODE-BACKED | The deposit's payment status at the time this provider response was received (from Dictionary.PaymentStatus). Useful for correlating the provider response with the deposit's lifecycle state. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| da (FROM) | History.DepositAction | Direct Read | Most recent action with a provider response (ResponseID IS NOT NULL) for the given deposit |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| DepositUser (permissions) | EXECUTE grant | Permission | Deposit processing service role. Created for PAYIL-8999 GetDepositStatus flow. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetLastDepositActionWithResponseCode (procedure)
└── History.DepositAction (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.DepositAction | Table | FROM - most recent action with non-NULL ResponseID for @DepositID |

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

### 8.1 Get the last provider response for a deposit

```sql
EXEC Billing.GetLastDepositActionWithResponseCode @DepositID = 7654321
-- Returns: DepositActionID, ResponseID (non-NULL), PaymentStatusID
-- Returns empty set if the deposit has no actions with a provider response
```

### 8.2 Equivalent ad-hoc query

```sql
SELECT TOP 1
    da.DepositActionID,
    da.ResponseID,
    da.PaymentStatusID
FROM History.DepositAction da WITH (NOLOCK)
WHERE da.DepositID = 7654321
  AND da.ResponseID IS NOT NULL
ORDER BY da.DepositActionID DESC
```

### 8.3 Compare with all actions to see which had provider responses

```sql
-- All actions:
EXEC Billing.GetLastDepositAction @DepositID = 7654321
-- Latest with response:
EXEC Billing.GetLastDepositActionWithResponseCode @DepositID = 7654321
-- If the latest action (from GetLastDepositAction) has NULL ResponseID,
-- GetLastDepositActionWithResponseCode will return an older action row.
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9B, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.GetLastDepositActionWithResponseCode | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetLastDepositActionWithResponseCode.sql*
