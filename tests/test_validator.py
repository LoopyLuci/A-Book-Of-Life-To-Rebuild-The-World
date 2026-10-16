import subprocess
import sys


def test_validate_runs():
    result = subprocess.run(
        [sys.executable, "scripts/validate.py"],
        capture_output=True,
        text=True,
    )
    assert result.returncode == 0, result.stderr
