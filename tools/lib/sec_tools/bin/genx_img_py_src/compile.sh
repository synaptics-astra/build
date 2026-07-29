#!/usr/bin/env bash
set -e

# Go to the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VENV_DIR=".venv"
APP_NAME="genx_img_py"
ENTRY_FILE="main.py"
OUTPUT_FILE="${1:-${SCRIPT_DIR}/${APP_NAME}}"
DIST_DIR="$(dirname "${OUTPUT_FILE}")"

echo "Working directory: $SCRIPT_DIR"

echo "Cleaning previous build outputs..."

# Remove PyInstaller output folders/files
rm -rf build
rm -rf dist
rm -f "${APP_NAME}.spec"

# Remove Python cache files/folders
find . -type d -name "__pycache__" -prune -exec rm -rf {} +
find . -type f -name "*.pyc" -delete
rm -rf .pytest_cache

# Optional: remove old executable if it exists in project root
rm -f "${OUTPUT_FILE}"

# Create virtual environment only if it does not exist
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating new Python virtual environment..."
    python3 -m venv "$VENV_DIR"
else
    echo "Virtual environment already exists: $VENV_DIR"
fi

echo "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

echo "Python:"
python --version

echo "Pip:"
python -m pip --version

# Helper function to check whether a Python module can be imported
python_module_exists() {
    python -c "import $1" >/dev/null 2>&1
}

echo "Checking required packages..."

# Check pycryptodome
# pip package name: pycryptodome
# import module name: Crypto
if python_module_exists "Crypto"; then
    echo "pycryptodome already installed."
else
    echo "Installing pycryptodome..."
    python -m pip install pycryptodome
fi

# Check pyinstaller
# pip package name: pyinstaller
# import module name: PyInstaller
if python_module_exists "PyInstaller"; then
    echo "pyinstaller already installed."
else
    echo "Installing pyinstaller..."
    python -m pip install pyinstaller
fi

echo "Building ${APP_NAME} executable..."
mkdir -p "${DIST_DIR}"
pyinstaller --onefile --name "$APP_NAME" --distpath "${DIST_DIR}" "$ENTRY_FILE"

echo ""
echo "Build completed successfully."
echo "Executable generated at:"
echo "${OUTPUT_FILE}"

chmod +x "${OUTPUT_FILE}"

deactivate