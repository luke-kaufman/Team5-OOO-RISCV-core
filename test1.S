.text
.global main
main:
    add sp,sp,-32 // 32'hfe010113
    sw s0,28(sp) // 32'h00812e23
    sw s1,24(sp) // 32'h00912c23
    add s0,sp,32 // 32'h02010413
    sw a0,-20(s0) // 32'hfea42623
    sw a1,-24(s0) // 32'hfeb42423
    li s1,15 // 32'h00f00493
    add s1,s1,19 // 32'h01348493
    add s1,s1,-4 // 32'hffc48493
    mv a4,s1 // 32'h00048713
    lui a5,0x80000 // 32'h800007b7
    xor a5,a4,a5 // 32'h00f747b3
    mv s1,a5 // 32'h00078493
    lui a5,0x80000 // 32'h800007b7
    add a5,a5,-1 // 7fffffff <__BSS_END__+0x7ffed77f> // 32'hfff78793
    and s1,s1,a5 // 32'h00f4f4b3
    mv a5,s1 // 32'h00048793
    mv a0,a5 // 32'h00078513
    lw s0,28(sp) // 32'h01c12403
    lw s1,24(sp) // 32'h01812483
    add sp,sp,32 // 32'h02010113
    ret // 32'h00008067