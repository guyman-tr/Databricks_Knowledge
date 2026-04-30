# AffiliateCommission.ResetClosedPositionTrackingEligibility

> Disqualifies a closed position from commission eligibility by setting its Valid flag to 0, preventing any future commission calculations for that position. PART-2448.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates ClosedPosition.Valid to 0 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

ResetClosedPositionTrackingEligibility is a commission governance procedure introduced in PART-2448 (CPA New Compensation Design). It allows the system to retroactively disqualify a closed position from the commission pipeline. When Valid is set to 0, the position is excluded from future commission calculations, triggered events, and aggregation queries.

There are several business scenarios that require disqualification. A position may be invalidated when fraud is detected on the associated customer account, when a trade is reversed or corrected by the back office, or when regulatory review determines that a specific position should not generate affiliate commissions. Rather than deleting the position record (which would lose the audit trail), this soft-invalidation approach preserves the historical data while effectively removing it from the commission pipeline.

The procedure performs an UPDATE rather than a DELETE, which is a deliberate design choice. The ClosedPosition table contains the authoritative record of closed trades, and downstream systems (reporting, reconciliation, audit) may reference these rows. Setting Valid = 0 keeps the data intact for auditing while signaling to all commission queries that this position should be skipped.

---

## 2. Business Logic

### 2.1 Soft Invalidation

**What**: Sets the Valid flag to 0, disqualifying the position from commission eligibility without deleting data.

**Columns/Parameters Involved**: `@ClosedPositionID`, `ClosedPosition.Valid`, `ClosedPosition.ClosedPositionID`

**Rules**:
- UPDATE ClosedPosition SET Valid = 0 WHERE ClosedPositionID = @ClosedPositionID
- Only one row is affected (ClosedPositionID is unique)
- If the position is already invalid (Valid = 0), the update is idempotent
- If the ClosedPositionID does not exist, no rows are updated
- Commission queries must filter on Valid = 1 to respect this disqualification

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ClosedPositionID | BIGINT (IN) | NO | - | CODE-BACKED | The closed position to disqualify. Matches the ClosedPositionID column in the ClosedPosition table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ClosedPositionID | AffiliateCommission.ClosedPosition | WRITE (UPDATE) | Sets Valid = 0 on the target position |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission processing pipeline or administrative tools when a position must be disqualified.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.ResetClosedPositionTrackingEligibility (procedure)
+-- AffiliateCommission.ClosedPosition (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPosition | Table | UPDATE Valid flag by ClosedPositionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission pipeline) | External | Disqualifies positions from commission eligibility |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Disqualify a closed position from commission eligibility
```sql
EXEC [AffiliateCommission].[ResetClosedPositionTrackingEligibility]
    @ClosedPositionID = 500456
```

### 8.2 Verify the position was invalidated
```sql
SELECT ClosedPositionID, Valid, AffiliateID, CID, CloseDate
FROM [AffiliateCommission].[ClosedPosition] WITH (NOLOCK)
WHERE ClosedPositionID = 500456
```

### 8.3 Count valid vs invalidated positions
```sql
SELECT Valid,
    COUNT(*) AS PositionCount,
    MIN(CloseDate) AS EarliestClose,
    MAX(CloseDate) AS LatestClose
FROM [AffiliateCommission].[ClosedPosition] WITH (NOLOCK)
GROUP BY Valid
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-2448: CPA New Compensation Design

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.ResetClosedPositionTrackingEligibility | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.ResetClosedPositionTrackingEligibility.sql*
