"""Annotate each candidate row with the target Dim_X wiki (or unresolved).

Strategy:
  1) Hand-curated irregular map for known eToro shorthand (`Club -> Dim_PlayerLevel`).
  2) Heuristic `<X>ID -> Dim_<X>` if the Dim wiki exists.
  3) `Dictionary.<X>` fallback when no Dim wiki found but column shape is clear.
  4) Mark unresolved otherwise.

Self-reference suppression: if the wiki being scanned IS the target Dim AND the
column is the natural-key/label of that Dim, the row is dropped (KEEP policy).
"""
from __future__ import annotations

import csv
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
WIKI = REPO / "knowledge" / "synapse" / "Wiki"

# Hand-curated, empirically grounded. Keys are the EXACT column name as it
# appears in wiki Elements rows. Values are the target Dim_X wiki stem.
IRREGULAR_DIM_MAP: dict[str, str] = {
    # --- naming-shift columns (rebrand / shorthand) ---
    "Club": "Dim_PlayerLevel",
    "ClubID": "Dim_PlayerLevel",
    "Club_ID": "Dim_PlayerLevel",
    "Previous_ClubID": "Dim_PlayerLevel",
    "PlayerLevel": "Dim_PlayerLevel",
    "CurrentLevel": "Dim_PlayerLevel",
    "OldTier": "Dim_PlayerLevel",
    "CurrentTier": "Dim_PlayerLevel",
    "LastDowngradeID": "Dim_PlayerLevel",

    # --- regulation ---
    "WalletRegulation": "Dim_Regulation",
    "CurrentRegulationID": "Dim_Regulation",

    # --- instrument / instrument-type (type lives inside Dim_Instrument) ---
    "InstrumentType": "Dim_Instrument",
    "InstrumentTypeID": "Dim_Instrument",
    "InstrumentTypeName": "Dim_Instrument",
    "instrument_type_id": "Dim_Instrument",

    # --- currency ---
    "Currency": "Dim_Currency",
    "CurrencyTypeID": "Dim_Currency",
    "CurrencyBalanceISOCode": "Dim_Currency",
    "CurrencyIson": "Dim_Currency",
    "FiatID": "Dim_Currency",
    "FiatId": "Dim_Currency",

    # --- crypto ---
    "BlockchainCryptoId": "Dim_Currency",  # crypto IDs live alongside currency
    "CryptoCoinProviderId": "Dim_Currency",
    "CryptoID": "Dim_Currency",
    "CryptoId": "Dim_Currency",

    # --- contract / commercial ---
    "ContractType": "Dim_ContractType",

    # --- card / payment ---
    "CardType": "Dim_CardType",
    "CardStatus": "Dim_CardType",  # statuses are 3DS / Active codes per card type
    "CardStatusID": "Dim_CardType",
    "CreditCardType": "Dim_CardType",
    "PaymentActionStatusID": "Dim_PaymentStatus",
    "PaymentActionTypeID": "Dim_PaymentStatus",
    "PaymentSchemaType": "Dim_PaymentStatus",
    "PaymentSchemaTypeID": "Dim_PaymentStatus",
    "PaymentTypeID": "Dim_PaymentStatus",
    "PaymentOrderStatus": "Dim_PaymentStatus",
    "PaymentStatus_PaymentStatusID": "Dim_PaymentStatus",
    "TranStatusID": "Dim_PaymentStatus",
    "TransactionCode": "Dim_PaymentStatus",
    "Mcc": "Dim_PaymentStatus",  # MCC = merchant category code, near payment
    "ECIIndicator": "Dim_PaymentStatus",
    "ErrorCode": "Dim_PaymentStatus",
    "AuthorizationType": "Dim_PaymentStatus",
    "AuthorizationTypeID": "Dim_PaymentStatus",
    "ThreeDsResponseTypeID": "Dim_ThreeDsResponseTypes",
    "TransactionStatus": "Dim_PaymentStatus",
    "TransactionStatusID": "Dim_PaymentStatus",
    "TransactionType": "Dim_FundingType",
    "TransactionTypeID": "Dim_FundingType",
    "TransactionTypeId": "Dim_FundingType",
    "TransactionCategoryID": "Dim_FundingType",
    "ReceivedTransactionTypeID": "Dim_FundingType",
    "ReceivedTransactionTypeId": "Dim_FundingType",
    "TxTypeID": "Dim_FundingType",

    # --- channel / sub-channel ---
    "SubChannelID": "Dim_Channel",

    # --- KYC / verification ---
    "LevelId": "Dim_VerificationLevel",
    "NoTIN_Reason": "Dictionary.NoTINReason",  # no Dim wiki - synapse-only
    "NoTIN_ReasonID": "Dictionary.NoTINReason",
    "Q23_Is_Assessment_Pass": "",  # boolean codepoint, not a dim
    "Is_Assessment_101_104_Pass": "",  # boolean codepoint
    "HasSelfie": "",  # boolean codepoint
    "PhoneVerifiedID": "Dim_PhoneVerified",
    "AmlProviderId": "Dictionary.AmlProvider",

    # --- risk ---
    "RiskClassID": "Dim_RiskClassification",
    "PreviousRiskClassID": "Dim_RiskClassification",
    "RiskGroupID": "Dictionary.RiskGroup",
    "RiskScore": "Dim_RiskStatus",

    # --- target platform routing ---
    "TargetPlatformID": "Dim_Platform",

    # --- wallet / tangany / blockchain ---
    "TanganyStatus": "Dictionary.TanganyStatus",
    "TanganyStatusID": "Dictionary.TanganyStatus",
    "WalletPoolStatusId": "Dictionary.WalletPoolStatus",
    "LastWalletPoolStatus": "Dictionary.WalletPoolStatus",
    "WalletTypeId": "Dictionary.WalletType",
    "InternalWalletTypeId": "Dictionary.WalletType",
    "DepotModeID": "Dim_BillingDepot",
    "ProtocolID": "Dim_BillingProtocolMIDSettingsID",

    # --- close-position / open-position reasons ---
    "OpenPositionReasonID": "Dim_ClosePositionReason",
    "RollbackReason": "Dim_ClosePositionReason",
    "PendingClosureStatusName": "Dim_PendingClosureStatus",

    # --- compensation ---
    "Compensation": "Dim_CompensationReason",
    "CompensationReasonID": "Dim_CompensationReason",

    # --- conversion ---
    "IsConversion": "",  # boolean codepoint
    "IsFeeDividend": "",
    "IsRedeem": "",
    "IsSettled": "",
    "Blocked": "",
    "Active_Trade_or_Loggedin": "",
    "CanDeposit": "",
    "OpenCashout": "",
    "CountryOpenforWallet": "",

    # --- AML / abuse rankings ---
    "AML_Rank": "Dictionary.AMLRank",
    "KYC_Country_Rank": "Dictionary.CountryRank",
    "CountryRank": "Dictionary.CountryRank",
    "CountryRankID": "Dictionary.CountryRank",
    "CountryRankDescription": "Dictionary.CountryRank",

    # --- fee / cost ---
    "FeeOperationTypeID": "Dim_FeeOperationTypes",
    "AccountFeeGroupId": "Dim_CashoutFeeGroup",
    "AccountLimitsGroupId": "Dictionary.AccountLimitsGroup",
    "AccountProgram": "Dictionary.AccountProgram",
    "AccountProgramID": "Dictionary.AccountProgram",
    "Program": "Dictionary.AccountProgram",
    "ProgramId": "Dictionary.AccountProgram",
    "AccountStatus": "Dim_AccountStatus",
    "CostConfigurationId": "Dim_CostConfigurationId",
    "FundType": "Dim_FundType",

    # --- conversion status / various pipeline statuses (no Dim wiki) ---
    "ConversionStatusID": "Dictionary.ConversionStatus",
    "RequestLastStatusID": "Dictionary.RequestStatus",
    "RequestStatusId": "Dictionary.RequestStatus",
    "RequestTypeId": "Dictionary.RequestType",
    "TribeScriptStatus": "Dictionary.TribeScriptStatus",
    "TribeScriptStatusID": "Dictionary.TribeScriptStatus",
    "InstanceStatus": "Dictionary.InstanceStatus",

    # --- generic Status / ID without context (AMBIGUOUS - user must decide) ---
    "ID": "",
    "Status": "",
    "StatusID": "",
    "StatusId": "",
    "TypeID": "",
    "ParentID": "",
    "Sort": "",
    "CurrentSort": "",
    "OldSort": "",
    "Entity": "",
    "Mode": "",
    "OrderType": "",
    "PortfolioType": "",
    "PositionType": "",
    "AttributedID": "",  # disambiguation: marketing attribution dim is missing
    "HedgeServerID": "",
    "InterestRateID": "",
    "OperationTypeId": "",
    "AnswerId": "",
    "UserInteractionActionId": "",
    "QuestionId": "",
    "FieldID": "Dim_ExtendedUserField",
    "FieldTypeID": "Dim_ExtendedUserField",
    "ExtendedUserField": "Dim_ExtendedUserField",

    # --- profile / professional ---
    "ProfessionalStatus": "Dim_VerificationStatus",

    # --- revenue metric ---
    "RevenueMetricCategoryID": "Dim_Revenue_Metrics",
    "NetProfit_Other": "",
    "RevShare": "",
    "ClubRevShare": "",

    # --- change type ---
    "ChangeTypeID": "Dim_CustomerChangeType",

    # --- google geo (no Dim wiki) ---
    "country_criteria_id": "Dictionary.GoogleGeoCriteria",
    "CountryCode": "Dim_Country",

    # --- mirror sync ---
    "CloseMirrorActionType": "Dim_MirrorType",

    # --- doc status name (label echoes ID) ---
    "DocumentStatusName": "Dim_DocumentStatus",
    "MifidCatigorization": "Dim_MifidCategorization",  # typo upstream
    "EV_MatchStatusID": "Dim_EvMatchStatus",
    "RefreshIntervalMonths": "",  # numeric, not a dim
    "NumericCode": "",
    "MonthsSinceFirstOpen": "",
    "Age_On_Reg_grouped_Index": "",
    "RiskClassificationID": "Dim_RiskClassification",
    "RiskManagementStatusID": "Dim_RiskManagementStatus",
    "SelectedValue": "",  # generic survey answer
    "TierCountry": "Dictionary.CountryRank",
    "WorldCheckID": "Dim_WorldCheck",
    "SettlementTypeID": "Dictionary.SettlementType",
    "CashoutModeWeight": "Dim_CashoutMode",
    "CashoutStatusID_Withdraw": "Dim_CashoutStatus",
    "OpenPositionReasonID_": "Dim_ClosePositionReason",
    "MoveMoneyReasonID": "Dim_MoveMoneyReason",
    "FTDPlatformID": "Dim_FTDPlatform",
    "CarTypeName": "Dim_CardType",  # typo
    "etoro - CashoutStatus": "Dim_CashoutStatus",
    "etoro - RedeemReason": "Dim_RedeemReason",
    "etoro - RedeemStatus": "Dim_RedeemStatus",

    # --- balance status ---
    "CurrencyBalanceStatus": "",  # status string, not a Dim
    "CurrencyBalanceStatusID": "",
}

# Skip rule: if the wiki being scanned IS the target Dim AND the column is its
# own natural-key/label, KEEP the verbose enum (the dim is the source of truth).
SELF_REF_KEY_PATTERNS = ("ID", "Name", "id", "name")


def list_dim_wikis() -> dict[str, Path]:
    """Return {Dim_X: path-to-Dim_X.md} for every dim wiki."""
    out: dict[str, Path] = {}
    for p in WIKI.rglob("Dim_*.md"):
        if (p.name.endswith(".lineage.md")
                or p.name.endswith(".review-needed.md")
                or p.name.endswith(".deploy-report.md")):
            continue
        out.setdefault(p.stem, p)
    return out


DIM_WIKIS = list_dim_wikis()


def heuristic_dim(col_name: str) -> str | None:
    """Try `<X>ID -> Dim_<X>` (case-insensitive ID suffix)."""
    m = re.match(r"^([A-Za-z][A-Za-z0-9_]+?)(ID|Id)$", col_name)
    if not m:
        return None
    base = m.group(1)
    dim = f"Dim_{base}"
    if dim in DIM_WIKIS:
        return dim
    return None


def is_self_reference(col_name: str, wiki_md: str, target_dim: str) -> bool:
    """True if the wiki containing this column IS the target Dim AND the column
    is the Dim's own natural-key/label."""
    md_stem = Path(wiki_md).stem
    if md_stem != target_dim:
        return False
    base = target_dim.removeprefix("Dim_")
    key_set = {
        "ID", "id",
        "Name", "name",
        base,
        f"{base}ID", f"{base}Id",
        f"{base}Name",
    }
    return col_name in key_set


def resolve(col_name: str) -> tuple[str, str]:
    """Return (target_dim_or_dictionary, resolution_strategy)."""
    if col_name in IRREGULAR_DIM_MAP:
        return IRREGULAR_DIM_MAP[col_name], "irregular_map"
    h = heuristic_dim(col_name)
    if h:
        return h, "heuristic_<X>ID"
    # Final fallback: pluralised/singular non-ID variants
    if col_name in DIM_WIKIS:
        return col_name, "exact_dim_name"
    return "", "unresolved"


def main() -> int:
    src = REPO / "knowledge" / "_dict_ref_candidates.csv"
    out = REPO / "knowledge" / "_dict_ref_resolved.csv"
    rows_in = list(csv.DictReader(src.open(encoding="utf-8")))
    rows_out = []
    n_self = 0
    n_unresolved = 0
    n_dictionary = 0
    n_dim = 0
    for r in rows_in:
        target, strategy = resolve(r["column_name"])
        if target.startswith("Dim_"):
            if is_self_reference(r["column_name"], r["wiki_md"], target):
                n_self += 1
                continue
            target_md = DIM_WIKIS[target].relative_to(REPO).as_posix() if target in DIM_WIKIS else ""
            n_dim += 1
        elif target.startswith("Dictionary."):
            target_md = ""
            n_dictionary += 1
        else:
            target_md = ""
            n_unresolved += 1
        rows_out.append({
            **r,
            "target_dim": target,
            "resolution_strategy": strategy,
            "target_dim_md": target_md,
        })

    fnames = list(rows_in[0].keys()) + ["target_dim", "resolution_strategy", "target_dim_md"]
    with out.open("w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fnames)
        w.writeheader()
        for r in rows_out:
            w.writerow(r)

    print(f"Wrote {out.relative_to(REPO).as_posix()}")
    print(f"  Total rows in: {len(rows_in)}")
    print(f"  Self-references dropped (KEEP policy): {n_self}")
    print(f"  Resolved to Dim_X wiki: {n_dim}")
    print(f"  Resolved to Dictionary.X (no Dim wiki): {n_dictionary}")
    print(f"  Unresolved (user decides in review): {n_unresolved}")
    print(f"  Total rows out: {len(rows_out)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
