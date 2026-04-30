# AffiliateCommission.UpdateMissingFTD

> Marks a missing FTD (First Time Deposit) record as processed after it has been handled by the commission reconciliation pipeline.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Sets Processed = 1 on MissingFTD by GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is part of the FTD reconciliation workflow within the affiliate commission system. When the system detects that a customer's First Time Deposit was not properly captured or processed for commission - perhaps due to a timing issue, system failure, or data gap - a record is created in the MissingFTD table. After the missing FTD has been investigated and the commission has been retroactively calculated or the case has been resolved, this procedure marks the record as processed.

The Processed flag ensures that each missing FTD case is handled exactly once. The GetMissingFTD procedure retrieves unprocessed records (Processed = 0), and once the commission service has handled them, this procedure sets Processed = 1 to remove them from the active queue.

The procedure uses GCID (Global Customer ID) as the lookup key rather than CID, which aligns with the cross-system nature of FTD reconciliation where global identifiers are used to match across platforms.

---

## 2. Business Logic

### 2.1 Processing State Update

**What**: Sets Processed = 1 on a MissingFTD record identified by GCID, indicating the reconciliation case has been handled.

**Columns/Parameters Involved**: @GCID, MissingFTD.Processed

**Rules**:
- Targets records by GCID (Global Customer ID)
- Unconditionally sets Processed = 1
- May affect multiple records if a GCID has more than one missing FTD entry

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | No | - | CODE-BACKED | Global Customer ID identifying the missing FTD case to mark as processed |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | AffiliateCommission.MissingFTD | UPDATE target | Sets Processed = 1 on MissingFTD records |

### 5.2 Referenced By (other objects point to this)

Called by the FTD reconciliation service after a missing FTD case has been resolved, typically paired with GetMissingFTD which retrieves unprocessed cases.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.UpdateMissingFTD
  --> AffiliateCommission.MissingFTD (UPDATE)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.MissingFTD | Table | UPDATE target - sets Processed = 1 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| FTD reconciliation service | Application | Calls this SP after handling a missing FTD case |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Mark a missing FTD as processed
```sql
EXEC AffiliateCommission.UpdateMissingFTD @GCID = 900001;
```

### 8.2 Check unprocessed missing FTDs
```sql
SELECT GCID, Processed
FROM AffiliateCommission.MissingFTD WITH (NOLOCK)
WHERE Processed = 0;
```

### 8.3 Verify processing status for a specific GCID
```sql
SELECT GCID, Processed
FROM AffiliateCommission.MissingFTD WITH (NOLOCK)
WHERE GCID = 900001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

DDL comments reference:
- PART-4318: (27/4/25)

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.UpdateMissingFTD | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.UpdateMissingFTD.sql*
