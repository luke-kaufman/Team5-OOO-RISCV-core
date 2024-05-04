int NUM_INSTRS=13;
int instr_locs[13];
int instr_data[13];
instr_locs[0]=32h1018c;  instr_data[0]=32h00050613; // mv a2,a0        
instr_locs[1]=32h10190;  instr_data[1]=32h02a05463; // blez a0,101b8 <main+0x2c>       
instr_locs[2]=32h10194;  instr_data[2]=32h00000793; // li a5,0        
instr_locs[3]=32h10198;  instr_data[3]=32h00100513; // li a0,1        
instr_locs[4]=32h1019c;  instr_data[4]=32h00000713; // li a4,0        
instr_locs[5]=32h101a0;  instr_data[5]=32h00050693; // mv a3,a0        
instr_locs[6]=32h101a4;  instr_data[6]=32h00e50533; // add a0,a0,a4        
instr_locs[7]=32h101a8;  instr_data[7]=32h00178793; // add a5,a5,1        
instr_locs[8]=32h101ac;  instr_data[8]=32h00068713; // mv a4,a3        
instr_locs[9]=32h101b0;  instr_data[9]=32hfef618e3; // bne a2,a5,101a0 <main+0x14>       
instr_locs[10]=32h101b4;  instr_data[10]=32h00008067; // ret         
instr_locs[11]=32h101b8;  instr_data[11]=32h00000513; // li a0,0        
instr_locs[12]=32h101bc;  instr_data[12]=32h00008067; // ret         
