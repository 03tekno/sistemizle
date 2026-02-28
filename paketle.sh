#!/bin/bash

# Değişkenler
APP_NAME="sistemizle"
VERSION="1.0.0"
BUILD_DIR="${APP_NAME}_${VERSION}"
PYTHON_FILE="sistemizle.py"

echo "📦 Paketleme işlemi başlatılıyor: $APP_NAME"

# 1. Klasör yapısını oluştur
mkdir -p "$BUILD_DIR/DEBIAN"
mkdir -p "$BUILD_DIR/usr/bin"
mkdir -p "$BUILD_DIR/usr/share/applications"

# 2. Python dosyasını kopyala ve çalıştırılabilir yap
cp "$PYTHON_FILE" "$BUILD_DIR/usr/bin/sistemizle"
chmod +x "$BUILD_DIR/usr/bin/sistemizle"

# 3. Control dosyasını oluştur (Bağımlılıklar dahil)
cat << EOF > "$BUILD_DIR/DEBIAN/control"
Package: $APP_NAME
Version: $VERSION
Section: utils
Priority: optional
Architecture: all
Depends: python3, python3-psutil, python3-pyqt5, lm-sensors
Maintainer: Mobilturka>
Description: Basit sistem kaynaklari ve sicaklik gozlem araci.
 Masaustunde CPU, RAM ve sicaklik degerlerini gosteren kucuk bir arac.
EOF

# 4. Masaüstü kısayolunu oluştur
cat << EOF > "$BUILD_DIR/usr/share/applications/sistemizle.desktop"
[Desktop Entry]
Name=Sistem İzle
Comment=CPU, RAM ve Sıcaklık Takibi
Exec=/usr/bin/sistemizle
Icon=utilities-system-monitor
Type=Application
Categories=System;Monitor;
Terminal=false
EOF

# 5. Paketi derle
dpkg-deb --build "$BUILD_DIR"

# Temizlik (Opsiyonel)
# rm -rf "$BUILD_DIR"

echo "✅ İşlem tamamlandı! ${BUILD_DIR}.deb dosyası oluşturuldu."