# Price.CleanUnmappedInstrumentRateSources

> Maintenance procedure that removes orphaned rows from Price.InstrumentRateSources - deletes rate source assignments whose backing liquidity account is either inactive or no longer mapped via LiquidityAccountToInstrument or PCSToLiquidityAccount.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (no parameters - operates on entire table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.CleanUnmappedInstrumentRateSources is a housekeeping procedure for Price.InstrumentRateSources. It removes rate source priority entries that have become invalid because the liquidity account backing them is either:
1. No longer mapped to the instrument in LiquidityAccountToInstrument (instrument-account link removed), OR
2. No longer assigned to any PCS instance (PCSToLiquidityAccount link removed), OR
3. The liquidity account is marked inactive (IsActive=0 in Trade.LiquidityAccounts)

The InstrumentRateSources table records which rate sources (and at what priority) each instrument should use. If a liquidity account is deactivated or an instrument-account mapping is removed, the InstrumentRateSources entries that relied on that account become orphaned - they reference a rate source that the system can no longer actually route through. This procedure finds and deletes those orphans.

Primary caller: Price.DelistInstrument executes this procedure after removing an instrument from liquidity account mappings. The call ensures that delisting an instrument also cleans up its InstrumentRateSources configuration without leaving dangling priority assignments.

---

## 2. Business Logic

### 2.1 DELETE 1 - Remove IRS Rows Not Backed by Active Instrument-Account Mapping

**What**: Removes InstrumentRateSources rows where no active non-execution liquidity account is mapped to both the instrument (via LiquidityAccountToInstrument) AND carries the matching AccountRateSourceID.

**Columns/Parameters Involved**: `InstrumentRateSourceID`, `AccountRateSourceID`, `InstrumentID`, `IsActive`

**Rules**:
- Build the valid set: LATI -> TLA (non-execution, LiquidityAccountTypeID <> 2) -> IRS (matching on ARS + InstrumentID)
- RIGHT JOIN to IRS2 (full IRS table): all IRS rows are evaluated, not just those with matches
- Delete condition: IRS.InstrumentRateSourceID IS NULL (no valid account mapping found) OR IsActive=0 (account is inactive)
- Execution accounts (LiquidityAccountTypeID=2) are excluded from the backing check - IRS rows can only be backed by non-execution accounts
- This catches: instruments removed from LiquidityAccountToInstrument OR whose mapped accounts carry a different ARS

**Pattern**:
```
IRS row is ORPHANED if:
  no LATI row links this instrument to any non-execution LiquidityAccount
  where that account's AccountRateSourceID matches IRS.AccountRateSourceID
  OR the linked account has IsActive = 0
```

### 2.2 DELETE 2 - Remove IRS Rows Not Backed by PCS-Assigned Account

**What**: Removes InstrumentRateSources rows where the rate source's liquidity account is no longer assigned to any PCS instance.

**Columns/Parameters Involved**: `InstrumentRateSourceID`, `AccountRateSourceID`, `IsActive`

**Rules**:
- Build the valid set: PCSToLiquidityAccount -> TLA (non-execution) -> IRS (matching on ARS)
- RIGHT JOIN to IRS2: all IRS rows evaluated
- Delete condition: IRS.InstrumentRateSourceID IS NULL (ARS not reachable via any PCS account) OR IsActive=0
- Note: the JOIN condition in the DDL contains a potential bug - `TLA ON PTLA.LiquidityAccountID = PTLA.LiquidityAccountID` compares PTLA to itself rather than TLA.LiquidityAccountID = PTLA.LiquidityAccountID. This produces a cross-join between PCSToLiquidityAccount and all non-execution LiquidityAccounts, then filtered by ARS match. In practice this means: if the IRS.AccountRateSourceID exists in ANY non-execution liquidity account, it survives; if not, it is deleted.

### 2.3 Commented-Out Original Implementation

**What**: The DDL contains a commented-out DELETE that was the original implementation, replaced by the current two-DELETE approach.

**Rules**:
- The commented version used a different join strategy: LATI1 (instrument must be in LATI at all) + LEFT JOIN LATI (account-level coverage) + LEFT JOIN PCSToLiquidityAccount (PCS assignment)
- Deleted when: PCSID IS NULL (no PCS) OR LATI.LiquidityAccountID IS NULL (no account) OR IsActive=0 AND LiquidityAccountTypeID<>2
- The current version splits this into two separate passes (instrument-account coherence, then PCS coverage) using the RIGHT JOIN anti-join pattern

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No input parameters. Operates on the full Price.InstrumentRateSources table without filtering. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentRateSourceID | Price.InstrumentRateSources | DELETE target | Deletes orphaned rate source priority assignments in two passes |
| InstrumentID + AccountRateSourceID | Price.LiquidityAccountToInstrument | JOIN (backing check) | Validates instrument-account mapping in DELETE 1 |
| AccountRateSourceID + LiquidityAccountID | Trade.LiquidityAccounts | JOIN | Validates account activity and type; excludes execution accounts (type 2) |
| LiquidityAccountID | Price.PCSToLiquidityAccount | JOIN (backing check) | Validates PCS coverage in DELETE 2 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.DelistInstrument | EXEC | CALLER | Called after delisting an instrument to clean up orphaned InstrumentRateSources rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.CleanUnmappedInstrumentRateSources (procedure)
├── Price.InstrumentRateSources (table) - DELETE target (both passes)
├── Price.LiquidityAccountToInstrument (table) - backing check (DELETE 1)
├── Trade.LiquidityAccounts (table) - activity + type filter (both passes)
└── Price.PCSToLiquidityAccount (table) - PCS coverage check (DELETE 2)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentRateSources | Table | DELETE target - removes orphaned rows in both passes |
| Price.LiquidityAccountToInstrument | Table | JOIN source in DELETE 1 - checks instrument-to-account mapping |
| Trade.LiquidityAccounts | Table | JOIN in both DELETEs - filters by IsActive and LiquidityAccountTypeID |
| Price.PCSToLiquidityAccount | Table | JOIN source in DELETE 2 - checks PCS assignment coverage |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.DelistInstrument | Stored Procedure | EXEC caller - runs cleanup after delisting an instrument |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. No parameters, no explicit transaction, no error handling, no SET NOCOUNT ON. The procedure runs two independent DELETE passes. The second DELETE contains a likely DDL bug: `JOIN Trade.LiquidityAccounts TLA ON PTLA.LiquidityAccountID = PTLA.LiquidityAccountID` compares PTLA to itself instead of joining TLA.LiquidityAccountID = PTLA.LiquidityAccountID, producing a cross-join between PCSToLiquidityAccount and all non-execution accounts. With only 5 rows in PCSToLiquidityAccount currently, the practical effect is bounded.

---

## 8. Sample Queries

### 8.1 Run the cleanup procedure

```sql
EXEC Price.CleanUnmappedInstrumentRateSources;
```

### 8.2 Preview what DELETE 1 would remove (dry-run)

```sql
SELECT IRS2.InstrumentRateSourceID, IRS2.InstrumentID, IRS2.AccountRateSourceID, IRS2.Priority
FROM Price.LiquidityAccountToInstrument LATI WITH (NOLOCK)
JOIN Trade.LiquidityAccounts TLA WITH (NOLOCK) ON LATI.LiquidityAccountID = TLA.LiquidityAccountID AND TLA.LiquidityAccountTypeID <> 2
JOIN Price.InstrumentRateSources IRS WITH (NOLOCK) ON TLA.AccountRateSourceID = IRS.AccountRateSourceID AND LATI.InstrumentID = IRS.InstrumentID
RIGHT JOIN Price.InstrumentRateSources IRS2 WITH (NOLOCK) ON IRS2.InstrumentRateSourceID = IRS.InstrumentRateSourceID
WHERE IRS.InstrumentRateSourceID IS NULL OR TLA.IsActive = 0;
```

### 8.3 Count of InstrumentRateSources before and after cleanup

```sql
SELECT COUNT(*) AS BeforeClean FROM Price.InstrumentRateSources WITH (NOLOCK);
EXEC Price.CleanUnmappedInstrumentRateSources;
SELECT COUNT(*) AS AfterClean FROM Price.InstrumentRateSources WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.7/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.CleanUnmappedInstrumentRateSources | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.CleanUnmappedInstrumentRateSources.sql*
