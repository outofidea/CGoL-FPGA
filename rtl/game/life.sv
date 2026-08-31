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
        NEIGH_ADDR_CALC,
        NEIGH,
        CALC,
        WRITEBACK,
        WAIT_BUF
    } LIFE_STATES_e;


    LIFE_STATES_e life_state, life_state_next;

    // Neighbor layout:
    // [neigh0]   [neigh1]   [neigh2]
    // [neigh3]   [self  ]   [neigh4]
    // [neigh5]   [neigh6]   [neigh7]

    logic [3:0] neighbor_read_count;  // 0-8: index into which neighbor to read
    logic [8:0] neighbor_states;      // bit 0=neigh0, bit 1=neigh1, ..., bit 7=neigh7, bit 8=self
    logic [3:0] cur_total_living_neighbors;

    assign cur_total_living_neighbors = neighbor_states[0] + 
                                        neighbor_states[1] + 
                                        neighbor_states[2] + 
                                        neighbor_states[3] + 
                                        neighbor_states[4] + 
                                        neighbor_states[5] + 
                                        neighbor_states[6] + 
                                        neighbor_states[7];

    logic cur_cell_state;
    cell_address cur_cell_addr;

    logic final_cell;
    logic new_cell_state;


    always_ff @(posedge clk) begin : life_state_advance_logic
        if (rst) begin
            life_state <= RESET;
        end else begin
            life_state <= life_state_next;
        end
    end

    // Compute one neighbor address based on neighbor_read_count
    // Indices 0-7: the 8 neighbors
    // Index 8: the cell itself
    cell_address computed_addr;

    always_comb begin : compute_neighbor_addr
        case (neighbor_read_count[3:0])
            4'd0: computed_addr = '{cell_addr_x: cur_cell_addr.cell_addr_x - 1, cell_addr_y: cur_cell_addr.cell_addr_y - 1};
            4'd1: computed_addr = '{cell_addr_x: cur_cell_addr.cell_addr_x,     cell_addr_y: cur_cell_addr.cell_addr_y - 1};
            4'd2: computed_addr = '{cell_addr_x: cur_cell_addr.cell_addr_x + 1, cell_addr_y: cur_cell_addr.cell_addr_y - 1};
            4'd3: computed_addr = '{cell_addr_x: cur_cell_addr.cell_addr_x - 1, cell_addr_y: cur_cell_addr.cell_addr_y};
            4'd4: computed_addr = '{cell_addr_x: cur_cell_addr.cell_addr_x + 1, cell_addr_y: cur_cell_addr.cell_addr_y};
            4'd5: computed_addr = '{cell_addr_x: cur_cell_addr.cell_addr_x - 1, cell_addr_y: cur_cell_addr.cell_addr_y + 1};
            4'd6: computed_addr = '{cell_addr_x: cur_cell_addr.cell_addr_x,     cell_addr_y: cur_cell_addr.cell_addr_y + 1};
            4'd7: computed_addr = '{cell_addr_x: cur_cell_addr.cell_addr_x + 1, cell_addr_y: cur_cell_addr.cell_addr_y + 1};
            4'd8: computed_addr = cur_cell_addr;  // The cell itself
            default: computed_addr = '0;
        endcase
    end


    always_comb begin : life_logic_comb
        state_bram_cell_addr     = '0;
        state_bram_cell_data_out = 0;
        state_bram_we            = 0;
        life_state_next          = life_state;
        calc_done                = 0;
        
        unique case (life_state)

            RESET: begin
                life_state_next = NEIGH_ADDR_CALC;
            end

            NEIGH_ADDR_CALC: begin
                // Issue one neighbor address per cycle
                state_bram_cell_addr = computed_addr;
                
                // After issuing address 8 (the cell itself), move to NEIGH to collect data
                if (neighbor_read_count == 4'd8) begin
                    life_state_next = NEIGH;
                end
            end

            NEIGH: begin
                // Collect neighbor data. After collecting all 9 states (0-8), move to CALC
                if (neighbor_read_count == 4'd0) begin
                    life_state_next = CALC;
                end
            end

            CALC: begin
                life_state_next = WRITEBACK;
            end

            WRITEBACK: begin
                state_bram_we            = 1;
                state_bram_cell_data_out = new_cell_state;
                state_bram_cell_addr     = cur_cell_addr;
                if (final_cell) begin
                    life_state_next = WAIT_BUF;
                end else begin
                    life_state_next = NEIGH_ADDR_CALC;
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
                    neighbor_read_count      <= '0;
                    cur_cell_neighbors_state <= '0;
                    cur_cell_addr            <= '{default: 0};
                    new_cell_state           <= 0;
                    final_cell               <= 0;
                    prev_neighbor_avail      <= 0;
                    prev_neighbors           <= '0;
                    corners                  <= '0;
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

                NEIGH_ADDR_CALC: begin
                    // Compute one address per cycle and issue it
                    // Increment counter for next iteration
                    neighbor_read_count <= neighbor_read_count + 1;
                end

                NEIGH: begin
                    // Collect data that was prefetched in NEIGH_ADDR_CALC
                    // Data arrives one cycle after address was issued
                    // Decrement counter back to track which data slot we're filling
                    neighbor_read_count <= neighbor_read_count - 1;

                    // Route incoming data to appropriate neighbor position based on read count
                    if (prev_neighbor_avail) begin

                        if (corners[2] == 1) begin  // In corner/edge
                            unique case (corners[1:0])
                                2'b00: begin  // Top-left: needs data for indices 4, 7
                                    case (neighbor_read_count)
                                        4'd4:
                                        cur_cell_neighbors_state[4] <= state_bram_cell_data_in;
                                        4'd7:
                                        cur_cell_neighbors_state[7] <= state_bram_cell_data_in;
                                        default: ;
                                    endcase
                                end
                                2'b01: begin  // Bottom-left: no extra data
                                end
                                2'b10: begin  // Top-right: needs data for indices 2, 4
                                    case (neighbor_read_count)
                                        4'd2:
                                        cur_cell_neighbors_state[2] <= state_bram_cell_data_in;
                                        4'd4:
                                        cur_cell_neighbors_state[4] <= state_bram_cell_data_in;
                                        default: ;
                                    endcase
                                end
                                2'b11: begin  // Bottom-right: no extra data
                                end
                            endcase

                        end else begin  // Not in corner: needs data for indices 0-7
                            cur_cell_neighbors_state[neighbor_read_count[2:0]] <= state_bram_cell_data_in;
                        end
                    
                    end else begin  // ? prev_neighbor NOT avail
                        if (corners[2] == 1) begin
                            unique case (corners[1:0])
                                2'b00: begin  // Top-left: needs self, 4, 6, 7
                                    case (neighbor_read_count)
                                        4'd0: cur_cell_state <= state_bram_cell_data_in;
                                        4'd4:
                                        cur_cell_neighbors_state[4] <= state_bram_cell_data_in;
                                        4'd6:
                                        cur_cell_neighbors_state[6] <= state_bram_cell_data_in;
                                        4'd7:
                                        cur_cell_neighbors_state[7] <= state_bram_cell_data_in;
                                        default: ;
                                    endcase
                                end
                                2'b01: begin  // Bottom-left: needs self, 3, 5, 6
                                    case (neighbor_read_count)
                                        4'd0: cur_cell_state <= state_bram_cell_data_in;
                                        4'd3:
                                        cur_cell_neighbors_state[3] <= state_bram_cell_data_in;
                                        4'd5:
                                        cur_cell_neighbors_state[5] <= state_bram_cell_data_in;
                                        4'd6:
                                        cur_cell_neighbors_state[6] <= state_bram_cell_data_in;
                                        default: ;
                                    endcase
                                end
                                2'b10: begin  // Top-right: needs self, 1, 2, 4
                                    case (neighbor_read_count)
                                        4'd0: cur_cell_state <= state_bram_cell_data_in;
                                        4'd1:
                                        cur_cell_neighbors_state[1] <= state_bram_cell_data_in;
                                        4'd2:
                                        cur_cell_neighbors_state[2] <= state_bram_cell_data_in;
                                        4'd4:
                                        cur_cell_neighbors_state[4] <= state_bram_cell_data_in;
                                        default: ;
                                    endcase
                                end
                                2'b11: begin  // Bottom-right: needs self, 0, 1, 3
                                    case (neighbor_read_count)
                                        4'd0: cur_cell_state <= state_bram_cell_data_in;
                                        4'd1:
                                        cur_cell_neighbors_state[1] <= state_bram_cell_data_in;
                                        4'd2:
                                        cur_cell_neighbors_state[0] <= state_bram_cell_data_in;
                                        4'd3:
                                        cur_cell_neighbors_state[3] <= state_bram_cell_data_in;
                                        default: ;
                                    endcase
                                end
                            endcase
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
