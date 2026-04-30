# Trade.GetCorporateInstrumentActions

> Returns all pending corporate actions for instruments, joining the instrument action schedule with the corporate action dictionary to provide action type context.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID, EffectiveDate, and CorporateActionType |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides the schedule of corporate actions (dividends, stock splits, mergers, etc.) that are pending for specific instruments. It joins the instrument-level action records with the corporate action dictionary to return the action type ID. This data feeds into the corporate action processing pipeline that adjusts positions, calculates dividend payouts, or handles stock split ratio changes.

Without this procedure, the system would not know which instruments have upcoming corporate actions and when they take effect, preventing timely processing of these events.

Data flow: Corporate action scheduler calls this procedure -> receives all instrument actions with effective dates and types -> schedules processing jobs for each action on or before the effective date.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a schedule data reader. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

None.

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | INT | - | - | CODE-BACKED | Financial instrument that has a pending corporate action. From Trade.CorporateInstrumentActions. |
| 2 | EffectiveDate | DATETIME | - | - | CODE-BACKED | Date when the corporate action takes effect. From Trade.CorporateInstrumentActions. |
| 3 | CorporateActionType | INT | - | - | CODE-BACKED | Corporate action type ID. Aliased from Dictionary.CorporateAction.CorporateActionTypeID. Joined via CorporateInstrumentActionType. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.CorporateInstrumentActions | Read | Source of instrument action schedule |
| CorporateInstrumentActionType | Dictionary.CorporateAction | JOIN | Resolves action type to dictionary entry |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Corporate Action Scheduler | EXEC | Caller | Loads pending corporate actions for processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCorporateInstrumentActions (procedure)
├── Trade.CorporateInstrumentActions (table)
└── Dictionary.CorporateAction (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CorporateInstrumentActions | Table | Source of instrument-level corporate action schedule |
| Dictionary.CorporateAction | Table | JOINed for corporate action type resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Corporate Action Scheduler | External | Loads action schedule for processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- No date filter - returns ALL actions regardless of date (past and future)
- INNER JOIN means instruments without a matching dictionary entry are excluded

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Trade.GetCorporateInstrumentActions;
```

### 8.2 Find upcoming corporate actions

```sql
SELECT tca.InstrumentID, tca.EffectiveDate,
       dca.CorporateActionTypeID, dca.Description
FROM Trade.CorporateInstrumentActions tca WITH (NOLOCK)
INNER JOIN Dictionary.CorporateAction dca WITH (NOLOCK)
    ON dca.CorporateActionTypeID = tca.CorporateInstrumentActionType
WHERE tca.EffectiveDate >= GETDATE()
ORDER BY tca.EffectiveDate;
```

### 8.3 Count actions by type

```sql
SELECT dca.Description, COUNT(*) AS ActionCount
FROM Trade.CorporateInstrumentActions tca WITH (NOLOCK)
INNER JOIN Dictionary.CorporateAction dca WITH (NOLOCK)
    ON dca.CorporateActionTypeID = tca.CorporateInstrumentActionType
GROUP BY dca.Description
ORDER BY COUNT(*) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCorporateInstrumentActions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCorporateInstrumentActions.sql*
