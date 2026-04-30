# Trade.DividendsGetMirrorState

> Returns the active/inactive state of mirrors (copy-trade relationships) for a list of MirrorIDs, used during dividend processing to determine mirror eligibility.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorIDs |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

During dividend payment processing, the system needs to know whether a copy-trade mirror is still active. If a mirror is active, dividend payments may need to flow through the copy-trade hierarchy (leader → copier). If inactive, the position is treated independently. This simple lookup procedure provides the **IsActive status for a batch of mirrors**, enabling the dividend service to branch its payment logic accordingly.

---

## 2. Business Logic

### 2.1 Mirror State Lookup

**What**: Returns MirrorID and IsActive for each mirror in the input list.

**Columns/Parameters Involved**: `Trade.Mirror.MirrorID`, `Trade.Mirror.IsActive`

**Rules**:
- INNER JOIN @MirrorIDs TVP against Trade.Mirror on MirrorID = Id
- Returns MirrorID and IsActive columns
- Uses NOLOCK hint for non-blocking reads
- Mirrors not found in Trade.Mirror are silently excluded (INNER JOIN)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorIDs | Trade.IdIntList (TVP) | READONLY | - | CODE-BACKED | List of mirror IDs to check. Joined against Trade.Mirror to retrieve active state. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorIDs | Trade.Mirror | Read | Looks up IsActive state |
| @MirrorIDs | Trade.IdIntList | UDT (TVP) | Integer list table type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Dividends service) | N/A | Application caller | Called during dividend payment processing to determine mirror eligibility |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DividendsGetMirrorState (procedure)
+-- Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Source for mirror active state |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: Read-only procedure with NOLOCK. Simple batch lookup pattern.

---

## 8. Sample Queries

### 8.1 Check mirror states manually

```sql
SELECT  MirrorID, IsActive
FROM    Trade.Mirror WITH (NOLOCK)
WHERE   MirrorID IN (100, 200, 300);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DividendsGetMirrorState | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DividendsGetMirrorState.sql*
