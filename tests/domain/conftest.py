"""Module to define fixtures for testing the domain layer of the application."""

import pickle

from pandas import read_parquet
import pytest


@pytest.fixture
def test_parquet_with_brewery_loc():
    """Fixture to read a parquet with brewery location col."""
    return read_parquet("tests/test_data/test_parquet_with_brewery_loc.parquet")


@pytest.fixture
def test_parquet_without_brewery_loc():
    """Fixture to read a parquet with brewery location col."""
    return read_parquet("tests/test_data/test_parquet_without_brewery_loc.parquet")


@pytest.fixture
def partition_cols():
    """Fixture to provide partition columns for testing."""
    return ["brewery_location"]


@pytest.fixture
def test_kms_key():
    """Fixture to provide a KMS key for testing."""
    return "alias/brewery_etl_key"


@pytest.fixture
def test_json_raw():
    """Fixture to load raw JSON data for testing."""
    return pickle.load(open("tests/test_data/breweries_test_json.pkl", "rb"))


@pytest.fixture
def test_s3_path():
    """Fixture to provide an S3 path for testing."""
    return "s3://brewery-test-files-temp2/test-data/test_brewery_parquet/test_brewery_parquet1"


@pytest.fixture
def test_s3_path_for_json():
    """Fixture to provide an S3 path for testing."""
    return "s3://brewery-test-files-temp2/test-data/test_brewery_data.json"


@pytest.fixture
def test_s3_path_for_raw_data_handler():
    """Fixture to provide an S3 path for testing."""
    return "s3://brewery-test-files-temp2/test-data/test_brewery_parquet2/test_brewery_data2"


@pytest.fixture
def test_parquet_raw():
    """Fixture to load raw Parquet data for testing."""
    return read_parquet("tests/test_data/test_parquet_raw.parquet")


@pytest.fixture
def test_start_page():
    """Fixture to be used to test the raw data handler class."""
    return "5"


@pytest.fixture
def test_url():
    """Fixture to provide a URL for testing."""
    return "https://api.openbrewerydb.org/v1/breweries?page=1"


@pytest.fixture
def test_wrong_url():
    """Fixture to provide a wrong URL for testing."""
    return "https://wrongurl.com/breweries.json"


@pytest.fixture
def test_bucket_name():
    """Fixture to provide a bucket name for testing."""
    return "brewery-test-files-temp2"


@pytest.fixture
def test_bucket_key():
    """Fixture to provide a bucket name for testing."""
    return "abc/def/ghi"


@pytest.fixture
def test_parameter_name():
    """Fixture to provide a parameter name for testing."""
    return "brewery_test_parameter"
