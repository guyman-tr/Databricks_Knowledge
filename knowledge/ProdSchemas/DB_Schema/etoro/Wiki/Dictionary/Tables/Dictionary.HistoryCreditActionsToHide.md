# Dictionary.HistoryCreditActionsToHide

> Configuration table defining which CreditType + CompensationReason combinations should be hidden from customer-facing credit history views — filtering out internal system adjustments that would confuse end users.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CreditTypeID + CompensationReasonID (COMPOSITE PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.HistoryCreditActionsToHide defines a blacklist of credit action combinations that should be excluded from customer-visible credit history. eToro's credit system records many internal adjustments — corporate action compensations, dividend adjustments, fee corrections — that are operationally necessary but would confuse customers if displayed in their transaction history. This table acts as a filter: any credit record matching a CreditTypeID + CompensationReasonID pair listed here is suppressed from the customer-facing history API.

This table exists because the internal credit system captures far more detail than customers need or should see. Showing internal bookkeeping entries (like inter-account adjustments or system-generated corrections) in the customer's credit history would generate confusion and support tickets. By maintaining a configurable blacklist, the product team can control visibility without modifying stored procedure logic.

The table is consumed by eight Trade.TAPI_GetFlatCreditHistoryByCID* stored procedures — the variants for active credit, historical credit, cashflow-filtered, manual-filtered, and copy-filtered views all join to this table to exclude hidden entries.

---

## 2. Business Logic

### 2.1 Credit History Visibility Filter

**What**: A configurable blacklist of CreditType + CompensationReason pairs that are hidden from customer-facing credit history.

**Columns/Parameters Involved**: `CreditTypeID`, `CompensationReasonID`

**Rules**:
- All 12 current entries use CreditTypeID = 6 (a specific credit type category) with various CompensationReasonIDs (64, 68, 72-77, 79, 88, 89, 91)
- If a credit history record's (CreditTypeID, CompensationReasonID) pair exists in this table, it is excluded from customer-facing views
- The exclusion applies to both active and historical credit history queries
- The composite PK ensures each combination is listed at most once

**Diagram**:
```
Credit History Pipeline:
  All Credit Records (Trade.CreditHistory)
         │
         ▼
  JOIN HistoryCreditActionsToHide
         │
    ┌────┴────┐
    │ Match   │ No Match
    ▼         ▼
  HIDDEN    VISIBLE
  (internal) (customer-facing)
```

---

## 3. Data Overview

| CreditTypeID | CompensationReasonID | Meaning |
|---|---|---|
| 6 | 64 | Internal credit action of type 6 with compensation reason 64 — hidden from customer credit history to avoid exposing internal bookkeeping adjustments. |
| 6 | 72 | Internal compensation adjustment — one of a cluster of related compensation reasons (72-77) that represent systematic internal adjustments not meaningful to customers. |
| 6 | 88 | Internal compensation reason that represents a system-generated correction. Hidden because the customer sees only the net effect through other visible credit entries. |
| 6 | 89 | Related to compensation reason 88 — another system-generated correction that is suppressed from the customer view. |
| 6 | 91 | Internal adjustment that would appear as a confusing debit/credit pair to customers. Hidden to keep the credit history clean and understandable. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditTypeID | tinyint | NO | - | CODE-BACKED | Part of composite PK. References Dictionary.CreditType to identify the credit category. All current entries use CreditTypeID=6. Used by 8 Trade.TAPI_GetFlatCreditHistory* procedures to filter credit records. |
| 2 | CompensationReasonID | int | NO | - | CODE-BACKED | Part of composite PK. Identifies the specific compensation reason within the credit type. Combined with CreditTypeID, defines which credit actions are hidden from customers. Current values: 64, 68, 72-77, 79, 88, 89, 91. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CreditTypeID | Dictionary.CreditType | Implicit FK | References the credit type category being filtered |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit | - | JOIN | Filters active credit history for customer display |
| Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryCredit | - | JOIN | Filters historical credit records for customer display |
| Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit | - | JOIN | Filters cashflow-filtered active credit history |
| Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryCredit | - | JOIN | Filters cashflow-filtered historical credit |
| Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryActiveCredit | - | JOIN | Filters manual-only active credit history |
| Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryCredit | - | JOIN | Filters manual-only historical credit |
| Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit | - | JOIN | Filters copy-trading active credit history |
| Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryCredit | - | JOIN | Filters copy-trading historical credit |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryActiveCredit | Stored Procedure | Reads — filters visible credit entries |
| Trade.TAPI_GetFlatCreditHistoryByCID_From_HistoryCredit | Stored Procedure | Reads — filters visible credit entries |
| Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryActiveCredit | Stored Procedure | Reads — cashflow-filtered credit |
| Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCashflows_HistoryCredit | Stored Procedure | Reads — cashflow-filtered credit |
| Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryActiveCredit | Stored Procedure | Reads — manual-filtered credit |
| Trade.TAPI_GetFlatCreditHistoryByCIDFilterByManual_HistoryCredit | Stored Procedure | Reads — manual-filtered credit |
| Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryActiveCredit | Stored Procedure | Reads — copy-filtered credit |
| Trade.TAPI_GetFlatCreditHistoryByCIDFilterByCopy_HistoryCredit | Stored Procedure | Reads — copy-filtered credit |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryCreditActionsToHide | CLUSTERED PK | CreditTypeID ASC, CompensationReasonID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryCreditActionsToHide | PRIMARY KEY | Composite key ensuring each CreditType + CompensationReason pair is listed at most once |

---

## 8. Sample Queries

### 8.1 List all hidden credit action combinations
```sql
SELECT  CreditTypeID,
        CompensationReasonID
FROM    [Dictionary].[HistoryCreditActionsToHide] WITH (NOLOCK)
ORDER BY CreditTypeID, CompensationReasonID;
```

### 8.2 Join to CreditType for readable names
```sql
SELECT  h.CreditTypeID,
        ct.Name AS CreditTypeName,
        h.CompensationReasonID
FROM    [Dictionary].[HistoryCreditActionsToHide] h WITH (NOLOCK)
JOIN    [Dictionary].[CreditType] ct WITH (NOLOCK)
        ON h.CreditTypeID = ct.CreditTypeID
ORDER BY h.CreditTypeID, h.CompensationReasonID;
```

### 8.3 Check if a specific credit action is hidden
```sql
SELECT  CASE WHEN EXISTS (
            SELECT 1
            FROM   [Dictionary].[HistoryCreditActionsToHide] WITH (NOLOCK)
            WHERE  CreditTypeID = 6
            AND    CompensationReasonID = 72
        ) THEN 'HIDDEN' ELSE 'VISIBLE' END AS Visibility;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.HistoryCreditActionsToHide | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.HistoryCreditActionsToHide.sql*
