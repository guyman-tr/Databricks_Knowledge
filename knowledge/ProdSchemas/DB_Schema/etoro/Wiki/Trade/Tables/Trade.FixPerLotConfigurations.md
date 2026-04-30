# Trade.FixPerLotConfigurations

> Configuration table for fixed per-lot trading fees (as opposed to percentage-based); counterpart to Trade.FeeInPercentageConfigurations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (identity) |
| **Partition** | None; on PRIMARY |
| **Indexes** | 4 (PK, UNIQUE, IX_InstrumentID, IX_InstrumentTypeID) |

---

## 1. Business Meaning

**WHAT**: Trade.FixPerLotConfigurations stores fixed-amount fees per lot for trading operations. Each row defines a FeeValue (in currency per lot) that applies when opening or closing positions, scoped by InstrumentID, InstrumentTypeID, or GroupID, combined with IsSettled (CFD vs real) and FeeOperationTypeID (Open, Close, or All). This is the counterpart to Trade.FeeInPercentageConfigurations, which stores percentage-based fees.

**WHY**: Some instruments charge a fixed fee per lot (e.g., $1.50 per lot) instead of a percentage. Trade.FnGetCloseFixPerLot uses this table to resolve close-phase fixed fees at position close. The trading engine needs both percentage (FeeInPercentageConfigurations) and fixed-per-lot (FixPerLotConfigurations) configs to compute total fees.

**HOW**: Resolution follows priority: (1) config by InstrumentID, (2) config by GroupID (MAX if multiple groups), (3) config by InstrumentTypeID. Trade.FnGetCloseFixPerLot filters by FeeOperationTypeID in (2, 3) - Close and All. The table is system-versioned; History.FixPerLotConfigurations holds historical rows. A CHECK constraint enforces that exactly one of InstrumentID, InstrumentTypeID, or GroupID is non-NULL.

---

## 2. Business Logic

### 2.1 Fee Resolution Priority

Trade.FnGetCloseFixPerLot resolves fee by: (1) config by InstrumentID from Trade.InstrumentMetaData, (2) config by GroupID from Trade.InstrumentGroups (MAX FeeValue if instrument in multiple groups), (3) config by InstrumentTypeID from Trade.InstrumentMetaData. IsSettled matches CFD (0) or real (1); NULL means both. FeeOperationTypeID in (2, 3) = Close or All.

### 2.2 CRUD and Validation

Trade.AddFixPerLotConfigurations inserts from table-valued parameter [Trade].[FixPerLotConfigurationsTbl] after Trade.FixPerLotConfigurationsTblValidate. Trade.UpdateFixPerLotConfigurations and Trade.DeleteFixPerLotConfigurations modify/delete by ID. Trade.ValidateFixPerLotConfigurations enforces rules. Trade.GetAllFixPerLotConfigurations returns all configs.

### 2.3 Unique Constraint

UNIQUE on (InstrumentID, InstrumentTypeID, IsSettled, FeeOperationTypeID, GroupID) prevents duplicate configs. Exactly one scope (InstrumentID, InstrumentTypeID, or GroupID) must be non-NULL per CHECK.

---

## 3. Data Overview

| ID | InstrumentID | InstrumentTypeID | IsSettled | FeeOperationTypeID | FeeValue | DataUpdated | GroupID |
|----|--------------|------------------|-----------|--------------------|----------|--------------|---------|
| 9 | NULL | NULL | 0 | 2 | 1 | 2025-12-25 12:12 | 41 |
| 10 | NULL | NULL | 1 | 1 | 0 | 2025-12-15 13:51 | 31 |
| 35 | 1001 | NULL | NULL | 3 | 1.5 | 2025-12-28 19:50 | NULL |
| 93 | 1003 | NULL | 1 | 2 | 1.6 | 2025-12-28 19:50 | NULL |
| 100 | 1111 | NULL | NULL | 3 | 1.4 | 2025-12-16 11:25 | NULL |

FeeOperationTypeID: 1=Open, 2=Close, 3=All. IsSettled: 0=CFD, 1=Real, NULL=both.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | VERIFIED | Surrogate primary key. |
| 2 | InstrumentID | int | YES | - | VERIFIED | Specific instrument; mutually exclusive with InstrumentTypeID and GroupID per CHECK. |
| 3 | InstrumentTypeID | int | YES | - | VERIFIED | Instrument type; mutually exclusive with InstrumentID and GroupID per CHECK. |
| 4 | IsSettled | bit | YES | - | VERIFIED | 0=CFD, 1=Real (settled). NULL = applies to both. |
| 5 | FeeOperationTypeID | tinyint | NO | - | VERIFIED | FK Dictionary.FeeOperationTypes: 1=Open, 2=Close, 3=All. |
| 6 | FeeValue | decimal(16,4) | NO | - | VERIFIED | Fixed fee per lot (e.g., 1.5 = $1.50 per lot). |
| 7 | DataUpdated | datetime | NO | - | VERIFIED | When row was last updated. |
| 8 | DbLoginName | varchar | - | (computed) | CODE-BACKED | suser_name() - DB login. |
| 9 | AppLoginName | varchar(500) | - | (computed) | CODE-BACKED | context_info() - application login. |
| 10 | SysStartTime | datetime2(7) | NO | (generated) | VERIFIED | Temporal row start. |
| 11 | SysEndTime | datetime2(7) | NO | (generated) | VERIFIED | Temporal row end. |
| 12 | GroupID | int | YES | - | VERIFIED | Fee group; mutually exclusive with InstrumentID and InstrumentTypeID per CHECK. |

---

## 5. Relationships

### 5.1 References To

| Referenced Object | Key | Relationship |
|------------------|-----|--------------|
| Dictionary.FeeOperationTypes | FeeOperationTypeID | Open/Close/All |
| Trade.Instrument (implicit) | InstrumentID | When scoped by instrument |
| Trade.InstrumentGroups | GroupID | When scoped by group |

### 5.2 Referenced By

| Object | Usage |
|--------|-------|
| Trade.FnGetCloseFixPerLot | Function | Resolves close-phase fixed per-lot fees |
| Trade.FnGetCloseFee, Trade.FnGetCloseFeeOnOpen | Function | Consume FnGetCloseFixPerLot output |
| Trade.AddFixPerLotConfigurations | Procedure | Inserts |
| Trade.UpdateFixPerLotConfigurations | Procedure | Updates |
| Trade.DeleteFixPerLotConfigurations | Procedure | Deletes |
| Trade.GetAllFixPerLotConfigurations | Procedure | Selects all |
| Trade.ValidateFixPerLotConfigurations | Procedure | Validates configs |
| Trade.FixPerLotConfigurationsTblValidate | Procedure | Batch validation |
| History.FixPerLotConfigurations | Table | Temporal history |

---

## 6. Dependencies

### 6.0 Dependency Chain

Dictionary.FeeOperationTypes -> Trade.FixPerLotConfigurations -> Trade.FnGetCloseFixPerLot -> Trade.FnGetCloseFee
Trade.Instrument, Trade.InstrumentGroups, Trade.InstrumentMetaData -> Trade.FixPerLotConfigurations

### 6.1 Objects This Depends On

| Object | Type | Purpose |
|--------|------|---------|
| Dictionary.FeeOperationTypes | Table | FeeOperationTypeID |
| Trade.Instrument/Trade.InstrumentMetaData | Table | InstrumentID resolution |
| Trade.InstrumentGroups | Table | GroupID resolution |

### 6.2 Objects That Depend On This

| Object | Type | Purpose |
|--------|------|---------|
| Trade.FnGetCloseFixPerLot | Function | Fee lookup at close |
| Trade.AddFixPerLotConfigurations | Procedure | Insert |
| Trade.UpdateFixPerLotConfigurations | Procedure | Update |
| Trade.DeleteFixPerLotConfigurations | Procedure | Delete |
| Trade.GetAllFixPerLotConfigurations | Procedure | Read |
| Trade.ValidateFixPerLotConfigurations | Procedure | Validation |
| History.FixPerLotConfigurations | Table | Temporal history |

---

## 7. Technical Details

### 7.1 Indexes

| Name | Type | Key Columns | Purpose |
|-----|------|-------------|---------|
| PK_FixPerLotConfigurations_Id | Clustered PK | ID | Primary key |
| UNIQUE_FixPerLotConfigurations | Unique nonclustered | InstrumentID, InstrumentTypeID, IsSettled, FeeOperationTypeID, GroupID | Prevent duplicates |
| IX_InstrumentID | Nonclustered | InstrumentID | Lookup by instrument |
| IX_InstrumentTypeID | Nonclustered | InstrumentTypeID | Lookup by type |

### 7.2 Constraints

| Name | Type | Definition |
|-----|------|------------|
| PK_FixPerLotConfigurations_Id | PRIMARY KEY | ID |
| FK_Trade_FixPerLotConfigurations | FOREIGN KEY | FeeOperationTypeID -> Dictionary.FeeOperationTypes |
| CHECK_InstrumentID_InstrumentTypeID_FixPerLotConfigurations | CHECK | Exactly one of InstrumentID, InstrumentTypeID, GroupID non-NULL; others NULL |
| TRG_TradeFixPerLotConfigurations_INSERT | Trigger | UPDATE no-op for temporal/audit |

---

## 8. Sample Queries

```sql
-- All configs for an instrument
SELECT ID, InstrumentID, InstrumentTypeID, IsSettled, FeeOperationTypeID, FeeValue, DataUpdated
FROM Trade.FixPerLotConfigurations WITH (NOLOCK)
WHERE InstrumentID = 1001;

-- FeeOperationTypes reference
SELECT * FROM Dictionary.FeeOperationTypes WITH (NOLOCK);

-- Configs by FeeOperationType
SELECT fot.Name, COUNT(*) AS ConfigCount
FROM Trade.FixPerLotConfigurations fp WITH (NOLOCK)
JOIN Dictionary.FeeOperationTypes fot WITH (NOLOCK) ON fp.FeeOperationTypeID = fot.FeeOperationTypeID
GROUP BY fot.FeeOperationTypeID, fot.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.7/10 | Sources: DDL, MCP live data, Trade.Add/Update/Delete/GetAll/Validate, Trade.FnGetCloseFixPerLot, Dictionary.FeeOperationTypes*
