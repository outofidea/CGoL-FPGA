module top (

    input        ext_osc_clk,
    rst_but_n,
    output       lcd_vsync,
    lcd_hsync,
    lcd_clk,
    output [15:0] lcd_dat

);

    parameter WIDTH = 120;
    parameter HEIGHT = 120;

    life #(
        .WIDTH (WIDTH),
        .HEIGHT(HEIGHT)
    ) life (
        .clk                       (clk),
        .rst                       (rst),
        .state_bram_re             (state_bram_re),
        .state_bram_cell_addr      (state_bram_cell_addr),
        .state_bram_cell_data_in   (state_bram_cell_data_in),
        .state_bram_cell_data_out  (state_bram_cell_data_out),
        .state_bram_cell_data_valid(state_bram_cell_data_valid),
        .calc_done                 (calc_done)
    );

    state #(
        .WIDTH (WIDTH /* default 420 */),
        .HEIGHT(HEIGHT /* default 270 */)
     ) state (
        .calc_clk                (calc_clk),
        .display_clk             (display_clk),
        .rst                     (rst),
        .calc_cell_addr          (calc_cell_addr),
        .calc_we                 (calc_we),
        .calc_done               (calc_done),
        .calc_dat_in             (calc_dat_in),
        .calc_dat_out            (calc_dat_out),
        .ready                   (ready),
        .valid                   (valid),
        .display_out_cell_addr   (display_out_cell_addr),
        .display_buf_change_ack  (display_buf_change_ack),
        .display_buf_change_ready(display_buf_change_ready),
        .display_out_cell_state  (display_out_cell_state),
        .display_out_valid       (display_out_valid)
    );

    // lcd #(
    //     .R_WIDTH            (R_WIDTH  /* default 5 */),
    //     .G_WIDTH            (G_WIDTH  /* default 6 */),
    //     .B_WIDTH            (B_WIDTH  /* default 5 */),
    //     .V_PIX              (V_PIX  /* default 272 */),
    //     .H_PIX              (H_PIX  /* default 480 */),
    //     .H_BACK_PORCH_CLK   (H_BACK_PORCH_CLK  /* default 2 */),
    //     .H_FRONT_PORCH_CLK  (H_FRONT_PORCH_CLK  /* default 2 */),
    //     .HSYNC_CLK          (HSYNC_CLK  /* default 41 */),
    //     .VSYNC_LINES        (VSYNC_LINES  /* default 10 */),
    //     .V_FRONT_PORCH_LINES(V_FRONT_PORCH_LINES  /* default 2 */),
    //     .V_BACK_PORCH_LINES (V_BACK_PORCH_LINES  /* default 2 */),
    //     .CLK_FREQ_MHZ       (CLK_FREQ_MHZ  /* default 10 */)
    // ) lcd (
    //     .i_clk     (i_clk),
    //     .i_rst     (i_rst),
    //     .i_r       (i_r),
    //     .i_g       (i_g),
    //     .i_b       (i_b),
    //     .lcd_cur_x (lcd_cur_x),
    //     .lcd_cur_y (lcd_cur_y),
    //     .lcd_active(lcd_active),
    //     .lcd_r     (lcd_r),
    //     .lcd_g     (lcd_g),
    //     .lcd_b     (lcd_b),
    //     .lcd_vsync (lcd_vsync),
    //     .lcd_hsync (lcd_hsync),
    //     .lcd_pixclk(lcd_pixclk),
    //     .lcd_de    (lcd_de)
    // );

endmodule
