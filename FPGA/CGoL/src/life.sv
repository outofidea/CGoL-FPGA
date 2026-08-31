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
        CORNERS_CHECK,
        NEIGH,
        CALC,
        WRITEBACK,
        WAIT_BUF
    } LIFE_STATES_e;


    LIFE_STATES_e life_state, life_state_next;

    /*
        ! Just optimizes x advance
        ? [neigh0]   [neigh1]   [neigh2]
        ? [neigh3]   [self  ]   [neigh4]
        ? [neigh5]   [neigh6]   [neigh7]

        ? [prev_neigh0]   [prev_neigh1       ] [new_neigh_x]   
        ? [prev_neigh2]   [self (prev_neigh3}] [new_neigh_x]   
        ? [prev_neigh4]   [prev_neigh5       ] [new_neigh_x]   
    */

    logic [3:0] neighbor_read_count;  // 8 neighbors , 1 self:
    logic [7:0] cur_cell_neighbors_state;
    logic [3:0] cur_total_living_neighbors;

    //! DUDE WTF
    assign cur_total_living_neighbors = cur_cell_neighbors_state[0] + 
                                        cur_cell_neighbors_state[1] + 
                                        cur_cell_neighbors_state[2] + 
                                        cur_cell_neighbors_state[3] + 
                                        cur_cell_neighbors_state[4] + 
                                        cur_cell_neighbors_state[5] + 
                                        cur_cell_neighbors_state[6] + 
                                        cur_cell_neighbors_state[7];

    logic cur_cell_state;
    cell_address cur_cell_addr;

    logic prev_neighbor_avail;
    logic [5:0] prev_neighbors;
    logic final_cell;

    logic new_cell_state;

    logic [2:0] corners;  //? corners[0] == 0 is left side, == 1 is right side.
                          //? corners[1] == 0 is top side, ==1 is bottom side
                          //? corners[2] == 0 is not in corner, == 1 is in corner


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
        state_bram_cell_data_out = 0;
        state_bram_we            = 0;
        life_state_next          = life_state;
        calc_done                = 0;
        unique case (life_state)

            RESET: begin
                life_state_next = CORNERS_CHECK;
            end

            CORNERS_CHECK: begin
                life_state_next = NEIGH;
            end

            NEIGH: begin  //! hardcoded combinatorial hell coming

                if (prev_neighbor_avail) begin
                    //! neighbor info and in edges / corners, should be in 
                    //! the 2 horizontal edges minus first column only

                    if (corners[2] == 1) begin
                        unique case (corners[1:0])

                            2'b00: begin
                                unique case (neighbor_read_count)
                                    //? needs neigh[4,7] only
                                    0: state_bram_cell_addr = neighbor4_addr;
                                    1: state_bram_cell_addr = neighbor7_addr;
                                    2: life_state_next = CALC;
                                endcase
                            end

                            2'b01: begin
                                //? dont need amy neighbors
                                life_state_next = CALC;
                            end

                            2'b10: begin
                                unique case (neighbor_read_count)
                                    //? needs neigh [2,4] only
                                    0: state_bram_cell_addr = neighbor2_addr;
                                    1: state_bram_cell_addr = neighbor4_addr;
                                    2: life_state_next = CALC;
                                endcase
                            end

                            2'b11: begin
                                //? dont need any neighbors
                                life_state_next = CALC;
                            end
                        endcase


                    end else begin //! neighbor info and not in edges / corners, should happen most of the times
                        //? needs neigh[2,4,7]
                        unique case (neighbor_read_count)
                            0: state_bram_cell_addr = neighbor2_addr;
                            1: state_bram_cell_addr = neighbor4_addr;
                            2: state_bram_cell_addr = neighbor7_addr;
                            3: life_state_next = CALC;
                        endcase


                    end

                end else begin

                    if (corners[2] == 1) begin //! prev neighbor NOT avail and in corners (should be only on the left vertical screen edge)
                        unique case (corners[1:0])
                            2'b00: begin
                                //? only self and neigh[4,6,7]
                                unique case (neighbor_read_count)  //! trust me vro
                                    0:
                                    state_bram_cell_addr = cur_cell_addr; //put self address, value reg'ed in stage 1
                                    1: state_bram_cell_addr = neighbor4_addr;
                                    2: state_bram_cell_addr = neighbor6_addr;
                                    3: state_bram_cell_addr = neighbor7_addr;
                                    4: life_state_next = CALC;

                                endcase

                            end

                            2'b01: begin
                                //? only self and neigh[3,5,6]
                                $warning("Seems like its not js the left edge lol");
                                unique case (neighbor_read_count)  //! trust me vro
                                    0: state_bram_cell_addr = cur_cell_addr;
                                    1: state_bram_cell_addr = neighbor3_addr;
                                    2: state_bram_cell_addr = neighbor5_addr;
                                    3: state_bram_cell_addr = neighbor6_addr;
                                    4: life_state_next = CALC;

                                endcase
                            end

                            2'b10: begin
                                //? only self and neigh[1,2,4]
                                unique case (neighbor_read_count)  //! trust me vro
                                    0: state_bram_cell_addr = cur_cell_addr;
                                    1: state_bram_cell_addr = neighbor1_addr;
                                    2: state_bram_cell_addr = neighbor2_addr;
                                    3: state_bram_cell_addr = neighbor4_addr;
                                    4: life_state_next = CALC;

                                endcase

                            end

                            2'b11: begin
                                //? only self and neigh[1,0,3]
                                $warning("Seems like its not js the left edge lol");
                                unique case (neighbor_read_count)  //! trust me vro
                                    0: state_bram_cell_addr = cur_cell_addr;
                                    1: state_bram_cell_addr = neighbor1_addr;
                                    2: state_bram_cell_addr = neighbor0_addr;
                                    3: state_bram_cell_addr = neighbor3_addr;
                                    4: life_state_next = CALC;

                                endcase
                            end
                        endcase

                    end else begin //! prev neighbor not avail and not in corners, should be impossible ?
                        // unique case (neighbor_read_count)
                        //     0: begin

                        //     end

                        //     1: begin

                        //     end

                        //     2: begin

                        //     end

                        //     3: begin

                        //     end
                        // endcase  
                        $error("HOW ?");
                    end

                end

            end  // next state logic from NEIGH

            CALC: begin
                life_state_next = WRITEBACK;
            end

            WRITEBACK: begin
                state_bram_we            = 1;  //! enable write
                state_bram_cell_data_out = new_cell_state;
                state_bram_cell_addr     = cur_cell_addr;
                if (final_cell) begin
                    life_state_next = WAIT_BUF;
                end else begin
                    life_state_next = CORNERS_CHECK;
                end
            end

            WAIT_BUF: begin
                calc_done = 1;
                if (calc_done_ack) begin
                    life_state_next = RESET;
                end
            end

        endcase
    end

    always_ff @(posedge clk) begin : life_logic_ff

        if (rst) begin
            neighbor_read_count      <= '0;
            cur_cell_neighbors_state <= '0;
            cur_cell_addr            <= '{default: 0};
            new_cell_state           <= 0;
            final_cell               <= 0;
            prev_neighbor_avail      <= 0;
            prev_neighbors           <= '0;
            corners                  <= '0;
        end else begin

            unique case (life_state)
                RESET: begin


                end  //end state IDLE

                CORNERS_CHECK: begin
                    if (cur_cell_addr.cell_addr_x == 0) begin  // left side
                        {cur_cell_neighbors_state[0], cur_cell_neighbors_state[3], cur_cell_neighbors_state[5]} <= '0;
                        corners[2] <= 1;
                    end
                    if (cur_cell_addr.cell_addr_x == WIDTH - 1) begin //? Will shit itself if over/underflows
                        {cur_cell_neighbors_state[2], cur_cell_neighbors_state[4], cur_cell_neighbors_state[7]} <= '0;
                        corners[2] <= 1;
                        corners[0] <= 1;
                    end

                    if (cur_cell_addr.cell_addr_y == 0) begin
                        cur_cell_neighbors_state[2:0] <= '0;
                        prev_neighbors[1:0]           <= '0;
                        corners[2]                    <= 1;

                    end
                    if (cur_cell_addr.cell_addr_y == HEIGHT - 1) begin //? Will shit itself if over/underflows
                        cur_cell_neighbors_state[7:5] <= '0;
                        prev_neighbors[4:3]           <= '0;
                        corners[2]                    <= 1;
                        corners[1]                    <= 1;
                    end


                end  //end state CORNERS_CHECK

                NEIGH: begin
                    // CORNER AND EDGES HANDLING
                    if (prev_neighbor_avail) begin  //! prev neighbor avail

                        if (corners[2] == 1) begin  //! in corners and neighbor is avail
                            unique case (corners[1:0])

                                2'b00: begin
                                    //? only neigh[4,7]
                                    unique case (neighbor_read_count)  //! trust me vro
                                        0: begin
                                            neighbor_read_count <= neighbor_read_count + 1; //skipping one
                                        end

                                        1: begin
                                            cur_cell_state      <= state_bram_cell_data_in;
                                            neighbor_read_count <= neighbor_read_count + 1;
                                        end

                                        2: begin
                                            cur_cell_neighbors_state[4] <= state_bram_cell_data_in;
                                            neighbor_read_count         <= 0;
                                        end
                                    endcase
                                end

                                2'b01: begin
                                    //? no extra neighbor needed
                                end

                                2'b10: begin
                                    //? only neigh[2,4]
                                    unique case (neighbor_read_count)  //! trust me vro
                                        0: begin
                                            neighbor_read_count <= neighbor_read_count + 1; //skipping one

                                        end

                                        1: begin
                                            cur_cell_state      <= state_bram_cell_data_in;
                                            neighbor_read_count <= neighbor_read_count + 1;
                                        end

                                        2: begin
                                            cur_cell_neighbors_state[1] <= state_bram_cell_data_in;
                                            neighbor_read_count         <= 0;
                                        end
                                    endcase
                                end

                                2'b11: begin
                                    //? no extra neighbors needed
                                end

                            endcase

                        end else begin  //! NOT in corners and prev neighbor is avail
                            cur_cell_neighbors_state[1:0] <= prev_neighbors[1:0];
                            cur_cell_state                <= prev_neighbors[3];
                            cur_cell_neighbors_state[3]   <= prev_neighbors[2];
                            cur_cell_neighbors_state[6:5] <= prev_neighbors[5:4];
                            unique case (neighbor_read_count)
                                //? reads self and neigh[2,4,7]
                                0: begin
                                    neighbor_read_count <= neighbor_read_count + 1;  //skip 1
                                end

                                1: begin
                                    cur_cell_state      <= state_bram_cell_data_in;
                                    neighbor_read_count <= neighbor_read_count + 1;
                                end

                                2: begin
                                    cur_cell_neighbors_state[2] <= state_bram_cell_data_in;
                                    neighbor_read_count         <= neighbor_read_count + 1;
                                end

                                3: begin
                                    cur_cell_neighbors_state[4] <= state_bram_cell_data_in;
                                    neighbor_read_count         <= neighbor_read_count + 1;
                                end

                                4: begin
                                    cur_cell_neighbors_state[7] <= state_bram_cell_data_in;
                                    neighbor_read_count         <= 0;
                                end

                            endcase
                        end

                    end else begin  //! prev neighbor not avail
                        if (corners[2] == 1) begin  //! prev neighbor not avail and in corners
                            unique case (corners[1:0])
                                2'b00: begin
                                    //? only self and neigh[4,6,7]
                                    unique case (neighbor_read_count)
                                        0: begin
                                            neighbor_read_count <= neighbor_read_count + 1; //? skip 1
                                        end

                                        1: begin
                                            cur_cell_state      <= state_bram_cell_data_in;
                                            neighbor_read_count <= neighbor_read_count + 1;
                                        end

                                        2: begin
                                            cur_cell_neighbors_state[4] <= state_bram_cell_data_in;
                                            neighbor_read_count         <= neighbor_read_count + 1;
                                        end

                                        3: begin
                                            cur_cell_neighbors_state[6] <= state_bram_cell_data_in;
                                            neighbor_read_count         <= neighbor_read_count + 1;
                                        end

                                        4: begin
                                            cur_cell_neighbors_state[7] <= state_bram_cell_data_in;
                                            neighbor_read_count         <= 0;
                                        end

                                    endcase
                                end

                                2'b01: begin
                                    //? only self and neigh[3,5,6]
                                    unique case (neighbor_read_count)
                                        0: begin
                                            neighbor_read_count <= neighbor_read_count + 1; //? skip 1
                                        end

                                        1: begin
                                            cur_cell_state      <= state_bram_cell_data_in;
                                            neighbor_read_count <= neighbor_read_count + 1;
                                        end

                                        2: begin
                                            cur_cell_neighbors_state[3] <= state_bram_cell_data_in;
                                            neighbor_read_count         <= neighbor_read_count + 1;
                                        end

                                        3: begin
                                            cur_cell_neighbors_state[5] <= state_bram_cell_data_in;
                                            neighbor_read_count         <= neighbor_read_count + 1;
                                        end

                                        4: begin
                                            cur_cell_neighbors_state[6] <= state_bram_cell_data_in;
                                            neighbor_read_count         <= 0;
                                        end
                                    endcase
                                end

                                2'b10: begin
                                    //? only self and neigh[1,2,4]
                                    unique case (neighbor_read_count)
                                        0: begin
                                            neighbor_read_count <= neighbor_read_count + 1; //? skip 1
                                        end

                                        1: begin
                                            cur_cell_state      <= state_bram_cell_data_in;
                                            neighbor_read_count <= neighbor_read_count + 1;
                                        end

                                        2: begin
                                            cur_cell_neighbors_state[1] <= state_bram_cell_data_in;
                                            neighbor_read_count         <= neighbor_read_count + 1;
                                        end

                                        3: begin
                                            cur_cell_neighbors_state[2] <= state_bram_cell_data_in;
                                            neighbor_read_count         <= neighbor_read_count + 1;
                                        end

                                        4: begin
                                            cur_cell_neighbors_state[4] <= state_bram_cell_data_in;
                                            neighbor_read_count         <= 0;
                                        end
                                    endcase
                                end

                                2'b11: begin
                                    //? only self and neigh[1,0,3]
                                    unique case (neighbor_read_count)
                                        0: begin
                                            neighbor_read_count <= neighbor_read_count + 1; //? skip 1
                                        end

                                        1: begin
                                            cur_cell_state      <= state_bram_cell_data_in;
                                            neighbor_read_count <= neighbor_read_count + 1;
                                        end

                                        2: begin
                                            cur_cell_neighbors_state[1] <= state_bram_cell_data_in;
                                            neighbor_read_count         <= neighbor_read_count + 1;
                                        end

                                        3: begin
                                            cur_cell_neighbors_state[0] <= state_bram_cell_data_in;
                                            neighbor_read_count         <= neighbor_read_count + 1;
                                        end

                                        4: begin
                                            cur_cell_neighbors_state[3] <= state_bram_cell_data_in;
                                            neighbor_read_count         <= 0;
                                        end
                                    endcase
                                end
                            endcase

                        end else begin  //! prev neighbor not avail and not in corners... ?????
                            $error("fucking up the unfuckable are we ?");
                        end
                    end
                end  // end state NEIGH

                CALC: begin
                    if (cur_cell_state) begin
                        if (cur_total_living_neighbors < 2) begin  //? dies of underpopulation
                            new_cell_state <= 0;
                        end

                        if (cur_total_living_neighbors == 2 | cur_total_living_neighbors == 3) begin //? lives
                            new_cell_state <= 1;
                        end

                        if (cur_total_living_neighbors > 3) begin  //? dies of overpopulation
                            new_cell_state <= 0;
                        end
                    end else begin
                        if (cur_total_living_neighbors == 3) begin  //? birth
                            new_cell_state <= 1;
                        end
                    end

                    if (cur_cell_addr.cell_addr_x == WIDTH - 1) begin
                        if (cur_cell_addr.cell_addr_y == HEIGHT - 1) begin
                            final_cell <= 1;
                        end else begin
                            cur_cell_addr <= '{
                                cell_addr_x: '0,
                                cell_addr_y: cur_cell_addr.cell_addr_y + 1
                            };
                            prev_neighbor_avail <= 0;
                        end

                    end else begin
                        cur_cell_addr <= '{
                            cell_addr_x: cur_cell_addr.cell_addr_x + 1,
                            cell_addr_y: cur_cell_addr.cell_addr_y
                        };
                        prev_neighbor_avail <= 1;

                        prev_neighbors[1:0] <= cur_cell_neighbors_state[2:1];
                        prev_neighbors[3] <= cur_cell_neighbors_state[4];
                        prev_neighbors[2] <= cur_cell_state;
                        prev_neighbors[5:4] <= cur_cell_neighbors_state[7:6];
                    end
                end

                WRITEBACK: begin

                end

                WAIT_BUF: begin

                end

            endcase  // end state logic
        end
    end


endmodule
