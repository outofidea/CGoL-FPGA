import cell_address_package::*;
module state_bram #(
) (
    input logic rst,

    input logic calc_clk,
    input logic display_clk,

    input  logic                                            calc_we,
    input  cell_address_class#()::cell_address calc_addr,
    input  logic                                            calc_data_in,
    output logic                                            calc_data_out,

    input  cell_address_class#()::cell_address display_addr,
    output logic                                            display_data_out

);

    logic mem_array[0:16383];  //! taking the whole 16kbit for fun

    always_ff @(posedge calc_clk) begin
        if (rst) begin
            calc_data_out <= 0;
        end else begin
            if (!calc_we) begin : mem_array1_calc_read
                calc_data_out <= mem_array[calc_addr];
            end else begin : mem_array1_calc_write
                mem_array[calc_addr] <= calc_data_in;
            end
        end

    end

    always_ff @(posedge display_clk) begin
        if (rst) begin
            display_data_out <= 0;
        end else begin
            if (!calc_we) begin : mem_array1_display_read
                display_data_out <= mem_array[display_addr];
            end
        end
    end




endmodule
