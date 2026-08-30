import cell_address_package::*;
module state #(
    parameter WIDTH  = 420,
    parameter HEIGHT = 270
) (
    input logic calc_clk,
    input logic display_clk,
    input logic rst,

    input  cell_address_class#()::cell_address calc_cell_addr,
    input  logic                               calc_we,
    input  logic                               calc_done,
    input  logic                               calc_dat_in,
    output logic                               calc_dat_out,
    output logic                               valid,


    input  cell_address_class#()::cell_address display_out_cell_addr,
    input  logic                               display_buf_change_req,
    output logic                               display_buf_change_ack,
    output logic                               display_out_cell_state,
    output logic                               display_out_valid


);

    //? Buffer management follows calculation clock (as its the fastest (should be))

    logic next_buffer_ready;

    logic current_display_buffer;

    logic buf1_calc_we;
    cell_address_class #()::cell_address buf1_calc_addr;
    logic buf1_calc_data_in;
    logic buf1_calc_data_out;
    cell_address_class #()::cell_address buf1_display_addr;
    logic buf1_display_data_out;


    logic buf2_calc_we;
    cell_address_class #()::cell_address buf2_calc_addr;
    logic buf2_calc_data_in;
    logic buf2_calc_data_out;
    cell_address_class #()::cell_address buf2_display_addr;
    logic buf2_display_data_out;


    typedef enum {
        INIT,
        WAIT_CALCULATION,  //when 2 buffer not ready
        WAIT_DISPLAY,  // when at least 1 buffer ready
        WAIT_DISPLAY_ACK  // when waiting for display ack (its clock is slower)
    } BUFFER_STATE_e;

    BUFFER_STATE_e state, state_next;

    always_ff @(posedge calc_clk) begin
        if (rst) begin
            state <= INIT;
        end else begin
            state <= state_next;
        end


    end


    always_ff @(posedge calc_clk) begin
        unique case (state)

            INIT: begin

            end

            WAIT_CALCULATION: begin

            end
        endcase
    end



    always_comb begin : buffer_mux_comb

        buf1_calc_we           = '0;
        buf1_calc_addr         = '0;
        buf1_calc_data_in      = '0;
        buf1_display_addr      = '0;

        buf2_calc_we           = '0;
        buf2_calc_addr         = '0;
        buf2_calc_data_in      = '0;
        buf2_display_addr      = '0;

        calc_dat_out           = '0;
        display_out_cell_state = '0;

        valid                  = 0;

        unique case (state) inside
            INIT: begin
                buf1_calc_we      = '0;
                buf1_calc_addr    = '0;
                buf1_calc_data_in = '0;
                buf1_display_addr = '0;

                buf2_calc_we      = '0;
                buf2_calc_addr    = '0;
                buf2_calc_data_in = '0;
                buf2_display_addr = '0;

                valid = 0;
            end

            WAIT_CALCULATION, WAIT_DISPLAY, WAIT_DISPLAY_ACK: begin
                if (current_display_buffer == 1) begin  //! writes to buf1, reads from buf2
                    buf1_calc_we           = calc_we;
                    buf1_calc_addr         = calc_cell_addr;
                    buf1_calc_data_in      = calc_dat_in;

                    buf2_calc_we           = 1'b0;
                    buf2_calc_addr         = calc_cell_addr;
                    calc_dat_out           = buf2_calc_data_out;

                    buf2_display_addr      = display_out_cell_addr;
                    display_out_cell_state = buf2_display_data_out;

                end else begin  //! reads from buf1, writes to buf2
                    buf1_calc_we           = 1'b0;
                    buf1_calc_addr         = calc_cell_addr;
                    calc_dat_out           = buf1_calc_data_out;

                    buf2_calc_we           = calc_we;
                    buf2_calc_addr         = calc_cell_addr;
                    buf2_calc_data_in      = calc_dat_in;

                    buf1_display_addr      = display_out_cell_addr;
                    display_out_cell_state = buf1_display_data_out;
                end
            end


        endcase
    end





    state_bram #(
    ) buffer_1 (
        .rst             (rst),
        .calc_clk        (calc_clk),
        .display_clk     (display_clk),
        .calc_we         (buf1_calc_we),
        .calc_addr       (buf1_calc_addr),
        .calc_data_in    (buf1_calc_data_in),
        .calc_data_out   (buf1_calc_data_out),
        .display_addr    (buf1_display_addr),
        .display_data_out(buf1_display_data_out)
    );



    state_bram #(
    ) buffer_2 (
        .rst             (rst),
        .calc_clk        (calc_clk),
        .display_clk     (display_clk),
        .calc_we         (buf2_calc_we),
        .calc_addr       (buf2_calc_addr),
        .calc_data_in    (buf2_calc_data_in),
        .calc_data_out   (buf2_calc_data_out),
        .display_addr    (buf2_display_addr),
        .display_data_out(buf2_display_data_out)
    );

endmodule
