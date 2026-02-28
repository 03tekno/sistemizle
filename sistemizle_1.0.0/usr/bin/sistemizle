#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
import psutil
from PyQt6.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QHBoxLayout, 
    QLabel, QSystemTrayIcon, QMenu, QGraphicsDropShadowEffect, QPushButton
)
from PyQt6.QtCore import QTimer, Qt, QPoint, QThread, pyqtSignal
from PyQt6.QtGui import QAction

# Wayland/X11 Uyumluluğu
os.environ["QT_QPA_PLATFORM"] = "xcb"

PID_FILE = os.path.expanduser("~/.sistemizle_v1_pid")

class DataWorker(QThread):
    data_updated = pyqtSignal(dict)

    def run(self):
        while True:
            data = {
                "cpu_perc": psutil.cpu_percent(),
                "ram_perc": psutil.virtual_memory().percent,
                "temps": self.get_all_temps(),
                "battery": psutil.sensors_battery()
            }
            self.data_updated.emit(data)
            self.msleep(1500)

    def get_all_temps(self):
        temps = {"CPU": "N/A", "GPU": "N/A", "HDD": "N/A", "MB": "N/A"}
        try:
            raw = psutil.sensors_temperatures()
            for name, entries in raw.items():
                if not entries: continue
                val = f"{int(entries[0].current)}°C"
                n = name.lower()
                if any(x in n for x in ("core", "cpu", "k10")): temps["CPU"] = val
                elif any(x in n for x in ("gpu", "nvidia", "amdgpu")): temps["GPU"] = val
                elif any(x in n for x in ("nvme", "sd", "ata", "drive")): temps["HDD"] = val
                elif any(x in n for x in ("acpi", "pch", "mb", "it8", "mainboard")): temps["MB"] = val
        except: pass
        return temps

class ModernMonitor(QWidget):
    def __init__(self):
        super().__init__()
        self.oldPos = QPoint()
        self.labels = {}
        self.sensor_keys = ["CPU", "RAM", "GPU", "HDD", "MB", "BAT"]
        self.is_vertical = False 
        
        self.init_ui()
        self.start_worker()
        QTimer.singleShot(200, self.align_position)

    def init_ui(self):
        self.setWindowFlags(Qt.WindowType.FramelessWindowHint | Qt.WindowType.WindowStaysOnTopHint | Qt.WindowType.Tool)
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        
        self.base_style = """
            QLabel {
                color: #00FF41;
                font-family: 'Segoe UI', sans-serif;
                font-size: 12px; font-weight: bold;
                background-color: rgba(15, 15, 20, 210);
                padding: 8px; border-radius: 8px;
                border: 1px solid rgba(0, 255, 65, 40);
            }
        """

        # Kapat butonu oluşturma
        self.btn_close = QPushButton("✕")
        self.btn_close.setFixedSize(26, 26)
        self.btn_close.setCursor(Qt.CursorShape.PointingHandCursor)
        self.btn_close.setStyleSheet("""
            QPushButton {
                background-color: rgba(231, 76, 60, 160);
                color: white; border-radius: 13px; border: none; font-weight: bold;
            }
            QPushButton:hover { background-color: rgba(231, 76, 60, 255); }
        """)
        self.btn_close.clicked.connect(self.close_app)

        for key in self.sensor_keys:
            lbl = QLabel(f"{key}: --")
            lbl.setStyleSheet(self.base_style)
            shadow = QGraphicsDropShadowEffect(blurRadius=5, xOffset=0, yOffset=2)
            lbl.setGraphicsEffect(shadow)
            self.labels[key] = lbl

        self.update_layout_direction()
        self.setContextMenuPolicy(Qt.ContextMenuPolicy.CustomContextMenu)
        self.customContextMenuRequested.connect(self.show_menu)
        self.setup_tray()

    def update_layout_direction(self):
        # Eski layout temizliği
        if self.layout() is not None:
            old_layout = self.layout()
            while old_layout.count():
                item = old_layout.takeAt(0)
                widget = item.widget()
                if widget:
                    widget.setParent(None)
            QWidget().setLayout(old_layout)

        # Yeni Layout
        new_layout = QVBoxLayout() if self.is_vertical else QHBoxLayout()
        new_layout.setContentsMargins(10, 10, 10, 10)
        new_layout.setSpacing(8)
        
        # Dikey modda kapat butonu en üstte, yatayda en sonda olsun
        if self.is_vertical:
            new_layout.addWidget(self.btn_close, alignment=Qt.AlignmentFlag.AlignRight)
        
        for key in self.sensor_keys:
            new_layout.addWidget(self.labels[key])
            
        if not self.is_vertical:
            new_layout.addWidget(self.btn_close)
        
        self.setLayout(new_layout)
        self.adjustSize()

    def show_menu(self, pos):
        menu = QMenu(self)
        menu.setStyleSheet("background-color: #1a1a1a; color: #00FF41; border: 1px solid #00FF41;")
        toggle_action = QAction("Dikey/Yatay Değiştir", self)
        toggle_action.triggered.connect(self.toggle_orientation)
        quit_action = QAction("Kapat", self)
        quit_action.triggered.connect(self.close_app)
        menu.addAction(toggle_action)
        menu.addSeparator()
        menu.addAction(quit_action)
        menu.exec(self.mapToGlobal(pos))

    def toggle_orientation(self):
        self.is_vertical = not self.is_vertical
        self.update_layout_direction()
        self.align_position()

    def start_worker(self):
        self.worker = DataWorker()
        self.worker.data_updated.connect(self.update_ui)
        self.worker.start()

    def update_ui(self, data):
        t = data['temps']
        self.labels["CPU"].setText(f"CPU: %{int(data['cpu_perc'])} ({t['CPU']})")
        self.labels["RAM"].setText(f"RAM: %{int(data['ram_perc'])}")
        self.labels["GPU"].setText(f"GPU: {t['GPU']}")
        self.labels["HDD"].setText(f"HDD: {t['HDD']}")
        self.labels["MB"].setText(f"MB: {t['MB']}")
        
        if data['battery']:
            self.labels["BAT"].setText(f"BAT: %{int(data['battery'].percent)}")
            self.labels["BAT"].show()
        else:
            self.labels["BAT"].hide()

        for key in ["GPU", "HDD", "MB"]:
            self.labels[key].setVisible(t[key] != "N/A")
            
        self.adjustSize()

    def align_position(self):
        screen = QApplication.primaryScreen().availableGeometry()
        x = screen.width() - self.width() - 20
        y = screen.height() - self.height() - 20
        self.move(x, y)

    def setup_tray(self):
        self.tray = QSystemTrayIcon(self)
        self.tray.setIcon(self.style().standardIcon(self.style().StandardPixmap.SP_ComputerIcon))
        self.tray.show()

    def close_app(self):
        if os.path.exists(PID_FILE): os.remove(PID_FILE)
        QApplication.quit()

    def mousePressEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton:
            self.oldPos = event.globalPosition().toPoint()

    def mouseMoveEvent(self, event):
        if event.buttons() == Qt.MouseButton.LeftButton:
            delta = QPoint(event.globalPosition().toPoint() - self.oldPos)
            self.move(self.x() + delta.x(), self.y() + delta.y())
            self.oldPos = event.globalPosition().toPoint()

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setQuitOnLastWindowClosed(False)
    monitor = ModernMonitor()
    monitor.show()
    sys.exit(app.exec())