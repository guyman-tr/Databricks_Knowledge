# Price.InsertLiquidityProviderPriceSource

> Inserts a new liquidity provider to price source mapping in Price.LiquidityProviderPriceSource, with three-step validation (LP exists, source exists, mapping not duplicate), optional CONTEXT_INFO audit tagging, and a return SELECT with human-readable names.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LiquidityProviderID, @PriceSourceID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.InsertLiquidityProviderPriceSource creates a new LP-to-price-source mapping: it declares which exchange or data venue (PriceSourceID) is the authoritative price origin for a given liquidity provider (LiquidityProviderID). This mapping is used for price attribution - when a price comes from a particular LP, the system can report it as originating from NASDAQ, LSE, CME, etc.

The procedure enforces the one-to-one constraint (each LP has exactly one price source) through an existence check before inserting: if a mapping already exists, it rejects the call and directs the caller to use Price.UpdateLiquidityProviderPriceSource instead. This prevents accidental overwrites via the insert path.

The `@AppLoginName` parameter enables application-level audit: if provided, it sets SQL Server's CONTEXT_INFO to the application user name before the INSERT. The temporal system versioning on Price.LiquidityProviderPriceSource (and any trigger/default that reads CONTEXT_INFO) then records this user in the AppLoginName column of the target table, allowing change attribution to the application user rather than just the database login.

After the INSERT, the procedure returns the newly inserted row enriched with the LP name and price source name - giving the caller confirmation of what was created with human-readable labels.

---

## 2. Business Logic

### 2.1 Three-Step Validation Guard

**What**: Three sequential existence checks before INSERT - any failure raises an error and returns without inserting.

**Columns/Parameters Involved**: `@LiquidityProviderID`, `@PriceSourceID`

**Rules**:
1. `IF NOT EXISTS (SELECT 1 FROM Trade.LiquidityProviders WHERE LiquidityProviderID = @LiquidityProviderID)` -> RAISERROR('LiquidityProviderID %d does not exist in Trade.LiquidityProviders', 16, 1, @LiquidityProviderID); RETURN
2. `IF NOT EXISTS (SELECT 1 FROM Dictionary.PriceSourceName WHERE PriceSourceID = @PriceSourceID)` -> RAISERROR('PriceSourceID %d does not exist in Dictionary.PriceSourceName', 16, 1, @PriceSourceID); RETURN
3. `IF EXISTS (SELECT 1 FROM Price.LiquidityProviderPriceSource WHERE LiquidityProviderID = @LiquidityProviderID)` -> RAISERROR('Mapping for LiquidityProviderID %d already exists. Use Update procedure instead.', 16, 1, @LiquidityProviderID); RETURN
- Severity 16 = state error (caller-correctable); not severity 11+ which would be system errors
- RAISERROR + RETURN pattern: no ROLLBACK needed (no transaction opened yet); simply rejects the call

### 2.2 CONTEXT_INFO Audit Tagging

**What**: @AppLoginName sets SQL Server session CONTEXT_INFO before INSERT for application-level audit trail.

**Columns/Parameters Involved**: `@AppLoginName`, `@OpsUserInfo`

**Rules**:
- Default: `@AppLoginName varchar(50) = ''` - empty string default means audit tagging is optional
- `IF @AppLoginName != ''`: only sets CONTEXT_INFO when a non-empty name is provided
- `DECLARE @OpsUserInfo VARBINARY(128) = CAST(@AppLoginName AS VARBINARY(128)); SET CONTEXT_INFO @OpsUserInfo`: converts the user name to binary and sets as session context
- CONTEXT_INFO is read by a trigger or default on Price.LiquidityProviderPriceSource (the table has an AppLoginName column per its CRUD API design) to capture application user identity at insert time
- This is the standard eToro audit pattern: CONTEXT_INFO carries the OPS/application user; DbLoginName carries the DB login

### 2.3 Insert and Return

**What**: Inserts the LP-to-source mapping and returns the created row with human-readable names.

**Columns/Parameters Involved**: `LiquidityProviderID`, `PriceSourceID`

**Rules**:
- `INSERT INTO Price.LiquidityProviderPriceSource (LiquidityProviderID, PriceSourceID) VALUES (@LiquidityProviderID, @PriceSourceID)`: minimal insert (no explicit DbLoginName/AppLoginName - handled by trigger/default reading CONTEXT_INFO)
- Return SELECT: `SELECT lp.LiquidityProviderID, lp.PriceSourceID, lprov.LiquidityProviderName, psn.Name AS PriceSourceName` FROM LiquidityProviderPriceSource JOIN LiquidityProviders JOIN PriceSourceName WHERE lp.LiquidityProviderID = @LiquidityProviderID
- The return SELECT re-reads the table after INSERT (confirming the row was written) and enriches with display names

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityProviderID | INT | NOT NULL | - | CODE-BACKED | The liquidity provider to create a price source mapping for. Must exist in Trade.LiquidityProviders; must not already have a mapping in Price.LiquidityProviderPriceSource. |
| 2 | @PriceSourceID | INT | NOT NULL | - | CODE-BACKED | The price source to associate with this LP. Must exist in Dictionary.PriceSourceName. Valid values: 0=eToro, 1=Xignite, 2=CME, 3=NASDAQ, 4=Chi-Ex, 5=LSE PLC, 6=Xetra, 7=Euronext, 8=DFM, 9=HKEX, 10=TMX, 11=ADX, 12=BME, 13=Nasdaq Nordic, 14=CBOE Japan, 15=SGX, 16=TWSE, 17=CBOE EU, 18=CBOE AUS, 19=Wiener Borse, 20=Prague SE, 21=Warsaw SE, 22=Budapest SE, 27=NSE, 28=Nasdaq Baltic, 29=KRX, 30=Blue Ocean. |
| 3 | @AppLoginName | VARCHAR(50) | YES | '' | CODE-BACKED | Application user name for audit trail. Set as CONTEXT_INFO before INSERT so the table's trigger/default can record it in AppLoginName column. Empty string (default) skips CONTEXT_INFO setting. |

**Result set columns** (4 columns, on success):

| # | Column | Description |
|---|--------|-------------|
| 1 | LiquidityProviderID | The LP ID of the newly created mapping (echoes @LiquidityProviderID). |
| 2 | PriceSourceID | The price source ID of the newly created mapping (echoes @PriceSourceID). |
| 3 | LiquidityProviderName | Human-readable LP name from Trade.LiquidityProviders. |
| 4 | PriceSourceName | Human-readable price source name from Dictionary.PriceSourceName (e.g., "NASDAQ", "CME", "eToro"). |

**On validation failure**: No result set; RAISERROR raised with severity 16.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @LiquidityProviderID | Trade.LiquidityProviders | VALIDATOR + READER | Existence check before insert; JOIN in return SELECT for LiquidityProviderName |
| @PriceSourceID | Dictionary.PriceSourceName | VALIDATOR + READER | Existence check before insert; JOIN in return SELECT for Name |
| LiquidityProviderID | Price.LiquidityProviderPriceSource | WRITER | INSERT of new mapping; duplicate check before insert; re-read in return SELECT |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (LP configuration API/OPS tool) | @LiquidityProviderID, @PriceSourceID | CALLER | Called when a new LP is set up and its price source needs to be declared |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.InsertLiquidityProviderPriceSource (procedure)
+-- Trade.LiquidityProviders (table) - validation: LP must exist
+-- Dictionary.PriceSourceName (table) - validation: price source must exist
+-- Price.LiquidityProviderPriceSource (table) - write target + duplicate check + return read
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviders | Table | Existence validation for @LiquidityProviderID; JOIN in return SELECT |
| Dictionary.PriceSourceName | Table | Existence validation for @PriceSourceID; JOIN in return SELECT |
| Price.LiquidityProviderPriceSource | Table | INSERT target; duplicate check (SELECT EXISTS); return SELECT after insert |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (LP configuration API) | External | Calls to register a new LP-to-price-source mapping |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

SET NOCOUNT ON. No explicit transaction (the INSERT is a single atomic statement). RAISERROR severity 16 is state-class (user error) - will propagate to the caller as an exception in .NET/app code. The duplicate-check condition is `WHERE LiquidityProviderID = @LiquidityProviderID` (not checking for the combination with PriceSourceID) - this correctly enforces the one-per-LP rule regardless of which PriceSourceID is supplied. CONTEXT_INFO is session-scoped: if the procedure errors after SET CONTEXT_INFO (which cannot happen since CONTEXT_INFO is set immediately before the INSERT), the CONTEXT_INFO would remain set for the session. Since the RAISERROR+RETURN guards occur before CONTEXT_INFO, this is not a practical concern.

---

## 8. Sample Queries

### 8.1 Insert a new LP-to-price-source mapping

```sql
EXEC Price.InsertLiquidityProviderPriceSource
    @LiquidityProviderID = 5,
    @PriceSourceID = 3,           -- NASDAQ
    @AppLoginName = 'ops_user@etoro.com';
-- Returns: LiquidityProviderID=5, PriceSourceID=3, LiquidityProviderName='...', PriceSourceName='NASDAQ'
```

### 8.2 Insert without audit (system/automated)

```sql
EXEC Price.InsertLiquidityProviderPriceSource
    @LiquidityProviderID = 5,
    @PriceSourceID = 3;
-- @AppLoginName defaults to '' - no CONTEXT_INFO set
```

### 8.3 Verify current mappings

```sql
SELECT lp.LiquidityProviderID, lp.PriceSourceID,
       lprov.LiquidityProviderName, psn.Name AS PriceSourceName
FROM Price.LiquidityProviderPriceSource lp WITH (NOLOCK)
JOIN Trade.LiquidityProviders lprov WITH (NOLOCK)
    ON lp.LiquidityProviderID = lprov.LiquidityProviderID
JOIN Dictionary.PriceSourceName psn WITH (NOLOCK)
    ON lp.PriceSourceID = psn.PriceSourceID;
-- Currently returns 0 rows (table is empty)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.InsertLiquidityProviderPriceSource | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.InsertLiquidityProviderPriceSource.sql*
