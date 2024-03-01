# Define the compiler, flags, and the command for running simulations
IVERILOG = iverilog
VVP = vvp
FLAGS = -Wall -g2012

STDCELLS_PATH = freepdk-45nm/stdcells.v
MISC_DIR = misc
TESTBENCH_DIR = testing/misc

# Identify all misc files
MISCS = $(wildcard $(MISC_DIR)/*.v)

# Identify all testbench files
TESTBENCHES = $(wildcard *_tb.v)

# Derive simulation binary names from testbenches
SIMS = $(TESTBENCHES:%_tb.v=%_tb.vvp)

# Default target: compile and run all simulations
all: $(SIMS)
	@for sim in $(SIMS); do \
		echo "Running $$sim..."; \
		$(VVP) $$sim; \
	done

# Rule to compile testbench into its simulation binary
$(TESTBENCH_DIR)/%_tb.vvp: $(TESTBENCH_DIR)/%_tb.v $(MISCS)
	$(IVERILOG) $(FLAGS) -o $@ $^ $(STDCELLS_PATH)

# Rule to run a specific simulation
.PHONY: run-%
run-%: $(TESTBENCH_DIR)/%_tb.vvp
	@echo "Running simulation for $*"
	$(VVP) $<

# Clean up generated files
clean:
	rm -f $(SIMS)
