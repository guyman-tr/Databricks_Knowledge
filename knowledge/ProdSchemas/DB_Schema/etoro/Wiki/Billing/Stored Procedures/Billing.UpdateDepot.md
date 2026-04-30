# Billing.UpdateDepot

> Activates or deactivates a payment depot in Billing.Depot - the first step in the Provider Recovery Service's depot state change sequence, followed by Billing.UpdateCardTypeToBank to propagate the change to card routing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @DepotID - targets Billing.Depot.IsActive |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdateDepot` is the Provider Recovery Service's primary control lever for taking a payment depot online or offline. A depot in `Billing.Depot` represents a specific acquiring bank / payment processor endpoint configuration (identified by its FundingTypeID, PaymentTypeID, ProtocolID combination). When a provider experiences downtime, connection failures, or planned maintenance, the recovery service calls this procedure to mark the depot as inactive (`IsActive=0`), removing it from the routing engine's eligibility pool and preventing new transactions from being routed to an unavailable endpoint.

The procedure works in tandem with `Billing.UpdateCardTypeToBank`: first, `UpdateDepot` marks the depot as inactive; then, `UpdateCardTypeToBank` propagates that change to the card-type routing table (`Dictionary.CardTypeToBank`) for all acquiring banks mapped to this depot. Together, these two procedures implement the full depot deactivation/reactivation cycle.

Called exclusively by the `ProviderRecoveryServiceUser` role, confirming this is automated recovery tooling (not manual operations). Of the 163 depots in `Billing.Depot`, 114 (70%) are currently active.

---

## 2. Business Logic

### 2.1 Depot Activation/Deactivation

**What**: Toggles the `IsActive` flag on a depot, controlling whether the routing engine can use this depot for new transactions.

**Columns/Parameters Involved**: `@DepotID`, `@IsActive`, `Billing.Depot.IsActive`

**Rules**:
- `UPDATE Billing.Depot SET IsActive = @IsActive WHERE DepotID = @DepotID`
- `@IsActive = 1`: depot comes online; routing engine can select this depot for new deposits/payouts
- `@IsActive = 0`: depot goes offline; routing engine skips this depot; in-flight transactions are not cancelled but new ones will not be routed here
- If `@DepotID` does not exist, the UPDATE silently affects 0 rows
- The routing engine uses `WHERE IsActive=1` when selecting depots, so this flag is the primary gating mechanism

**Recovery sequence**:
```
Provider outage detected:
  Step 1: EXEC Billing.UpdateDepot @DepotID=X, @IsActive=0
          -> Depot removed from routing pool immediately
  Step 2: EXEC Billing.UpdateCardTypeToBank @DepotID=X, @IsActive=0
          -> Visa/MC/Maestro card routing disabled for banks mapped to this depot
  (Routing engine now routes to fallback depots for this funding type/payment type/protocol)

Provider restored:
  Step 1: EXEC Billing.UpdateDepot @DepotID=X, @IsActive=1
          -> Depot re-added to routing pool
  Step 2: EXEC Billing.UpdateCardTypeToBank @DepotID=X, @IsActive=1
          -> Card routing re-enabled for banks mapped to this depot
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DepotID | BIGINT | NO | - | CODE-BACKED | The depot to activate or deactivate. Maps to `Billing.Depot.DepotID` (INT in the table, BIGINT in the SP parameter - implicit conversion). If DepotID does not exist, the UPDATE silently affects 0 rows. |
| 2 | @IsActive | BIT | NO | - | CODE-BACKED | Whether to activate (1) or deactivate (0) this depot. Written to `Billing.Depot.IsActive`. 1=depot is eligible for routing; 0=depot is excluded from routing. The routing engine's eligibility filter uses `WHERE IsActive=1`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE DepotID | Billing.Depot | UPDATE | Toggles IsActive on the target depot, controlling routing eligibility |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Provider Recovery service | @DepotID, @IsActive | EXEC (ProviderRecoveryServiceUser role) | Called as Step 1 of the depot state change sequence; followed by Billing.UpdateCardTypeToBank as Step 2 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdateDepot (procedure)
`- Billing.Depot (table) - UPDATE target

Provider Recovery sequence:
  Billing.UpdateDepot -> Billing.UpdateCardTypeToBank
  (depot IsActive change -> card routing propagation)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Depot | Table | UPDATE - sets IsActive=@IsActive WHERE DepotID=@DepotID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by Provider Recovery service (ProviderRecoveryServiceUser role). Typically followed by Billing.UpdateCardTypeToBank to complete the depot state change. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. `Billing.Depot` has a PK NONCLUSTERED on `DepotID` - the WHERE clause uses this index for an efficient single-row update.

### 7.2 Constraints

N/A for stored procedure. Note: `@DepotID` is declared as BIGINT while `Billing.Depot.DepotID` is INT - SQL Server performs implicit narrowing conversion (BIGINT -> INT). This works for all current DepotID values (max 174) but would fail for values exceeding INT range. Also note: deactivating a depot does NOT cancel in-flight transactions; it only prevents new routing decisions from selecting this depot.

---

## 8. Sample Queries

### 8.1 Take a depot offline (provider maintenance)
```sql
-- Step 1: Deactivate depot
EXEC Billing.UpdateDepot @DepotID = 13, @IsActive = 0;
-- Step 2: Propagate to card routing
EXEC Billing.UpdateCardTypeToBank @DepotID = 13, @IsActive = 0;
```

### 8.2 Bring a depot back online
```sql
-- Step 1: Reactivate depot
EXEC Billing.UpdateDepot @DepotID = 13, @IsActive = 1;
-- Step 2: Re-enable card routing
EXEC Billing.UpdateCardTypeToBank @DepotID = 13, @IsActive = 1;
```

### 8.3 Check current depot status
```sql
SELECT DepotID, Name, IsActive, FundingTypeID, PaymentTypeID, ProtocolID
FROM Billing.Depot WITH (NOLOCK)
WHERE DepotID = 13;
```

### 8.4 List all currently inactive depots
```sql
SELECT DepotID, Name, FundingTypeID, PaymentTypeID, ProtocolID
FROM Billing.Depot WITH (NOLOCK)
WHERE IsActive = 0
ORDER BY DepotID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (UpdateCardTypeToBank - companion SP) | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdateDepot | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdateDepot.sql*
