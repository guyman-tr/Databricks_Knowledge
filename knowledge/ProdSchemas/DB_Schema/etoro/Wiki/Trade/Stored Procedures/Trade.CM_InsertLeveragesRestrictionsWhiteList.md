# Trade.CM_InsertLeveragesRestrictionsWhiteList

> Content Management procedure that inserts or updates per-customer leverage restriction overrides for specific instruments, allowing compliance teams to set custom max/min/default leverage values that override the platform defaults.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ErrorLog (OUTPUT) - validation error messages |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.CM_InsertLeveragesRestrictionsWhiteList is a Content Management (CM) procedure used by the back-office compliance or trading operations team to assign custom leverage restrictions to specific customers (by GCID) for specific instruments. Normally, leverage limits are configured globally per instrument, but some customers require exceptions - either stricter limits (for risk management or regulatory compliance) or elevated limits (for professional/institutional traders).

Without this procedure, all customers would share the same leverage limits per instrument. This enables per-customer overrides that are critical for regulatory compliance (e.g., ESMA leverage caps for retail clients, MiFID II categorization) and for managing high-risk or VIP accounts differently.

The procedure accepts lists of GCIDs and instrument IDs (or instrument type IDs to resolve all instruments of a type), validates that the requested leverage values actually exist in the system's leverage dictionary, and uses MERGE to insert-or-update each combination. Invalid GCIDs or instruments where the leverage values don't exist are logged to the @ErrorLog output parameter rather than causing the entire operation to fail.

---

## 2. Business Logic

### 2.1 Instrument Resolution

**What**: The procedure resolves the target instrument set from either a direct instrument ID list or an instrument type ID list.

**Columns/Parameters Involved**: `@InstrumentIDsListTable`, `@InstrumentTypeIDsListTable`

**Rules**:
- If @InstrumentIDsListTable has rows, those exact InstrumentIDs are used
- If @InstrumentIDsListTable is empty, all InstrumentIDs matching the @InstrumentTypeIDsListTable types are resolved from Trade.GetInstrument
- This allows bulk operations like "set leverage for ALL forex instruments for this customer"

### 2.2 Leverage Validation

**What**: Each requested leverage value (max, min, default) must exist as a valid leverage in Trade.ProviderInstrumentToLeverage for each instrument.

**Columns/Parameters Involved**: `@MaxLeverage`, `@MinLeverage`, `@DefaultLeverage`

**Rules**:
- For each instrument, the procedure checks that ALL three leverage values exist in ProviderInstrumentToLeverage (for ProviderID=1)
- Instruments where any of the three leverage values is invalid are excluded from the final set
- Excluded instrument IDs are written to @ErrorLog
- The validation uses a COUNT(*) = @NumOfDistinctValues pattern to ensure all values match

### 2.3 GCID Validation and MERGE

**What**: Each GCID is validated against Customer.CustomerStatic, then a MERGE upserts the whitelist entries.

**Columns/Parameters Involved**: `@GCIDsListTable`, Trade.LeveragesRestrictionsWhiteList

**Rules**:
- Invalid GCIDs (not found in Customer.CustomerStatic) are logged to @ErrorLog and skipped
- Valid GCIDs get a MERGE: if the GCID+InstrumentID combination already exists, UPDATE the leverage values; if not, INSERT
- Processing iterates through GCIDs one at a time using a WHILE loop (highest CID first, descending)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxLeverage | INT | NO | - | CODE-BACKED | Maximum leverage multiplier to allow for this customer/instrument combination. Must exist in Dictionary.Leverage via ProviderInstrumentToLeverage. E.g., 30 for 30x leverage. |
| 2 | @MinLeverage | INT | NO | - | CODE-BACKED | Minimum leverage multiplier. Must exist in Dictionary.Leverage. Ensures the customer cannot select a leverage below this threshold. |
| 3 | @DefaultLeverage | INT | NO | - | CODE-BACKED | Default leverage value pre-selected for this customer/instrument. Must be between Min and Max (validation is on existence, not range order). |
| 4 | @Comments | VARCHAR(500) | NO | - | CODE-BACKED | Free-text comments explaining why this override was created (e.g., "Professional client - elevated leverage per MiFID II"). Stored in LeveragesRestrictionsWhiteList.Comments. |
| 5 | @GCIDsListTable | Trade.CidList (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing the list of Global Customer IDs (GCIDs) to apply leverage restrictions to. Each GCID is validated against Customer.CustomerStatic. |
| 6 | @InstrumentIDsListTable | Trade.InstrumentIDsTbl (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing specific instrument IDs. If populated, these exact instruments are used. If empty, instruments are resolved from @InstrumentTypeIDsListTable. |
| 7 | @InstrumentTypeIDsListTable | Trade.InstrumentIDsTbl (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing instrument type IDs. Used only when @InstrumentIDsListTable is empty - resolves all instruments of these types from Trade.GetInstrument. |
| 8 | @ErrorLog | VARCHAR(MAX) | YES | - | CODE-BACKED | OUTPUT parameter. Accumulates validation errors: instrument IDs where leverage values were invalid, and GCIDs that don't exist in CustomerStatic. Returns NULL if no errors. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MERGE target | Trade.LeveragesRestrictionsWhiteList | Writer | Inserts or updates per-customer leverage restriction override records |
| Leverage validation | Trade.ProviderInstrumentToLeverage | Lookup | Validates that requested leverage values exist for each instrument (ProviderID=1) |
| Leverage validation | Dictionary.Leverage | Lookup | Joined to ProviderInstrumentToLeverage to match leverage values |
| Instrument resolution | Trade.GetInstrument | Reader | Resolves instrument IDs from instrument type IDs when direct list is empty |
| GCID validation | Customer.CustomerStatic | Lookup | Validates that each GCID exists before creating whitelist entries |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Likely called from Content Management UI or back-office tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.CM_InsertLeveragesRestrictionsWhiteList (procedure)
+-- Trade.LeveragesRestrictionsWhiteList (table)
+-- Trade.ProviderInstrumentToLeverage (table)
+-- Dictionary.Leverage (table)
+-- Trade.GetInstrument (view/table)
+-- Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LeveragesRestrictionsWhiteList | Table | MERGE target for leverage override records |
| Trade.ProviderInstrumentToLeverage | Table | Validates leverage values per instrument |
| Dictionary.Leverage | Table | Leverage value dictionary joined for validation |
| Trade.GetInstrument | View/Table | Resolves instruments from type IDs |
| Customer.CustomerStatic | Table | GCID existence validation |
| Trade.CidList | User Defined Type | TVP type for GCID list parameter |
| Trade.InstrumentIDsTbl | User Defined Type | TVP type for instrument ID list parameters |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CM_UpdateLeveragesRestrictionsWhiteList | Stored Procedure | Companion procedure for updating existing whitelist entries |
| Trade.CM_DeleteLeveragesRestrictionsWhiteList | Stored Procedure | Companion procedure for deleting whitelist entries |
| Trade.CM_GetLeveragesRestrictionsWhiteList | Stored Procedure | Companion procedure for reading whitelist entries |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check existing whitelist entries for a customer
```sql
SELECT *
FROM   Trade.LeveragesRestrictionsWhiteList WITH (NOLOCK)
WHERE  GCID = 12345
```

### 8.2 Verify leverage values exist for an instrument
```sql
SELECT pitl.InstrumentID, l.Value AS LeverageValue
FROM   Trade.ProviderInstrumentToLeverage pitl WITH (NOLOCK)
       JOIN Dictionary.Leverage l WITH (NOLOCK) ON pitl.LeverageID = l.LeverageID
WHERE  pitl.ProviderID = 1
       AND pitl.InstrumentID = 1001
ORDER BY l.Value
```

### 8.3 Find instruments by type
```sql
SELECT InstrumentID, InstrumentTypeID
FROM   Trade.GetInstrument WITH (NOLOCK)
WHERE  InstrumentTypeID IN (1, 2, 3)
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HLD COAIL-276: Appropriateness scoring mechanism](https://etoro-jira.atlassian.net/wiki/spaces/CR/pages/897777665) | Confluence | Context on leverage restrictions as part of regulatory appropriateness scoring |

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.CM_InsertLeveragesRestrictionsWhiteList | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.CM_InsertLeveragesRestrictionsWhiteList.sql*
