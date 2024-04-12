int NUM_INSTRS=23;
int instr_locs[23];
int instr_data[23];
instr_locs[0]=32h1018c;  instr_data[0]=32hfd010113; // add sp,sp,-48        
instr_locs[1]=32h10190;  instr_data[1]=32h02812623; // sw s0,44(sp)        
instr_locs[2]=32h10194;  instr_data[2]=32h03010413; // add s0,sp,48        
instr_locs[3]=32h10198;  instr_data[3]=32hfca42e23; // sw a0,-36(s0)        
instr_locs[4]=32h1019c;  instr_data[4]=32hfcb42c23; // sw a1,-40(s0)        
instr_locs[5]=32h101a0;  instr_data[5]=32hfe042623; // sw zero,-20(s0)        
instr_locs[6]=32h101a4;  instr_data[6]=32hfe042423; // sw zero,-24(s0)        
instr_locs[7]=32h101a8;  instr_data[7]=32hfe042623; // sw zero,-20(s0)        
instr_locs[8]=32h101ac;  instr_data[8]=32h01c0006f; // j 101c8 <main+0x3c>       
instr_locs[9]=32h101b0;  instr_data[9]=32hfe842783; // lw a5,-24(s0)        
instr_locs[10]=32h101b4;  instr_data[10]=32h00178793; // add a5,a5,1        
instr_locs[11]=32h101b8;  instr_data[11]=32hfef42423; // sw a5,-24(s0)        
instr_locs[12]=32h101bc;  instr_data[12]=32hfec42783; // lw a5,-20(s0)        
instr_locs[13]=32h101c0;  instr_data[13]=32h00178793; // add a5,a5,1        
instr_locs[14]=32h101c4;  instr_data[14]=32hfef42623; // sw a5,-20(s0)        
instr_locs[15]=32h101c8;  instr_data[15]=32hfec42703; // lw a4,-20(s0)        
instr_locs[16]=32h101cc;  instr_data[16]=32h00100793; // li a5,1        
instr_locs[17]=32h101d0;  instr_data[17]=32hfee7d0e3; // bge a5,a4,101b0 <main+0x24>       
instr_locs[18]=32h101d4;  instr_data[18]=32hfe842783; // lw a5,-24(s0)        
instr_locs[19]=32h101d8;  instr_data[19]=32h00078513; // mv a0,a5        
instr_locs[20]=32h101dc;  instr_data[20]=32h02c12403; // lw s0,44(sp)        
instr_locs[21]=32h101e0;  instr_data[21]=32h03010113; // add sp,sp,48        
instr_locs[22]=32h101e4;  instr_data[22]=32h00008067; // ret         
