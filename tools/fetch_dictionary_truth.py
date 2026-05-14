"""Fetch Tier-1 dictionary truth for the audit, across three sources:
  - DWH_dbo.Dim_*       (default for most BI_DB / DWH wikis)
  - eMoney_Dictionary.* (for eMoney_dbo wikis and BI_DB eMoney-themed tables)
  - EXW_Dictionary.*    (for EXW_dbo/EXW_Wallet wikis)
plus a special-case for InstrumentTypeID / InstrumentType (synthesized from
SELECT DISTINCT in DWH_dbo.Dim_Instrument since there is no Dim_InstrumentType
table).

The output knowledge/_dictionary_truth.json has keys of the form
  "<column>"           — default lookup (DWH dimension)
  "<column>@eMoney"    — when the wiki file is under eMoney_dbo/
  "<column>@EXW"       — when the wiki file is under EXW_dbo/ or EXW_Wallet/
Decoded-sibling columns get pure aliases (e.g. "Club" -> same blob as
"PlayerLevelID"), so the audit can resolve them without any *ID suffix.

Usage:
  python tools/fetch_dictionary_truth.py
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO))
from synapse_connect import connect, run_query  # noqa: E402

OUT = REPO / "knowledge" / "_dictionary_truth.json"

# (wiki_column, schema, table, id_col, name_col)
DWH_DIMS: list[tuple[str, str, str, str, str]] = [
    ("AccountStatusID", "DWH_dbo", "Dim_AccountStatus", "AccountStatusID", "AccountStatusName"),
    ("AccountTypeID", "DWH_dbo", "Dim_AccountType", "AccountTypeID", "Name"),
    ("ActionTypeID", "DWH_dbo", "Dim_ActionType", "ActionTypeID", "Name"),
    ("BonusTypeID", "DWH_dbo", "Dim_BonusType", "BonusTypeID", "Name"),
    ("CardTypeID", "DWH_dbo", "Dim_CardType", "CardTypeID", "CarTypeName"),
    ("CashoutFeeGroupID", "DWH_dbo", "Dim_CashoutFeeGroup", "CashoutFeeGroupID", "CashoutFeeGroupName"),
    ("CashoutModeID", "DWH_dbo", "Dim_CashoutMode", "CashoutModeID", "CashoutModeName"),
    ("CashoutStatusID", "DWH_dbo", "Dim_CashoutStatus", "CashoutStatusID", "Name"),
    ("ClosePositionReasonID", "DWH_dbo", "Dim_ClosePositionReason", "ClosePositionReasonID", "Name"),
    ("ContractTypeID", "DWH_dbo", "Dim_ContractType", "ContractTypeID", "Name"),
    ("CountryID", "DWH_dbo", "Dim_Country", "CountryID", "Name"),
    ("CreditTypeID", "DWH_dbo", "Dim_CreditType", "CreditTypeID", "CreditTypeName"),
    ("CurrencyID", "DWH_dbo", "Dim_Currency", "CurrencyID", "Name"),
    ("CustomerChangeTypeID", "DWH_dbo", "Dim_CustomerChangeType", "CustomerChangeTypeID", "Name"),
    ("DocumentStatusID", "DWH_dbo", "Dim_DocumentStatus", "DocumentStatusID", "DocumentStatusName"),
    ("EvMatchStatusID", "DWH_dbo", "Dim_EvMatchStatus", "EvMatchStatusID", "EvMatchStatusName"),
    ("FundTypeID", "DWH_dbo", "Dim_FundType", "FundTypeID", "FundTypeName"),
    ("FundingTypeID", "DWH_dbo", "Dim_FundingType", "FundingTypeID", "Name"),
    ("GuruStatusID", "DWH_dbo", "Dim_GuruStatus", "GuruStatusID", "GuruStatusName"),
    ("LabelID", "DWH_dbo", "Dim_Label", "LabelID", "Name"),
    ("LanguageID", "DWH_dbo", "Dim_Language", "LanguageID", "Name"),
    ("MifidCategorizationID", "DWH_dbo", "Dim_MifidCategorization", "MifidCategorizationID", "Name"),
    ("MirrorTypeID", "DWH_dbo", "Dim_MirrorType", "MirrorTypeID", "MirrorTypeName"),
    ("MoveMoneyReasonID", "DWH_dbo", "Dim_MoveMoneyReason", "MoveMoneyReasonID", "MoveMoneyReason"),
    ("PaymentStatusID", "DWH_dbo", "Dim_PaymentStatus", "PaymentStatusID", "Name"),
    ("PendingClosureStatusID", "DWH_dbo", "Dim_PendingClosureStatus", "PendingClosureStatusID", "PendingClosureStatusName"),
    ("PhoneVerifiedID", "DWH_dbo", "Dim_PhoneVerified", "PhoneVerifiedID", "PhoneVerifiedName"),
    ("PlatformID", "DWH_dbo", "Dim_Platform", "PlatformID", "Platform"),
    ("PlatformTypeID", "DWH_dbo", "Dim_PlatformType", "ProductID", "Platform"),
    ("PlayerLevelID", "DWH_dbo", "Dim_PlayerLevel", "PlayerLevelID", "Name"),
    ("PlayerStatusID", "DWH_dbo", "Dim_PlayerStatus", "PlayerStatusID", "Name"),
    ("ProductID", "DWH_dbo", "Dim_Product", "ProductID", "Product"),
    ("RegulationID", "DWH_dbo", "Dim_Regulation", "ID", "Name"),
    ("RiskClassificationID", "DWH_dbo", "Dim_RiskClassification", "RiskClassificationID", "RiskClassificationName"),
    ("RiskManagementStatusID", "DWH_dbo", "Dim_RiskManagementStatus", "RiskManagementStatusID", "Name"),
    ("RiskStatusID", "DWH_dbo", "Dim_RiskStatus", "RiskStatusID", "Name"),
    ("ScreeningStatusID", "DWH_dbo", "Dim_ScreeningStatus", "ScreeningStatusID", "Name"),
    ("SocialNetworkID", "DWH_dbo", "Dim_SocialNetwork", "SocialNetworkID", "Name"),
    ("VerificationLevelID", "DWH_dbo", "Dim_VerificationLevel", "ID", "Name"),
    ("WorldCheckID", "DWH_dbo", "Dim_WorldCheck", "WorldCheckID", "WorldCheckName"),
]

# eMoney_Dictionary tables all have shape (Id, Name).
EMONEY_DIMS: list[tuple[str, str, str, str, str]] = [
    ("AccountProgramID", "eMoney_Dictionary", "AccountPrograms", "Id", "Name"),
    ("AccountStatusID@eMoney", "eMoney_Dictionary", "AccountStatuses", "Id", "Name"),
    ("AuthorizationTypeID", "eMoney_Dictionary", "AuthorizationTypes", "Id", "Name"),
    ("CardStatusID", "eMoney_Dictionary", "CardStatuses", "Id", "Name"),
    ("CurrencyBalanceStatusID", "eMoney_Dictionary", "CurrencyBalanceStatuses", "Id", "Name"),
    ("PaymentSchemaTypeID", "eMoney_Dictionary", "PaymentSchemaType", "Id", "Name"),
    ("PaymentSpecificationStatusTypeID", "eMoney_Dictionary", "PaymentSpecificationStatusTypes", "Id", "Name"),
    ("PaymentSpecificationTypeID", "eMoney_Dictionary", "PaymentSpecificationTypes", "Id", "Name"),
    ("ProviderID", "eMoney_Dictionary", "Providers", "Id", "Name"),
    ("TransactionCategoryID@eMoney", "eMoney_Dictionary", "TransactionCategories", "Id", "Name"),
    ("TxCategoryID@eMoney", "eMoney_Dictionary", "TransactionCategories", "Id", "Name"),
    ("TransactionStatusID@eMoney", "eMoney_Dictionary", "TransactionStatuses", "Id", "Name"),
    ("TxStatusID@eMoney", "eMoney_Dictionary", "TransactionStatuses", "Id", "Name"),
    ("TransactionTypeID@eMoney", "eMoney_Dictionary", "TransactionTypes", "Id", "Name"),
    ("TxTypeID@eMoney", "eMoney_Dictionary", "TransactionTypes", "Id", "Name"),
    ("TribeScriptStatusID", "eMoney_Dictionary", "TribeScriptStatus", "Id", "Name"),
]

EXW_DIMS: list[tuple[str, str, str, str, str]] = [
    ("ChecksumTypeID", "EXW_Dictionary", "ChecksumTypes", "Id", "Name"),
    ("ConversionStatusID", "EXW_Dictionary", "ConversionStatuses", "Id", "Name"),
    ("CountryGroupID", "EXW_Dictionary", "CountryGroup", "CountryGroupID", "CountryGroupName"),
    ("CryptoCoinProviderID", "EXW_Dictionary", "CryptoCoinProviders", "Id", "Name"),
    ("DynamicGroupID", "EXW_Dictionary", "DynamicGroup", "DynamicGroupID", "Name"),
    ("ManualApproveTransactionStatusID", "EXW_Dictionary", "ManualApproveTransactionStatus", "Id", "Name"),
    ("PaymentStatusID@EXW", "EXW_Dictionary", "PaymentStatuses", "Id", "Name"),
    ("ReceivedTransactionTypeID", "EXW_Dictionary", "ReceivedTransactionTypes", "Id", "Name"),
    ("RequestStatusID", "EXW_Dictionary", "RequestStatuses", "Id", "Name"),
    ("RequestLastStatusID", "EXW_Dictionary", "RequestStatuses", "Id", "Name"),
    ("RequestTypeID", "EXW_Dictionary", "RequestTypes", "Id", "Name"),
    ("StakingStatusID", "EXW_Dictionary", "StakingStatuses", "Id", "Name"),
    ("TransactionStatusID@EXW", "EXW_Dictionary", "TransactionStatus", "Id", "Name"),
    ("TranStatusID@EXW", "EXW_Dictionary", "TransactionStatus", "Id", "Name"),
    ("TransactionTypeID@EXW", "EXW_Dictionary", "TransactionTypes", "Id", "Name"),
    ("WalletPoolStatusID", "EXW_Dictionary", "WalletPoolStatuses", "Id", "Name"),
    ("WalletProviderID", "EXW_Dictionary", "WalletProvider", "Id", "Name"),
    ("WalletTypeID", "EXW_Dictionary", "WalletTypes", "Id", "Name"),
]

# Decoded-column aliases (column name in the wiki -> primary truth key).
# These mirror an existing entry; the audit will look them up directly.
ALIAS_MAP: dict[str, str] = {
    # Decoded siblings of *ID columns (DWH dims)
    "Country": "CountryID",
    "Currency": "CurrencyID",
    "PlayerLevel": "PlayerLevelID",
    "Club": "PlayerLevelID",
    "Tier": "PlayerLevelID",
    "CurrentTier": "PlayerLevelID",
    "PlayerStatus": "PlayerStatusID",
    "AccountType": "AccountTypeID",
    "AccountStatus": "AccountStatusID",
    "Label": "LabelID",
    "Regulation": "RegulationID",
    "Language": "LanguageID",
    "CardType": "CardTypeID",
    "ContractType": "ContractTypeID",
    "GuruStatus": "GuruStatusID",
    "DocumentStatus": "DocumentStatusID",
    "CreditType": "CreditTypeID",
    "MoveMoneyReason": "MoveMoneyReasonID",
    "BonusType": "BonusTypeID",
    "ActionType": "ActionTypeID",
    "ClosePositionReason": "ClosePositionReasonID",
    "CashoutMode": "CashoutModeID",
    "CashoutStatus": "CashoutStatusID",
    "EvMatchStatus": "EvMatchStatusID",
    "FundType": "FundTypeID",
    "FundingType": "FundingTypeID",
    "MifidCategorization": "MifidCategorizationID",
    "PaymentStatus": "PaymentStatusID",
    "PendingClosureStatus": "PendingClosureStatusID",
    "PhoneVerified": "PhoneVerifiedID",
    "Platform": "PlatformID",
    "Product": "ProductID",
    "RiskClassification": "RiskClassificationID",
    "RiskManagementStatus": "RiskManagementStatusID",
    "RiskStatus": "RiskStatusID",
    "ScreeningStatus": "ScreeningStatusID",
    "SocialNetwork": "SocialNetworkID",
    "VerificationLevel": "VerificationLevelID",
    "WorldCheck": "WorldCheckID",
    "MirrorType": "MirrorTypeID",
    "CustomerChangeType": "CustomerChangeTypeID",
    "InstrumentType": "InstrumentTypeID",
    # Decoded siblings of eMoney / EXW columns
    "AuthorizationType": "AuthorizationTypeID",
    "CardStatus": "CardStatusID",
    "CurrencyBalanceStatus": "CurrencyBalanceStatusID",
    "PaymentSchemaType": "PaymentSchemaTypeID",
    "Provider": "ProviderID",
    "TransactionCategory": "TransactionCategoryID@eMoney",
    "TransactionType": "TransactionTypeID@eMoney",   # primary; @EXW also covered
    "TxType": "TxTypeID@eMoney",
    "TransactionStatus": "TransactionStatusID@eMoney",
    "TxStatus": "TxStatusID@eMoney",
    "ConversionStatus": "ConversionStatusID",
    "RequestStatus": "RequestStatusID",
    "LastWalletPoolStatus": "WalletPoolStatusID",
    "WalletPoolStatus": "WalletPoolStatusID",
    "WalletType": "WalletTypeID",
    "WalletProvider": "WalletProviderID",
    "StakingStatus": "StakingStatusID",
}


def _fetch_one(cn, key: str, schema: str, table: str, id_col: str, name_col: str) -> dict:
    sql = (
        f"SELECT CAST([{id_col}] AS NVARCHAR(16)) AS id, "
        f"CAST([{name_col}] AS NVARCHAR(256)) AS name "
        f"FROM [{schema}].[{table}]"
    )
    try:
        cols, rows = run_query(cn, sql)
        rowmap = {str(r[0]): (r[1] or "").strip() for r in rows}
        return {
            "key": key,
            "schema": schema,
            "table": table,
            "dim": f"{schema}.{table}",
            "id_col": id_col,
            "name_col": name_col,
            "rows": rowmap,
        }
    except Exception as e:
        return {
            "key": key,
            "schema": schema,
            "table": table,
            "dim": f"{schema}.{table}",
            "id_col": id_col,
            "name_col": name_col,
            "rows": {},
            "error": str(e).replace("\n", " ")[:200],
        }


def main() -> None:
    sys.stdout.reconfigure(line_buffering=True)
    print("Connecting to Synapse...", flush=True)
    cn = connect()
    truth: dict[str, dict] = {}

    for src_name, src in (("DWH_dbo", DWH_DIMS), ("eMoney_Dictionary", EMONEY_DIMS),
                          ("EXW_Dictionary", EXW_DIMS)):
        print(f"\n[{src_name}] fetching {len(src)} dictionaries", flush=True)
        for key, schema, table, id_col, name_col in src:
            entry = _fetch_one(cn, key, schema, table, id_col, name_col)
            truth[key] = {k: v for k, v in entry.items() if k != "key"}
            err = entry.get("error")
            count = len(entry.get("rows") or {})
            tag = f"  {key:<36} -> {schema}.{table:<32} {count:>5} rows"
            if err:
                tag += f"  ERROR: {err}"
            print(tag, flush=True)

    # Special case: InstrumentTypeID has no Dim_InstrumentType. Synthesize from
    # SELECT DISTINCT in Dim_Instrument.
    print("\n[special] InstrumentTypeID via Dim_Instrument DISTINCT", flush=True)
    try:
        cols, rows = run_query(
            cn,
            "SELECT DISTINCT CAST(InstrumentTypeID AS NVARCHAR(16)) AS id, "
            "CAST(InstrumentType AS NVARCHAR(256)) AS name "
            "FROM DWH_dbo.Dim_Instrument WHERE InstrumentTypeID IS NOT NULL "
            "ORDER BY id",
        )
        rowmap = {str(r[0]): (r[1] or "").strip() for r in rows}
        truth["InstrumentTypeID"] = {
            "schema": "DWH_dbo", "table": "Dim_Instrument (DISTINCT)",
            "dim": "DWH_dbo.Dim_Instrument (DISTINCT InstrumentTypeID/InstrumentType)",
            "id_col": "InstrumentTypeID", "name_col": "InstrumentType",
            "rows": rowmap,
        }
        print(f"  InstrumentTypeID                     -> Dim_Instrument distinct "
              f"{len(rowmap):>5} rows", flush=True)
    except Exception as e:
        print(f"  InstrumentTypeID  ERROR: {e}", flush=True)

    cn.close()

    # Apply aliases (one-level only; alias-of-alias forbidden).
    print(f"\n[aliases] adding {len(ALIAS_MAP)} decoded-sibling pointers", flush=True)
    for alias_col, primary_key in ALIAS_MAP.items():
        if primary_key not in truth:
            print(f"  WARN: alias '{alias_col}' -> '{primary_key}' not in truth; skipping",
                  flush=True)
            continue
        if alias_col in truth:
            continue  # alias name collides with a real key, leave the real one
        primary = truth[primary_key]
        truth[alias_col] = {
            **primary,
            "alias_of": primary_key,
        }

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(truth, indent=2, sort_keys=True), encoding="utf-8")
    total = sum(len(t.get("rows") or {}) for t in truth.values()
                if not t.get("alias_of"))
    print(f"\nWrote truth cache: {OUT.relative_to(REPO)}  "
          f"({len(truth)} keys, {total} unique truth rows)", flush=True)


if __name__ == "__main__":
    main()
