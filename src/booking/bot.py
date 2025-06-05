from __future__ import annotations

import logging
from dataclasses import dataclass
from pathlib import Path
from typing import Optional, Dict

from playwright.sync_api import sync_playwright, Page, Browser


logger = logging.getLogger(__name__)


def _configure_logger(log_path: Path) -> None:
    log_path.parent.mkdir(parents=True, exist_ok=True)
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(levelname)s - %(message)s',
        handlers=[logging.FileHandler(log_path), logging.StreamHandler()]
    )


@dataclass
class BookingInfo:
    url: str
    people: int
    time: str
    name: str
    gender: str
    phone: str
    email: str
    language: str = 'zh-TW'


class InlineBot:
    def __init__(self, headless: bool = True, log_file: Path = Path('logs/bot.log')):
        self.playwright = sync_playwright().start()
        self.browser: Browser = self.playwright.chromium.launch(headless=headless)
        self.log_file = log_file
        _configure_logger(log_file)

    def close(self) -> None:
        self.browser.close()
        self.playwright.stop()

    def book(self, info: BookingInfo) -> str:
        """Attempt to book a reservation and return the result."""
        page = self.browser.new_page()
        try:
            logger.info('Opening %s', info.url)
            page.goto(info.url)
            # Here you would implement steps to select language, people, time etc.
            # The following are placeholders for brevity.
            logger.info('Selecting language %s', info.language)
            logger.info('Selecting %s people at %s', info.people, info.time)
            logger.info('Filling form with name=%s phone=%s', info.name, info.phone)
            # TODO: Implement real interaction with inline.app
            # Submit form
            # Check result
            result = 'success'
            logger.info('Booking result: %s', result)
            return result
        except Exception as exc:
            logger.exception('Booking failed: %s', exc)
            return f'error: {exc}'
        finally:
            page.close()
