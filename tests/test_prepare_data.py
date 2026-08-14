"""Smoke tests for Step 1: prepare-data.

Runs independently of SCons (per the template's testing convention). Run after a
successful build with:  pytest tests/ -v

These guard the data-prep step against silent corruption: a missing standardised
variable or a duplicated panel key would break every downstream table and
regression without any Stata error.
"""
import pandas as pd
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DTA = ROOT / '1.prepare-data/output/nlswork_processed.dta'

EXPECTED_VARS = [
    'ln_wage_norm', 'tenure_norm', 'ttl_exp_norm', 'hours_norm',  # standardised outcomes
    'industry_grp', 'post',                                        # constructed regressors
    'idcode', 'year',                                              # panel keys
]


def _load(columns=None):
    # convert_categoricals=False keeps value-labelled columns (e.g. industry_grp)
    # numeric instead of pandas categoricals, so range checks work.
    return pd.read_stata(DTA, columns=columns, convert_categoricals=False)


def test_file_exists():
    assert DTA.is_file(), f"prepared dataset missing at {DTA}"


def test_has_expected_variables():
    df = _load()
    missing = [v for v in EXPECTED_VARS if v not in df.columns]
    assert not missing, f"prepare_data.do dropped variables: {missing}"


def test_nonempty():
    df = _load()
    assert len(df) > 0, "prepared dataset is empty"


def test_panel_key_is_unique():
    # xtset idcode year requires unique idcode x year; duplicates would distort
    # the clustered SEs and lag operators in every regression table.
    df = _load(columns=['idcode', 'year'])
    dups = df.duplicated(['idcode', 'year']).sum()
    assert dups == 0, f"{dups} duplicate idcode x year rows -- xtset would be invalid"


def test_industry_grp_in_range():
    # 7 groups (1-7) plus possibly missing; nothing outside that range.
    df = _load(columns=['industry_grp']).dropna()
    assert df['industry_grp'].between(1, 7).all(), "industry_grp has values outside 1-7"
