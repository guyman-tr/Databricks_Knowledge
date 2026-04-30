# Trade.InsertLeveragesRestrictionsWhiteList

> Inserts a single per-GCID custom leverage configuration row into Trade.LeveragesRestrictionsWhiteList, defining min/max/default leverage for a whitelisted user on a specific instrument outside standard country or customer-tier restrictions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @GCID + @InstrumentID - composite PK of target table |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertLeveragesRestrictionsWhiteList creates a custom leverage configuration for a specific whitelisted user (GCID) on a specific instrument. It writes directly to Trade.LeveragesRestrictionsWhiteList, which overrides standard leverage rules (LeverageRestrictionsByCountry, LeverageRestrictionsByCustomer) for the named user/instrument pair.

This procedure is the simple single-row insertion endpoint. Its bulk/merge equivalent is Trade.CM_InsertLeveragesRestrictionsWhiteList which uses a TVP and MERGE pattern. This SP is used for individual VIP promotions or manual configuration management where a specific customer needs elevated or customized leverage limits that fall outside the standard rule engine.

Data flow: Called by a Configuration Management (CM) UI or admin workflow. The inserted row is then read by Trade.GetLeveragesRestrictionsWhiteList and Trade.GetCustomerRestrictionsWhiteList to present or apply the custom leverage configuration.

---

## 2. Business Logic

### 2.1 Direct INSERT - No Deduplication

**What**: Single row inserted directly into Trade.LeveragesRestrictionsWhiteList without existence check.

**Columns/Parameters Involved**: `@GCID`, `@InstrumentID`, `@MaxLeverage`, `@MinLeverage`, `@DefaultLeverage`

**Rules**:
- Straight INSERT: no IF NOT EXISTS guard and no MERGE.
- If (GCID, InstrumentID) already exists, the INSERT will fail with a PK violation (the table PK is CLUSTERED on GCID, InstrumentID).
- Callers must validate uniqueness before calling, or use Trade.CM_InsertLeveragesRestrictionsWhiteList (MERGE upsert) for idempotent behavior.
- Comments and LastUpdateDate columns in the table use their column defaults (NULL and GETUTCDATE() respectively) - not set by this procedure.
- Leverage semantics: MinLeverage <= DefaultLeverage <= MaxLeverage is expected; no CHECK constraint enforces this.

**Diagram**:
```
EXEC InsertLeveragesRestrictionsWhiteList
    @GCID=1001, @InstrumentID=9, @MaxLeverage=400, @MinLeverage=2, @DefaultLeverage=50
         |
         v
   INSERT Trade.LeveragesRestrictionsWhiteList
   (GCID, InstrumentID, MaxLeverage, MinLeverage, DefaultLeverage)
         |
         v
   Trade.GetLeveragesRestrictionsWhiteList
   --> Returns custom leverage range for this GCID/Instrument
         |
         v
   Leverage selection UI: offer 2x-400x range, default 50x for GCID 1001 / Instrument 9
```

### 2.2 Custom Leverage vs Standard Rules

**What**: Whitelisted entries allow users to exceed standard regulatory/tier leverage limits.

**Rules**:
- Standard leverage rules are stored in LeverageRestrictionsByCountry and LeverageRestrictionsByCustomer.
- Whitelist entries are for approved exceptions: VIP users, institutional accounts, or manual promotions.
- The MaxLeverage/MinLeverage columns bound the allowed leverage range; DefaultLeverage is pre-selected.
- No expiry date on the whitelist entry - it remains active until deleted via Trade.CM_DeleteLeveragesRestrictionsWhiteList.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | INT | NO | - | CODE-BACKED | Group Customer ID (GCID) of the user receiving the custom leverage whitelist entry. Must be a valid GCID. Becomes the PK first component in LeveragesRestrictionsWhiteList (GCID, InstrumentID). |
| 2 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument for which the custom leverage rule applies. FK to Trade.Instrument.InstrumentID. Becomes the PK second component in LeveragesRestrictionsWhiteList. |
| 3 | @MaxLeverage | INT | NO | - | CODE-BACKED | Maximum leverage the whitelisted user may select for this instrument. Upper bound of the allowed leverage range. |
| 4 | @MinLeverage | INT | NO | - | CODE-BACKED | Minimum leverage the whitelisted user may select for this instrument. Lower bound of the allowed leverage range. |
| 5 | @DefaultLeverage | INT | NO | - | CODE-BACKED | Default/pre-selected leverage for this instrument for the whitelisted user. Should satisfy MinLeverage <= DefaultLeverage <= MaxLeverage. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID + @InstrumentID | Trade.LeveragesRestrictionsWhiteList | Write (INSERT) | Inserts the custom leverage configuration row |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by configuration management (CM) tooling for individual whitelist entries.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertLeveragesRestrictionsWhiteList (procedure)
+-- Trade.LeveragesRestrictionsWhiteList (table) - INSERT target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LeveragesRestrictionsWhiteList | Table | Single-row INSERT target |

### 6.2 Objects That Depend On This

No dependents found in stored procedures. Called externally by CM admin tooling.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK violation risk | PK constraint | No dedup guard - (GCID, InstrumentID) PK enforced by target table |
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| Auto-commit | Transaction | No explicit transaction; single INSERT is atomic |

---

## 8. Sample Queries

### 8.1 Whitelist a customer for custom leverage on a specific instrument

```sql
EXEC Trade.InsertLeveragesRestrictionsWhiteList
    @GCID = 1001,
    @InstrumentID = 9,       -- e.g., EUR/USD
    @MaxLeverage = 400,
    @MinLeverage = 2,
    @DefaultLeverage = 50;
```

### 8.2 Verify the inserted whitelist entry

```sql
SELECT GCID, InstrumentID, MinLeverage, MaxLeverage, DefaultLeverage, LastUpdateDate
FROM   Trade.LeveragesRestrictionsWhiteList WITH (NOLOCK)
WHERE  GCID = 1001 AND InstrumentID = 9;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertLeveragesRestrictionsWhiteList | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertLeveragesRestrictionsWhiteList.sql*
