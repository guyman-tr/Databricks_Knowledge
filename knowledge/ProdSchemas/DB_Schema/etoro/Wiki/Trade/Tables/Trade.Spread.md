# Trade.Spread

> Spread (bid-ask markup) configuration per instrument per provider. Defines pips to add to bid and ask for customer pricing.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | SpreadID (INT, CLUSTERED PK) |
| **Partition** | Yes - ON [MAIN] |
| **Indexes** | 2 active (PK + TSPR_PROVIDER2INSTRUMENT) |

---

## 1. Business Meaning

Trade.Spread stores the bid and ask spread (in pips) for each (ProviderID, InstrumentID) pair. Each row defines how many pips to add to the raw bid (Bid) and ask (Ask) when quoting prices to customers. SpreadID is a unique identifier; the same SpreadID can be linked to multiple spread groups via Trade.SpreadToGroup, enabling different customer tiers (Default, Expert, etc.) to share or override spreads.

This table exists because eToro applies different spreads to different instruments and customer segments. Without it, the system could not determine the markup for order pricing, position valuation, or P&L. Trade.GetSpreadGroup joins Spread with SpreadGroup and SpreadToGroup to resolve which Bid/Ask applies for a given SpreadGroupID. Trade.OrdersAdd, Trade.GetForexRates, and Trade.GetPendingOrders all depend on spread resolution.

Data flows: rows are created by `Trade.SpreadAdd` (Internal.GetSpreadID for ID allocation), updated by `Trade.SpreadEdit`, and deleted by `Trade.SpreadDelete`. Trade.InsertInstrumentRealTable bulk-inserts during instrument onboarding. ASM triggers (AuditInsert, AuditUpdate, AuditDelete) log Bid/Ask to History.AuditHistory. History triggers (SpreadInsert, SpreadUpdate, TSpreadDelete) maintain History.Spread with ValidFrom/ValidTo for temporal auditing.

---

## 2. Business Logic

### 2.1 Spread Group Mapping

**What**: Spread rows are linked to spread groups (Default, Expert, etc.) via Trade.SpreadToGroup.

**Columns/Parameters Involved**: `SpreadID`, `ProviderID`, `InstrumentID`, `Bid`, `Ask`

**Rules**:
- One SpreadID per (ProviderID, InstrumentID) - but the same SpreadID can appear in multiple SpreadToGroup rows (many-to-many with SpreadGroup).
- Trade.GetSpreadGroup: TSPG (SpreadGroup) JOIN TS2G (SpreadToGroup) JOIN TSPR (Spread) produces Bid, Ask per (SpreadGroupID, ProviderID, InstrumentID).
- Bid and Ask are typically small integers (pips). Negative Bid observed (e.g., -2) - may indicate discount from raw or convention.

**Diagram**:
```
Trade.SpreadGroup (0=Default, 1=Expert)
       |
       v
Trade.SpreadToGroup (SpreadGroupID, SpreadID)
       |
       v
Trade.Spread (SpreadID, ProviderID, InstrumentID, Bid, Ask)
```

### 2.2 Bid and Ask as Pip Offsets

**What**: Bid and Ask are integer pip offsets applied to raw prices.

**Columns/Parameters Involved**: `Bid`, `Ask`

**Rules**:
- Sample data: Bid ranges -3 to -1, Ask ranges 1 to 2. Negative Bid may mean "subtract from raw" or pip convention.
- ASM triggers audit both columns on INSERT, UPDATE, DELETE.
- History.Spread stores full history via SpreadInsert, SpreadUpdate, TSpreadDelete triggers (ValidFrom, ValidTo).

---

## 3. Data Overview

| SpreadID | ProviderID | InstrumentID | Bid | Ask | Meaning |
|----------|------------|--------------|-----|-----|---------|
| 1 | 1 | 1 | -2 | 1 | EUR/USD (Instrument 1). Bid offset -2, Ask +1 pips. |
| 2 | 1 | 2 | -2 | 2 | GBP. Slightly wider ask. |
| 3 | 1 | 3 | -3 | 2 | NZD/USD. Tighter bid offset. |
| 5 | 1 | 5 | -1 | 1 | JPY. Narrow spread. |
| 10 | 1 | 10 | -2 | 2 | EUR/JPY. Standard spread. |

**Selection criteria**: First 10 by SpreadID show ProviderID=1, InstrumentID 1-10. Bid values -3 to -1; Ask 1-2. Linked via SpreadToGroup to SpreadGroupID for customer-tier resolution.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | SpreadID | int | NO | - | CODE-BACKED | Primary key. Allocated by Internal.GetSpreadID in Trade.SpreadAdd. Used by Trade.SpreadToGroup to link spreads to groups. |
| 2 | ProviderID | int | NO | - | CODE-BACKED | FK part -> Trade.ProviderToInstrument. Execution provider. |
| 3 | InstrumentID | int | NO | - | CODE-BACKED | FK part -> Trade.ProviderToInstrument. Tradeable instrument. |
| 4 | Bid | int | NO | - | CODE-BACKED | Pip offset for bid. Applied when quoting buy price. Audited by ASM triggers. |
| 5 | Ask | int | NO | - | CODE-BACKED | Pip offset for ask. Applied when quoting sell price. Audited by ASM triggers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ProviderID, InstrumentID | Trade.ProviderToInstrument | FK | FK_TPVI_TSPR. Instrument must exist in ProviderToInstrument. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SpreadToGroup | SpreadID | FK | Links spread to spread groups (many-to-many). |
| Trade.GetSpreadGroup | JOIN | Reader | View joins SpreadGroup, Spread, SpreadToGroup for Bid/Ask per group. |
| Trade.SpreadAdd | INSERT | Writer | Creates rows. |
| Trade.SpreadEdit | UPDATE | Modifier | Updates Bid, Ask. |
| Trade.SpreadDelete | DELETE | Deleter | Removes rows. |
| Trade.CheckValidInstruments | EXISTS/INSERT | Reader/Writer | Validates InstrumentID, creates Spread if missing. |
| Trade.GetPendingOrders | JOIN | Reader | Resolves spread for pending order display. |
| Trade.InsertInstrumentRealTable | INSERT | Writer | Bulk load during instrument onboarding. |
| History.AuditHistory | Trigger | Audit | ASM AuditInsert/Update/Delete on Bid, Ask. |
| History.Spread | Trigger | History | SpreadInsert, SpreadUpdate, TSpreadDelete maintain ValidFrom/ValidTo. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Spread (table)
└── Trade.ProviderToInstrument (table)
      ├── Trade.Provider (table)
      └── Trade.Instrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FK (ProviderID, InstrumentID) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.SpreadToGroup | Table | FK SpreadID |
| Trade.GetSpreadGroup | View | JOIN |
| Trade.SpreadAdd | Procedure | INSERT |
| Trade.SpreadEdit | Procedure | UPDATE |
| Trade.SpreadDelete | Procedure | DELETE |
| Trade.CheckValidInstruments | Procedure | Validation, auto-create Spread |
| Trade.GetForexRates | Procedure | Via GetSpreadGroup (SpreadGroupID=0) |
| Trade.GetPendingOrders | Procedure | JOIN for spread |
| History.Spread | Table | Trigger history |
| History.AuditHistory | Table | ASM audit |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TSPR | CLUSTERED | SpreadID | - | - | Active |
| TSPR_PROVIDER2INSTRUMENT | NC | ProviderID, InstrumentID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_TPVI_TSPR | FK | (ProviderID, InstrumentID) -> Trade.ProviderToInstrument |

### 7.3 Triggers

| Trigger | Event | Action |
|---------|-------|--------|
| AuditDelete_Trade_Spread | DELETE | Log Bid, Ask to History.AuditHistory |
| AuditInsert_Trade_Spread | INSERT | Log Bid, Ask to History.AuditHistory |
| AuditUpdate_Trade_Spread | UPDATE | Log changed Bid, Ask to History.AuditHistory |
| Trade.SpreadInsert | INSERT | Insert into History.Spread (ValidFrom, ValidTo) |
| Trade.SpreadUpdate | UPDATE | Close old History.Spread row, insert new |
| Trade.TSpreadDelete | DELETE | Close History.Spread row (ValidTo = GETDATE) |

---

## 8. Sample Queries

### 8.1 List spreads for Provider 1
```sql
SELECT SpreadID, ProviderID, InstrumentID, Bid, Ask
  FROM Trade.Spread S WITH (NOLOCK)
 WHERE ProviderID = 1
 ORDER BY InstrumentID
```

### 8.2 Get spread with instrument name
```sql
SELECT S.SpreadID, S.ProviderID, S.InstrumentID, PTI.PresentationCode, S.Bid, S.Ask
  FROM Trade.Spread S WITH (NOLOCK)
  JOIN Trade.ProviderToInstrument PTI WITH (NOLOCK)
    ON S.ProviderID = PTI.ProviderID AND S.InstrumentID = PTI.InstrumentID
 WHERE S.ProviderID = 1
 ORDER BY S.InstrumentID
```

### 8.3 Spreads by spread group (Default = 0)
```sql
SELECT SG.SpreadGroupID, SG.Name, S.SpreadID, S.InstrumentID, S.Bid, S.Ask
  FROM Trade.GetSpreadGroup SG WITH (NOLOCK)
 WHERE SG.SpreadGroupID = 0
   AND S.ProviderID = 1
 ORDER BY S.InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.Spread | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.Spread.sql*
