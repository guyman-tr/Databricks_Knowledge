# Trade.FeeInPercentageConfigurations

> Configuration table for percentage-based trading fees (spreads, commissions) applied at open, close, or both.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (identity) |
| **Partition** | None; on PRIMARY |
| **Indexes** | 3 (PK, IX_InstrumentID, IX_InstrumentTypeID) |

---

## 1. Business Meaning

Trade.FeeInPercentageConfigurations stores percentage-based fee rules for trading operations. Each row defines a fee value (percentage) that applies when specific conditions are met: InstrumentID, InstrumentTypeID, or GroupID, combined with IsSettled (CFD vs real) and FeeOperationTypeID (Open, Close, or All).

The trading engine resolves fees through a priority: (1) InstrumentID, (2) GroupID, (3) InstrumentTypeID. Trade.FnGetCloseFeeInPercentage (and similar open-fee logic) uses this table with (NOLOCK) to look up close-fee percentages. FeeValue is stored as a decimal (e.g., 4 = 4%, 0.5 = 0.5%).

The table is system-versioned (temporal); History.FeeInPercentageConfigurations holds historical rows. A CHECK constraint enforces that exactly one of InstrumentID, InstrumentTypeID, or GroupID is non-NULL. FeeOperationTypeID references Dictionary.FeeOperationTypes: 1=Open, 2=Close, 3=All.

---

## 2. Business Logic

### 2.1 Fee Resolution Priority

Trade.FnGetCloseFeeInPercentage resolves fee by: (1) config by InstrumentID, (2) config by GroupID (MAX if multiple groups), (3) config by InstrumentTypeID. The first non-NULL FeeValue wins. IsSettled matches CFD (0) or real (1); NULL means both.

### 2.2 CRUD and Validation

Trade.AddFeeInPercentageConfigurations inserts from a table-valued parameter after Trade.FeeInPercentageConfigurationsTblValidate. Trade.UpdateFeeInPercentageConfigurations and Trade.DeleteFeeInPercentageConfigurations modify/delete by ID. Trade.ValidateFeeInPercentageConfigurations enforces rules: no conflicting IsSettled (NULL vs specific), no conflicting FeeOperationTypeID (3 vs 1/2), no duplicate (InstrumentID/Type/Group, IsSettled, FeeOperationTypeID).

### 2.3 Unique Constraint

UNIQUE on (InstrumentID, InstrumentTypeID, IsSettled, FeeOperationTypeID, GroupID) prevents duplicate configs.

---

## 3. Data Overview

| ID | InstrumentID | InstrumentTypeID | IsSettled | FeeOperationTypeID | FeeValue | DataUpdated | GroupID |
|----|--------------|------------------|-----------|--------------------|----------|--------------|---------|
| 507 | 3 | NULL | NULL | 3 | 334 | 2026-01-29 13:33 | NULL |
| 552 | 4 | NULL | 1 | 2 | 4 | 2025-08-03 08:35 | NULL |
| 625 | 1 | NULL | 0 | 1 | 1 | 2025-08-11 12:34 | NULL |
| 636 | 6 | NULL | 0 | 2 | 1 | 2026-01-26 13:02 | NULL |
| 637 | 7 | NULL | 1 | 1 | 1 | 2026-01-26 13:02 | NULL |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | VERIFIED | Surrogate primary key. |
| 2 | InstrumentID | int | YES | - | VERIFIED | Specific instrument; mutually exclusive with InstrumentTypeID and GroupID per CHECK. |
| 3 | InstrumentTypeID | int | YES | - | VERIFIED | Instrument type; mutually exclusive with InstrumentID and GroupID per CHECK. |
| 4 | IsSettled | bit | YES | - | VERIFIED | 0=CFD, 1=Real (settled). NULL = applies to both. |
| 5 | FeeOperationTypeID | tinyint | NO | - | VERIFIED | FK Dictionary.FeeOperationTypes: 1=Open, 2=Close, 3=All. |
| 6 | FeeValue | decimal(16,8) | NO | - | VERIFIED | Fee percentage (e.g., 4 = 4%). |
| 7 | DataUpdated | datetime | NO | - | VERIFIED | When row was last updated. |
| 8 | DbLoginName | varchar | - | (computed) | VERIFIED | suser_name() - DB login. |
| 9 | AppLoginName | varchar(500) | - | (computed) | VERIFIED | context_info() - application login. |
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
| Trade.FnGetCloseFeeInPercentage | Function | Resolves close-fee % by InstrumentID, GroupID, InstrumentTypeID |
| Trade.AddFeeInPercentageConfigurations | Procedure | Inserts |
| Trade.UpdateFeeInPercentageConfigurations | Procedure | Updates |
| Trade.DeleteFeeInPercentageConfigurations | Procedure | Deletes |
| Trade.GetAllFeeInPercentageConfigurations | Procedure | Selects all |
| Trade.ValidateFeeInPercentageConfigurations | Procedure | Validates before insert/update |
| Trade.FeeInPercentageConfigurationsTblValidate | Procedure | Batch validation |
| History.FeeInPercentageConfigurations | Table | Temporal history |

---

## 6. Dependencies

### 6.0 Dependency Chain

Dictionary.FeeOperationTypes -> Trade.FeeInPercentageConfigurations -> Trade.FnGetCloseFeeInPercentage
Trade.Instrument, Trade.InstrumentGroups -> Trade.FeeInPercentageConfigurations

### 6.1 Objects This Depends On

| Object | Type | Purpose |
|--------|------|---------|
| Dictionary.FeeOperationTypes | Table | FeeOperationTypeID |
| Trade.Instrument/Trade.InstrumentMetaData | Table | InstrumentID resolution |
| Trade.InstrumentGroups | Table | GroupID resolution |

### 6.2 Objects That Depend On This

| Object | Type | Purpose |
|--------|------|---------|
| Trade.FnGetCloseFeeInPercentage | Function | Fee lookup at close |
| Trade.AddFeeInPercentageConfigurations | Procedure | Insert |
| Trade.UpdateFeeInPercentageConfigurations | Procedure | Update |
| Trade.DeleteFeeInPercentageConfigurations | Procedure | Delete |
| Trade.GetAllFeeInPercentageConfigurations | Procedure | Read |
| Trade.ValidateFeeInPercentageConfigurations | Procedure | Validation |
| History.FeeInPercentageConfigurations | Table | Temporal history |

---

## 7. Technical Details

### 7.1 Indexes

| Name | Type | Key Columns | Purpose |
|-----|------|-------------|---------|
| PK_FeeInPercentageConfigurations_Id | Clustered PK | ID | Primary key |
| UNIQUE_FeeInPercentageConfigurations | Unique nonclustered | InstrumentID, InstrumentTypeID, IsSettled, FeeOperationTypeID, GroupID | Prevent duplicates |
| IX_InstrumentID | Nonclustered | InstrumentID | Lookup by instrument |
| IX_InstrumentTypeID | Nonclustered | InstrumentTypeID | Lookup by type |

### 7.2 Constraints

| Name | Type | Definition |
|-----|------|------------|
| PK_FeeInPercentageConfigurations_Id | PRIMARY KEY | ID |
| FK_Trade_FeeInPercentageConfigurations | FOREIGN KEY | FeeOperationTypeID -> Dictionary.FeeOperationTypes |
| CHECK_InstrumentID_InstrumentTypeID_FeeInPercentageConfigurations | CHECK | Exactly one of InstrumentID, InstrumentTypeID, GroupID non-NULL; others NULL |
| TRG_TradeFeeInPercentageConfigurations_INSERT | Trigger | UPDATE no-op (likely for temporal/audit) |

---

## 8. Sample Queries

```sql
-- All configs for an instrument
SELECT ID, InstrumentID, InstrumentTypeID, IsSettled, FeeOperationTypeID, FeeValue, DataUpdated
FROM Trade.FeeInPercentageConfigurations WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID;

-- FeeOperationTypes reference
SELECT * FROM Dictionary.FeeOperationTypes WITH (NOLOCK);

-- Configs by FeeOperationType
SELECT fot.Name, COUNT(*) AS ConfigCount, AVG(fp.FeeValue) AS AvgFee
FROM Trade.FeeInPercentageConfigurations fp WITH (NOLOCK)
JOIN Dictionary.FeeOperationTypes fot WITH (NOLOCK) ON fp.FeeOperationTypeID = fot.FeeOperationTypeID
GROUP BY fot.FeeOperationTypeID, fot.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.8/10 | Sources: DDL, MCP live data, Trade.Add/Update/Delete/GetAll/Validate, Trade.FnGetCloseFeeInPercentage, Dictionary.FeeOperationTypes*
