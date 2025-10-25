import sys
import os
from PyQt5.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QLineEdit, QPushButton, QFileDialog,
    QListWidget, QCheckBox, QSpinBox
)
from PyQt5.QtCore import Qt

from src.autoplayer import AutoPlayerThread
import src.config as config

class MainWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle('Artale Helper')
        self.autoplayer = None
        self._setup_ui()

    def _setup_ui(self):
        layout = QVBoxLayout()

        key_layout = QHBoxLayout()
        key_layout.addWidget(QLabel('Attack Key'))
        self.attack_edit = QLineEdit(config.attack_key)
        key_layout.addWidget(self.attack_edit)
        key_layout.addWidget(QLabel('Heal Key'))
        self.heal_edit = QLineEdit(config.heal_key)
        key_layout.addWidget(self.heal_edit)
        key_layout.addWidget(QLabel('Loot Key'))
        self.loot_edit = QLineEdit(config.loot_key)
        key_layout.addWidget(self.loot_edit)
        layout.addLayout(key_layout)

        interval_layout = QHBoxLayout()
        interval_layout.addWidget(QLabel('Attack Interval (ms)'))
        self.interval_spin = QSpinBox()
        self.interval_spin.setRange(100, 10000)
        self.interval_spin.setValue(int(config.attack_interval * 1000))
        interval_layout.addWidget(self.interval_spin)
        self.auto_heal_checkbox = QCheckBox('Auto Heal')
        self.auto_heal_checkbox.setChecked(config.auto_heal)
        interval_layout.addWidget(self.auto_heal_checkbox)
        layout.addLayout(interval_layout)

        def create_selector(text):
            h = QHBoxLayout()
            edit = QLineEdit()
            btn = QPushButton('Browse')
            h.addWidget(QLabel(text))
            h.addWidget(edit)
            h.addWidget(btn)
            return h, edit, btn

        self.monster_layout, self.monster_edit, monster_btn = create_selector('Monster Image')
        layout.addLayout(self.monster_layout)
        monster_btn.clicked.connect(lambda: self._select_file(self.monster_edit))

        self.hpbar_layout, self.hpbar_edit, hpbar_btn = create_selector('HP Bar Image')
        layout.addLayout(self.hpbar_layout)
        hpbar_btn.clicked.connect(lambda: self._select_file(self.hpbar_edit))

        self.loot_layout, self.loot_img_edit, loot_btn = create_selector('Loot Image')
        layout.addLayout(self.loot_layout)
        loot_btn.clicked.connect(lambda: self._select_file(self.loot_img_edit))

        self.start_btn = QPushButton('Start')
        self.start_btn.clicked.connect(self.toggle_bot)
        layout.addWidget(self.start_btn)

        self.log_list = QListWidget()
        layout.addWidget(QLabel('Loot Log'))
        layout.addWidget(self.log_list)

        self.setLayout(layout)

    def _select_file(self, edit):
        path, _ = QFileDialog.getOpenFileName(self, 'Select Image', os.getcwd(), 'Images (*.png *.jpg *.bmp)')
        if path:
            edit.setText(path)

    def toggle_bot(self):
        if self.autoplayer and self.autoplayer.isRunning():
            self.autoplayer.stop_bot()
            self.autoplayer = None
            self.start_btn.setText('Start')
        else:
            self.start_autoplayer()

    def start_autoplayer(self):
        atk = self.attack_edit.text() or config.attack_key
        heal = self.heal_edit.text() or config.heal_key
        loot = self.loot_edit.text() or config.loot_key
        interval = self.interval_spin.value() / 1000.0
        auto_heal = self.auto_heal_checkbox.isChecked()
        monster_img = self.monster_edit.text() or None
        hpbar_img = self.hpbar_edit.text() or None
        loot_img = self.loot_img_edit.text() or None
        self.autoplayer = AutoPlayerThread(
            attack_key=atk,
            heal_key=heal,
            loot_key=loot,
            attack_interval=interval,
            auto_heal=auto_heal,
            monster_img=monster_img,
            hpbar_img=hpbar_img,
            loot_img=loot_img,
        )
        self.autoplayer.loot_detected.connect(self.log_loot)
        self.autoplayer.start_bot()
        self.start_btn.setText('Stop')

    def log_loot(self, timestamp):
        text = f"{timestamp} Loot collected"
        self.log_list.addItem(text)
        with open('loot_log.txt', 'a', encoding='utf-8') as f:
            f.write(text + '\n')

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec_())

