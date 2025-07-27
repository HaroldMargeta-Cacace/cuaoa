#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

CHECK_MARK="\xE2\x9C\x94"
CROSS_MARK="\xE2\x9D\x8C"
WRENCH="\xF0\x9F\x94\xA7"
PACKAGE="\xF0\x9F\x93\xA6"
ROCKET="\xF0\x9F\x9A\x80"
CHAIN="\xE2\x9B\x93\xEF\xB8\x8F"
PUZZLE="\xF0\x9F\xA7\xA9"

MERIDIANS="\xF0\x9F\x8C\x90"
GEAR="\xE2\x9A\x99"
DIRECTORY="\xF0\x9F\x93\x81"
TRASH="\xF0\x9F\x97\x91"
LINK="\xF0\x9F\x94\x97"

VERBOSE=0
if [[ "$1" == "--verbose" || "$1" == "-v" ]]; then
    VERBOSE=1
fi

execute_command() {
    echo -e "${3}${NC} $2${NC}"
    if [ $VERBOSE -eq 1 ]; then
        $1
    else
        $1 > /dev/null 2>&1
    fi
}

echo -e "${LINK}${NC} Installing the ${GREEN}custatevec${NC} and ${GREEN}lbfgs${NC} libraries${NC}"
conda install custatevec conda-forge::liblbfgs
# execute_command "pip install maturin[patchelf]" "Installing the ${GREEN}maturin${NC} build tool with ${GREEN}patchelf${NC}" "$PUZZLE"
# execute_command "maturin build --release" "Building the project from source... (this might take a while)" "$GEAR "
# execute_command "uv build" "Building the project from source... (this might take a while)" "$GEAR "
pip install maturin[patchelf]
execute_command "maturin build --release" "Building the project from source... (this might take a while)" "$GEAR "
#WHEEL_FILE=$(find dist -name '*.whl' | sort | tail -n 1)
WHEEL_FILE=$(find target/wheels -name '*.whl' | sort | tail -n 1)
if [[ ! -z "$WHEEL_FILE" ]]; then
    execute_command "pip install $WHEEL_FILE" "Installing the wheel file with pip..." "$PACKAGE"
    echo -e "${GREEN}${CHECK_MARK}  Installation completed successfully. ${NC}"
else
    echo -e "${RED}${CROSS_MARK} Wheel file not found.${NC}"
    exit 1
fi

# Ensure CONDA_PREFIX is defined
if [[ -z "$CONDA_PREFIX" ]]; then
    echo -e "${YELLOW}Warning: CONDA_PREFIX is not set. Trying to infer from conda...${NC}"
    CONDA_PREFIX=$(conda info --base 2>/dev/null)
    if [[ -z "$CONDA_PREFIX" ]]; then
        echo -e "${RED}Error: Could not determine CONDA_PREFIX. Please activate your conda environment first.${NC}"
        exit 1
    else
        echo -e "${GREEN}Detected CONDA_PREFIX as $CONDA_PREFIX${NC}"
    fi
fi

# Path to compile_flags.txt (adjust if needed)
COMPILE_FLAGS_FILE="cuaoa/internal/compile_flags.txt"

# Detect CUDA version (major only)
CUDA_VERSION_STR=$($NVCC --version | grep "release" | sed -E 's/.*release ([0-9]+)\..*/\1/')
CUDA_VERSION=${CUDA_VERSION_STR:-11}  # fallback to 11 if detection fails

echo "Detected CUDA major version: $CUDA_VERSION"

# Read base flags and remove outdated gencode lines and $CONDA_PREFIX placeholder
BASE_FLAGS=$(grep -v -E 'gencode=arch=compute_8[9|0],code=sm_8[9|0]' "$COMPILE_FLAGS_FILE" | grep -v '\-I\$CONDA_PREFIX/include')

# Overwrite the file with cleaned base flags
echo "$BASE_FLAGS" > "$COMPILE_FLAGS_FILE"

# Append the actual CONDA_PREFIX include path
echo "-I${CONDA_PREFIX}/include" >> "$COMPILE_FLAGS_FILE"

# Append new arch flags only if CUDA >= 12
if [ "$CUDA_VERSION" -ge 12 ]; then
    echo "-gencode=arch=compute_89,code=sm_89" >> "$COMPILE_FLAGS_FILE"
    echo "-gencode=arch=compute_90,code=sm_90" >> "$COMPILE_FLAGS_FILE"
    echo "Appended CUDA 12+ architectures to compile_flags.txt"
else
    echo "CUDA version < 12, skipping newer architecture flags"
fi
