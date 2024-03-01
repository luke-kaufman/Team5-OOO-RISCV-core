IVERILOG = iverilog
VVP = vvp
FLAGS = -Wall -Wno-implicit -g2012

FREEPDK_DIR = freepdk-45nm
MISC_DIR = misc
TESTBENCH_DIR = testing/misc

$(TESTBENCH_DIR)/%_tb.vvp: $(TESTBENCH_DIR)/%_tb.v $(MISCS)
	$(IVERILOG) $(FLAGS) -I$(FREEPDK_DIR) -I$(MISC_DIR) -o $@ $<

%: $(TESTBENCH_DIR)/%_tb.vvp
	$(VVP) $<

lint-%: $(MISC_DIR)/%.v
	$(IVERILOG) $(FLAGS) -tnull -I$(FREEPDK_DIR) -I$(MISC_DIR) $<
