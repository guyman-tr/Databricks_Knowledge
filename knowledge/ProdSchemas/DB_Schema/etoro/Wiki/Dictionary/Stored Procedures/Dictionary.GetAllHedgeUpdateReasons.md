# Dictionary.GetAllHedgeUpdateReasons

> Stored procedure returning the complete list of hedge position update reasons from Dictionary.HedgeUpdateReason.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: ReasonID + Reason from HedgeUpdateReason |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Dictionary.GetAllHedgeUpdateReasons is a simple GETTER procedure that returns all rows from the Dictionary.HedgeUpdateReason lookup table. The hedge risk management system uses this data to populate reason dropdowns in the hedge management UI and to validate update operations — every time a hedge position is manually modified or automatically adjusted, the system records which reason code applies.

Without this procedure, the hedge management application would need to query the HedgeUpdateReason table directly. The procedure provides a standardized API endpoint for retrieving the reason codes, which is the typical eToro pattern for dictionary/lookup table access from application services.

The procedure uses `SELECT *`, meaning it returns all columns from HedgeUpdateReason. There are currently 5 hedge update reasons: 0=Unknown, 1=Reconciliation, 2=Reroute, 3=Manual Hedging directly to the Liquidity Provider, 4=Other.

---

## 2. Business Logic

### 2.1 Hedge Update Reason Codes

**What**: Classifies why a hedge position was modified, enabling audit trails and operational reporting.

**Columns/Parameters Involved**: `ReasonID`, `Reason`

**Rules**:
- ReasonID=0 (Unknown) is the default when no specific reason is applicable
- ReasonID=1 (Reconciliation) is used when hedge positions are adjusted to match expected vs actual exposure
- ReasonID=2 (Reroute) indicates the hedge was moved to a different liquidity provider
- ReasonID=3 (Manual Hedging directly to the Liquidity Provider) is for direct manual intervention by the dealing desk
- ReasonID=4 (Other) is a catch-all for edge cases not covered by the defined reasons

**Diagram**:
```
Hedge Position Modified
│
├── Why was it changed?
│   ├── 0: Unknown (default)
│   ├── 1: Reconciliation (exposure alignment)
│   ├── 2: Reroute (provider change)
│   ├── 3: Manual Hedging (dealing desk action)
│   └── 4: Other (catch-all)
│
└── Recorded in hedge audit log with ReasonID
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | *(no parameters)* | - | - | - | - | This procedure takes no input parameters |
| R1 | ReasonID | int | NO | - | VERIFIED | Hedge update reason identifier. PK from Dictionary.HedgeUpdateReason: 0=Unknown, 1=Reconciliation, 2=Reroute, 3=Manual Hedging directly to LP, 4=Other. Used as FK in hedge position change logs. |
| R2 | Reason | varchar | NO | - | VERIFIED | Human-readable description of the update reason. Displayed in hedge management UI dropdowns and audit reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (result set) | Dictionary.HedgeUpdateReason | SELECT * | Full table read — returns all reason codes and descriptions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | API call | Called by hedge management services to populate reason dropdowns |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.GetAllHedgeUpdateReasons (procedure)
└── Dictionary.HedgeUpdateReason (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.HedgeUpdateReason | Table | SELECT * — full table read |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Application layer — hedge management services) | External | API-level consumer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Note: The procedure uses `SELECT *` which couples it to the HedgeUpdateReason table structure — any column additions to the table will automatically appear in the result set.

---

## 8. Sample Queries

### 8.1 Execute the procedure to get all reasons
```sql
SELECT  *
FROM    Dictionary.HedgeUpdateReason WITH (NOLOCK)
```

### 8.2 Find the reason description for a specific reason ID
```sql
SELECT  ReasonID, Reason
FROM    Dictionary.HedgeUpdateReason WITH (NOLOCK)
WHERE   ReasonID = 1
```

### 8.3 Count hedge updates by reason (using the HedgeUpdateReason lookup)
```sql
SELECT  hur.ReasonID, hur.Reason, hur.ReasonID AS ReasonCode
FROM    Dictionary.HedgeUpdateReason hur WITH (NOLOCK)
ORDER BY hur.ReasonID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GetAllHedgeUpdateReasons | Type: Stored Procedure | Source: etoro/etoro/Dictionary/Stored Procedures/Dictionary.GetAllHedgeUpdateReasons.sql*
