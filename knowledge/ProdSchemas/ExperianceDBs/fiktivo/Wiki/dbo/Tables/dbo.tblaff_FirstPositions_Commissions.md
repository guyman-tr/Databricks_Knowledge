# dbo.tblaff_FirstPositions_Commissions

> Stores tier-based affiliate commission records from first-position events, with an explicit FK to tblaff_FirstPositions ensuring referential integrity.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY, PK NC) |
| **Partition** | No |
| **Indexes** | 3 active |

---

## 1. Business Meaning

dbo.tblaff_FirstPositions_Commissions records affiliate commissions earned when referred customers open their first trading position (tblaff_FirstPositions). A customer's first position is a significant conversion milestone - it indicates the customer has progressed from registration through deposit to active trading.

This table has an explicit FK to tblaff_FirstPositions (unique among commission tables, which typically use triggers). Contains only 4 records, suggesting first-position commissions are either rarely used or this feature was added recently/is in testing.

---

## 2. Business Logic

### 2.1 First-Position Commission Distribution

**What**: Commission for the milestone event of a customer's first trade.

**Columns/Parameters Involved**: `FirstPositionID`, `AffiliateID`, `Commission`, `Tier`

**Rules**:
- FirstPositionID has an explicit FK to tblaff_FirstPositions.FirstPositionID
- Standard multi-tier distribution: Tier 1 = direct affiliate, Tier 2-5 = parent affiliates
- Only 4 records exist - very low-volume commission type

### 2.2 Payment Lifecycle

**Columns/Parameters Involved**: `Paid`, `PaymentID`
- Same pattern: Paid=0/PaymentID=0 = unpaid, Paid=1/PaymentID>0 = paid

---

## 3. Data Overview

Table contains only 4 rows. First-position commissions are the rarest commission type in the system.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY | NO | - | CODE-BACKED | Auto-incrementing primary key. NOT FOR REPLICATION. |
| 2 | FirstPositionID | int | YES | 0 | VERIFIED | References tblaff_FirstPositions.FirstPositionID via explicit FK (FK__FirstPosition_FirstPositionID). The customer's first trading position event. |
| 3 | AffiliateID | int | YES | 0 | VERIFIED | The affiliate receiving this commission. Maps to tblaff_Affiliates. |
| 4 | Commission | float | YES | 0 | VERIFIED | Commission amount for this tier. |
| 5 | Tier | int | YES | 0 | VERIFIED | Commission tier level: 1-5. |
| 6 | Paid | bit | NO | 0 | VERIFIED | Payment status: 0 = unpaid, 1 = paid. |
| 7 | PaymentID | int | NO | 0 | VERIFIED | References tblaff_PaymentHistory.PaymentID when paid. |
| 8 | SubAffiliateID | nvarchar(1024) | YES | - | CODE-BACKED | Sub-affiliate tracking tag. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FirstPositionID | dbo.tblaff_FirstPositions | FK (explicit) | The first-position event (FK__FirstPosition_FirstPositionID) |
| AffiliateID | dbo.tblaff_Affiliates | Implicit | The affiliate receiving commission |
| PaymentID | dbo.tblaff_PaymentHistory | Implicit | Payment batch when paid |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.UpdateSubAffiliateID | UPDATE | Procedure (MODIFIER) | Late-binding attribution |
| dbo.qry_aff_FirstPositionsDetailAllTiers | FROM | View (READER) | All-tier first-position commission details |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.UpdateSubAffiliateID | Stored Procedure | MODIFIER |
| dbo.qry_aff_Tier1FirstPositionsCommissions through Tier5 | Views | Per-tier aggregation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| aaaaatblaff_FirstPositions_Commissions_PK | NC PK | ID ASC | - | - | Active (PAGE) |
| IDX_tblaff_FirstPositions_Commissionss_FirstPositionID | NC | FirstPositionID | - | - | Active (PAGE) |
| IX_tblaff_FirstPositions_Commissions_AffiliateIDPaid | NC | AffiliateID, Paid | FirstPositionID, Commission | - | Active (PAGE) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK__FirstPosition_FirstPositionID | FOREIGN KEY | FirstPositionID -> tblaff_FirstPositions(FirstPositionID) |
| DF_tblaff_FirstPositions_Commissions_Paid | DEFAULT | 0 |
| DF_tblaff_FirstPositions_Commissions_PaymentID | DEFAULT | 0 |

---

## 8. Sample Queries

### 8.1 All first-position commissions (small table)
```sql
SELECT * FROM dbo.tblaff_FirstPositions_Commissions WITH (NOLOCK)
ORDER BY FirstPositionID, Tier
```

### 8.2 Join with first-position event details
```sql
SELECT fc.Commission, fc.Tier, fp.OriginalCID AS CustomerCID
FROM dbo.tblaff_FirstPositions_Commissions fc WITH (NOLOCK)
JOIN dbo.tblaff_FirstPositions fp WITH (NOLOCK) ON fc.FirstPositionID = fp.FirstPositionID
WHERE fc.AffiliateID = @AffiliateID
```

### 8.3 Unpaid first-position commissions
```sql
SELECT AffiliateID, SUM(Commission) AS TotalUnpaid
FROM dbo.tblaff_FirstPositions_Commissions WITH (NOLOCK)
WHERE Paid = 0
GROUP BY AffiliateID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_FirstPositions_Commissions | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_FirstPositions_Commissions.sql*
