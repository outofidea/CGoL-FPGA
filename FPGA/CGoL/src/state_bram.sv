import cell_address_package::*;
module state_bram #(
    parameter int unsigned WIDTH     = 480,
    parameter int unsigned HEIGHT    = 272,
    parameter string       INIT_FILE = "",
    parameter bit          INIT_FILL = 1
) (
    input logic rst,

    input logic calc_clk,
    input logic display_clk,

    input  logic        calc_we,
    input  cell_address calc_addr,
    input  logic        calc_data_in,
    output logic        calc_data_out,

    input  cell_address display_addr,
    output logic        display_data_out

);




    //BUFFER 1 

    // verilator lint_off MULTIDRIVEN
    logic mem_array[0:WIDTH * HEIGHT - 1];
    // verilator lint_on MULTIDRIVEN

    initial begin : memory_init
        // for (int unsigned address = 0; address < WIDTH * HEIGHT; address++) begin
        //     mem_array[address] = 1'b0;
        // end
        if (INIT_FILE != "") begin
            $readmemb(INIT_FILE, mem_array);
        end else if (INIT_FILL) begin
            mem_array <= '{default:1};
        end

    end

    function automatic int unsigned linear_address(input cell_address address);
        // linear_address = (int'(address.cell_addr_y) << 9)
        //            - (int'(address.cell_addr_y) << 5)
        //            + int'(address.cell_addr_x);
        linear_address = address.cell_addr_y * WIDTH + address.cell_addr_x;
    endfunction  //! ima trust GPT on this one

    always_ff @(posedge calc_clk) begin
        if (calc_we) begin
            mem_array[linear_address(calc_addr)] <= calc_data_in;
        end
        //! INSANE FUCKING FOOTGUN OMG
        //! read be4 write only avail. on single port
        //! cuz the synth cant prove that we don't 
        //! simul. read and write to same idx
        //! although we do  (duh)                                                          
        //! synthesis WILL fail
    end

    always_ff @(posedge calc_clk) begin
        if (rst) begin
            calc_data_out <= 0;
        end else begin
            if (!calc_we) begin
                calc_data_out <= mem_array[linear_address(calc_addr)];
            end
        end

    end

    always_ff @(posedge display_clk) begin
        if (rst) begin
            display_data_out <= 0;
        end else begin
            display_data_out <= mem_array[linear_address(display_addr)];
        end
    end




endmodule
