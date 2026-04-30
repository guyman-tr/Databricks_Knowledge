# Dictionary.TradeLevel

> Lookup table defining user access levels for different trading platform interface versions.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | TradeLevelID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.TradeLevel controls which version of the trading platform UI a user can access. The platform offers different interface tiers: the standard eToro experience, a professional-grade "Pro" interface with advanced tools, and a simplified "Visual" interface. Some users may be restricted to specific interfaces only.

---

## 2. Business Logic

No complex multi-column business logic patterns detected.

---

## 3. Data Overview

| TradeLevelID | Name | Meaning |
|---|---|---|
| 0 | Normal | Standard eToro trading platform - default for all users |
| 1 | eToro Pro | Professional trading interface with advanced charting and order types |
| 2 | eToro Visual | Simplified visual trading interface for beginners |
| 3 | Pro Only | User restricted to Pro interface only |
| 4 | Visual Only | User restricted to Visual interface only |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TradeLevelID | int | NO | - | CODE-BACKED | Primary key. UI access level: 0=Normal, 1=eToro Pro, 2=eToro Visual, 3=Pro Only, 4=Visual Only. See [Trade Level](_glossary.md#trade-level). |
| 2 | Name | char(50) | NO | - | CODE-BACKED | Interface tier label. Padded char(50) type. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer user tables | TradeLevelID | Lookup | Stores user's assigned UI access level |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TradeLevel | CLUSTERED PK | TradeLevelID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all trade levels
```sql
SELECT TradeLevelID, RTRIM(Name) AS Name FROM Dictionary.TradeLevel WITH (NOLOCK) ORDER BY TradeLevelID
```

### 8.2 Find Pro users
```sql
SELECT u.CustomerID FROM Customer.Users u WITH (NOLOCK)
JOIN Dictionary.TradeLevel tl WITH (NOLOCK) ON u.TradeLevelID = tl.TradeLevelID WHERE tl.TradeLevelID IN (1, 3)
```

### 8.3 Trade level distribution
```sql
SELECT RTRIM(tl.Name) AS TradeLevel, COUNT(*) AS UserCount FROM Customer.Users u WITH (NOLOCK)
JOIN Dictionary.TradeLevel tl WITH (NOLOCK) ON u.TradeLevelID = tl.TradeLevelID GROUP BY tl.Name ORDER BY UserCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.TradeLevel | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.TradeLevel.sql*
