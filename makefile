# VHDL make file

RTL_ROOT := rtl
VCOM_FLAGS := -93 -source -quiet
BUILD_DIR := build
TAG_DIR := $(BUILD_DIR)/tags
LIB_BASE_DIR := $(BUILD_DIR)/lib

NO_COLOR=\x1b[0m
SUCC_COLOR=\x1b[32;01m
ERROR_COLOR=\x1b[31;01m
WARN_COLOR=\x1b[33;01m

OK=$(OK_COLOR)[OK]$(NO_COLOR)

# Find the RTL source files
RTL_DIRS := $(wildcard $(RTL_ROOT)/*)
LIB_DIRS := $(foreach sdir, $(RTL_DIRS), $(LIB_BASE_DIR)/$(notdir $(sdir)) )

VPATH = $(RTL_DIRS)
VPATH += $(TAG_DIR)

# Skip XST specific timing package
EXCLUDE_RTL := timing_ops_xilinx.vhdl random_20xx.vhdl
RTL := $(filter-out $(EXCLUDE_RTL), $(foreach sdir, $(RTL_DIRS), $(notdir $(wildcard $(sdir)/*.vhd*))))
RTL := $(filter %.vhd %.vhdl, $(RTL))

TAG_OBJS := $(foreach fname, $(RTL), $(basename $(notdir $(fname))).tag)

.SUFFIXES:
.SUFFIXES: .vhdl .vhd

define BUILD_VHDL
@echo "** Compiling:" $<
dir=`dirname $<`; \
vcom $(VCOM_FLAGS) -work `basename $$dir` $<
@touch $(TAG_DIR)/$@
endef

%.tag: %.vhdl
	$(BUILD_VHDL)

%.tag: %.vhd
	$(BUILD_VHDL)


.PHONY: compile clean

compile: $(TAG_OBJS)

clean:
	rm -rf $(BUILD_DIR)



# Generate dependency rules
RULES := auto_rules.mk

$(BUILD_DIR)/$(RULES): $(RTL) | $(BUILD_DIR)
	@echo Making rules
	@python scripts/vdep.py $^ > $@

include $(BUILD_DIR)/$(RULES)



$(BUILD_DIR):
	mkdir $(BUILD_DIR)

$(TAG_DIR): | $(BUILD_DIR)
	mkdir $(TAG_DIR)


$(LIB_BASE_DIR): | $(BUILD_DIR)
	mkdir $(LIB_BASE_DIR)

$(LIB_DIRS): | $(LIB_BASE_DIR)
	@echo $(LIB_DIRS) | xargs -n 1 vlib



$(TAG_OBJS): | $(TAG_DIR) $(LIB_DIRS) $(BUILD_DIR)/$(RULES)

#all: $(TAG_OBJS)


