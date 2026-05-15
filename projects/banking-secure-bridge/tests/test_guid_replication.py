from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "bindings"))

from py_polycall_bank import submit, Transaction


def test_guid_replication_shape():
    result = submit(Transaction("A-100", 100.0))
    assert "guid" in result
    assert result["status"] == "accepted"
