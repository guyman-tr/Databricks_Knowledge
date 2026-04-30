# Trade.UpdateInstrumentsAvailableLeverages

> Replaces the full leverage configuration for a batch of instruments: deletes all existing leverage rows for those instruments, re-expands the leverage range (MinLeverageID to MaxLeverageID) into individual rows, then calls Trade.SyncLeveragesList per instrument to synchronize downstream systems.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentNewConfigTable (TVP - Trade.InstrumentAvailableLeveragesConfigTable) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateInstrumentsAvailableLeverages is the write path for reconfiguring the set of available leverage values for trading instruments. `Trade.ProviderInstrumentToLeverage` stores one row per (ProviderID, InstrumentID, LeverageID) triplet - each row representing one available leverage option for that instrument with that provider. This procedure replaces the entire leverage set for a batch of instruments in one atomic transaction.

The process is replace-all: the procedure first deletes ALL existing leverage rows for the target instruments, then re-expands the new leverage range from the TVP. The range is defined by MinLeverageID and MaxLeverageID (IDs into `Dictionary.Leverage`), and every leverage value between min and max (inclusive, by value) becomes a separate row. The DefaultLeverageID determines which of these rows gets the IsDefault=1 flag.

After repopulating the rows, `Trade.SyncLeveragesList` is called per instrument to push the updated configuration to the connected trading engine or downstream systems.

This is a complete configuration replacement - there is no merge or partial update. If only one leverage needs changing, all leverages for that instrument are still deleted and re-inserted.

---

## 2. Business Logic

### 2.1 Delete-All Before Reinsert

**What**: All existing leverage rows for the target instruments are deleted before any new rows are inserted.

**Columns/Parameters Involved**: `Trade.ProviderInstrumentToLeverage.InstrumentID`, `@InstrumentNewConfigTable.InstrumentID`

**Rules**:
- `DELETE FROM Trade.ProviderInstrumentToLeverage WHERE InstrumentID IN (SELECT InstrumentID FROM @InstrumentNewConfigTable)`
- Deletes ALL rows for those InstrumentIDs regardless of ProviderID or LeverageID
- This is a full replacement pattern - no merge or delta logic
- Runs inside BEGIN TRANSACTION (atomicity with subsequent INSERT)

### 2.2 Leverage Range Expansion

**What**: Each TVP row defines a leverage range by MinLeverageID and MaxLeverageID. The procedure expands this range into individual rows by joining Dictionary.Leverage for all leverage values between min and max.

**Columns/Parameters Involved**: `@InstrumentNewConfigTable.InstrumentID`, `.MinLeverageID`, `.MaxLeverageID`, `.DefaultLeverageID`, `Dictionary.Leverage.LeverageID`, `.Value`

**Rules**:
- JOIN Dictionary.Leverage DMIN ON MinLeverageID = DMIN.LeverageID (resolves min Value)
- JOIN Dictionary.Leverage DMAX ON MaxLeverageID = DMAX.LeverageID (resolves max Value)
- JOIN Dictionary.Leverage DL ON DL.Value >= DMIN.Value AND DL.Value <= DMAX.Value (expands range)
- Result: one INSERT row per leverage value in [MinValue, MaxValue]
- ProviderID=1 (hardcoded - provider 1 is the primary/internal trading provider)
- Percentage=0, LeverageType=1 (fixed constants for standard leverages)
- IsDefault: `CASE WHEN DefaultLeverageID = DL.LeverageID THEN 1 ELSE 0 END`

**Example**:
```
TVP: InstrumentID=100, MinLeverageID=2 (Value=2), MaxLeverageID=10 (Value=200), DefaultLeverageID=5 (Value=30)
Dictionary.Leverage values in [2..200]: 2, 5, 10, 15, 20, 25, 30, 50, 100, 200 (example)
Result: 10 rows inserted, each with their LeverageID, IsDefault=1 only for LeverageID=5
```

### 2.3 SyncLeveragesList Call Per Instrument

**What**: After repopulating the leverage rows, Trade.SyncLeveragesList is called once per instrument to synchronize the changes downstream.

**Columns/Parameters Involved**: `@InstrumentID` (iterated from TVP)

**Rules**:
- WHILE loop iterates instruments in ascending InstrumentID order using TOP 1 + WHERE InstrumentID > @PrevInstrumentID pattern
- For each instrument: `EXECUTE Trade.SyncLeveragesList 1, @InstrumentID` (ProviderID=1 hardcoded)
- Each call outputs `@InstrumentID AS InstrumentIDForSync` (a diagnostic SELECT, not a result set)
- Loop continues until no more instruments remain in the TVP

### 2.4 Transaction and Error Handling

**What**: The entire DELETE + INSERT + sync sequence runs inside a single explicit transaction.

**Rules**:
- `BEGIN TRANSACTION` at start; `COMMIT TRANSACTION` at end of try block
- CATCH: `IF @@TRANCOUNT=1 ROLLBACK ELSE COMMIT` (same unusual pattern as other Trade schema SPs; the ELSE COMMIT is a code template artifact)
- RETURN 0 on success
- `@LocalError = ERROR_NUMBER()` is set but not used after THROW (dead code)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentNewConfigTable | Trade.InstrumentAvailableLeveragesConfigTable READONLY | NO | - | CODE-BACKED | TVP defining the new leverage configuration for a batch of instruments. Each row: InstrumentID (NOT NULL, the instrument to reconfigure), MinLeverageID (NOT NULL, FK to Dictionary.Leverage - lower bound of range), MaxLeverageID (NOT NULL, FK to Dictionary.Leverage - upper bound of range), DefaultLeverageID (NOT NULL, FK to Dictionary.Leverage - which leverage in the range is the default). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentNewConfigTable | Trade.InstrumentAvailableLeveragesConfigTable | TVP | Input parameter type (InstrumentID, MinLeverageID, MaxLeverageID, DefaultLeverageID) |
| DELETE + INSERT target | Trade.ProviderInstrumentToLeverage | Modifier | Full replacement of leverage rows for target instruments |
| Range expansion | Dictionary.Leverage | Read | Resolves leverage values within [MinLeverageID, MaxLeverageID] range |
| EXEC | Trade.SyncLeveragesList | Caller | Synchronizes leverage changes downstream per instrument |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - PROD_BIadmins role has EXECUTE permission. Invoked by leverage configuration tooling or admin scripts.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentsAvailableLeverages (procedure)
+-- Trade.InstrumentAvailableLeveragesConfigTable (TVP type)
+-- Trade.ProviderInstrumentToLeverage (table)
+-- Dictionary.Leverage (table)
+-- Trade.SyncLeveragesList (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentAvailableLeveragesConfigTable | User Defined Type (TVP) | Input parameter type |
| Trade.ProviderInstrumentToLeverage | Table | DELETE + INSERT target for leverage rows |
| Dictionary.Leverage | Table | Range expansion - resolves all leverage values in [min, max] |
| Trade.SyncLeveragesList | Stored Procedure | Called per instrument to synchronize leverage configuration downstream |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins (DB role) | Permission grantee | Admin role with execute access; invoked by leverage configuration tooling |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Uses SET NOCOUNT ON, explicit BEGIN/COMMIT TRANSACTION, TRY/CATCH with THROW. ProviderID=1 and LeverageType=1 are hardcoded constants.

---

## 8. Sample Queries

### 8.1 Set available leverages for a batch of instruments
```sql
DECLARE @Config Trade.InstrumentAvailableLeveragesConfigTable;

INSERT INTO @Config (InstrumentID, MinLeverageID, MaxLeverageID, DefaultLeverageID)
VALUES
  (1001, 2, 20, 10),   -- instrument 1001: leverages 2x to 20x, default 10x
  (1002, 1, 10, 5);    -- instrument 1002: leverages 1x to 10x, default 5x

EXEC Trade.UpdateInstrumentsAvailableLeverages
    @InstrumentNewConfigTable = @Config;
```

### 8.2 Check current leverages for an instrument
```sql
SELECT pil.InstrumentID, pil.ProviderID, pil.LeverageID,
       dl.Value AS LeverageValue, pil.IsDefault
FROM   Trade.ProviderInstrumentToLeverage pil WITH (NOLOCK)
JOIN   Dictionary.Leverage dl WITH (NOLOCK) ON dl.LeverageID = pil.LeverageID
WHERE  pil.InstrumentID = 1001
ORDER  BY dl.Value;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentsAvailableLeverages | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentsAvailableLeverages.sql*
