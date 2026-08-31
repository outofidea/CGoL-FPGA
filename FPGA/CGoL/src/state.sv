// `default_nettype none
import cell_address_package::*;
module state #(
    parameter WIDTH  = 480,
    parameter HEIGHT = 272
) (
    input logic calc_clk,
    input logic display_clk,
    input logic rst,

    input  cell_address calc_cell_addr,
    input  logic        calc_we,
    input  logic        calc_done,
    output logic        calc_done_ack,
    input  logic        calc_dat_in,
    output logic        calc_dat_out,

    output logic valid,


    input  cell_address display_out_cell_addr,
    input  logic        display_buf_change_ack,
    output logic        display_buf_change_ready,
    output logic        display_out_cell_state,
    output logic        display_out_valid,
    input  logic        display_out_cell_addr_valid

);

    //? Buffer management follows calculation clock (as its the fastest (should be))



    logic current_display_buffer;
    logic display_buffer_display;
    logic display_buf_change_ack_sync_1;
    logic display_buf_change_ack_sync_2;

    logic buf1_calc_we;
    cell_address buf1_calc_addr;
    logic buf1_calc_data_in;
    logic buf1_calc_data_out;
    cell_address buf1_display_addr;
    logic buf1_display_data_out;


    logic buf2_calc_we;
    cell_address buf2_calc_addr;
    logic buf2_calc_data_in;
    logic buf2_calc_data_out;
    cell_address buf2_display_addr;
    logic buf2_display_data_out;

    typedef enum {
        INIT,
        WAIT_CALCULATION,  //when next buf not ready
        WAIT_DISPLAY  // when at least 1 buffer ready
    } BUFFER_STATE_e;

    BUFFER_STATE_e state;

    always_ff @(posedge calc_clk) begin
        if (rst) begin
            state                         <= INIT;
            current_display_buffer        <= 1'b0;
            calc_done_ack                 <= 1'b0;
            display_buf_change_ready      <= 1'b0;
            display_buf_change_ack_sync_1 <= 1'b0;
            display_buf_change_ack_sync_2 <= 1'b0;
        end else begin
            display_buf_change_ack_sync_1 <= display_buf_change_ack;
            display_buf_change_ack_sync_2 <= display_buf_change_ack_sync_1;
            case (state)

                INIT: begin
                    current_display_buffer   <= 1'b0;
                    calc_done_ack            <= 1'b0;
                    display_buf_change_ready <= 1'b0;
                    state                    <= WAIT_CALCULATION;
                end

                WAIT_CALCULATION: begin
                    display_buf_change_ready <= 1'b0;
                    if (calc_done) begin
                        state         <= WAIT_DISPLAY;
                        calc_done_ack <= 1'b1;
                    end
                end

                WAIT_DISPLAY: begin
                    display_buf_change_ready <= 1'b1;

                    if (display_buf_change_ack_sync_2) begin
                        display_buf_change_ready <= 1'b0;
                        current_display_buffer   <= !current_display_buffer;
                        state                    <= WAIT_CALCULATION;
                    end

                    calc_done_ack <= 1'b0;
                end

                default: begin
                    state <= INIT;
                end
            endcase
        end
    end

    always_ff @(posedge display_clk) begin
        if (rst) begin
            display_buffer_display <= 1'b0;
            display_out_valid      <= 1'b0;
        end else begin
            display_out_valid <= display_out_cell_addr_valid;
            if (display_buf_change_ack) begin
                display_buffer_display <= !display_buffer_display;
            end
        end
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

                valid             = 0;
            end

            WAIT_CALCULATION, WAIT_DISPLAY: begin
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

        if (state != INIT) begin
            if (display_buffer_display == 1'b0) begin
                buf1_display_addr      = display_out_cell_addr;
                display_out_cell_state = buf1_display_data_out;
            end else begin
                buf2_display_addr      = display_out_cell_addr;
                display_out_cell_state = buf2_display_data_out;
            end
        end
    end





    state_bram #(
        .WIDTH    (WIDTH),
        .HEIGHT   (HEIGHT),
        .INIT_FILE("seed.mem")
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
        .WIDTH (WIDTH),
        .HEIGHT(HEIGHT)
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
