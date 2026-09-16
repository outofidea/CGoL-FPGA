//! Veryl transpiled this shit so badly omg
module lcd #(
    parameter byte unsigned R_WIDTH = 5,
    parameter byte unsigned G_WIDTH = 6,
    parameter byte unsigned B_WIDTH = 5,

    parameter shortint unsigned V_PIX = 272,
    parameter shortint unsigned H_PIX = 480,

    parameter shortint unsigned H_BACK_PORCH_CLK  = 2,
    parameter shortint unsigned H_FRONT_PORCH_CLK = 2,
    parameter shortint unsigned HSYNC_CLK         = 41,

    parameter shortint unsigned VSYNC_LINES         = 10,
    parameter shortint unsigned V_FRONT_PORCH_LINES = 2,
    parameter shortint unsigned V_BACK_PORCH_LINES  = 2

) (
    input logic i_clk,
    input logic i_rst,

    input logic [R_WIDTH-1:0] i_r,
    input logic [G_WIDTH-1:0] i_g,
    input logic [B_WIDTH-1:0] i_b,

    output logic [$clog2(H_PIX)-1:0] lcd_cur_x,
    output logic [$clog2(V_PIX)-1:0] lcd_cur_y,

    output logic lcd_active,

    output logic [R_WIDTH-1:0] lcd_r,
    output logic [G_WIDTH-1:0] lcd_g,
    output logic [B_WIDTH-1:0] lcd_b,
    output logic               v_back_porch,
    output logic               lcd_vsync,
    output logic               lcd_hsync,
    output logic               lcd_pixclk,
    output logic               lcd_de

);

    initial begin
        $dumpfile("lol.fst");
        $dumpvars();
    end

    logic hsync;
    logic vsync;

    always_comb lcd_vsync = vsync;
    always_comb lcd_hsync = hsync;

    always_comb lcd_de = hsync & vsync & lcd_active;

    localparam shortint unsigned H_TOTAL_CLK = H_BACK_PORCH_CLK + H_PIX + H_FRONT_PORCH_CLK + HSYNC_CLK;

    localparam shortint unsigned V_TOTAL_LINES = V_BACK_PORCH_LINES + V_PIX + V_FRONT_PORCH_LINES + VSYNC_LINES;
    localparam logic [$clog2(V_PIX)-1:0] LAST_VISIBLE_Y = $clog2(V_PIX)'(V_PIX - 1);

    shortint unsigned line_cnter;

    shortint unsigned line_pix_cnter;

    logic v_active;
    always_comb
        v_active = (((line_cnter) >= ((VSYNC_LINES
        + V_BACK_PORCH_LINES))) && ((line_cnter) < ((VSYNC_LINES + V_BACK_PORCH_LINES + V_PIX))));

    logic h_active;
    always_comb
        h_active = (line_pix_cnter >= (HSYNC_CLK + H_BACK_PORCH_CLK)) && 
        (line_pix_cnter < (HSYNC_CLK + H_BACK_PORCH_CLK + H_PIX));


    assign v_back_porch = (line_cnter >= VSYNC_LINES) && (line_cnter < (VSYNC_LINES + V_BACK_PORCH_LINES));

    logic v_front_porch;

    always_comb
        v_front_porch = (((line_cnter) >= ((VSYNC_LINES + V_BACK_PORCH_LINES
        + V_PIX))) && ((line_cnter) < ((V_TOTAL_LINES))));

    always_comb lcd_r = v_active & h_active ? i_r : '0;
    always_comb lcd_g = v_active & h_active ? i_g : '0;
    always_comb lcd_b = v_active & h_active ? i_b : '0;
    always_comb lcd_pixclk = i_clk & !i_rst;
    always_comb lcd_active = h_active & v_active;

    always_ff @(posedge i_clk) begin
        if (i_rst) begin
            line_pix_cnter <= 0;
            line_cnter     <= 0;
            hsync          <= 1;
            vsync          <= 1;
            lcd_cur_x      <= 0;
            lcd_cur_y      <= 0;
        end else begin
            case (1'b1)

                line_pix_cnter < HSYNC_CLK: begin
                    hsync          <= 0;
                    line_pix_cnter <= line_pix_cnter + (1);
                end

                (line_pix_cnter >= HSYNC_CLK) && 
                (line_pix_cnter < (HSYNC_CLK + H_BACK_PORCH_CLK)): begin
                    hsync          <= 1;
                    line_pix_cnter <= line_pix_cnter + (1);
                end

                (line_pix_cnter >= (HSYNC_CLK + H_BACK_PORCH_CLK)) && 
                (line_pix_cnter < (HSYNC_CLK + H_BACK_PORCH_CLK + H_PIX)): begin
                    hsync <= 1;
                    if (v_active) begin
                        lcd_cur_x <= lcd_cur_x + (1);
                    end
                    line_pix_cnter <= line_pix_cnter + (1);
                end


                (line_pix_cnter >= (HSYNC_CLK + H_BACK_PORCH_CLK + H_PIX)) && (line_pix_cnter < H_TOTAL_CLK): begin
                    if ((line_pix_cnter == H_TOTAL_CLK - 1)) begin
                        line_pix_cnter <= 0;
                        if (line_cnter == V_TOTAL_LINES - 1) begin
                            line_cnter <= 0;
                        end else begin
                            line_cnter <= line_cnter + (1);
                        end
                        lcd_cur_x <= 0;
                        if ((v_active)) begin
                            if ((lcd_cur_y == LAST_VISIBLE_Y)) begin
                                lcd_cur_y <= 0;
                            end else begin
                                lcd_cur_y <= lcd_cur_y + (1);
                            end
                        end
                    end else begin
                        line_pix_cnter <= line_pix_cnter + (1);
                    end
                end

                default: hsync <= 1;

            endcase

            case (1'b1)

                line_cnter < VSYNC_LINES: begin
                    vsync <= 0;
                end

                (line_cnter >= (VSYNC_LINES + V_BACK_PORCH_LINES)) && 
                (line_cnter < (VSYNC_LINES + V_BACK_PORCH_LINES + V_PIX)): begin
                    vsync <= 1;
                end

                line_cnter == V_TOTAL_LINES - 1: begin
                    line_cnter <= 0;
                    vsync      <= 0;
                end

                default: begin
                    vsync <= 1;
                end
            endcase

        end
    end

endmodule
