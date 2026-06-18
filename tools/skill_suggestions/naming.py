"""Naming helpers for UC external-table anti-purge rules."""
from __future__ import annotations

from dataclasses import dataclass
from urllib.parse import urlparse


PROD_STORAGE_ACCOUNT = "dldataplatformprodwe"
STG_STORAGE_ACCOUNT = "stgdpdlwe"


@dataclass(frozen=True)
class NamingValidationResult:
    expected_table_name: str
    storage_account: str
    is_abfss: bool
    env_ok: bool
    table_name_ok: bool
    schema_ok: bool

    @property
    def is_valid(self) -> bool:
        return (
            self.is_abfss
            and self.env_ok
            and self.table_name_ok
            and self.schema_ok
        )


def compute_expected_table_name(location: str) -> str:
    """Compute purge-formula table name from ABFSS location."""
    parts = location.split("/")
    start_index = 4 if "external-sources" in location else 3
    segments = parts[start_index:-1] if location.endswith("/") else parts[start_index:]
    return "_".join(segments).lower().replace("-", "_").replace(".", "_")


def extract_storage_account(location: str) -> str:
    """
    Extract storage account from:
      abfss://container@account.dfs.core.windows.net/path
    """
    parsed = urlparse(location)
    # parsed.netloc => "container@account.dfs.core.windows.net"
    account_host = parsed.netloc.split("@")[-1]
    return account_host.split(".")[0].lower()


def required_storage_for_schema(schema: str) -> str:
    return STG_STORAGE_ACCOUNT if schema.lower().endswith("_stg") else PROD_STORAGE_ACCOUNT


def validate_table_name_and_location(
    *,
    schema: str,
    table_name: str,
    location: str,
) -> NamingValidationResult:
    schema_l = schema.lower()
    table_l = table_name.lower()
    is_abfss = location.lower().startswith("abfss://")

    expected = compute_expected_table_name(location) if is_abfss else ""
    storage = extract_storage_account(location) if is_abfss else ""
    required = required_storage_for_schema(schema_l)

    return NamingValidationResult(
        expected_table_name=expected,
        storage_account=storage,
        is_abfss=is_abfss,
        env_ok=(storage == required) if is_abfss else False,
        table_name_ok=(table_l == expected) if is_abfss else False,
        schema_ok=(schema_l != "default"),
    )
