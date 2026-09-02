//! THERES GONNA BE AN ABYSMAL NR. OF INDEXING BUGS BUT I CANT CARE FFS, THERES NO SEGFAULT IN HARDWARE
//* Fmax GONNA BE SHITE

import cell_address_package::*;
module life #(
    parameter unsigned WIDTH  = 480,
    parameter unsigned HEIGHT = 272

) (
    input logic clk,
    input logic rst,


    output logic        state_bram_we,
    input  logic        state_bram_cell_data_in,
    output cell_address state_bram_cell_addr,
    output logic        state_bram_cell_data_out,

    output logic calc_done,
    input  logic calc_done_ack

);

    typedef enum {
        RESET,
        NEIGH,
        CALC,
        WRITEBACK,
        WAIT_NEW_BUF
    } LIFE_STATES_e;
    //! yea im too lazy


    LIFE_STATES_e life_state, life_state_next;

    /*
        [neigh0]   [neigh1]   [neigh2]
        [neigh3]   [self  ]   [neigh4]
        [neigh5]   [neigh6]   [neigh7]

        [prev_x]   [prev_neigh0]   [prev_neigh1]
        [prev_x]   [prev_neigh2]   [self       ]
        [prev_x]   [prev_neigh3]   [prev_neigh4]
    */

    logic [9:0] cells_read_state;  //? 8 neighbors , 1 self, OneHot
    logic [7:0] cur_cell_neighbors;
    logic [4:0] tot_neighbors;
    // logic cur_cell_state;
    logic next_cell_state;
    cell_address cur_cell_addr, next_cell_addr;

    logic final_cell;


    //! WTF LOL OMEGALUL
    cell_address
        neighbor0_addr,
        neighbor1_addr,
        neighbor2_addr,
        neighbor3_addr,
        neighbor4_addr,
        neighbor5_addr,
        neighbor6_addr,
        neighbor7_addr;

    assign neighbor0_addr = '{
            cell_addr_x: cur_cell_addr.cell_addr_x - 1,
            cell_addr_y: cur_cell_addr.cell_addr_y - 1
        };

    assign neighbor1_addr = '{
            cell_addr_x: cur_cell_addr.cell_addr_x,
            cell_addr_y: cur_cell_addr.cell_addr_y - 1
        };

    assign neighbor2_addr = '{
            cell_addr_x: cur_cell_addr.cell_addr_x + 1,
            cell_addr_y: cur_cell_addr.cell_addr_y - 1
        };

    assign neighbor3_addr = '{
            cell_addr_x: cur_cell_addr.cell_addr_x - 1,
            cell_addr_y: cur_cell_addr.cell_addr_y
        };

    assign neighbor4_addr = '{
            cell_addr_x: cur_cell_addr.cell_addr_x + 1,
            cell_addr_y: cur_cell_addr.cell_addr_y
        };

    assign neighbor5_addr = '{
            cell_addr_x: cur_cell_addr.cell_addr_x - 1,
            cell_addr_y: cur_cell_addr.cell_addr_y + 1
        };

    assign neighbor6_addr = '{
            cell_addr_x: cur_cell_addr.cell_addr_x,
            cell_addr_y: cur_cell_addr.cell_addr_y + 1
        };

    assign neighbor7_addr = '{
            cell_addr_x: cur_cell_addr.cell_addr_x + 1,
            cell_addr_y: cur_cell_addr.cell_addr_y + 1
        };


    always_ff @(posedge clk) begin : life_state_advance_logic
        if (rst) begin
            life_state <= RESET;
        end else begin
            life_state <= life_state_next;
        end
    end

    always_comb begin : life_logic_comb //? might separate bram addressing logic and state jump logic later
        state_bram_cell_addr     = '0;
        state_bram_we            = 0;
        state_bram_cell_data_out = 0;
        life_state_next          = life_state;
        next_cell_addr           = 0;
        calc_done                = 0;
        unique case (life_state)

            RESET: begin
                life_state_next = NEIGH;
            end

            NEIGH: begin  //needs to get neighbors and self
                unique case (1'b1)  //! shenanigans 
                    //? reads neighbors first, self later
                    cells_read_state[0]: state_bram_cell_addr = neighbor0_addr;
                    cells_read_state[1]: state_bram_cell_addr = neighbor1_addr;
                    cells_read_state[2]: state_bram_cell_addr = neighbor2_addr;
                    cells_read_state[3]: state_bram_cell_addr = neighbor3_addr;
                    cells_read_state[4]: state_bram_cell_addr = neighbor4_addr;
                    cells_read_state[5]: state_bram_cell_addr = neighbor5_addr;
                    cells_read_state[6]: state_bram_cell_addr = neighbor6_addr;
                    cells_read_state[7]: state_bram_cell_addr = neighbor7_addr;
                    cells_read_state[8]: begin
                        state_bram_cell_addr = cur_cell_addr;
                        life_state_next      = CALC;
                    end
                endcase
            end

            CALC: begin
                life_state_next = WRITEBACK;
            end

            WRITEBACK: begin
                state_bram_we            = 1;
                state_bram_cell_data_out = next_cell_state;
                if (final_cell) begin

                end else begin
                    life_state_next = NEIGH;
                end
            end

            WAIT_NEW_BUF: begin
                calc_done = 1;
                if (calc_done_ack) begin
                    life_state_next = RESET;
                end
            end
        endcase
    end

    always_ff @(posedge clk) begin : life_logic_ff

        unique case (life_state)
            RESET: begin
                cells_read_state   <= '0;
                cur_cell_neighbors <= '0;
                cur_cell_addr      <= '{default: 0};
                cells_read_state   <= 10'b0000000001;
            end  //end state IDLE

            //! get neighbors first then correct corners later, as simple as possible
            NEIGH: begin
                unique case (1'b1)  //! more shenanigans
                    cells_read_state[0]: cells_read_state <= 10'b0000000010;  //? skip 

                    cells_read_state[1]: begin
                        cur_cell_neighbors[0] <= state_bram_cell_data_out;
                        tot_neighbors[0]      <= state_bram_cell_data_in;
                        cells_read_state      <= 10'b0000000100;
                    end

                    cells_read_state[2]: begin
                        cur_cell_neighbors[1] <= state_bram_cell_data_out;
                        tot_neighbors         <= tot_neighbors + state_bram_cell_data_in;
                        cells_read_state      <= 10'b0000001000;
                    end

                    cells_read_state[3]: begin
                        cur_cell_neighbors[2] <= state_bram_cell_data_out;
                        tot_neighbors         <= tot_neighbors + state_bram_cell_data_in;
                        cells_read_state      <= 10'b0000010000;
                    end

                    cells_read_state[4]: begin
                        cur_cell_neighbors[3] <= state_bram_cell_data_out;
                        tot_neighbors         <= tot_neighbors + state_bram_cell_data_in;
                        cells_read_state      <= 10'b0000100000;
                    end

                    cells_read_state[5]: begin
                        cur_cell_neighbors[4] <= state_bram_cell_data_out;
                        tot_neighbors         <= tot_neighbors + state_bram_cell_data_in;
                        cells_read_state      <= 10'b0001000000;
                    end

                    cells_read_state[6]: begin
                        cur_cell_neighbors[5] <= state_bram_cell_data_out;
                        tot_neighbors         <= tot_neighbors + state_bram_cell_data_in;
                        cells_read_state      <= 10'b0010000000;
                    end

                    cells_read_state[7]: begin
                        cur_cell_neighbors[6] <= state_bram_cell_data_out;
                        tot_neighbors         <= tot_neighbors + state_bram_cell_data_in;
                        cells_read_state      <= 10'b0100000000;
                    end

                    cells_read_state[8]: begin
                        cur_cell_neighbors[7] <= state_bram_cell_data_out;
                        tot_neighbors         <= tot_neighbors + state_bram_cell_data_in;
                        cells_read_state      <= 10'b1000000000;
                    end

                    cells_read_state[9]: begin
                        cur_cell_neighbors[7] <= state_bram_cell_data_out;
                        tot_neighbors         <= tot_neighbors + state_bram_cell_data_in;
                        cells_read_state      <= 10'b0000000001;
                    end
                endcase



            end  // end state NEIGH

            CALC: begin
                if (state_bram_cell_data_out) begin
                    unique if (tot_neighbors < 2 | tot_neighbors > 3) begin
                        next_cell_state = 0;
                    end else if (tot_neighbors == 2 | tot_neighbors == 3) begin
                        next_cell_state = 1;
                    end
                end else begin
                    if (tot_neighbors == 3) begin
                        next_cell_state = 1;
                    end
                end
            end

            WRITEBACK: begin
                if (cur_cell_addr.cell_addr_x == WIDTH - 1) begin
                    if (cur_cell_addr.cell_addr_y == HEIGHT - 1) begin
                        final_cell    <= 1;
                        cur_cell_addr <= '0;
                    end else begin
                        cur_cell_addr.cell_addr_x <= '0;
                        cur_cell_addr.cell_addr_y <= cur_cell_addr.cell_addr_y + 1;
                    end
                end else begin
                    cur_cell_addr.cell_addr_x <= cur_cell_addr.cell_addr_x + 1;
                end
            end

            WAIT_NEW_BUF: begin

            end

        endcase  // end state logic
    end


endmodule
