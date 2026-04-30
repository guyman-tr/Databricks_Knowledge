# Dictionary.MirrorDividendRejectionReason

> Enumerates the reasons why a CopyTrading (mirror) dividend distribution may be rejected, preventing copied dividend payments from being processed.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | MirrorDividendRejectionReasonID (tinyint, PK) |
| **Partition** | No |
| **Indexes** | 1 clustered PK |

---

## 1. Business Meaning

Dictionary.MirrorDividendRejectionReason defines why a dividend payment to a CopyTrading copier may be rejected. When a Popular Investor (leader) receives a dividend on a stock position, the system attempts to distribute a proportional dividend to all copiers. This table captures the validation rules that can block that distribution.

Without this table, the system could not explain to copiers or operations staff why a copied dividend was not paid. It provides audit trail transparency for dividend distribution failures in the CopyTrading ecosystem.

The two rejection reasons represent amount-based validation gates: the dividend is either too small to process or exceeds the copier's withdrawal limit (since dividends function as cash credits that could be withdrawn).

---

## 2. Business Logic

### 2.1 Dividend Distribution Validation

**What**: Two validation gates that can block copied dividend payments.

**Columns/Parameters Involved**: `MirrorDividendRejectionReasonID`, `Name`

**Rules**:
- ID 1 (Amount Too Low): The proportional dividend amount for the copier is below the minimum processing threshold — not worth the operational cost
- ID 2 (Amount higher than Withdrawal Limit): The dividend would exceed the copier's available withdrawal limit, potentially creating a compliance/AML issue
- These checks run BEFORE the dividend credit is applied to the copier's balance

**Diagram**:
```
Leader receives dividend
       │
       ▼
Calculate copier's proportional share
       │
       ├── Amount < minimum threshold? ──> Reject (1: Amount Too Low)
       │
       ├── Amount > withdrawal limit? ──> Reject (2: Exceeds Limit)
       │
       └── Valid ──> Credit dividend to copier
```

---

## 3. Data Overview

| MirrorDividendRejectionReasonID | Name | Meaning |
|---|---|---|
| 1 | Amount To Low | The copier's proportional dividend share is below the minimum processing threshold — typically fractions of a cent that are not worth crediting |
| 2 | Amount higher than Withdrawal Limit | The dividend credit would exceed the copier's withdrawal limit, which could create a compliance issue if the copier immediately withdraws the excess |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MirrorDividendRejectionReasonID | tinyint | NO | - | CODE-BACKED | Unique identifier for the rejection reason: 1=Amount Too Low, 2=Amount higher than Withdrawal Limit. Referenced by CopyTrading dividend distribution logic. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable rejection reason displayed in BackOffice dividend audit screens and copier notifications. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CopyTrading dividend logs | MirrorDividendRejectionReasonID | Implicit | Dividend distribution records reference this for failed distributions |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in SSDT codebase beyond the DDL itself.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DMDRS | CLUSTERED PK | MirrorDividendRejectionReasonID | - | - | Active |

### 7.2 Constraints

None beyond PK.

---

## 8. Sample Queries

### 8.1 List all rejection reasons
```sql
SELECT  MirrorDividendRejectionReasonID,
        Name
FROM    [Dictionary].[MirrorDividendRejectionReason] WITH (NOLOCK)
ORDER BY MirrorDividendRejectionReasonID;
```

### 8.2 Find rejection reason by ID
```sql
SELECT  Name
FROM    [Dictionary].[MirrorDividendRejectionReason] WITH (NOLOCK)
WHERE   MirrorDividendRejectionReasonID = 1;
```

### 8.3 Look up both rejection reasons with descriptions
```sql
SELECT  MirrorDividendRejectionReasonID AS ID,
        Name AS RejectionReason,
        CASE MirrorDividendRejectionReasonID
            WHEN 1 THEN 'Dividend amount below minimum threshold'
            WHEN 2 THEN 'Dividend exceeds copier withdrawal limit'
        END AS BusinessMeaning
FROM    [Dictionary].[MirrorDividendRejectionReason] WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.MirrorDividendRejectionReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.MirrorDividendRejectionReason.sql*
