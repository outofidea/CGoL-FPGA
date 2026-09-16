//* Glue logic for framebuf to lcd, also handles pausing and stuff.
import cell_address_package::*;
import disp_data_package::*;
module display #(
    parameter WIDTH  = 480,
    parameter HEIGHT = 272
) (
    input               display_clk,
    input               disp_rst,
    output cell_address disp_cell_addr,
    output logic        disp_cell_addr_valid,
    input  logic        disp_cell_state,
    input  logic        disp_cell_state_valid,

    input  logic playpause,
    input  logic screen_ovrd,
    input  logic display_buf_change_ready,
    output logic display_buf_change_req,

    output disp_dat display_data,
    output logic    lcd_vsync,
    output logic    lcd_hsync,
    output logic    lcd_pixclk,
    output logic    lcd_de

);

    logic [4:0] lcd_r_dat;
    logic [5:0] lcd_g_dat;
    logic [4:0] lcd_b_dat;

    logic [$clog2(WIDTH)-1:0] lcd_cur_x;
    logic [$clog2(HEIGHT)-1:0] lcd_cur_y;

    logic lcd_active;
    logic lcd_v_back_porch;
    logic [4:0] lcd_r;
    logic [5:0] lcd_g;
    logic [4:0] lcd_b;

    assign display_data.lcd_r_dat = lcd_r;
    assign display_data.lcd_g_dat = lcd_g;
    assign display_data.lcd_b_dat = lcd_b;

    logic display_buf_change_ready_sync_1;
    logic display_buf_change_ready_sync_2;

    assign disp_cell_addr       = '{cell_addr_x: lcd_cur_x, cell_addr_y: lcd_cur_y};

    assign disp_cell_addr_valid = lcd_active;

    always_comb begin
        if ((disp_cell_state_valid && disp_cell_state)) begin
            lcd_r_dat = 5'h1f;
            lcd_g_dat = 6'h3f;

            lcd_b_dat = 5'h1f;
        end else begin
            lcd_r_dat = '0;
            lcd_g_dat = '0;
            lcd_b_dat = '0;
        end

        if (screen_ovrd) begin
            lcd_r_dat = lcd_cur_x;
            lcd_g_dat = lcd_cur_y;
            lcd_b_dat = '0;
        end

    end

    logic buf_changed_this_frame;

    always_ff @(posedge display_clk) begin
        if (disp_rst) begin
            display_buf_change_ready_sync_1 <= 1'b0;
            display_buf_change_ready_sync_2 <= 1'b0;
        end else begin
            display_buf_change_ready_sync_1 <= display_buf_change_ready;
            display_buf_change_ready_sync_2 <= display_buf_change_ready_sync_1;
        end
    end

    //! on vsync: check if we have already requested and a buffer change has fired
    //! if yes, do nothing and reset after vsync goes down
    //! if no, request a buf change  

    assign display_buf_change_req = (!lcd_vsync && lcd_v_back_porch) && playpause && ! buf_changed_this_frame;

    always_ff @(posedge display_clk) begin
        if (disp_rst) begin
            buf_changed_this_frame <= 1'b1;
        end else begin

            if (display_buf_change_req && display_buf_change_ready_sync_2) begin
                buf_changed_this_frame <= 1;
            end

            if (buf_changed_this_frame && !lcd_vsync) begin
                buf_changed_this_frame <= 0;
            end

        end
    end

    //! should change buffer at the final and largest blanking period
    //! at the bottom edge
    lcd #(
        .R_WIDTH(5),
        .G_WIDTH(6),
        .B_WIDTH(5),
        .H_PIX  (WIDTH),
        .V_PIX  (HEIGHT)
    ) lcd (
        .i_clk     (display_clk),
        .i_rst     (disp_rst),
        .i_r       (lcd_r_dat),
        .i_g       (lcd_g_dat),
        .i_b       (lcd_b_dat),
        .lcd_cur_x (lcd_cur_x),
        .lcd_cur_y (lcd_cur_y),
        .lcd_active(lcd_active),
        .v_back_porch(lcd_v_back_porch),
        .lcd_r     (lcd_r),
        .lcd_g     (lcd_g),
        .lcd_b     (lcd_b),
        .lcd_vsync (lcd_vsync),
        .lcd_hsync (lcd_hsync),
        .lcd_pixclk(lcd_pixclk),
        .lcd_de    (lcd_de)
    );



endmodule
