import flowfield_types::particle_coord_t;

module particle_mem #(
    parameter MEM_DEPTH = 10,
    localparam MEM_DEPTH_BITS = $clog2(MEM_DEPTH)

) (

    input logic clk,
    input logic rst,

    input  logic uart_cfg_req,
    input  logic field_calc_req,
    output logic uart_cfg_grant,
    output logic field_calc_grant,
    output logic field_calc_release_req,

    //* Field port 1 and 2 dat in
    input particle_coord_t data_port_1_field_in,
    input particle_coord_t data_port_2_field_in,


    //* Field port 1 and 2 dat out
    output particle_coord_t data_port_1_field_out,
    output particle_coord_t data_port_2_field_out,
    output logic data_port_1_field_out_vld,
    data_port_2_field_out_vld,

    //* Cfg port dat in
    input particle_coord_t data_uart_in,
    input logic data_uart_in_vld,


    input wire wen_port_1_field,
    input wire wen_port_2_field,
    input wire wen_uart,


    input logic [MEM_DEPTH_BITS-1:0] address_1_field,
    input logic [MEM_DEPTH_BITS-1:0] address_2_field,
    input logic [MEM_DEPTH_BITS-1:0] address_uart

);

    //! Port 1 will be used only for field calculations, Port 2 will be shared with field calc and uart cfg
    typedef enum logic {
        UART_GRANTED,
        FIELD_GRANTED
    } CUR_GRANTED_MODULE_t;

    CUR_GRANTED_MODULE_t port_2_granted_module;


    particle_coord_t mem_port_2_dat_in;
    assign mem_port_2_dat_in  = (port_2_granted_module == UART_GRANTED) ? data_uart_in : data_port_2_field_in;


    logic [MEM_DEPTH_BITS-1:0] mem_port_2_address_in;
    assign mem_port_2_address_in = (port_2_granted_module == UART_GRANTED) ? address_uart : address_2_field;


    wire port2_wen;
    assign port2_wen = (port_2_granted_module == UART_GRANTED) ? data_uart_in_vld : wen_port_2_field;


    always_ff @(posedge clk) begin : Priority_dec
        if (rst) begin
            port_2_granted_module = UART_GRANTED;
        end else begin
            unique case (port_2_granted_module)
                UART_GRANTED: begin
                    // * UART cfg module releases this on completion
                    if (!uart_cfg_req && field_calc_req) begin
                        port_2_granted_module <= FIELD_GRANTED;
                    end

                end

                FIELD_GRANTED: begin
                    if (uart_cfg_req) begin
                        field_calc_release_req <= 1;
                    end

                    if (!field_calc_req) begin
                        port_2_granted_module <= UART_GRANTED;
                    end
                end
            endcase
        end
    end : Priority_dec

    always_comb begin : Priority_dec_comb
        unique case (port_2_granted_module)
            UART_GRANTED: begin
                uart_cfg_grant   = 1;
                field_calc_grant = 0;
            end

            FIELD_GRANTED: begin
                uart_cfg_grant   = 0;
                field_calc_grant = 1;
            end
        endcase
    end : Priority_dec_comb


    //* Registered mem out 
    particle_coord_t mem_port_1_out_reg, mem_port_2_out_reg;
    assign data_port_1_field_out = mem_port_1_out_reg;
    assign data_port_2_field_out = mem_port_2_out_reg;

    //* Valid logic (delay 1 clk)
    logic port_1_vld_reg, port_2_vld_reg;
    assign data_port_1_field_out_vld = port_1_vld_reg;
    assign data_port_2_field_out_vld = port_2_vld_reg;

    always_ff @(posedge clk) begin : Memory_vld_gen
        port_1_vld_reg <= !wen_port_1_field;
        port_2_vld_reg <= !port2_wen;
    end

    //* Bram infer
    particle_coord_t mem_array[MEM_DEPTH];
    always_ff @(posedge clk) begin : Memory

        begin : Port_1
            if (rst) begin
                mem_port_1_out_reg <= '{default: 0};
            end else begin
                if (wen_port_1_field) begin
                    mem_array[address_1_field] <= data_port_1_field_in;
                end
                mem_port_1_out_reg <= mem_array[address_1_field];
            end
        end

        begin : Port_2
            if (rst) begin
                mem_port_2_out_reg <= '{default: 0};
            end else begin
                if (port2_wen) begin
                    mem_array[mem_port_2_address_in] <= mem_port_2_dat_in;
                end
                mem_port_2_out_reg <= mem_array[mem_port_2_address_in];
            end
        end

    end : Memory






endmodule
