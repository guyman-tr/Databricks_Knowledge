# Trade.sp_GetPositionData

> Returns key position summary data for a single position ID, joining to Customer.Customer to include the account username.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves a concise summary of a single trading position, enriched with the customer's username. It is a simple lookup utility that combines the position's key financial and status fields with the account identifier, making it useful for operational lookups, debugging, and support tooling where a human-readable position summary is needed.

The sp_ prefix (vs SI_ for system integration endpoints) suggests this is a more general-purpose lookup procedure used by internal tools, support dashboards, or admin interfaces.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | Bigint | NO | - | CODE-BACKED | The unique identifier of the position to retrieve. Filters Trade.GetPositionData WHERE PositionID = @PositionID. |
| Output: PositionID | bigint | - | - | CODE-BACKED | Unique position identifier - same as @PositionID input. |
| Output: InstrumentID | int | - | - | CODE-BACKED | Trading instrument (asset) for this position. FK to Trade.ProviderToInstrument. |
| Output: IsOpened | bit | - | - | CODE-BACKED | Position state: 1 = still open (active), 0 = closed (historical). |
| Output: OpenOccurred | datetime | - | - | CODE-BACKED | Timestamp when the position was opened. |
| Output: CloseOccurred | datetime | - | - | CODE-BACKED | Timestamp when the position was closed (NULL for open positions). |
| Output: OpenRate | decimal | - | - | CODE-BACKED | Price rate at which the position was opened. Aliased from InitForexRate. |
| Output: Leverage | int | - | - | CODE-BACKED | Leverage multiplier: 1 = no leverage (real stock), >1 = leveraged position. |
| Output: UserName | varchar | - | - | CODE-BACKED | Account username from Customer.Customer. Joined on CID for human-readable account identification. |
| Output: CID | int | - | - | CODE-BACKED | Customer ID owning this position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Trade.GetPositionData | Reader | Reads position data filtered by PositionID |
| CID | Customer.Customer | Reader | JOINed on CID to get the account UserName |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.sp_GetPositionData (procedure)
├── Trade.GetPositionData (view) [filtered by PositionID]
└── Customer.Customer (table) [joined on CID for UserName]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetPositionData | View | Read with NOLOCK filtered by PositionID |
| Customer.Customer | Table | Joined on CID to retrieve the account UserName |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No callers found in Trade SP folder | - | Used by operational/support tooling |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get position summary for a specific position

```sql
EXEC Trade.sp_GetPositionData @PositionID = 123456789;
```

### 8.2 Direct equivalent query

```sql
SELECT tgp.PositionID, tgp.InstrumentID, tgp.IsOpened, tgp.OpenOccurred, tgp.CloseOccurred,
       tgp.InitForexRate AS OpenRate, tgp.Leverage, Customer.UserName, tgp.CID
FROM Trade.GetPositionData tgp WITH (NOLOCK)
INNER JOIN Customer.Customer WITH (NOLOCK) ON Customer.CID = tgp.CID
WHERE tgp.PositionID = 123456789;
```

### 8.3 Look up multiple positions by customer

```sql
SELECT tgp.PositionID, tgp.InstrumentID, tgp.IsOpened, tgp.OpenOccurred, tgp.InitForexRate AS OpenRate
FROM Trade.GetPositionData tgp WITH (NOLOCK)
INNER JOIN Customer.Customer WITH (NOLOCK) ON Customer.CID = tgp.CID
WHERE tgp.CID = 12345
ORDER BY tgp.OpenOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.sp_GetPositionData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.sp_GetPositionData.sql*
