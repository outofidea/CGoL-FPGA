import cell_address_package::*;
module state_bram #(
    parameter int unsigned WIDTH     = 8,
    parameter int unsigned HEIGHT    = 8,
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

    //! Standalone bram access delay should be 2 cyc 

    function automatic int unsigned linear_address(input cell_address address);
        // linear_address = (int'(address.cell_addr_y) << 9)
        //            - (int'(address.cell_addr_y) << 5)
        //            + int'(address.cell_addr_x);
        linear_address = address.cell_addr_y * WIDTH + address.cell_addr_x;
    endfunction

    cell_address dbg_calc_cur_addr_dlayed1, dbg_calc_cur_addr_dlayed2;
    cell_address dbg_disp_cur_addr_dlayed1, dbg_disp_cur_addr_dlayed2;

    always_ff @(posedge calc_clk) begin
        dbg_calc_cur_addr_dlayed1 <= calc_addr;
        dbg_calc_cur_addr_dlayed2 <= dbg_calc_cur_addr_dlayed1;
    end

    always_ff @(posedge calc_clk) begin
        dbg_disp_cur_addr_dlayed1 <= calc_addr;
        dbg_disp_cur_addr_dlayed2 <= dbg_calc_cur_addr_dlayed1;
    end

    //? Pipelining regs cuz the linear addr map is crazy slow
    logic reg_calc_we;
    int unsigned reg_calc_addr;
    logic reg_calc_data_in;

    int unsigned reg_display_addr;

    always_ff @(posedge calc_clk) begin
        reg_calc_we      <= calc_we;
        reg_calc_addr    <= linear_address(calc_addr);
        reg_calc_data_in <= calc_data_in;
    end

    always_ff @(posedge display_clk) begin : blockName
        reg_display_addr <= linear_address(display_addr);
    end

    //BUFFER 1 

    // verilator lint_off MULTIDRIVEN
    logic mem_array[0:WIDTH * HEIGHT - 1];
    // verilator lint_on MULTIDRIVEN

    initial begin : memory_init
        $readmemh("seed.hex", mem_array);
    end

    //! ima trust GPT on this one

    always_ff @(posedge calc_clk) begin
        if (reg_calc_we) begin
            mem_array[reg_calc_addr] <= reg_calc_data_in;
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
            if (!reg_calc_we) begin
                calc_data_out <= mem_array[reg_calc_addr];
            end
        end

    end

    always_ff @(posedge display_clk) begin
        if (rst) begin
            display_data_out <= 0;
        end else begin
            display_data_out <= mem_array[reg_display_addr];
        end
    end




endmodule
