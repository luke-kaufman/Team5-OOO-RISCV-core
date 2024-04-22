// OpenRAM SRAM model
// Words: 64
// Word size: 48
// Write size: 24

module sram_64x48_1rw_wsize24(
`ifdef USE_POWER_PINS
    vdd,
    gnd,
`endif
// Port 0: RW
    clk0,csb0,web0,rst_aL,wmask0,addr0,din0,dout0,
    init
  );

  parameter NUM_WMASKS = 2 ;
  parameter DATA_WIDTH = 48 ;
  parameter ADDR_WIDTH = 6 ;
  parameter RAM_DEPTH = 1 << ADDR_WIDTH;
  // FIXME: This delay is arbitrary.
  parameter DELAY = 3 ;
  parameter VERBOSE = 1 ; //Set to 0 to only display warnings
  parameter T_HOLD = 1 ; //Delay to hold dout value after posedge. Value is arbitrary

`ifdef USE_POWER_PINS
    inout vdd;
    inout gnd;
`endif
  input  clk0; // clock
  input init;
  input rst_aL;
  input   csb0; // active low chip select
  input  web0; // active low write control
  input [ADDR_WIDTH-1:0]  addr0;
  input [NUM_WMASKS-1:0]   wmask0; // write mask
  input [DATA_WIDTH-1:0]  din0;
  output [DATA_WIDTH-1:0] dout0;

  reg [DATA_WIDTH-1:0]    mem [0:RAM_DEPTH-1];

  reg  csb0_reg;
  reg  web0_reg;
  reg [NUM_WMASKS-1:0]  wmask0_reg;
  reg [ADDR_WIDTH-1:0]  addr0_reg;
  reg [DATA_WIDTH-1:0]  din0_reg;
  reg [DATA_WIDTH-1:0]  dout0;

  // All inputs are registers
  always @(posedge clk0 or posedge init or negedge rst_aL) // TODO: no negedge rst_aL in the sensitivity list?
  begin
    if(init | !rst_aL) begin
        // reset regs
        csb0_reg <= 1'b1;
        web0_reg <= 1'b1;
        wmask0_reg <= 1'b1;
        addr0_reg <= 6'b0;
        din0_reg <= 48'b0;
        dout0 <= 48'b0;
        // reset mem
        for (int i = 0; i < RAM_DEPTH; i = i + 1) begin
            mem[i] <= 48'b0;
        end
    end
    else begin
      csb0_reg = csb0;
      web0_reg = web0;
      wmask0_reg = wmask0;
      addr0_reg = addr0;
      din0_reg = din0;
      // /*#(T_HOLD)*/ dout0 = 48'bx; // TODO: why did we comment this T_HOLD delay out?
      #1 // TODO: why do we have this #1 delay?
      if ( !csb0_reg && web0_reg && VERBOSE )
        // THIS IS SETUP FOR ICACHE, NEED TO DO FOR DCACHE (DIRTY BIT)
        $display("%6d Reading %m addr0=%b dout0: (way1_v:%b, way1_tag:%b, way0_v:%b, way0_tag:%b)", $time-1, addr0_reg,mem[addr0_reg][47], mem[addr0_reg][46:24], mem[addr0_reg][23], mem[addr0_reg][22:0]);
      if ( !csb0_reg && !web0_reg && VERBOSE )
        $display("%6d Writing %m addr0=%b din0: (way1_v:%b, way1_tag:%b, way0_v:%b, way0_tag:%b  wmask0=%b)", $time-1, addr0_reg, din0_reg[47], din0_reg[46:24], din0_reg[23], din0_reg[22:0], wmask0_reg);
    end
  end


  // Memory Write Block Port 0
  // Write Operation : When web0 = 0, csb0 = 0
  always @ (negedge clk0)
  begin : MEM_WRITE0
    if ( !csb0_reg && !web0_reg ) begin
        if (wmask0_reg[0])
                mem[addr0_reg][23:0] = din0_reg[23:0];
        if (wmask0_reg[1])
                mem[addr0_reg][47:24] = din0_reg[47:24];
    end
  end

  // Memory Read Block Port 0
  // Read Operation : When web0 = 1, csb0 = 0
  always @ (negedge clk0)
  begin : MEM_READ0
    if (!csb0_reg && web0_reg)
       dout0 <= /*#(DELAY)*/ mem[addr0_reg]; // TODO: why did we comment this DELAY delay out?
  end

endmodule
