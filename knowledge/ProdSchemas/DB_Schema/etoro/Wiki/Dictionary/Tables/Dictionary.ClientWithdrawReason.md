# Dictionary.ClientWithdrawReason

> Lookup table defining customer-facing reasons for requesting a withdrawal. Displayed in the withdrawal form UI and used for analytics and churn understanding.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ClientWithdrawReasonID (int, PK CLUSTERED) |
| **Partition** | PRIMARY filegroup, FILLFACTOR 90, PAGE compression |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.ClientWithdrawReason stores the predefined reasons a customer can select when submitting a withdrawal request. These reasons appear in the withdrawal form UI during the cash-out flow, allowing clients to indicate why they are withdrawing funds. The options are designed to be empathetic and professional — ranging from "Withdrawing profits" and "Fulfill other financial commitments" to "Moving to a competitor" and "None of the reasons above."

The reasons serve dual purposes. First, they improve UX by giving customers a structured way to provide optional feedback during a sensitive moment. Second, they support product analytics and churn analysis: understanding why customers withdraw helps the business identify patterns (e.g., trading goals not met, platform fit, competitor migration) and inform retention strategies.

The table is curated by the product team via IsActive and DisplayOrder. IsActive controls which reasons appear in the UI; DisplayOrder determines the sequence. When Billing.WithdrawRequestAdd or Billing.WithdrawalService_WithdrawRequestAdd creates a withdrawal, the selected ClientWithdrawReasonID (and optional ClientWithdrawReasonComment) is stored in Billing.Withdraw. BackOffice and SalesForce procs join to this table to display the reason in reports and integrations.

---

## 2. Business Logic

### 2.1 Active Reasons for Withdrawal Form

**What**: Only active reasons (IsActive = 1) are returned for the withdrawal form UI, ordered by DisplayOrder.

**Columns/Parameters Involved**: `IsActive`, `DisplayOrder`, `ClientWithdrawReasonID`

**Rules**:
- **IsActive = 1**: Reason is available for selection in the withdrawal form. Billing.WithdrawalService_GetClientWitdrawReasons returns only these.
- **IsActive = 0**: Reason is hidden from new requests but may exist in historical Billing.Withdraw records.
- **DisplayOrder**: Ascending order for UI display. Lower values appear first (e.g., 1 = top of list).

**Diagram**:
```
Withdrawal Request Flow:

  Customer ──► Withdrawal Form ──► WithdrawalService_GetClientWitdrawReasons
                                       │ (returns active reasons, ORDER BY DisplayOrder)
                                       ▼
  Customer selects reason ─────────► WithdrawalService_WithdrawRequestAdd
                                       @ClientWithdrawReasonID, @ClientWithdrawReasonComment
                                       │
                                       ▼
                                  Billing.Withdraw (ClientWithdrawReasonID, ClientWithdrawReasonComment)
                                       │
                                       ▼
  BackOffice / SalesForce ────────► JOIN Dictionary.ClientWithdrawReason
                                    (ClientWithdrawReason, GetUnapprovedWithdrawRequests,
                                     GetCashOutRequests_Main, GetWithdraws)
```

### 2.2 "None of the reasons above" Fallback

**What**: ClientWithdrawReasonID = 1 ("None of the reasons above") is typically the last option (DisplayOrder = 7). When selected, ClientWithdrawReasonComment is used to capture the free-text reason.

**Columns/Parameters Involved**: `ClientWithdrawReasonID`, `ClientWithdrawReasonComment` (in Billing.Withdraw)

**Rules**:
- Reason 1 allows customers to provide a custom explanation when the predefined list does not fit.
- ClientWithdrawReasonComment stores the free-text; BackOffice and SalesForce procs surface both the Name and Comment for full context.

---

## 3. Data Overview

| ClientWithdrawReasonID | Name | IsActive | DisplayOrder | Meaning |
|---|---|---|---|---|
| 2 | Withdrawing profits | true | 1 | Customer is taking out profits from successful trading. Common positive outcome. |
| 3 | Fulfill other financial commitments | true | 2 | Customer needs funds for external obligations (bills, other investments). |
| 4 | I Have not achieved my trading goals | true | 3 | Indicates dissatisfaction with platform or strategy; churn risk indicator. |
| 5 | This platform is not for me | true | 4 | Platform-fit feedback; may inform product or UX improvements. |
| 6 | I Would like to close my account | true | 5 | Explicit account closure intent; may trigger compliance or retention workflows. |
| 7 | Moving to a competitor | true | 6 | Direct competitor churn; valuable for competitive analysis. |
| 1 | None of the reasons above | true | 7 | Fallback; ClientWithdrawReasonComment holds custom text. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClientWithdrawReasonID | int | NO | - | CODE-BACKED | Primary key. Values 1–7. Referenced by Billing.Withdraw via FK. Passed as @ClientWithdrawReasonID to WithdrawalService_WithdrawRequestAdd, WithdrawRequestAdd, UpsertWithdraw. |
| 2 | Name | varchar(50) | YES | - | CODE-BACKED | Human-readable reason label displayed in the withdrawal form. E.g., "Withdrawing profits", "Moving to a competitor". NULL allowed. |
| 3 | IsActive | bit | NO | 1 | CODE-BACKED | Controls visibility in UI. 1 = shown in WithdrawalService_GetClientWitdrawReasons; 0 = hidden for new requests. |
| 4 | DisplayOrder | int | NO | - | CODE-BACKED | Sort order for UI display. Lower values first. Used in ORDER BY when fetching active reasons. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Withdraw | ClientWithdrawReasonID | FK | Each withdrawal records the selected reason |
| Billing.WithdrawRequestAdd | @ClientWithdrawReasonID | Parameter | Proc creates withdrawal with reason |
| Billing.WithdrawalService_WithdrawRequestAdd | @ClientWithdrawReasonID | Parameter | Service proc creates withdrawal with reason |
| Billing.WithdrawalService_GetClientWitdrawReasons | - | SELECT | Returns active reasons for withdrawal form |
| Billing.UpsertWithdraw | @ClientWithdrawReasonID | Parameter | Upsert proc updates withdrawal with reason |
| Billing.TBL_Withdraw | ClientWithdrawReasonID | UDT | User-defined type includes reason |
| BackOffice.GetWithdrawRequests | - | JOIN | BO proc joins for reason display |
| BackOffice.GetUnapprovedWithdrawRequests | ClientWithdrawReasonID | JOIN | BO proc joins Dictionary.ClientWithdrawReason for CWR.Name |
| BackOffice.GetCashOutRequests_Main | ClientWithdrawReasonID | SELECT | BO proc returns reason for cash-out requests |
| SalesForce.GetWithdraws | ClientWithdrawReasonID | SELECT | SF integration returns reason |
| SalesForce.GetWithdrawsByCID | ClientWithdrawReasonID | SELECT | SF integration by CID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.ClientWithdrawReason (table)
```

This object has no dependencies. Tables have no code-level dependencies (no FROM/JOIN in CREATE TABLE).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | FK — each withdrawal records ClientWithdrawReasonID |
| Billing.WithdrawRequestAdd | Stored Procedure | Parameter and INSERT target |
| Billing.WithdrawalService_WithdrawRequestAdd | Stored Procedure | Parameter and INSERT target |
| Billing.WithdrawalService_GetClientWitdrawReasons | Stored Procedure | SELECT active reasons for UI |
| Billing.UpsertWithdraw | Stored Procedure | Parameter and MERGE target |
| BackOffice.GetUnapprovedWithdrawRequests | Stored Procedure | JOIN for reason display |
| BackOffice.GetCashOutRequests_Main | Stored Procedure | SELECT reason |
| SalesForce.GetWithdraws / GetWithdrawsByCID | Stored Procedure | SELECT reason for SF |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_ClientWithdrawReason | CLUSTERED PK | ClientWithdrawReasonID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_ClientWithdrawReason | PRIMARY KEY | Unique reason identifier. FILLFACTOR 90, DATA_COMPRESSION PAGE, PRIMARY filegroup. |

---

## 8. Sample Queries

### 8.1 List all active withdrawal reasons ordered for UI
```sql
SELECT  ClientWithdrawReasonID,
        Name,
        DisplayOrder
FROM    Dictionary.ClientWithdrawReason WITH (NOLOCK)
WHERE   IsActive = 1
ORDER BY DisplayOrder;
```

### 8.2 Count withdrawals by reason with description
```sql
SELECT  cwr.Name                      AS WithdrawReason,
        COUNT(*)                      AS WithdrawCount
FROM    Billing.Withdraw bw WITH (NOLOCK)
LEFT JOIN Dictionary.ClientWithdrawReason cwr WITH (NOLOCK)
        ON bw.ClientWithdrawReasonID = cwr.ClientWithdrawReasonID
GROUP BY cwr.Name
ORDER BY WithdrawCount DESC;
```

### 8.3 Find unapproved withdrawal requests with reason and comment
```sql
SELECT  bw.WithdrawID,
        bw.CID,
        cwr.Name                      AS ClientWithdrawReason,
        bw.ClientWithdrawReasonComment
FROM    Billing.Withdraw bw WITH (NOLOCK)
LEFT JOIN Dictionary.ClientWithdrawReason cwr WITH (NOLOCK)
        ON bw.ClientWithdrawReasonID = cwr.ClientWithdrawReasonID
WHERE   bw.CashoutStatusID IN (1, 2, 5, 6, 9, 10, 11, 12, 14, 15)
ORDER BY bw.WithdrawID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: DDL + MCP live data + Billing.Withdraw, WithdrawalService_WithdrawRequestAdd, GetClientWitdrawReasons, BackOffice procs, SalesForce procs | Corrections: 0 applied*
*Object: Dictionary.ClientWithdrawReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ClientWithdrawReason.sql*
