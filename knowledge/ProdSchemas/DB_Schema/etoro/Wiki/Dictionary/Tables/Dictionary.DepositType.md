# Dictionary.DepositType

> Lookup table defining the 8 categories of deposit transactions, distinguishing real deposits from internal credits and fee adjustments.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | DepositTypeID (INT, CLUSTERED PK) |
| **Partition** | No (PRIMARY filegroup, PAGE compressed) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.DepositType classifies deposit transactions by their source and nature. The critical distinction is between real deposits (actual money from external sources) and internal credits (bonus, fee adjustments, promotional credits).

The ApplyFtd flag is the most important business column — it determines whether a deposit of this type counts toward the user's First Time Deposit (FTD). FTD is a crucial business metric for marketing attribution, partner commissions, and user onboarding milestones. Promotional credits and internal adjustments do NOT count as FTD.

DepositTypeID is stored in Billing.Deposit and referenced by deposit processing procedures, FTD calculations, and marketing attribution logic.

---

## 2. Business Logic

### 2.1 FTD Attribution

**What**: Only certain deposit types count toward First Time Deposit, which drives marketing attribution and partner commissions.

**Columns/Parameters Involved**: `DepositTypeID`, `ApplyFtd`

**Rules**:
- ApplyFtd=1: Real deposits from external payment methods (credit card, wire, e-wallet). These count toward FTD and trigger marketing attribution events.
- ApplyFtd=0: Internal credits, bonuses, fee adjustments. These do NOT count as FTD even if they're the first transaction on the account.
- The user's FTD amount and date drive affiliate commissions, CPA payments, and onboarding milestone tracking.

---

## 3. Data Overview

| DepositTypeID | DepositType | Description | ApplyFtd | Meaning |
|---|---|---|---|---|
| 1 | Deposit | Standard Deposit | 1 | A real deposit of funds from an external payment method. Counts as FTD. The primary and most common deposit type. |
| 2 | Credit | Credit | 0 | Internal credit adjustment — manual addition of funds by operations team. Does NOT count as FTD. Used for error corrections, goodwill credits. |
| 3 | Bonus | Bonus | 0 | Promotional bonus credited to the user's account. Does NOT count as FTD. Part of marketing campaigns — subject to withdrawal restrictions. |
| 6 | Adjustment | Fee Adjustment | 0 | Correction for incorrectly charged fees. Does NOT count as FTD. Typically paired with a matching debit for the original fee. |
| 7 | DepositByAcquirer | Deposit By Acquirer | 1 | Deposit processed by an acquiring bank rather than through the standard flow. Counts as FTD. Used for certain payment providers. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepositTypeID | int | NO | - | CODE-BACKED | Primary key identifying the deposit category. See [Deposit Type](_glossary.md#deposit-type). (Dictionary.DepositType) |
| 2 | DepositType | varchar(20) | NO | - | CODE-BACKED | Short code name for the deposit category. Used in code branching and API classification. |
| 3 | Description | varchar(50) | NO | - | CODE-BACKED | Human-readable description. Displayed in back-office deposit management and reporting. |
| 4 | ApplyFtd | bit | NO | (1) | CODE-BACKED | Whether this deposit type counts toward First Time Deposit. 1=real external deposit, 0=internal/promotional credit. Drives marketing attribution, partner commission calculations, and onboarding milestone tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Deposit | DepositTypeID | Implicit Lookup | Classifies each deposit transaction |

---

## 6. Dependencies

This object has no dependencies.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DepositTypeID | CLUSTERED PK | DepositTypeID ASC | - | - | Active |

### 7.2 Storage

DATA_COMPRESSION = PAGE on the primary key index.

---

## 8. Sample Queries

### 8.1 List all deposit types
```sql
SELECT DepositTypeID, DepositType, Description, ApplyFtd
FROM [Dictionary].[DepositType] WITH (NOLOCK) ORDER BY DepositTypeID;
```

### 8.2 Count real vs promotional deposits
```sql
SELECT dt.DepositType, dt.ApplyFtd, COUNT(*) AS DepositCount
FROM [Billing].[Deposit] d WITH (NOLOCK)
JOIN [Dictionary].[DepositType] dt WITH (NOLOCK) ON d.DepositTypeID = dt.DepositTypeID
GROUP BY dt.DepositType, dt.ApplyFtd ORDER BY DepositCount DESC;
```

---

*Generated: 2026-03-13 | Quality: 8.0/10*
*Object: Dictionary.DepositType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DepositType.sql*
