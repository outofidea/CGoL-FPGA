import cell_address_package::*;
import disp_data_package::*;
module top (
    input logic rst_but_n,
    input logic ext_27M_osc,

    output logic       lcd_vsync,
    output logic       lcd_hsync,
    output logic       lcd_clk,
    output logic       lcd_de,
    output logic [4:0] lcd_r_dat,
    output logic [5:0] lcd_g_dat,
    output logic [4:0] lcd_b_dat,

    output led2,
    led3,
    input  sw_5,
    sw_4

);


    parameter WIDTH = 480;
    parameter HEIGHT = 272;

    //TODO in fpga top lv add PLLs and resets
    logic pll_lock;

    logic calc_clk, disp_clk;

    logic calc_state_we;
    logic calc_state_data_in, calc_state_data_out;
    logic calc_done, calc_done_ack;

    logic rst_but_debounce, sys_rst;


    rPLL #() pll (
        .CLKOUTP(),
        .CLKOUTD3(),
        .RESET(1'b0),
        .RESET_P(1'b0),
        .CLKFB(1'b0),
        .FBDSEL(6'b0),
        .IDSEL(6'b0),
        .ODSEL(6'b0),
        .PSDA(4'b0),
        .DUTYDA(4'b0),
        .FDLY(4'b0),
        .CLKIN(ext_27M_osc),  // 27 MHz
        .CLKOUT(disp_clk),  // 81 MHz
        .CLKOUTD(calc_clk),  // 10.125 MHz
        .LOCK(pll_lock)
    );


    debounce #(
        .CLK_FREQ_HZ     (81_000_000),
        .DEBOUNCE_TIME_MS(  /* default 20 */)
    ) fpga_reset_debounce (
        .rst       (!pll_lock),
        .clk       (calc_clk),
        .button_in (!rst_but_n),
        .button_out(rst_but_debounce)
    );


    assign sys_rst = !pll_lock | rst_but_debounce;

    assign led2    = !sys_rst;

    logic [3:0] disp_rst_sync;
    logic disp_rst;
    assign disp_rst = disp_rst_sync[3];

    //! sync-er for disp reset
    always_ff @(posedge disp_clk or posedge sys_rst) begin
        if (sys_rst) begin
            disp_rst_sync <= 4'b1111;
        end else begin
            disp_rst_sync[3:0] <= {disp_rst_sync[2:0], 1'b0};
        end
    end

    assign led3 = disp_rst;

    //! CALC
    cell_address calc_state_cell_addr;
    life #(
        .WIDTH (WIDTH),
        .HEIGHT(HEIGHT)
    ) life (
        .clk                     (calc_clk),
        .rst                     (sys_rst),
        .state_bram_we           (calc_state_we),
        .state_bram_cell_addr    (calc_state_cell_addr),
        .state_bram_cell_data_in (calc_state_data_in),
        .state_bram_cell_data_out(calc_state_data_out),
        .calc_done               (calc_done),
        .calc_done_ack           (calc_done_ack)
    );


    //! DISP
    cell_address display_out_cell_addr;
    logic
        display_buf_change_ready,
        display_buf_change_ack,
        display_out_cell_state,
        display_out_valid,
        display_addr_valid;

    logic disp_ovrd, play_pause;

    debounce #(
        .CLK_FREQ_HZ     (10_125_000),
        .DEBOUNCE_TIME_MS(  /* default 20 */)
    ) disp_override_debounce (
        .rst       (!pll_lock),
        .clk       (disp_clk),
        .button_in (sw_5),
        .button_out(disp_ovrd)
    );

    debounce #(
        .CLK_FREQ_HZ     (10_125_000),
        .DEBOUNCE_TIME_MS(  /* default 20 */)
    ) play_pause_debounce (
        .rst       (!pll_lock),
        .clk       (disp_clk),
        .button_in (sw_4),
        .button_out(play_pause)
    );


    disp_dat lcd_data_bundle;

    assign lcd_r_dat = lcd_data_bundle.lcd_r_dat;
    assign lcd_g_dat = lcd_data_bundle.lcd_g_dat;
    assign lcd_b_dat = lcd_data_bundle.lcd_b_dat;


    display display (
        .display_clk             (disp_clk),
        .disp_rst                (disp_rst),
        .disp_cell_addr          (display_out_cell_addr),
        .disp_cell_addr_valid    (display_addr_valid),
        .disp_cell_state         (display_out_cell_state),
        .disp_cell_state_valid   (display_out_valid),
        .playpause               (play_pause),
        .display_buf_change_ready(display_buf_change_ready),
        .display_buf_change_req  (display_buf_change_ack),
        .screen_ovrd             (disp_ovrd),
        .display_data            (lcd_data_bundle),
        .lcd_vsync               (lcd_vsync),
        .lcd_hsync               (lcd_hsync),
        .lcd_pixclk              (lcd_clk),
        .lcd_de                  (lcd_de)
    );


    //! STATE
    state #(
        .WIDTH (WIDTH),
        .HEIGHT(HEIGHT)
    ) state (
        .calc_clk                   (calc_clk),
        .display_clk                (disp_clk),
        .rst                        (sys_rst),
        .calc_cell_addr             (calc_state_cell_addr),
        .calc_we                    (calc_state_we),
        .calc_done                  (calc_done),
        .calc_done_ack              (calc_done_ack),
        .calc_dat_in                (calc_state_data_out),
        .calc_dat_out               (calc_state_data_in),
        .valid                      (),
        .display_out_cell_addr      (display_out_cell_addr),
        .display_buf_change_ack     (display_buf_change_ack),
        .display_buf_change_ready   (display_buf_change_ready),
        .display_out_cell_state     (display_out_cell_state),
        .display_out_valid          (display_out_valid),
        .display_out_cell_addr_valid(display_addr_valid)
    );
endmodule
