# dbo.UpdateSubAffiliateID

> Late-binding attribution procedure that retroactively updates SubAffiliateID (and optionally AffiliateID/DownloadID) across ALL commission tables and ClosedPositions for a given customer, enabling mobile registration attribution.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates attribution across 9 event/commission table pairs + ClosedPositions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.UpdateSubAffiliateID is a critical attribution procedure that solves the "late-binding" problem in mobile affiliate marketing. When customers register via mobile apps, the affiliate tracking parameters (SubAffiliateID, AffiliateID, DownloadID) may not be available at registration time. This procedure retroactively updates these values across ALL commission-related tables once the attribution data becomes available.

Without this procedure, mobile-originated customers would never be properly attributed to their referring affiliate, resulting in lost commissions and inaccurate reporting. It is the single point of retroactive attribution correction for the entire affiliate system.

The procedure updates 9 event/commission table pairs (Registrations, Leads, CPA, Bonuses, Chargebacks, CopyTraders, FirstPositions, Sales) plus the ClosedPositions view, using TRY/CATCH blocks for each to ensure partial failures don't block other updates. Error messages are collected in a temp table and returned to the caller.

---

## 2. Business Logic

### 2.1 Comprehensive Cross-Table Attribution Update

**What**: Updates SubAffiliateID (and optionally AffiliateID/DownloadID) across all commission-related tables for a customer.

**Columns/Parameters Involved**: `@CID`, `@SubAffiliateID`, `@AffiliateID`, `@DownloadID`

**Rules**:
- For each event type, updates BOTH the event table AND the commission table
- Only updates unpaid commissions (Paid=0) at Tier 1 - does not retroactively change already-paid commissions
- If @AffiliateID is provided: updates both SubAffiliateID AND AffiliateID (full re-attribution)
- If @AffiliateID is NULL: updates only SubAffiliateID (tracking tag correction)
- If @DownloadID is provided: also updates DownloadID on event tables
- ClosedPositions: updates SubSerialID (=SubAffiliateID) and SerialID (=AffiliateID)
- Each table update is wrapped in TRY/CATCH - failure on one table does not block others
- Returns a result set of any errors encountered

### 2.2 Tables Updated

**Event + Commission pairs** (each pair updated in sequence):
1. tblaff_Registrations + tblaff_Registrations_Commissions
2. tblaff_Leads + tblaff_Leads_Commissions
3. tblaff_CPA + tblaff_CPA_Commissions
4. tblaff_Bonuses + tblaff_Bonuses_Commissions
5. tblaff_Chargebacks + tblaff_Chargebacks_Commissions
6. tblaff_CopyTraders + tblaff_CopyTraders_Commissions
7. tblaff_FirstPositions + tblaff_FirstPositions_Commissions
8. tblaff_Sales + tblaff_Sales_Commissions
9. ClosedPositions (view -> ClosedPositionsTbl)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @CID | int | IN | - | VERIFIED | Customer ID to update attribution for. Matched against Optional3/OriginalCID columns in event tables, and CID in ClosedPositions. |
| 2 | @SubAffiliateID | nvarchar(1024) | IN | - | VERIFIED | The sub-affiliate tracking tag to set. Applied to SubAffiliateID in commission tables and SubSerialID in ClosedPositions. |
| 3 | @AffiliateID | int | IN | NULL | VERIFIED | Optional: the affiliate ID to re-attribute to. When provided, updates AffiliateID in commission tables and SerialID in ClosedPositions. When NULL, only SubAffiliateID is updated. |
| 4 | @DownloadID | int | IN | NULL | VERIFIED | Optional: download tracking ID. When provided, updates DownloadID on event tables (Registrations, Leads, CPA, Bonuses, Chargebacks, CopyTraders, FirstPositions, Sales). Added by Dror Meiri (2015-08-09). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE | dbo.tblaff_Registrations_Commissions | MODIFIER | Updates SubAffiliateID/AffiliateID for Tier 1 unpaid |
| UPDATE | dbo.tblaff_Registrations | MODIFIER | Updates DownloadID |
| UPDATE | dbo.tblaff_Leads_Commissions | MODIFIER | Same pattern |
| UPDATE | dbo.tblaff_Leads | MODIFIER | Updates DownloadID |
| UPDATE | dbo.tblaff_CPA_Commissions | MODIFIER | Same pattern |
| UPDATE | dbo.tblaff_CPA | MODIFIER | Updates DownloadID |
| UPDATE | dbo.tblaff_Bonuses_Commissions | MODIFIER | Same pattern |
| UPDATE | dbo.tblaff_Bonuses | MODIFIER | Updates DownloadID |
| UPDATE | dbo.tblaff_Chargebacks_Commissions | MODIFIER | Same pattern |
| UPDATE | dbo.tblaff_Chargebacks | MODIFIER | Updates DownloadID |
| UPDATE | dbo.tblaff_CopyTraders_Commissions | MODIFIER | Same pattern |
| UPDATE | dbo.tblaff_CopyTraders | MODIFIER | Updates DownloadID |
| UPDATE | dbo.tblaff_FirstPositions_Commissions | MODIFIER | Same pattern |
| UPDATE | dbo.tblaff_FirstPositions | MODIFIER | Updates DownloadID |
| UPDATE | dbo.tblaff_Sales_Commissions | MODIFIER | Same pattern |
| UPDATE | dbo.tblaff_Sales | MODIFIER | Updates DownloadID |
| UPDATE | dbo.ClosedPositions (view) | MODIFIER | Updates SubSerialID and SerialID |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by the mobile attribution service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.UpdateSubAffiliateID (procedure)
  +-- dbo.tblaff_Registrations_Commissions + tblaff_Registrations (tables)
  +-- dbo.tblaff_Leads_Commissions + tblaff_Leads (tables)
  +-- dbo.tblaff_CPA_Commissions + tblaff_CPA (tables)
  +-- dbo.tblaff_Bonuses_Commissions + tblaff_Bonuses (tables)
  +-- dbo.tblaff_Chargebacks_Commissions + tblaff_Chargebacks (tables)
  +-- dbo.tblaff_CopyTraders_Commissions + tblaff_CopyTraders (tables)
  +-- dbo.tblaff_FirstPositions_Commissions + tblaff_FirstPositions (tables)
  +-- dbo.tblaff_Sales_Commissions + tblaff_Sales (tables)
  +-- dbo.ClosedPositions (view -> ClosedPositionsTbl)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| 9 event tables | Tables | JOIN source for CID matching |
| 9 commission tables | Tables | UPDATE target for attribution |
| dbo.ClosedPositions | View | UPDATE target for position attribution |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes
N/A for stored procedure.

### 7.2 Constraints
N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Update sub-affiliate tracking tag only
```sql
EXEC dbo.UpdateSubAffiliateID @CID = 12345, @SubAffiliateID = 'campaign_2024_q1'
```

### 8.2 Full re-attribution (affiliate + sub-affiliate + download)
```sql
EXEC dbo.UpdateSubAffiliateID @CID = 12345, @SubAffiliateID = 'mobile_app',
     @AffiliateID = 5678, @DownloadID = 9012
```

### 8.3 Check errors from attribution update
```sql
DECLARE @Results TABLE (Tbl sysname, Msg nvarchar(4000))
INSERT INTO @Results EXEC dbo.UpdateSubAffiliateID @CID = 12345, @SubAffiliateID = 'test'
SELECT * FROM @Results WHERE Msg IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 9.0/10*
*Object: dbo.UpdateSubAffiliateID | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.UpdateSubAffiliateID.sql*
