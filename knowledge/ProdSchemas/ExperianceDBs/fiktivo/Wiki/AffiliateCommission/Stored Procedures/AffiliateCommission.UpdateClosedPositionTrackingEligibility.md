# AffiliateCommission.UpdateClosedPositionTrackingEligibility

> Marks a closed position as eligible for commission processing by setting its Valid flag to 1.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Sets Valid = 1 on ClosedPosition by ClosedPositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure approves a specific closed position event for affiliate commission processing by setting its Valid flag to 1. When the commission engine evaluates a closed position and determines it meets all eligibility criteria - such as minimum position size, valid instrument, and no fraud flags - this procedure is called to mark the event as commission-eligible.

The Valid flag acts as a gatekeeper in the commission pipeline. Only closed positions with Valid = 1 are included in commission calculations and eventual payouts to affiliates. This separation of eligibility determination from commission calculation allows the two concerns to be handled independently.

This is the counterpart to ResetClosedPositionTrackingEligibility, which sets Valid = 0 to revoke eligibility. Together they form the eligibility toggle mechanism for the closed position commission domain, following the same pattern used for Credit and Registration events.

---

## 2. Business Logic

### 2.1 Eligibility Approval

**What**: Sets the Valid flag to 1 on a specific closed position record, approving it for commission processing.

**Columns/Parameters Involved**: @ClosedPositionID, ClosedPosition.Valid

**Rules**:
- Targets a single closed position record by ClosedPositionID
- Unconditionally sets Valid = 1 regardless of current state
- No conditional checks - caller is responsible for validating eligibility before calling

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ClosedPositionID | BIGINT | No | - | CODE-BACKED | Unique identifier of the closed position record to approve |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ClosedPositionID | AffiliateCommission.ClosedPosition | UPDATE target | Sets Valid = 1 on the ClosedPosition table |

### 5.2 Referenced By (other objects point to this)

Called by the commission processing engine when a closed position event passes eligibility validation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.UpdateClosedPositionTrackingEligibility
  --> AffiliateCommission.ClosedPosition (UPDATE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPosition | Table | UPDATE target - sets Valid = 1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Commission processing service | Application | Calls this SP to approve closed positions for commission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Approve a closed position for commission
```sql
EXEC AffiliateCommission.UpdateClosedPositionTrackingEligibility @ClosedPositionID = 456789;
```

### 8.2 Check eligibility state of a closed position
```sql
SELECT ClosedPositionID, Valid, IsProcessed, CID
FROM AffiliateCommission.ClosedPosition WITH (NOLOCK)
WHERE ClosedPositionID = 456789;
```

### 8.3 Count eligible vs ineligible closed positions
```sql
SELECT Valid, COUNT(*) AS RecordCount
FROM AffiliateCommission.ClosedPosition WITH (NOLOCK)
GROUP BY Valid;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-2448: CPA New Compensation Design (17/12/23)
- 19/7/23 Ran Ovadia: Remove old tblaff tables

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.UpdateClosedPositionTrackingEligibility | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.UpdateClosedPositionTrackingEligibility.sql*
