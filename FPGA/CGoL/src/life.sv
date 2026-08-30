//! THERES GONNA BE AN ABYSMAL NR. OF INDEXING BUGS BUT I CANT CARE FFS, THERES NO SEGFAULT IN HARDWARE
//* Fmax GONNA BE SHITE

import cell_address_package::*;
module life #(
    parameter unsigned WIDTH  = 420,
    parameter unsigned HEIGHT = 270

) (
    input logic clk,
    input logic rst,


    output state_bram_re,
    output cell_address_class#(WIDTH, HEIGHT)::cell_address state_bram_cell_addr, //! EVIL EVIL EVIL EVIL EVIL
    input logic state_bram_cell_data_in,

    output logic state_bram_cell_data_out,
    input  logic state_bram_cell_data_valid,
    output logic calc_done

);

    typedef enum {
        IDLE,
        CORNERS_CHECK,
        NEIGH,
        CALC,
        WRITEBACK
    } LIFE_STATES_e;


    LIFE_STATES_e life_state, life_state_next;

    /*
        [neigh0]   [neigh1]   [neigh2]
        [neigh3]   [self  ]   [neigh4]
        [neigh5]   [neigh6]   [neigh7]

        [prev_x]   [prev_neigh0]   [prev_neigh1]
        [prev_x]   [prev_neigh2]   [self       ]
        [prev_x]   [prev_neigh3]   [prev_neigh4]
    */

    logic [3:0] neighbor_read_count;  // 8 neighbors , 1 self:
    logic [7:0] cur_cell_neighbors;
    logic cur_cell_state;
    cell_address_class #(WIDTH, HEIGHT)::cell_address cur_cell_addr;

    logic prev_neighbor_avail;
    logic [4:0] prev_neighbors;
    logic neighbor_read_done;

    logic [2:0] corners;  // corners[0] == 0 is left side, == 1 is right side.
                          // corners[1] == 0 is top side, ==1 is bottom side
                          // corners[2] == 0 is not in corner, == 1 is in corner


    //! WTF LOL OMEGALUL
    cell_address_class #(WIDTH, HEIGHT)::cell_address
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


    always_ff @(posedge clk) begin : life_state_logic
        if (rst) begin
            life_state <= IDLE;
        end else begin
            life_state <= life_state_next;
        end
    end




    always_comb begin : life_logic_comb
        state_bram_cell_addr = '0;
        life_state_next      = life_state;

        unique case (life_state)

            IDLE: begin

            end

            NEIGH: begin  //! hardcoded combinatorial hell coming

                if (prev_neighbor_avail) begin

                end else begin

                    if (corners[2] == 1) begin

                        unique case (corners[1:0])
                            2'b00: begin
                                //only self and neigh[4,6,7]
                                unique case (neighbor_read_count)  //! trust me vro
                                    0: begin
                                        //put self address, value will be registered in stage 1
                                        state_bram_cell_addr = cur_cell_addr;
                                    end

                                    1: begin
                                        //put neigh 4 addr, which is x+1
                                        state_bram_cell_addr = neighbor4_addr;
                                    end

                                    2: begin
                                        //put neigh 6 addr, which is y+1
                                        state_bram_cell_addr = neighbor6_addr;
                                    end

                                    3: begin
                                        //put neigh 7 addr, which is x+1. y+1
                                        state_bram_cell_addr = neighbor7_addr;
                                    end

                                    4: begin

                                    end
                                endcase

                            end

                            2'b01: begin
                                //only self and neigh[3,5,6]
                                unique case (neighbor_read_count)  //! trust me vro


                                    0: begin
                                        //put self address, value will be registered in stage 1
                                        state_bram_cell_addr = cur_cell_addr;
                                    end

                                    1: begin
                                        //put neigh 3 addr, which is x-1
                                        state_bram_cell_addr = neighbor3_addr;
                                    end

                                    2: begin
                                        //put neigh 5 addr, which is x-1. y+1
                                        state_bram_cell_addr = neighbor5_addr;
                                    end

                                    3: begin
                                        //put neigh 6 addr, which is y+1
                                        state_bram_cell_addr = neighbor6_addr;
                                    end
                                    4: begin

                                    end



                                endcase
                            end

                            2'b10: begin
                                //only self and neigh[1,2,4]

                                unique case (neighbor_read_count)  //! trust me vro
                                    0: begin
                                        //put self address, value will be registered in stage 1
                                        state_bram_cell_addr = cur_cell_addr;
                                    end

                                    1: begin
                                        //put neigh 1 addr, which is, y-1
                                        state_bram_cell_addr = neighbor1_addr;
                                    end

                                    2: begin
                                        //put neigh 2 addr, which is x+1. y-1
                                        state_bram_cell_addr = neighbor2_addr;
                                    end

                                    3: begin
                                        //put neigh 4 addr, which is x+1
                                        state_bram_cell_addr = neighbor4_addr;
                                    end
                                    4: begin

                                    end

                                endcase

                            end

                            2'b11: begin
                                //only self and neigh[1,0,3]

                                unique case (neighbor_read_count)  //! trust me vro
                                    0: begin
                                        //put self addr
                                        state_bram_cell_addr = cur_cell_addr;
                                    end

                                    1: begin
                                        //put neigh 1
                                        state_bram_cell_addr = neighbor1_addr;
                                    end

                                    2: begin
                                        //put neigh 0
                                        state_bram_cell_addr = neighbor0_addr;
                                    end

                                    3: begin
                                        //rput neigh 3
                                        state_bram_cell_addr = neighbor3_addr;
                                    end

                                    4: begin

                                    end

                                endcase
                            end

                        endcase
                    end else begin
                        // not in any edges / corners so we just need neigh[2,4,7]
                        unique case (neighbor_read_count)
                            0: begin

                            end

                            1: begin

                            end

                            2: begin

                            end

                            3: begin

                            end
                        endcase

                    end

                end

            end  // next state logic from NEIGH

            CALC: begin

            end

            WRITEBACK: begin

            end

        endcase
    end

    always_ff @(posedge clk) begin : life_logic_ff

        if (rst) begin
            neighbor_read_count <= '0;
            cur_cell_neighbors  <= '0;
            cur_cell_addr       <= '{default: 0};

        end else begin

            unique case (life_state)
                IDLE: begin


                end  //end state IDLE

                CORNERS_CHECK: begin
                    if (cur_cell_addr.cell_addr_x == 0) begin  // left side
                        {cur_cell_neighbors[0], cur_cell_neighbors[3], cur_cell_neighbors[5]} <= '0;
                        corners[2] <= 1;
                    end
                    if (cur_cell_addr.cell_addr_x == WIDTH - 1) begin //? Will shit itself if over/underflows
                        {cur_cell_neighbors[2], cur_cell_neighbors[4], cur_cell_neighbors[7]} <= '0;
                        corners[2] <= 1;
                        corners[0] <= 1;
                    end

                    if (cur_cell_addr.cell_addr_y == 0) begin
                        cur_cell_neighbors[2:0] <= '0;
                        prev_neighbors[1:0]     <= '0;
                        corners[2]              <= 1;

                    end
                    if (cur_cell_addr.cell_addr_y == HEIGHT - 1) begin //? Will shit itself if over/underflows
                        cur_cell_neighbors[7:5] <= '0;
                        prev_neighbors[4:3]     <= '0;
                        corners[2]              <= 1;
                        corners[1]              <= 1;
                    end


                end  //end state CORNERS_CHECK

                NEIGH: begin
                    // CORNER AND EDGES HANDLING
                    if (prev_neighbor_avail) begin

                        if (corners[2] == 1) begin

                            unique case (corners[1:0])
                                2'b00: begin
                                    //only self and neigh[4,6,7]
                                    unique case (neighbor_read_count)  //! trust me vro
                                        0: begin
                                            neighbor_read_count <= neighbor_read_count + 1; //skipping one

                                        end

                                        1: begin
                                            cur_cell_state      <= state_bram_cell_data_in;
                                            neighbor_read_count <= neighbor_read_count + 1;
                                        end

                                        2: begin
                                            cur_cell_neighbors[4] <= state_bram_cell_data_in;
                                            neighbor_read_count   <= neighbor_read_count + 1;
                                        end

                                        3: begin
                                            cur_cell_neighbors[6] <= state_bram_cell_data_in;
                                            neighbor_read_count   <= neighbor_read_count + 1;
                                        end

                                        4: begin
                                            cur_cell_neighbors[7] <= state_bram_cell_data_in;
                                            neighbor_read_count   <= 0;
                                        end
                                    endcase

                                end

                                2'b01: begin
                                    //only self and neigh[3,5,6]
                                    unique case (neighbor_read_count)  //! trust me vro
                                        0: begin
                                            neighbor_read_count <= neighbor_read_count + 1; //skipping one

                                        end

                                        1: begin
                                            cur_cell_state      <= state_bram_cell_data_in;
                                            neighbor_read_count <= neighbor_read_count + 1;
                                        end

                                        2: begin
                                            cur_cell_neighbors[3] <= state_bram_cell_data_in;
                                            neighbor_read_count   <= neighbor_read_count + 1;
                                        end

                                        3: begin
                                            cur_cell_neighbors[5] <= state_bram_cell_data_in;
                                            neighbor_read_count   <= neighbor_read_count + 1;
                                        end

                                        4: begin
                                            cur_cell_neighbors[6] <= state_bram_cell_data_in;
                                            neighbor_read_count   <= 0;
                                        end



                                    endcase
                                end

                                2'b10: begin
                                    //only self and neigh[1,2,4]

                                    unique case (neighbor_read_count)  //! trust me vro
                                        0: begin
                                            neighbor_read_count <= neighbor_read_count + 1; //skipping one

                                        end

                                        1: begin
                                            cur_cell_state      <= state_bram_cell_data_in;
                                            neighbor_read_count <= neighbor_read_count + 1;
                                        end

                                        2: begin
                                            cur_cell_neighbors[1] <= state_bram_cell_data_in;
                                            neighbor_read_count   <= neighbor_read_count + 1;
                                        end

                                        3: begin
                                            cur_cell_neighbors[2] <= state_bram_cell_data_in;
                                            neighbor_read_count   <= neighbor_read_count + 1;
                                        end

                                        4: begin
                                            cur_cell_neighbors[4] <= state_bram_cell_data_in;
                                            neighbor_read_count   <= 0;
                                        end

                                    endcase

                                end

                                2'b11: begin
                                    //only self and neigh[1,0,3]
                                    unique case (neighbor_read_count)  //! trust me vro
                                        0: begin
                                            neighbor_read_count <= neighbor_read_count + 1; //skipping one

                                        end

                                        1: begin
                                            cur_cell_state      <= state_bram_cell_data_in;
                                            neighbor_read_count <= neighbor_read_count + 1;
                                        end

                                        2: begin
                                            cur_cell_neighbors[1] <= state_bram_cell_data_in;
                                            neighbor_read_count   <= neighbor_read_count + 1;
                                        end

                                        3: begin
                                            cur_cell_neighbors[0] <= state_bram_cell_data_in;
                                            neighbor_read_count   <= neighbor_read_count + 1;
                                        end

                                        4: begin
                                            cur_cell_neighbors[3] <= state_bram_cell_data_in;
                                            neighbor_read_count   <= 0;
                                        end
                                    endcase
                                end

                            endcase






                        end else begin
                            cur_cell_neighbors[1:0] <= prev_neighbors[1:0];
                            cur_cell_neighbors[3]   <= prev_neighbors[2];
                            cur_cell_neighbors[6:5] <= prev_neighbors[4:3];

                        end

                    end else begin  // prev neighbor not avail.





                    end
                end  // end state NEIGH

            endcase  // end state logic
        end
    end


endmodule
