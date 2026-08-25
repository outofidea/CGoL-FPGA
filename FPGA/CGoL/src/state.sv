module state #(
    parameter WIDTH       = 420,
    parameter HEIGHT      = 270,
    parameter WIDTH_BITS  = $clog2(WIDTH),
    parameter HEIGHT_BITS = $clog2(HEIGHT)
) (
    input logic rst,

    input  logic                                    calc_clk,
    input  logic [WIDTH_BITS + HEIGHT_BITS - 1 : 0] cell_addr,
    input  logic                                    cell_rw,
    input  logic                                    calc_done,
    output logic                                    cell_state,
    output logic                                    valid,


    input                                           screen_clk,
    input  logic [WIDTH_BITS + HEIGHT_BITS - 1 : 0] screen_out_cell_addr,
    output logic                                    screen_out_cell_state,
    output logic                                    screen_out_valid,

    output logic [1:0] presentable_buffer  //0 is buf1, 1 is buf2

);
    always_ff @(posedge calc_clk) begin
        if (rst) begin
            presentable_buffer = '0;
        end
    end







    logic
        mem_array_1_rst,
        mem_array_1_calc_clk,
        mem_array_1_calc_we,
        mem_array_1_calc_addr,
        mem_array_1_calc_data_in,
        mem_array_1_calc_data_out,

        mem_array_1_display_clk,
        mem_array_1_display_addr,
        mem_array_1_display_data_out;

    //BUFFER 1 
    (* syn_preserve = "true" *) logic mem_array_1[WIDTH + HEIGHT -1 : 0];

    always_ff @(posedge mem_array_1_calc_clk) begin
        if (rst) begin
            mem_array_1_calc_data_out <= 0;
        end else begin
            if (!mem_array_1_calc_we) begin : mem_array1_calc_read
                mem_array_1_calc_data_out <= mem_array_1[mem_array_1_calc_addr];
            end else begin : mem_array1_calc_write
                mem_array_1[mem_array_1_calc_addr] <= mem_array_1_calc_data_in;
            end
        end

    end

    always_ff @(posedge mem_array_1_display_clk) begin
        if (rst) begin
            mem_array_1_display_data_out <= 0;
        end else begin
            if (!mem_array_1_calc_we) begin : mem_array1_display_read
                mem_array_1_display_data_out <= mem_array_1[mem_array_1_display_addr];
            end
        end
    end

    logic
        mem_array_2_rst,
        mem_array_2_calc_clk,
        mem_array_2_calc_we,
        mem_array_2_calc_addr,
        mem_array_2_calc_data_in,
        mem_array_2_calc_data_out,
        mem_array_2_display_clk,
        mem_array_2_display_addr,
        mem_array_2_display_data_out;
    //BUFFER 2
    (* syn_preserve = "true" *) logic mem_array_2[WIDTH + HEIGHT -1 : 0];

    always_ff @(posedge mem_array_2_calc_clk) begin
        if (rst) begin
            mem_array_2_calc_data_out <= 0;
        end else begin
            if (!mem_array_2_calc_we) begin : mem_array2_calc_read
                mem_array_2_calc_data_out <= mem_array_2[mem_array_2_calc_addr];
            end else begin : mem_array2_calc_write
                mem_array_2[mem_array_2_calc_addr] <= mem_array_2_calc_data_in;
            end
        end

    end

    always_ff @(posedge mem_array_2_display_clk) begin
        if (rst) begin
            mem_array_2_display_data_out <= 0;
        end else begin
            if (!mem_array_2_calc_we) begin : mem_array2_display_read
                mem_array_2_display_data_out <= mem_array_2[mem_array_2_display_addr];
            end
        end
    end

    assign mem_array_1_rst = rst;
    assign mem_array_2_rst = rst;




endmodule
