# genx_img Python Version

This directory contains the Python version of `genx_img`.

It is the source tree used to build the Python-based executable that corresponds to the deployed binary at /build/tools/lib/sec_tools/bin/genx_img_py`.

## Enabling the Python Version (`genx_img_py`)

By default the SDK build uses the legacy C `genx_img` tool. To use the Python
implementation instead, enable it through the build configuration.

The following Kconfig symbol controls whether the Python tool is built and used:

- `CONFIG_GENX_IMG_PY` — Build and use `genx_img_py`, the Python implementation of `genx_img`.

To enable the Python version of `genx_img`, set the following in your product
defconfig (`configs/product/<product>/<product>_defconfig`):

```
CONFIG_GENX_IMG_PY=y
```

That is all you need to do. When `CONFIG_GENX_IMG_PY=y`, the SDK build
automatically invokes `compile.sh` to build `genx_img_py` and uses it in place
of the legacy `genx_img`. You do not need to run `compile.sh` manually — the
instructions below are provided only for reference or for building the tool
standalone.

## Build Requirements

Install the required system packages before running the build script.

### Ubuntu 24.04
sudo apt update
sudo apt install python3 python3-venv libpython3.12 libpython3.12-dev python3.12-dev

### Ubuntu 22.04
sudo apt update
sudo apt install python3 python3-venv libpython3.10 libpython3.10-dev python3.10-dev

## How `compile.sh` Builds the Executable

> Note: `compile.sh` is normally called automatically by the SDK build scripts
> when `CONFIG_GENX_IMG_PY=y`. The steps below describe what it does and how to
> run it manually if needed; in a normal build you do not invoke it yourself.

The build flow is implemented in `compile.sh`.

It performs these steps:

1. Changes into the source directory.
2. Removes previous PyInstaller output such as `build`, `dist`, the generated spec file, `__pycache__`, `.pyc` files, and `.pytest_cache`.
3. Creates `.venv` if it does not already exist.
4. Activates the virtual environment.
5. Checks whether `pycryptodome` and `pyinstaller` are available and installs them if needed.
6. Runs PyInstaller in one-file mode with `main.py` as the entry point.
7. Produces the executable named `genx_img_py`.
8. Marks the generated executable as executable.

By default the executable is named `genx_img_py` and is written to this source
directory. You can override the output path by passing it as the first argument
to `compile.sh`:

```bash
./compile.sh <output-path>
```

The core build command used by the script is:

```bash
pyinstaller --onefile --name genx_img_py --distpath <output-directory> main.py
```
