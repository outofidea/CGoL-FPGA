package cell_address_package;

    parameter WIDTH = 128; 
    parameter HEIGHT = 128;
    parameter WIDTH_BITS = $clog2(WIDTH);
    parameter HEIGHT_BITS = $clog2(HEIGHT);

    typedef struct packed {
        logic [WIDTH_BITS-1:0]  cell_addr_x;
        logic [HEIGHT_BITS-1:0] cell_addr_y;
    } cell_address;

endpackage
