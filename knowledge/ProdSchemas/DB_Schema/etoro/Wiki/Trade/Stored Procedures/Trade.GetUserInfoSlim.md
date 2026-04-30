# Trade.GetUserInfoSlim

> Lightweight customer context loader - returns 7-column subset (CID, GCID, CountryID, RegulationID, PlayerLevelID, IsBeingCopied, TradingRiskStatusID) for lightweight pre-execution or routing checks that don't need full credit or account detail.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer to retrieve |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUserInfoSlim` is the lightweight variant of `Trade.GetUserInfo`, returning only the fields required for routing and eligibility decisions that do not require credit amounts, account type names, or blocking detail. It is used when the caller needs to know: who is this customer (CID/GCID/Country), what regulation applies, are they a Popular Investor (PlayerLevelID), are they being copied (IsBeingCopied), and what is their risk classification (TradingRiskStatusID)?

This slim profile is appropriate for pre-execution routing decisions, regulatory routing (which execution path to use based on RegulationID), and copy-related validations where full credit and block details are not needed. The use of `Customer.CustomerStatic` (vs `Customer.Customer`) follows the TRADEA-387 detachment pattern.

The `IsBeingCopied` computation is identical to GetUserInfo: EXISTS on Trade.Mirror for ParentCID.

---

## 2. Business Logic

### 2.1 Slim Field Selection

**What**: Returns only 7 essential routing fields.

**Rules**:
- CID, GCID, CountryID: identity and geography
- `RegulationID = ISNULL(BC.DesignatedRegulationID, 0)`: override regulation (0 = no override, same pattern as GetUserInfo)
- `PlayerLevelID`: customer tier for copy/PI routing
- `IsBeingCopied`: EXISTS check on Trade.Mirror
- `TradingRiskStatusID`: risk classification for execution routing

### 2.2 IsBeingCopied Pre-Computation

**What**: Same EXISTS-on-Mirror pattern as GetUserInfo.

**Rules**:
- `@IsBeingCopied = CAST(CASE WHEN EXISTS(SELECT 1 FROM Trade.Mirror WHERE ParentCID = @CID) THEN 1 ELSE 0 END AS BIT)`
- Pre-computed variable to avoid correlated subquery in main SELECT

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID for slim context retrieval. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | CID | INT | NO | - | CODE-BACKED | Database-local Customer ID. |
| 3 | GCID | INT | NO | - | CODE-BACKED | Global Customer ID. |
| 4 | CountryID | INT | NO | - | CODE-BACKED | Country of residence. FK to Dictionary.Country. |
| 5 | RegulationID | INT | NO | - | CODE-BACKED | ISNULL(BC.DesignatedRegulationID, 0). Designated regulation override; 0 = no override. |
| 6 | PlayerLevelID | INT | NO | - | CODE-BACKED | Customer tier from Customer.CustomerStatic. 1=Regular, 2=Popular Investor, 4=Etorian. FK to Dictionary.PlayerLevel. |
| 7 | IsBeingCopied | BIT | NO | - | CODE-BACKED | 1 = has active copiers (any Trade.Mirror row with ParentCID=@CID); 0 = not being copied. |
| 8 | TradingRiskStatusID | INT | NO | - | CODE-BACKED | Trading risk classification from BackOffice.Customer. FK to Dictionary.TradingRiskStatus. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| IsBeingCopied | Trade.Mirror | EXISTS subquery | Any mirror where ParentCID = @CID |
| FROM | Customer.CustomerStatic | FROM | CID, GCID, CountryID, PlayerLevelID |
| JOIN | BackOffice.Customer | INNER JOIN | DesignatedRegulationID, TradingRiskStatusID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (execution routing) | @CID | EXEC caller | Lightweight eligibility/routing context checks |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUserInfoSlim (procedure)
+-- Trade.Mirror (table) [IsBeingCopied EXISTS]
+-- Customer.CustomerStatic (view/table)
+-- BackOffice.Customer (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | EXISTS check for IsBeingCopied |
| Customer.CustomerStatic | View/Table | CID, GCID, CountryID, PlayerLevelID |
| BackOffice.Customer | Table | DesignatedRegulationID, TradingRiskStatusID |

### 6.2 Objects That Depend On This

No documented dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH (NOLOCK) | Isolation | Dirty reads on CustomerStatic and BackOffice.Customer |
| ISNULL(DesignatedRegulationID, 0) | Pattern | Returns 0 when no override; callers fall back to base regulation |

---

## 8. Sample Queries

### 8.1 Get slim user context
```sql
EXEC Trade.GetUserInfoSlim @CID = 123456
```

### 8.2 Compare slim vs full GetUserInfo output
```sql
-- Slim: 7 columns, no credit, no block detail
EXEC Trade.GetUserInfoSlim @CID = 123456;

-- Full: 25 columns, credit in cents, block status, account type, etc.
EXEC Trade.GetUserInfo @CID = 123456;
```

### 8.3 N/A - third query not applicable

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUserInfoSlim | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUserInfoSlim.sql*
