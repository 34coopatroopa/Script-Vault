#!/bin/bash

echo "========================================"
echo " ScriptVault UI - Starting..."
echo "========================================"
echo

cd "$(dirname "$0")"
cd utilities/python

echo "Checking for Python..."
if ! command -v python3 &> /dev/null; then
    echo "ERROR: Python3 not found!"
    echo "Please install Python from https://www.python.org/"
    exit 1
fi

echo "Installing Flask if needed..."
pip3 install flask -q

echo
echo "Starting ScriptVault UI..."
echo
python3 scriptvault_ui.py

