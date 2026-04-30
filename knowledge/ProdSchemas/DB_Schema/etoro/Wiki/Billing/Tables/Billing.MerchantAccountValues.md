# Billing.MerchantAccountValues

> Merchant account credentials and parameter store. Each row holds one parameter value for a specific merchant account, using a (MerchantAccountID, ParameterID) key. 279 entries storing API keys, entity names, boolean flags, and other per-merchant-account settings. The second half of the two-table merchant account system (routing in MerchantAccountRouting, credentials here).

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID - IDENTITY(1,1) PRIMARY KEY CLUSTERED; UNIQUE on (MerchantAccountID, ParameterID) |
| **Row Count** | 279 rows |
| **Partition** | N/A - filegroup PRIMARY |
| **Indexes** | 1 CLUSTERED PK on ID; 1 NONCLUSTERED UNIQUE on (MerchantAccountID, ParameterID) (FILLFACTOR=95) |

---

## 1. Business Meaning

`Billing.MerchantAccountValues` stores the credentials and settings for each merchant account. After `Billing.MerchantAccountRouting` resolves which `MerchantAccountID` to use for a payment context, `GetMerchantValues` joins here to retrieve all parameter values for that account.

Each merchant account (e.g., MerchantAccountID=1 "EU LTD") has multiple parameter entries:
- **ParameterID=9**: Entity/company name ("EU LTD", "UK LTD")
- **ParameterID=156**: API key identifier ("ApiKeyCheckoutEU")
- **ParameterID=167**: Boolean flag ("false")

The `Value` column stores everything as VARCHAR(4000), regardless of the actual type. A test/placeholder row exists with MerchantAccountID=0, ParameterID=0, Value="string".

---

## 2. Column Reference

| Column | Type | Nullable | Default | FK | Description |
|--------|------|----------|---------|-----|-------------|
| **ID** | int IDENTITY(1,1) | NOT NULL | Auto | - | [CODE-BACKED] Surrogate PK. NOT FOR REPLICATION. Physical clustered key. Not used as application-layer key. |
| **MerchantAccountID** | int | NOT NULL | - | Billing.MerchantAccountRouting(MerchantAccountID) [implicit] | [CODE-BACKED] Merchant account identifier; part of logical unique key. Groups all parameters for one merchant account. No explicit FK. |
| **ParameterID** | int | NULL | - | Billing.Parameter(ParameterID) [implicit] | [CODE-BACKED] Parameter type; part of logical unique key. Defines what this value represents (API key, entity name, flag, etc.). NULL allowed (MerchantAccountID=0 test row uses ParameterID=0). |
| **Value** | varchar(4000) | NOT NULL | - | - | [CODE-BACKED] The parameter value as a string. Values include API key names ("ApiKeyCheckoutEU"), entity names ("EU LTD"), boolean strings ("false"), and other credentials. Max 4000 chars. |

---

## 3. Index Reference

| Index | Type | Columns | Notes |
|-------|------|---------|-------|
| PK_Billing.MerchantAccountValues | CLUSTERED | ID ASC | FILLFACTOR=95. |
| UQ_MerchantAccountID_Parameter | NONCLUSTERED UNIQUE | (MerchantAccountID ASC, ParameterID ASC) | FILLFACTOR=95. Enforces one value per parameter per merchant account. Primary lookup path. |

---

## 4. Key Procedures

| Procedure | Role |
|-----------|------|
| `Billing.GetMerchantValues` | Primary reader: resolves merchant account via routing then returns all parameter values |
| `Billing.GetMerchantValues_V2` | Enhanced version |
| `Billing.GetMerchantValuesByMerchantID` | Direct lookup by MerchantAccountID |
| `Billing.GetMerchantValuesByDeposit` | Lookup via DepositID context |

---

## 5. Relationships

| Relation | Direction | Join | Notes |
|----------|-----------|------|-------|
| Billing.MerchantAccountRouting | Many-to-one | MerchantAccountValues.MerchantAccountID = MerchantAccountRouting.MerchantAccountID | Implicit. The routing table selects which merchant account to use; values table provides its parameters. |
| Billing.Parameter | Many-to-one | MerchantAccountValues.ParameterID = Parameter.ParameterID | Implicit. Defines parameter name/type. |

---

*Quality: 9.0/10 | 4 CODE-BACKED, 0 NAME-INFERRED | Phases: 1,2,3,5,8,9,11*
