# Makefile for ProjAPB UVM testbench
# Defaults to Synopsys VCS; tweak SIMULATOR for Questa/Xcelium.

SIMULATOR ?= vcs
TEST      ?= apb_write_read_test
SEED      ?= 1
UVM_VERBOSITY ?= UVM_MEDIUM

RTL_DIR := ../../src/rtl
TB_DIR  := .

RTL_FILES := \
    $(RTL_DIR)/apb_slave.v

TB_FILES := \
    $(TB_DIR)/apb_if.sv \
    $(TB_DIR)/apb_pkg.sv \
    $(TB_DIR)/tb_top.sv

# ---------------- VCS ----------------
ifeq ($(SIMULATOR),vcs)
COMP_CMD = vcs -full64 -sverilog -ntb_opts uvm-1.2 \
              -timescale=1ns/1ps -debug_access+all \
              +incdir+$(TB_DIR) \
              $(RTL_FILES) $(TB_FILES) -o simv
RUN_CMD  = ./simv +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(UVM_VERBOSITY) +ntb_random_seed=$(SEED)
endif

# ---------------- Questa ----------------
ifeq ($(SIMULATOR),questa)
COMP_CMD = vlib work && \
           vlog -sv +incdir+$(TB_DIR) -L $(QUESTA_UVM)/uvm-1.2 $(RTL_FILES) $(TB_FILES)
RUN_CMD  = vsim -c -do "run -all; quit" tb_top +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(UVM_VERBOSITY) -sv_seed $(SEED)
endif

# ---------------- Xcelium ----------------
ifeq ($(SIMULATOR),xcelium)
COMP_CMD = xrun -sv -uvm -uvmhome CDNS-1.2 +incdir+$(TB_DIR) \
                $(RTL_FILES) $(TB_FILES) -access +rwc \
                +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(UVM_VERBOSITY) -svseed $(SEED)
RUN_CMD  = @echo "xrun runs compile+sim in one step"
endif

.PHONY: all compile run clean regress

all: compile run

compile:
	$(COMP_CMD)

run:
	$(RUN_CMD)

# Run every test sequentially
regress:
	@for t in apb_write_read_test apb_write_all_test apb_strobe_test apb_error_test apb_random_test apb_regression_test ; do \
	    echo ">>>>>>>>>>>>> Running $$t <<<<<<<<<<<<<" ; \
	    $(MAKE) run TEST=$$t || exit 1 ; \
	done

clean:
	rm -rf simv simv.daidir csrc *.log *.vcd ucli.key work transcript vsim.wlf \
	       xcelium.d xrun.* INCA_libs *.history
