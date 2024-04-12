generate blocks: the conditionals inside these blocks must only use constants and parameters
should not use "assign" statements --> need to use the std cell
could create tool to translate boolean expressions to use the PDK

Only do module declaration/instantiation

ONLY named instantiations are allowed (except stdcells). This is a hard rule because the alternative always leads to a bug at some point.
BE AWARE that stcell outputs are the last argument, as opposed to the first argument as in the case of builtin gates.
module_name m(a, b, c) -> This is forbidden
module_name m(.a(a), .b(b), .c(c)) -> This is allowed

ONLY wires and parameters. NO regs (except testbenches).
ALL wires should be all lowercase. One exception to this is the Nangate/FreePDK stdcell port names. We can't change those.
ALL parameters should be all UPPERCASE.

testbenches should be written so that they should output PASSED only (unlike mux4 so far).

Running tests with Icarus Verilog (example with adder.v and adder_tb.v):

1. iverilog -g2012 -gspecify -o adder_tb.vvp misc/adder.v freepdk-45nm/stdcells.v testing/misc/adder_tb.v
2. vvp adder_tb.vvp

1. do qsub-sim
2. ./run.sh <modulename>