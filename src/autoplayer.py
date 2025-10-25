"""Automation thread for MapleStory Artale helper."""

import time
from typing import Optional

import cv2
import numpy as np
import pyautogui
from PyQt5.QtCore import QThread, pyqtSignal

class AutoPlayerThread(QThread):
    """Background thread that checks the screen and presses keys."""

    loot_detected = pyqtSignal(str)

    def __init__(self, attack_key: str = 'z', heal_key: str = 'h', loot_key: str = 'x',
                 attack_interval: float = 1.0, auto_heal: bool = False,
                 monster_img: Optional[str] = None, hpbar_img: Optional[str] = None,
                 loot_img: Optional[str] = None):
        super().__init__()
        self.attack_key = attack_key
        self.heal_key = heal_key
        self.loot_key = loot_key
        self.attack_interval = attack_interval
        self.auto_heal = auto_heal
        self.monster_img = cv2.imread(monster_img, cv2.IMREAD_COLOR) if monster_img else None
        self.hpbar_img = cv2.imread(hpbar_img, cv2.IMREAD_COLOR) if hpbar_img else None
        self.loot_img = cv2.imread(loot_img, cv2.IMREAD_COLOR) if loot_img else None
        self.running = False

    def start_bot(self):
        if not self.isRunning():
            self.running = True
            self.start()

    def stop_bot(self):
        self.running = False
        self.wait()

    def _match(self, haystack, needle, threshold: float = 0.8) -> bool:
        """Return True if the needle image exists in the haystack."""
        if haystack is None or needle is None:
            return False
        res = cv2.matchTemplate(haystack, needle, cv2.TM_CCOEFF_NORMED)
        loc = np.where(res >= threshold)
        return len(loc[0]) > 0

    def run(self) -> None:
        """Main loop that performs detection and automation."""
        while self.running:
            screenshot = pyautogui.screenshot()
            frame = cv2.cvtColor(np.array(screenshot), cv2.COLOR_RGB2BGR)
            if self._match(frame, self.monster_img):
                pyautogui.press(self.attack_key)
                time.sleep(self.attack_interval)
            if self.auto_heal and self._match(frame, self.hpbar_img):
                pyautogui.press(self.heal_key)
            if self._match(frame, self.loot_img):
                pyautogui.press(self.loot_key)
                ts = time.strftime('%Y-%m-%d %H:%M:%S')
                self.loot_detected.emit(ts)
            time.sleep(0.1)

