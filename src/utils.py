import csv
import json
from pathlib import Path
from typing import List, Dict


def read_bookings(file_path: Path) -> List[Dict[str, str]]:
    """Read booking information from a JSON or CSV file."""
    if not file_path.exists():
        raise FileNotFoundError(file_path)
    if file_path.suffix.lower() == '.json':
        with file_path.open('r', encoding='utf-8') as fh:
            return json.load(fh)
    elif file_path.suffix.lower() == '.csv':
        with file_path.open('r', encoding='utf-8', newline='') as fh:
            reader = csv.DictReader(fh)
            return list(reader)
    else:
        raise ValueError('Unsupported file format: ' + file_path.suffix)


def write_log(path: Path, message: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('a', encoding='utf-8') as fh:
        fh.write(message + '\n')
