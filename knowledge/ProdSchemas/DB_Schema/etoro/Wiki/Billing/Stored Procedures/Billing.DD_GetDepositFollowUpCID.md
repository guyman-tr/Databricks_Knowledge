# Billing.DD_GetDepositFollowUpCID

> DataDog monitoring check that retrieves up to 10 customer IDs who have an approved deposit and are in "Follow Up" acceptance status, intended to surface customers requiring review after a same-moment deposit.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1-row result: value (count, up to 10) + CIDList (CSV of CIDs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DD_GetDepositFollowUpCID` is a DataDog synthetic monitor procedure (DBAD-17, initial version September 2022). It is designed to identify up to 10 customers who have both:
1. An approved deposit (`PaymentStatusID=2`) in `Billing.vDeposit`
2. An acceptance status of `AcceptanceStatusID=3` ("Follow Up") in `BackOffice.Customer`

The "Follow Up" acceptance status flags customers whose applications have been reviewed but require additional attention - for example, customers who deposited before completing KYC documentation or whose accounts require compliance review. The procedure is intended to surface these cases for the compliance or customer service team to action.

**Important note on likely defect**: The filter `ModificationDate = GETUTCDATE()` compares a stored datetime column against a sub-millisecond precise system clock value. In practice, this condition almost never evaluates to TRUE because the stored timestamp would need to match the exact moment of the procedure execution. The procedure was likely intended to use a date-range filter (e.g., today's deposits or deposits in the past N hours). As currently implemented, this procedure may consistently return `value=0` with an empty CIDList. DataDog using this monitor should be aware that it may not be detecting the intended pattern.

---

## 2. Business Logic

### 2.1 Follow-Up Customer Deposit Detection

**What**: Identifies customers in "Follow Up" acceptance state who have an approved deposit, limited to 10 results.

**Columns/Parameters Involved**: `Billing.vDeposit.PaymentStatusID`, `Billing.vDeposit.ModificationDate`, `BackOffice.Customer.AcceptanceStatusID`

**Rules**:
- No parameters - all thresholds are hardcoded
- `AcceptanceStatusID=3` = "Follow Up" (per `Dictionary.AcceptanceStatus`)
- `PaymentStatusID=2` = Approved deposits only
- `ModificationDate = GETUTCDATE()` - exact datetime match (see defect note above)
- TOP 10 limits output even if more qualifying records exist
- Returns COUNT as `value` (not boolean), plus comma-separated CIDs
- When count=0, CIDList is NULL

**Acceptance Status Values (Dictionary.AcceptanceStatus)**:
| ID | Name |
|----|------|
| 0 | Pending |
| 1 | Accepted |
| 2 | Rejected |
| 3 | Follow Up |

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | value (output) | INT | NO | - | CODE-BACKED | Count of CIDs (up to 10) from Billing.vDeposit joined to BackOffice.Customer that meet the filter criteria: PaymentStatusID=2 (approved) AND AcceptanceStatusID=3 (Follow Up) AND ModificationDate = GETUTCDATE(). Due to the exact-timestamp filter, this is likely always 0 in practice. |
| 2 | CIDList (output) | VARCHAR | YES | - | CODE-BACKED | Comma-separated string of CID values (up to 10) for customers meeting the criteria. NULL when value=0. Intended for the compliance or customer service team to identify follow-up cases requiring attention. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentStatusID, ModificationDate filter | Billing.vDeposit | Read | Reads the standard deposit view for approved deposits. See [Billing.vDeposit](../Views/Billing.vDeposit.md). |
| AcceptanceStatusID=3 filter | BackOffice.Customer | Cross-schema Read | Joins to BackOffice.Customer to filter customers in "Follow Up" acceptance status. Cross-schema dependency. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called externally by DataDog synthetic monitors.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DD_GetDepositFollowUpCID (procedure)
├── Billing.vDeposit (view)
│     ├── Billing.Deposit (table)
│     └── Billing.RecurringDeposit (table)
└── BackOffice.Customer (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.vDeposit | View | Provides approved deposit data with PaymentStatusID=2 filter |
| BackOffice.Customer | Table (cross-schema) | INNER JOIN on CID; filters to AcceptanceStatusID=3 (Follow Up) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DataDog Synthetic Monitor | External | Calls this procedure on a schedule to identify follow-up deposit cases |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run the DataDog check (likely returns 0 due to exact-timestamp filter)

```sql
EXEC Billing.DD_GetDepositFollowUpCID;
```

### 8.2 Intended query: find Follow Up customers with deposits TODAY (corrected logic)

```sql
SELECT TOP 10 bc.CID,
       MAX(bd.DepositID) AS LatestDepositID,
       MAX(bd.ModificationDate) AS LatestDepositDate
FROM Billing.vDeposit AS bd WITH (NOLOCK)
    JOIN BackOffice.Customer AS bc WITH (NOLOCK)
        ON bc.CID = bd.CID
WHERE bd.PaymentStatusID = 2
  AND CAST(bd.ModificationDate AS DATE) = CAST(GETUTCDATE() AS DATE)
  AND bc.AcceptanceStatusID = 3
GROUP BY bc.CID;
```

### 8.3 All Follow Up customers with any approved ACH or CC deposit in the last 7 days

```sql
SELECT bc.CID,
       COUNT(bd.DepositID) AS ApprovedDeposits,
       MAX(bd.ModificationDate) AS LastDeposit
FROM Billing.vDeposit AS bd WITH (NOLOCK)
    JOIN BackOffice.Customer AS bc WITH (NOLOCK)
        ON bc.CID = bd.CID
WHERE bd.PaymentStatusID = 2
  AND bd.ModificationDate >= DATEADD(DAY, -7, GETUTCDATE())
  AND bc.AcceptanceStatusID = 3
GROUP BY bc.CID
ORDER BY LastDeposit DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 9/10, Logic: 8/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DD_GetDepositFollowUpCID | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DD_GetDepositFollowUpCID.sql*
