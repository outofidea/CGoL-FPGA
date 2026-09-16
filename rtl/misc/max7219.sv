module max7219 #(
    parameter COMM_RATE_HZ = 100_000
) (
    input clk,
    input rst,

    output logic driver_cs_out,
    output logic driver_d_out,
    output logic driver_latch_out,
    output logic driver_clk_out
);

endmodule
