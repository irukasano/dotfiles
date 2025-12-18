#!/usr/bin/env bash
set -euo pipefail

echo "[resync] restarting chronyd..."
sudo systemctl restart chronyd

echo "[resync] stepping time via chrony..."
sudo chronyc -a makestep

echo "[resync] status:"
timedatectl

