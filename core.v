module core (
    input [31:0] address_bus,
    inout [31:0] data_bus,
    output memory_read,
    output memory_write
);
    ifu _fetch_unit(
        
    );

    dispatch_unit _dispatch_unit(
        
    );

    integer_unit _integer_unit(
        
    );

    load_store_unit _load_store_unit(
        
    );
endmodule
