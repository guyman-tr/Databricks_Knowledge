# Trade.FixPerLotConfigurationsTbl

> TVP for inserting new fix-per-lot fee configurations and for validation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID, InstrumentTypeID, GroupID, FeeValue |
| **Partition** | N/A |
| **Indexes** | None |

---

## 1. Business Meaning

Trade.FixPerLotConfigurationsTbl is a table-valued parameter used to insert new fix-per-lot fee configurations into Trade.FixPerLotConfigurations. It has a structure parallel to FeeInPercentageConfigurationsTbl but for fixed fees per lot rather than percentage-based fees. The type is passed to Trade.AddFixPerLotConfigurations for inserts and to Trade.FixPerLotConfigurationsTblValidate for validation before use.

Each row defines a fee rule: scope (InstrumentID, InstrumentTypeID, GroupID), FeeValue (decimal(16,4) fixed amount per lot), FeeOperationTypeID (when the fee applies), and IsSettled (1 for real stock, 0 for CFD). This supports batch onboarding of new fee configurations. No DBRowID is present because this type is for new rows, not updates.

---

## 2. Business Logic

### 2.1 Insert Configuration
**What**: Adds new fix-per-lot fee rules with scope, amount, operation type, and settlement flag.
**Columns/Parameters Involved**: InstrumentID, InstrumentTypeID, FeeValue, FeeOperationTypeID, GroupID, IsSettled.
**Rules**: FeeValue and FeeOperationTypeID are NOT NULL. InstrumentID, InstrumentTypeID, GroupID define scope; at least one typically used. IsSettled distinguishes real stock (1) vs CFD (0).

---

## 3. Data Overview
N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements
| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NULL | - | High | Instrument scope; references Trade.Instrument |
| 2 | InstrumentTypeID | int | NULL | - | High | Instrument type scope |
| 3 | FeeValue | decimal(16,4) | NOT NULL | - | High | Fixed fee amount per lot |
| 4 | FeeOperationTypeID | tinyint | NOT NULL | - | High | When the fee applies |
| 5 | GroupID | int | NULL | - | High | Group scope for fee applicability |
| 6 | IsSettled | bit | NULL | - | High | 1 = real stock, 0 = CFD |

---

## 5. Relationships
### 5.1 References To
Trade.FixPerLotConfigurations, Trade.Instrument
### 5.2 Referenced By
Trade.AddFixPerLotConfigurations (parameter @ConfigTable), Trade.FixPerLotConfigurationsTblValidate (parameter @ConfigTable)

---

## 6. Dependencies
### 6.0 Dependency Chain
This object has no dependencies.
### 6.1 Objects This Depends On
No dependencies.
### 6.2 Objects That Depend On This
Trade.AddFixPerLotConfigurations, Trade.FixPerLotConfigurationsTblValidate

---

## 7. Technical Details
### 7.1 Indexes
None.
### 7.2 Constraints
None.

---

## 8. Sample Queries
### 8.1 Add Single Config
```sql
DECLARE @ConfigTable Trade.FixPerLotConfigurationsTbl;
INSERT INTO @ConfigTable (InstrumentID, InstrumentTypeID, FeeValue, FeeOperationTypeID, GroupID, IsSettled)
VALUES (5001, 1, 2.5000, 1, 10, 0);
EXEC Trade.AddFixPerLotConfigurations @ConfigTable = @ConfigTable;
```
### 8.2 Validate Before Insert
```sql
DECLARE @ConfigTable Trade.FixPerLotConfigurationsTbl;
INSERT INTO @ConfigTable (InstrumentID, InstrumentTypeID, FeeValue, FeeOperationTypeID, GroupID, IsSettled)
SELECT InstrumentID, InstrumentTypeID, FeeValue, FeeOperationTypeID, GroupID, IsSettled
FROM #NewConfigs;
EXEC Trade.FixPerLotConfigurationsTblValidate @ConfigTable = @ConfigTable;
```
### 8.3 Batch Add Multiple Scopes
```sql
DECLARE @ConfigTable Trade.FixPerLotConfigurationsTbl;
INSERT INTO @ConfigTable (InstrumentID, InstrumentTypeID, FeeValue, FeeOperationTypeID, GroupID, IsSettled)
VALUES (5001, 1, 1.00, 1, NULL, 0), (NULL, 2, 2.50, 1, 20, 1);
EXEC Trade.AddFixPerLotConfigurations @ConfigTable = @ConfigTable;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.FixPerLotConfigurationsTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.FixPerLotConfigurationsTbl.sql*
