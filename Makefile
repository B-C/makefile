# Output
OUTPUT_DIR = build
EXE = $(BUILD_DIR)/exe
STRIPED = $(EXE)-strip
TEST = $(EXE)_test
COVERAGE_DIR = coverage
PROFRAW = $(EXE).profraw
PROFDATA = $(EXE).profdata

# Build tools
CXX = clang++-4.0
DB = lldb
PROF = llvm-profdata-4.0
COV = llvm-cov-4.0

# Flags
CPPFLAGS = -MMD -MP
CXXFLAGS = -std=c++1z -Wall -Wextra -g
LDFLAGS = -stdlib=libstdc++

ifdef RELEASE
BUILD_DIR := $(OUTPUT_DIR)/release
CPPFLAGS += -DNDEBUG
CXXFLAGS += -O3
else
BUILD_DIR := $(OUTPUT_DIR)/debug
endif

ifeq "$(MAKECMDGOALS)" "coverage"
BUILD_DIR := $(OUTPUT_DIR)/coverage
CXX_PROFILE_FLAGS := -fprofile-instr-generate -fcoverage-mapping
CXXFLAGS += $(CXX_PROFILE_FLAGS)
endif

# Objects
OBJS = $(patsubst src/%.cpp,$(BUILD_DIR)/%.o, $(wildcard src/*.cpp))
MAIN = $(BUILD_DIR)/main.o
TEST_OBJS = $(patsubst test/%.cpp,$(BUILD_DIR)/%.o, $(wildcard test/*.cpp))

# Googletest
GTEST_DIR = googletest/googletest
GTEST_CPPFLAGS = -isystem $(GTEST_DIR)/include
GTEST_SRCS = $(addprefix $(GTEST_DIR)/src/,gtest-all.cc gtest_main.cc)
GTEST_OBJS = $(patsubst $(GTEST_DIR)/src/%.cc,$(BUILD_DIR)/%.o, $(GTEST_SRCS))
GTEST_LIB = $(BUILD_DIR)/gtest.a

# Functions
RUN = time ./$^
RUN_DEBUG = $(DB) -o run ./$^
LINK = $(LINK.cpp) $^ $(LOADLIBES) $(LDLIBS) -o $@
BUILD = mkdir -p $(@D) && $(CXX) $(CXXFLAGS) $(CPPFLAGS) -c $< $(LIB_PATH) $(LIBS) -o $@

# Rules
.DEFAULT_GOAL := all
.PHONY: all exe clean run run-debug run-test run-test-debug coverage

all: $(STRIPED) $(TEST)

# Executable
exe: $(EXE)

run: $(EXE)
	$(RUN)

run-debug: $(EXE)
	$(RUN_DEBUG)

$(STRIPED): $(EXE)
	strip $< -o $@

$(EXE): $(OBJS)
	$(LINK)

$(OBJS): $(BUILD_DIR)/%.o : src/%.cpp
	$(BUILD)

# Unit tests
run-test: $(TEST)
	$(RUN)

run-test-debug: $(TEST)
	$(RUN_DEBUG)

$(TEST): $(filter-out $(MAIN),$(OBJS)) $(TEST_OBJS) $(GTEST_LIB)
	$(LINK) -lpthread

$(TEST_OBJS): $(BUILD_DIR)/%.o : test/%.cpp
	$(BUILD) $(GTEST_CPPFLAGS) -Isrc

$(GTEST_OBJS): $(BUILD_DIR)/%.o : $(GTEST_DIR)/src/%.cc
	$(filter-out $(CXX_PROFILE_FLAGS),$(BUILD)) $(GTEST_CPPFLAGS) -I$(GTEST_DIR)

$(GTEST_LIB): $(GTEST_OBJS)
	$(AR) $(ARFLAGS) $@ $^

# Coverage
$(PROFRAW): $(TEST)
	LLVM_PROFILE_FILE=$@ ./$<

$(PROFDATA): $(PROFRAW)
	$(PROF) merge -sparse $< -o $@

coverage: $(PROFDATA)
	$(COV) show ./$(TEST) -instr-profile=$< -format=html -o $(COVERAGE_DIR)

# Cleanup
clean:
	@rm -rf $(OUTPUT_DIR) $(COVERAGE_DIR)

# Dependencies
-include $(patsubst %.o,%.d, $(OBJS) $(TEST_OBJS) $(GTEST_OBJS))
