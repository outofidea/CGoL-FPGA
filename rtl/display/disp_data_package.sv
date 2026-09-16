package disp_data_package;

    parameter R_WIDTH = 5;
    parameter G_WIDTH = 6;
    parameter B_WIDTH = 5;

    typedef struct packed {
        logic [R_WIDTH - 1 : 0] lcd_r_dat;
        logic [G_WIDTH - 1 : 0] lcd_g_dat;
        logic [B_WIDTH - 1 : 0] lcd_b_dat;
    } disp_dat;

endpackage
