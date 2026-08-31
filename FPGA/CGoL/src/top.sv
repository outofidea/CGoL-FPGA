import cell_address_package::*;
import disp_data_package::*;
module top (
    input logic rst_but_n,
    input logic ext_27M_osc,

    output logic    lcd_vsync,
    output logic    lcd_hsync,
    output logic    lcd_clk,
    output logic    lcd_de,
    output disp_dat lcd_dat

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

    Gowin_rPLL main_pll (
        .clkout(calc_clk),  //output clkout
        .lock(pll_lock),  //output lock
        .clkoutd(disp_clk),  //output clkoutd
        .clkin(ext_27M_osc)  //input clkin
    );

    debounce #(
        .CLK_FREQ_HZ     (100_000_000),
        .DEBOUNCE_TIME_MS(  /* default 20 */)
    ) fpga_reset_debounce (
        .rst       (!pll_lock),
        .clk       (disp_clk),
        .button_in (!rst_but_n),
        .button_out(rst_but_debounce)
    );

    assign sys_rst = !pll_lock & rst_but_debounce;

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
        display_buf_change_ready, display_buf_change_ack, display_out_cell_state, display_out_valid,
        display_addr_valid;
    logic display_frame_end;

    display display (
        .display_clk             (disp_clk),
        .disp_rst                (disp_rst),
        .disp_cell_addr          (display_out_cell_addr),
        .disp_cell_addr_valid    (display_addr_valid),
        .disp_cell_state         (display_out_cell_state),
        .disp_cell_state_valid   (display_out_valid),
        .playpause               (1'b0),
        .display_buf_change_ready(display_buf_change_ready),
        .display_buf_change_ack  (display_buf_change_ack),
        .display_data            (lcd_dat),
        .lcd_vsync               (lcd_vsync),
        .lcd_hsync               (lcd_hsync),
        .lcd_pixclk              (lcd_clk),
        .lcd_de                  (lcd_de),
        .lcd_frame_end           (display_frame_end)
    );


    //! STATE
    state #(
        .WIDTH (WIDTH),
        .HEIGHT(HEIGHT)
    ) state (
        .calc_clk                (calc_clk),
        .display_clk             (disp_clk),
        .rst                     (sys_rst),
        .calc_cell_addr          (calc_state_cell_addr),
        .calc_we                 (calc_state_we),
        .calc_done               (calc_done),
        .calc_done_ack           (calc_done_ack),
        .calc_dat_in             (calc_state_data_out),
        .calc_dat_out            (calc_state_data_in),
        .valid                   (),
        .display_out_cell_addr   (display_out_cell_addr),
        .display_buf_change_ack  (display_buf_change_ack),
        .display_buf_change_ready(display_buf_change_ready),
        .display_out_cell_state  (display_out_cell_state),
        .display_out_valid       (display_out_valid),
        .display_out_cell_addr_valid(display_addr_valid)
    );
endmodule
