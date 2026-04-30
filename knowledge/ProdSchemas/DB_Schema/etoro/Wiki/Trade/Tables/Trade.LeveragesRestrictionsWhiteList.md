# Trade.LeveragesRestrictionsWhiteList

> Per-GCID leverage whitelist: defines min/max/default leverage allowed for specific users (by GCID) and instruments. Used for VIP/whitelisted customers who have custom leverage rules outside standard country/customer restrictions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | GCID, InstrumentID (PK CLUSTERED) |
| **Indexes** | 1 (PK clustered, FILLFACTOR 95) |

---

## 1. Business Meaning

Trade.LeveragesRestrictionsWhiteList stores custom leverage limits for whitelisted users (identified by GCID). Unlike LeverageRestrictionsByCountry and LeverageRestrictionsByCustomer (which store discrete allowed leverage values), this table holds a range per (GCID, InstrumentID): MinLeverage, MaxLeverage, and DefaultLeverage. It is used for VIP/approval flows where users receive elevated or customized leverage outside standard rules.

Trade.GetLeveragesRestrictionsWhiteList returns whitelist rows by GCID. Trade.GetCustomerRestrictionsWhiteList joins to Customer.CustomerStatic to show whitelisted customers with their leverage limits and country/player-level context. CM procedures (Insert/Update/Delete/Get) support a Configuration Management UI for managing whitelist entries.

---

## 2. Business Logic

### 2.1 Leverage Range per Whitelisted User

**What**: Each (GCID, InstrumentID) pair defines allowed min/max/default leverage for that user.

**Columns/Parameters Involved**: `GCID`, `InstrumentID`, `MinLeverage`, `MaxLeverage`, `DefaultLeverage`, `Comments`, `LastUpdateDate`

**Rules**:
- One row per (GCID, InstrumentID); PK enforces uniqueness
- MinLeverage ≤ DefaultLeverage ≤ MaxLeverage (logical expectation)
- DefaultLeverage is the preselected leverage for the instrument
- Comments stores optional notes; LastUpdateDate defaults to GETUTCDATE()

### 2.2 Population and Maintenance

**What**: Rows are inserted by Trade.InsertLeveragesRestrictionsWhiteList (single-row) and Trade.CM_InsertLeveragesRestrictionsWhiteList (bulk MERGE). Updates/deletes via CM_UpdateLeveragesRestrictionsWhiteList and CM_DeleteLeveragesRestrictionsWhiteList using TVPs.

**Columns/Parameters Involved**: All columns

**Rules**:
- InsertLeveragesRestrictionsWhiteList: simple INSERT with GCID, InstrumentID, MaxLeverage, MinLeverage, DefaultLeverage
- CM procedures use TVP types CM_UpdateLeveragesRestrictionsWhiteListTable and CM_DeleteLeveragesRestrictionsWhiteListTable
- GetLeveragesRestrictionsWhiteList joins to Trade.GetInstrument (view) for InstrumentTypeID

---

## 3. Data Overview

| GCID | InstrumentID | MaxLeverage | MinLeverage | DefaultLeverage | Comments | LastUpdateDate |
|------|--------------|-------------|-------------|----------------|----------|----------------|
| *(Live sample unavailable—MCP query failed)* | | | | | | |

Structure: One row per whitelisted (GCID, InstrumentID) with Min/Max/Default leverage values.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | VERIFIED | Global Customer ID. References Customer.CustomerStatic.GCID |
| 2 | InstrumentID | int | NO | - | VERIFIED | Instrument. References Trade.Instrument.InstrumentID |
| 3 | MaxLeverage | int | NO | - | VERIFIED | Maximum allowed leverage |
| 4 | MinLeverage | int | NO | - | VERIFIED | Minimum allowed leverage |
| 5 | DefaultLeverage | int | NO | - | VERIFIED | Default leverage for this pair |
| 6 | Comments | varchar(500) | YES | - | DDL | Optional notes |
| 7 | LastUpdateDate | smalldatetime | NO | GETUTCDATE() | DDL | Audit timestamp |

---

## 5. Relationships

### 5.1 References To

| Referenced Table | Column | Relationship |
|------------------|--------|--------------|
| Customer.CustomerStatic | GCID | Implicit; GCID must exist |
| Trade.Instrument | InstrumentID | Implicit; instrument must exist |

### 5.2 Referenced By

| Referencing Object | Column | Type |
|--------------------|--------|------|
| Trade.GetLeveragesRestrictionsWhiteList | LeveragesRestrictionsWhiteList | Reader—returns by GCID |
| Trade.GetLeveragesWhiteListUsersDistinctGcidsList | LeveragesRestrictionsWhiteList | Reader—distinct GCIDs |
| Trade.GetCustomerRestrictionsWhiteList | LeveragesRestrictionsWhiteList | Reader—joins to CustomerStatic |
| Trade.InsertLeveragesRestrictionsWhiteList | LeveragesRestrictionsWhiteList | Writer—single-row insert |
| Trade.CM_InsertLeveragesRestrictionsWhiteList | LeveragesRestrictionsWhiteList | Writer—MERGE |
| Trade.CM_UpdateLeveragesRestrictionsWhiteList | LeveragesRestrictionsWhiteList | Writer—UPDATE |
| Trade.CM_DeleteLeveragesRestrictionsWhiteList | LeveragesRestrictionsWhiteList | Writer—DELETE |
| Trade.CM_GetLeveragesRestrictionsWhiteList | LeveragesRestrictionsWhiteList | Reader—by GCID list |

---

## 6. Dependencies

### 6.0 Chain

```
Customer.CustomerStatic ──► Trade.LeveragesRestrictionsWhiteList
Trade.Instrument         ──► Trade.LeveragesRestrictionsWhiteList
```

### 6.1 Depends On

| Object | Purpose |
|--------|---------|
| Customer.CustomerStatic | GCID domain |
| Trade.Instrument | InstrumentID domain |

### 6.2 Depended On By

| Object | Purpose |
|--------|---------|
| Trade.GetLeveragesRestrictionsWhiteList | API/trading—leverage whitelist by GCID |
| Trade.GetCustomerRestrictionsWhiteList | Admin—whitelisted customers with leverage |
| Trade.CM_* procedures | Configuration management UI |
| TAPIUser, TradingSettingsAPI | EXECUTE on GetLeveragesRestrictionsWhiteList |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included | Fill Factor | Status |
|------------|------|-------------|----------|-------------|--------|
| PK_TradeLeveragesRestrictionsWhiteList | CLUSTERED | GCID ASC, InstrumentID ASC | - | 95 | Active |

### 7.2 Constraints

| Constraint | Type | Definition |
|------------|------|------------|
| PK_TradeLeveragesRestrictionsWhiteList | PRIMARY KEY | GCID, InstrumentID |
| DF_TradeLeveragesRestrictionsWhiteList_LastUpdateDate | DEFAULT | LastUpdateDate = GETUTCDATE() |

---

## 8. Sample Queries

```sql
SELECT TL.GCID, TL.InstrumentID, TL.MaxLeverage, TL.MinLeverage, TL.DefaultLeverage, TL.Comments, TL.LastUpdateDate
FROM Trade.LeveragesRestrictionsWhiteList TL WITH (NOLOCK)
WHERE TL.GCID = @GCID;

SELECT CUST.GCID, CUST.UserName, WL.InstrumentID, WL.MaxLeverage, WL.MinLeverage, WL.DefaultLeverage
FROM Customer.CustomerStatic CUST WITH (NOLOCK)
INNER JOIN Trade.LeveragesRestrictionsWhiteList WL WITH (NOLOCK) ON CUST.GCID = WL.GCID;
```

---

## 9. Atlassian Knowledge Sources

- No Jira/Confluence references found in this documentation pass.

---

*Generated: 2026-03-14 | Quality: 7.2/10*
