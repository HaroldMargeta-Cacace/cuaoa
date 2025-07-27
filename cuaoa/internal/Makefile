# Detect environment
CONDA_PREFIX ?= $(shell conda info --json 2>/dev/null | grep -o '"active_prefix": *"[^"]*"' | cut -d'"' -f4)
ifeq ($(CONDA_PREFIX),)
    CONDA_PREFIX := /usr
endif

CUDA_PATH ?= $(shell dirname $(shell dirname $(shell which nvcc)))
NVCC ?= $(shell which nvcc)
GPP ?= $(shell which g++)
# Detect CUDA version
CUDA_VERSION := $(shell $(NVCC) --version | grep -o -E "release ([0-9]+)\." | cut -d' ' -f2 | cut -d'.' -f1)

# Base NVCC flags
NVCC_FLAGS := -std=c++17 -Xcompiler="-fPIC -O3" \
    -gencode arch=compute_70,code=sm_70 \
    -gencode arch=compute_75,code=sm_75 \
    -gencode arch=compute_80,code=sm_80 \
    -gencode arch=compute_86,code=sm_86

# Add CUDA 12+ architectures if supported
ifeq ($(shell [ $(CUDA_VERSION) -ge 12 ] && echo true),true)
    NVCC_FLAGS += \
        -gencode arch=compute_89,code=sm_89 \
        -gencode arch=compute_90,code=sm_90
endif

NVCC_FLAGS += --expt-relaxed-constexpr

# Add both lib64 and lib to avoid issues across CUDA 11/12 installs
LD_FLAGS := -L$(CUDA_PATH)/lib64 -L$(CUDA_PATH)/lib -L$(CONDA_PREFIX)/lib \
    -lcudart -lcustatevec -llbfgs -lstdc++ -lgomp

# Include directories
INCLUDE := -I$(CUDA_PATH)/include -I./include -I$(CONDA_PREFIX)/include

# Library and binary target
LIB_TARGET := lib/libcuaoalg.so
TARGET := $(LIB_TARGET)

# Source and object files
CU_SRC := $(wildcard src/**/*.cu) $(wildcard src/*.cu)
CPP_SRC := $(wildcard src/**/*.cpp) $(wildcard src/*.cpp)
CU_OBJ := $(CU_SRC:src/%.cu=obj/%.o)
CPP_OBJ := $(CPP_SRC:src/%.cpp=obj/%.o)
OBJ := $(CU_OBJ) $(CPP_OBJ)

# Colors for printing
RED := \033[0;31m
GREEN := \033[0;32m
NC := \033[0m

# Default target
all: $(TARGET)

$(LIB_TARGET): $(filter-out obj/main.o, $(OBJ))
	@echo -e "${GREEN}Building library${NC}"
	@mkdir -p $(@D)
	@$(GPP) $(GPP_FLAGS) $(INCLUDE) $^ -shared -o $@ $(LD_FLAGS)

obj/%.o: src/%.cu
	@echo -e "${GREEN}Compiling CUDA source${NC} $<"
	@mkdir -p $(@D)
	@$(NVCC) $(NVCC_FLAGS) $(INCLUDE) -c $< -o $@

obj/%.o: src/%.cpp
	@echo -e "${GREEN}Compiling C++ source${NC} $<"
	@mkdir -p $(@D)
	@$(GPP) $(GPP_FLAGS) $(INCLUDE) -c $< -o $@

clean:
	@echo -e "${RED}Cleaning up...${NC}"
	@rm -rf obj $(TARGET)

.PHONY: all clean
