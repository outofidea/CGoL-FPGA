package cell_address_package;
    class cell_address_class #(
        parameter WIDTH       = 420,
        parameter HEIGHT      = 270,
        parameter WIDTH_BITS  = $clog2(WIDTH),
        parameter HEIGHT_BITS = $clog2(HEIGHT)
    );

        typedef struct packed {
            logic [WIDTH_BITS-1:0]  cell_addr_x;
            logic [HEIGHT_BITS-1:0] cell_addr_y;
        } cell_address;

    endclass  //cell_adress_package

endpackage
