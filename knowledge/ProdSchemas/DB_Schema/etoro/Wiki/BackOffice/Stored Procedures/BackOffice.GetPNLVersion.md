# BackOffice.GetPNLVersion

> Returns the P&L calculation version and conversion rates (initial and closing) for a specific trading position - used by BackOffice agents to diagnose P&L calculation methodology and FX conversion rate disputes for individual positions.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns key metadata about how a specific trading position's P&L (Profit and Loss) was calculated: the calculation version applied, and the FX conversion rates used at position open (InitConversionRate) and close (EndConversionRate).

eToro uses versioned P&L calculation methodologies, particularly important for multi-currency accounts where positions in non-USD instruments must be converted to USD for P&L reporting. BackOffice agents use this data to:
- Diagnose customer disputes about P&L results
- Verify which P&L methodology version was active when a position closed
- Confirm FX rates applied to a specific position

**Permission**: EXECUTE granted to BOUser and BOFacade - BackOffice agents and the BackOffice facade service.

---

## 2. Business Logic

### 2.1 Position P&L Metadata Retrieval

**What**: Returns the P&L version and conversion rates for a specific position from the Trade data view.

**Columns/Parameters Involved**: @PositionID, Trade.GetPositionDataForExternalUse

**Rules**:
- Queries `Trade.GetPositionDataForExternalUse` - a view/function that exposes position data for external (BackOffice) consumption without granting direct access to Trade schema tables.
- `WHERE PositionID = @PositionID`: Returns exactly one row (position IDs are unique).
- Returns NULL columns if the position is not found.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | The trading position identifier. References Trade.Position.PositionID. |

**Output Columns**:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | INT | YES | - | CODE-BACKED | Customer account ID who owns this position. |
| 2 | PnLVersion | INT | YES | - | CODE-BACKED | The P&L calculation methodology version applied to this position. Higher versions indicate newer calculation approaches (e.g., multi-currency handling, precision improvements). Used to diagnose P&L discrepancies between old and new calculation methods. |
| 3 | InitConversionRate | DECIMAL | YES | - | CODE-BACKED | The FX conversion rate at position open (InitConversionRate). For USD-denominated positions this is 1. For non-USD instruments, this is the rate used to convert the opening value to USD. |
| 4 | EndConversionRate | DECIMAL | YES | - | CODE-BACKED | The FX conversion rate at position close (EndConversionRate). Used to convert the closing value to USD. For open positions, this may be NULL or a mark-to-market rate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All columns | Trade.GetPositionDataForExternalUse | Read (FROM) | View/function exposing position data to BackOffice schema |
| @PositionID | Trade.Position | Implicit | The underlying position table (accessed via the view) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BOUser | EXECUTE | Permission | BackOffice agent users (manual investigation) |
| BOFacade | EXECUTE | Permission | BackOffice facade service (application calls) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetPNLVersion (procedure)
+-- Trade.GetPositionDataForExternalUse (view/function)
    +-- Trade.Position (table - underlying data)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionDataForExternalUse | View/Function | FROM clause; exposes CID, PnLVersion, InitConversionRate, EndConversionRate |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BOUser (agents) | Permission | Ad-hoc investigation of P&L calculation version |
| BOFacade | External service | Application-layer calls for P&L dispute resolution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Trade.GetPositionDataForExternalUse | Security boundary | Exposes Trade schema data without granting BackOffice direct access to Trade.Position |

---

## 8. Sample Queries

### 8.1 Check P&L version for a specific position

```sql
EXEC BackOffice.GetPNLVersion @PositionID = 987654321
```

### 8.2 Query the underlying view directly

```sql
SELECT CID, PositionID, PnLVersion, InitConversionRate, EndConversionRate
FROM Trade.GetPositionDataForExternalUse
WHERE PositionID = 987654321;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 app service consumers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetPNLVersion | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetPNLVersion.sql*
