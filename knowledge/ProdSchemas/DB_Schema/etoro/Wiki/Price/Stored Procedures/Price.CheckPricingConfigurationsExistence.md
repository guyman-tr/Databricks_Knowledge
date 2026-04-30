# Price.CheckPricingConfigurationsExistence

> Existence check procedure that returns a BIT indicating whether a pricing configuration row exists for the given instrument in Price.PricingConfigurations.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID (existence check input) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.CheckPricingConfigurationsExistence answers: "Does instrument X have a pricing configuration?" It performs a single EXISTS check on Price.PricingConfigurations and returns a BIT (1=exists, 0=does not exist) as IsPricingConfigurationsExists.

The procedure exists to provide a clean, typed existence check to callers that need to gate logic on whether a pricing configuration is present before attempting an INSERT (via Price.InsertPricingConfiguration) or before assuming an instrument is fully configured in the pricing engine. Without a dedicated existence check, callers would need to either issue raw SELECTs or attempt INSERTs and catch duplicate key violations.

Called by external pricing management services or admin tools when provisioning new instruments or validating configuration completeness. Returns a single-row, single-column result set with a BIT - usable directly by ORMs, application code, and diagnostic scripts.

---

## 2. Business Logic

### 2.1 EXISTS Pattern - Efficient Presence Check

**What**: Uses EXISTS (SELECT 1 FROM ...) rather than COUNT or SELECT, ensuring minimal I/O: SQL Server short-circuits on first matching row and does not scan the entire table.

**Columns/Parameters Involved**: `@InstrumentID`, `IsPricingConfigurationsExists`

**Rules**:
- EXISTS (SELECT 1 FROM Price.PricingConfigurations WHERE InstrumentID = @InstrumentID): returns TRUE on first match, FALSE if no rows found
- CASE WHEN EXISTS ... THEN 1 ELSE 0 END: converts EXISTS boolean to integer
- CAST(... AS BIT): promotes to typed BIT for clean consumer handling
- Output column aliased as IsPricingConfigurationsExists: explicit name for ORM binding
- Result: single-row, single-column result set (not a scalar RETURN or OUTPUT parameter)
- Uses the clustered PK on InstrumentID -> single seek operation, O(1) performance regardless of table size

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | BIGINT | IN | - | CODE-BACKED | The instrument identifier to check. Note: declared as BIGINT (wider than Price.PricingConfigurations.InstrumentID which is INT). Safe for forward-compatibility with larger instrument IDs. Used in WHERE InstrumentID = @InstrumentID against the clustered PK. |

**Output result set:**

| # | Column | Type | Nullable | Confidence | Description |
|---|--------|------|----------|------------|-------------|
| 1 | IsPricingConfigurationsExists | BIT | NO | CODE-BACKED | 1 = a row exists in Price.PricingConfigurations for this InstrumentID; 0 = no configuration exists. Returned as a BIT (CAST from CASE expression). Single-row, single-column result set. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Price.PricingConfigurations | READER (EXISTS check) | Checks for the existence of a pricing configuration row for this instrument |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no SQL callers found within the Price schema (called by external pricing management services).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.CheckPricingConfigurationsExistence (procedure)
└── Price.PricingConfigurations (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.PricingConfigurations | Table | EXISTS check - scans clustered PK index for InstrumentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL callers found in Price schema | - | Called by external pricing management services |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. SET NOCOUNT ON suppresses row-count messages. No error handling. Parameter type mismatch: @InstrumentID declared as BIGINT but PricingConfigurations.InstrumentID is INT - implicit conversion occurs; safe because BIGINT values within INT range are handled transparently.

---

## 8. Sample Queries

### 8.1 Check if a specific instrument has a pricing configuration

```sql
EXEC Price.CheckPricingConfigurationsExistence @InstrumentID = 1;
-- Returns: IsPricingConfigurationsExists = 1 (EUR/USD is configured)
```

### 8.2 Check for an instrument that may not be configured

```sql
EXEC Price.CheckPricingConfigurationsExistence @InstrumentID = 999999;
-- Returns: IsPricingConfigurationsExists = 0 if not configured
```

### 8.3 Equivalent inline query (for debugging or batch checking)

```sql
SELECT
    @InstrumentID AS InstrumentID,
    CAST(
        CASE
            WHEN EXISTS (SELECT 1 FROM Price.PricingConfigurations WITH (NOLOCK) WHERE InstrumentID = @InstrumentID)
            THEN 1 ELSE 0
        END AS BIT
    ) AS IsPricingConfigurationsExists;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.CheckPricingConfigurationsExistence | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.CheckPricingConfigurationsExistence.sql*
