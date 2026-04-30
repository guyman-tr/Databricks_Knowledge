# Billing.UpdateCardTypeToBank

> Activates or deactivates Visa/MasterCard/Maestro routing entries in Dictionary.CardTypeToBank for all acquiring banks mapped to a given payment depot - used by the provider recovery service to propagate depot state changes to card type routing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepotID, @IsActive - targets Dictionary.CardTypeToBank rows for banks in Billing.BankToDepot |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateCardTypeToBank` propagates a depot's active/inactive state to the card-type-to-bank routing table. When a payment depot goes offline (provider maintenance, connection failure) or comes back online, the Provider Recovery Service calls this procedure to enable or disable Visa (1), MasterCard (2), and Maestro (8) routing through all acquiring banks associated with that depot.

The logic resolves which banks to update via `Billing.BankToDepot` - it finds all banks mapped to the given depot, then updates `Dictionary.CardTypeToBank.IsActive` for those banks, but only for the three main card types (1=Visa, 2=MasterCard, 8=Maestro). This is targeted: Diners (3), Amex (4/7), JCB (6) and other inactive card types are not touched. The hardcoded card type filter (1, 2, 8) represents the three active card networks supported by the depot routing system.

Called exclusively by the ProviderRecoveryServiceUser role, confirming this is automated recovery tooling rather than a manual operation.

---

## 2. Business Logic

### 2.1 Depot-Driven Card Routing Toggle

**What**: Translates a depot-level enable/disable action into card-type routing changes by traversing the BankToDepot relationship.

**Columns/Parameters Involved**: `@DepotID`, `@IsActive`, `Billing.BankToDepot.BankID`, `Dictionary.CardTypeToBank.IsActive`, `Dictionary.CardTypeToBank.CardTypeID`

**Rules**:
- Step 1: CTE `MappedBanks` finds all DISTINCT BankIDs from `Billing.BankToDepot` WHERE `DepotID = @DepotID`
- Step 2: UPDATE `Dictionary.CardTypeToBank` SET `IsActive = @IsActive` for all rows WHERE `BankID IN MappedBanks` AND `CardTypeID IN (1, 2, 8)`
- `@IsActive = 1`: enables routing (depot coming online)
- `@IsActive = 0`: disables routing (depot going offline)
- CardTypeID filter (1, 2, 8) = Visa, MasterCard, Maestro ONLY - the three active card networks in the routing system
- CardTypeID 3 (Diners) is not updated despite being in Dictionary.CardTypeToBank - Diners uses different routing
- If a depot has no banks in BankToDepot, the CTE returns empty and no rows are updated (safe no-op)

**Diagram**:
```
Provider recovery: Depot X goes offline
  |
  EXEC UpdateCardTypeToBank @DepotID=X, @IsActive=0
    |
    CTE MappedBanks: SELECT DISTINCT BankID FROM Billing.BankToDepot WHERE DepotID=X
    -> BankIDs: [1, 3, 7, ...]
    |
    UPDATE Dictionary.CardTypeToBank SET IsActive=0
    WHERE BankID IN (1,3,7,...) AND CardTypeID IN (1,2,8)
    -> Visa/MC/Maestro routing disabled for all banks linked to Depot X

Provider recovery: Depot X comes back online
  -> EXEC UpdateCardTypeToBank @DepotID=X, @IsActive=1
  -> Same path, SET IsActive=1 (re-enables routing)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepotID | BIGINT | NO | - | CODE-BACKED | The payment depot whose associated banks' card routing should be updated. Maps to `Billing.BankToDepot.DepotID`. All banks mapped to this depot via BankToDepot are resolved and their CardTypeToBank entries updated. |
| 2 | @IsActive | BIT | NO | - | CODE-BACKED | Whether to activate (1) or deactivate (0) card routing for the resolved banks. Applied to `Dictionary.CardTypeToBank.IsActive` for CardTypeID IN (1=Visa, 2=MasterCard, 8=Maestro) only. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepotID (CTE lookup) | Billing.BankToDepot | SELECT (CTE) | Resolves which acquiring banks are mapped to the given depot |
| BankID (from CTE) | Dictionary.CardTypeToBank | UPDATE (cross-schema) | Sets IsActive for Visa/MC/Maestro rows matching the resolved banks |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Provider Recovery service | @DepotID, @IsActive | EXEC (ProviderRecoveryServiceUser role) | Called when a payment depot changes operational state (online/offline) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateCardTypeToBank (procedure)
├── Billing.BankToDepot (table) - SELECT in CTE
└── Dictionary.CardTypeToBank (table) - UPDATE
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.BankToDepot | Table | CTE SELECT - finds all BankIDs mapped to @DepotID; WITH NOLOCK (read-only) |
| Dictionary.CardTypeToBank | Table | UPDATE - sets IsActive=@IsActive for Visa/MC/Maestro rows for resolved banks |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by Provider Recovery service (ProviderRecoveryServiceUser role). |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. Note: The hardcoded CardTypeID IN (1, 2, 8) filter is intentional - it limits updates to Visa, MasterCard, and Maestro only. Other card types in Dictionary.CardTypeToBank (Diners=3, etc.) are not affected by depot state changes.

---

## 8. Sample Queries

### 8.1 Preview which banks and routing entries would be affected for a depot
```sql
-- See what BankToDepot entries exist for a depot
SELECT DISTINCT btd.BankID, ctb.CardTypeID, ctb.IsActive
FROM Billing.BankToDepot btd WITH (NOLOCK)
INNER JOIN Dictionary.CardTypeToBank ctb WITH (NOLOCK) ON ctb.BankID = btd.BankID
WHERE btd.DepotID = 13
  AND ctb.CardTypeID IN (1, 2, 8)
ORDER BY btd.BankID, ctb.CardTypeID;
```

### 8.2 Disable Visa/MC/Maestro routing for a depot going offline
```sql
-- Deactivate card routing when depot goes offline
EXEC Billing.UpdateCardTypeToBank @DepotID = 13, @IsActive = 0;
```

### 8.3 Re-enable card routing when a depot comes back online
```sql
-- Re-activate after depot recovery
EXEC Billing.UpdateCardTypeToBank @DepotID = 13, @IsActive = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateCardTypeToBank | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateCardTypeToBank.sql*
