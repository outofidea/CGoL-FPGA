module lcd #(
    parameter byte unsigned R_WIDTH = 5,
    parameter byte unsigned G_WIDTH = 6,
    parameter byte unsigned B_WIDTH = 5,

    parameter shortint unsigned V_PIX = 272,
    parameter shortint unsigned H_PIX = 480,

    parameter shortint unsigned H_BACK_PORCH_CLK  = 2 ,
    parameter shortint unsigned H_FRONT_PORCH_CLK = 2 ,
    parameter shortint unsigned HSYNC_CLK         = 41,

    parameter shortint unsigned VSYNC_LINES         = 10,
    parameter shortint unsigned V_FRONT_PORCH_LINES = 2 ,
    parameter shortint unsigned V_BACK_PORCH_LINES  = 2 ,

    parameter shortint unsigned CLK_FREQ_MHZ = 10

) (
    input var logic i_clk,
    input var logic i_rst,

    input var logic [R_WIDTH-1:0] i_r,
    input var logic [G_WIDTH-1:0] i_g,
    input var logic [B_WIDTH-1:0] i_b,

    output var logic [$clog2(H_PIX)-1:0] lcd_cur_x,
    output var logic [$clog2(V_PIX)-1:0] lcd_cur_y,

    output var logic lcd_active,

    output var logic [R_WIDTH-1:0] lcd_r     ,
    output var logic [G_WIDTH-1:0] lcd_g     ,
    output var logic [B_WIDTH-1:0] lcd_b     ,
    output var logic               lcd_vsync ,
    output var logic               lcd_hsync ,
    output var logic               lcd_pixclk,
    output var logic               lcd_de

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

    shortint unsigned line_cnter;

    shortint unsigned line_pix_cnter;

    logic v_active; always_comb v_active = (((line_cnter) >= ((VSYNC_LINES
        + V_BACK_PORCH_LINES))) && ((line_cnter) < ((VSYNC_LINES + V_BACK_PORCH_LINES + V_PIX))));

    logic h_active; always_comb h_active = (((line_pix_cnter) >= ((HSYNC_CLK
        + H_BACK_PORCH_CLK))) && ((line_pix_cnter) < ((HSYNC_CLK + H_BACK_PORCH_CLK + H_PIX))));

    logic v_back_porch; always_comb v_back_porch = (((line_cnter) >= (VSYNC_LINES)) && ((line_cnter) < ((VSYNC_LINES
        + V_BACK_PORCH_LINES))));

    logic v_front_porch; always_comb v_front_porch = (((line_cnter) >= ((VSYNC_LINES + V_BACK_PORCH_LINES
        + V_PIX))) && ((line_cnter) < ((V_TOTAL_LINES))));

    always_comb lcd_r      = (((v_active & h_active)) ? ( i_r ) : ( '0 ));
    always_comb lcd_g      = (((v_active & h_active)) ? ( i_g ) : ( '0 ));
    always_comb lcd_b      = (((v_active & h_active)) ? ( i_b ) : ( '0 ));
    always_comb lcd_pixclk = i_clk & i_rst;
    always_comb lcd_active = h_active & v_active;

    always_ff @ (posedge i_clk, negedge i_rst) begin
        if (!i_rst) begin
            line_pix_cnter <= 0;
            line_cnter     <= 0;
            hsync          <= 1;
            vsync          <= 1;
            lcd_cur_x      <= 0;
            lcd_cur_y      <= 0;
        end else begin
            case (1'b1)
                line_pix_cnter < HSYNC_CLK: begin

                    hsync <= 0;

                    line_pix_cnter <= line_pix_cnter + (1);
                end
                (((
                line_pix_cnter) >= (HSYNC_CLK)) && ((line_pix_cnter) < ((HSYNC_CLK + H_BACK_PORCH_CLK)))): begin
                    hsync          <= 1;
                    line_pix_cnter <= line_pix_cnter + (1);
                end
                (((
                line_pix_cnter) >= ((HSYNC_CLK + H_BACK_PORCH_CLK))) && ((line_pix_cnter) < ((HSYNC_CLK
                    + H_BACK_PORCH_CLK + H_PIX)))): begin
                    hsync <= 1;
                    if (v_active) begin
                        lcd_cur_x <= lcd_cur_x + (1);
                    end
                    line_pix_cnter <= line_pix_cnter + (1);
                end
                (((
                line_pix_cnter) >= ((HSYNC_CLK + H_BACK_PORCH_CLK
                    + H_PIX))) && ((line_pix_cnter) < (H_TOTAL_CLK))): begin
                    if ((line_pix_cnter == H_TOTAL_CLK - 1)) begin
                        line_pix_cnter <= 0;
                        line_cnter     <= line_cnter     + (1);
                        lcd_cur_x      <= 0;
                        if ((v_active)) begin
                            if ((lcd_cur_y == V_PIX)) begin
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
                (((
                line_cnter) >= (VSYNC_LINES + V_BACK_PORCH_LINES)) && ((line_cnter) < (VSYNC_LINES + V_BACK_PORCH_LINES
                    + V_PIX))): begin
                    vsync <= 1;
                end

                    line_cnter == V_TOTAL_LINES: begin
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
