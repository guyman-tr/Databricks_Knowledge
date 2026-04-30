# Monitoring.GetTravelRuleAddressMatches

> Detects travel rule transactions where the counterparty address matches an internal wallet address, indicating potential internal-to-internal transfers being incorrectly processed through the travel rule flow.

| Property | Value |
|----------|-------|
| **Schema** | Monitoring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns travel rule transactions with internal address matches |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Monitoring.GetTravelRuleAddressMatches identifies travel rule transactions where the counterparty's blockchain address belongs to an internal wallet. Travel rules are designed for external transfers - if the counterparty is actually an internal wallet, the travel rule verification was unnecessary and may indicate a classification bug in the transfer pipeline.

Without this procedure, internal-to-internal transfers incorrectly flagged for travel rule compliance would waste compliance resources and delay customer transactions unnecessarily.

The procedure checks both Address and NormalizedAddress matches using UNION ALL to catch both forms, joining to CustomerWalletsView to confirm the matched address belongs to an internal wallet.

---

## 2. Business Logic

### 2.1 Internal Address Detection

**What**: Matches travel rule counterparty addresses against internal wallet addresses.

**Columns/Parameters Involved**: `CounterpartyAddress`, `Address`, `NormalizedAddress`, `@HoursBack`

**Rules**:
- Checks CounterpartyAddress against WalletAddresses.Address (exact match)
- Also checks CounterpartyAddress against WalletAddresses.NormalizedAddress (normalized match)
- Both paths joined to CustomerWalletsView to confirm wallet ownership
- UNION ALL combines both match types
- Default lookback: 24 hours

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HoursBack | INT | NO | 24 | CODE-BACKED | Lookback window in hours. Default 24 hours. |

**Output Columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Address | NVARCHAR | NO | - | CODE-BACKED | The matching internal wallet address. |
| 2 | NormalizedAddress | NVARCHAR | YES | - | CODE-BACKED | Normalized form of the address. |
| 3 | WalletId | BIGINT | NO | - | CODE-BACKED | Internal wallet ID that owns the matched address. |
| 4 | Id | BIGINT | NO | - | CODE-BACKED | TransactionTravelRuleInformation ID of the flagged transaction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Query body | Wallet.TransactionTravelRuleInformation | FROM (read) | Travel rule records with counterparty addresses |
| Query body | Wallet.WalletAddresses | JOIN | Internal address matching |
| Query body | Wallet.CustomerWalletsView | JOIN | Wallet ownership confirmation |

### 5.2 Referenced By (other objects point to this)

No DB-level callers found. Called by external monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Monitoring.GetTravelRuleAddressMatches (procedure)
  ├── Wallet.TransactionTravelRuleInformation (table)
  ├── Wallet.WalletAddresses (table)
  └── Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionTravelRuleInformation | Table | FROM - TR records |
| Wallet.WalletAddresses | Table | JOIN - address matching |
| Wallet.CustomerWalletsView | View | JOIN - ownership |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check last 24 hours (default)
```sql
EXEC Monitoring.GetTravelRuleAddressMatches;
```

### 8.2 Check last week
```sql
EXEC Monitoring.GetTravelRuleAddressMatches @HoursBack = 168;
```

### 8.3 Check if a specific address is internal
```sql
SELECT wa.Address, wa.WalletId, cwv.Gcid
FROM Wallet.WalletAddresses wa WITH (NOLOCK)
JOIN Wallet.CustomerWalletsView cwv WITH (NOLOCK) ON cwv.Id = wa.WalletId
WHERE wa.Address = '0x1234...';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Monitoring.GetTravelRuleAddressMatches | Type: Stored Procedure | Source: WalletDB/Monitoring/Stored Procedures/Monitoring.GetTravelRuleAddressMatches.sql*
