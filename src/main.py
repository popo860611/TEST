from __future__ import annotations

import argparse
from pathlib import Path
from typing import List

from .booking.bot import InlineBot, BookingInfo
from .gui import BookingGUI
from .utils import read_bookings, write_log


def run_single(info: BookingInfo) -> None:
    bot = InlineBot(headless=True)
    try:
        result = bot.book(info)
        write_log(Path('logs/results.log'), f'{info.url},{result}')
    finally:
        bot.close()


def run_batch(file_path: Path) -> None:
    bookings: List[dict] = read_bookings(file_path)
    bot = InlineBot(headless=True)
    try:
        for data in bookings:
            info = BookingInfo(**data)
            result = bot.book(info)
            write_log(Path('logs/results.log'), f'{info.url},{result}')
    finally:
        bot.close()


def main() -> None:
    parser = argparse.ArgumentParser(description='Inline booking bot')
    parser.add_argument('--file', type=Path, help='JSON or CSV file for batch booking')
    args = parser.parse_args()

    if args.file:
        run_batch(args.file)
    else:
        gui = BookingGUI(run_single)
        gui.run()


if __name__ == '__main__':
    main()
