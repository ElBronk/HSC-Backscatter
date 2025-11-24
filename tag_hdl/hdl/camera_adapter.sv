module camera_adapter( 
    input clk_i, 
    input reset_i,
    input [3:0] data_i, 
    input vsync_i, 
    input hsync_i, 
    input [2:0] compress_command, //unused?
    output logic [7:0] output_data, 
    output logic write_en
    );
// input reset_i;
// input clk_i;
// input[3:0] data_i;
// input vsync_i, hsync_i;
// input[2:0] compress_command;

// output reg write_en;
// output reg[7:0] output_data;

logic frame_flag;
logic [3:0] buffer_state;
logic [1:0] repeat_counter;
logic [2:0] compress_mode;

/* only used in delta modulation */
logic [7:0] last_pixel;
logic [3:0] hi_nibble;
logic [7:0] pixel_idx;
logic lohalf;

/*
 * Camera Timing Diagram
 * VSYNC ____________|----------------------------------------------|___
 * HSYNC ____________________|-----------------------------------|______
 * clk_i  |_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|
 * COND       1      |   2   |               3                   | 2| 1
 */

/*
 * we are not considering full fifo. one possible solution is that we may add a "corrupted
 * frame" marker when the fifo full signal is positive. or we can adaptively adjust the
 * camera clock rate when we fifo is always getting stuffed. 
 */
 
always_ff @(posedge clk_i /*or negedge reset_i*/) begin
    if (!reset_i) begin
        buffer_state <= 0;
        write_en <= 0;
        frame_flag <= 0;
        output_data <= 8'd0;
        repeat_counter <= 2'd0;
        compress_mode <= 3'd0;

        last_pixel <= 0;
        pixel_idx <= 0;
        lohalf <= 0;
        hi_nibble <= 0;
    end else begin /* clk_i RISING edge */
        if (vsync_i == 1) begin
            frame_flag <= 1;    // record that in this cycle vsync is valid
            if (frame_flag == 0) begin // if vsync just rose
                buffer_state <= 0;
                compress_mode <= compress_command;  // register compress mode for this frame
                repeat_counter <= 2'd3;  // we will be transmitting 3 marker bytes
                write_en <= 0;

                last_pixel <= 0;
                pixel_idx <= 0;
                lohalf <= 0;
            end else if (repeat_counter != 2'd0) begin // if transmitting frame start mark
                /* need to transmit special marker (8'b10101010) byte this cycle */
                repeat_counter <= repeat_counter - 2'd1;    // decrease marker counter
                output_data <= 8'b10101010;
                write_en <= 1;
            end else if (hsync_i == 1) begin // if valid camera data is coming
                if (compress_mode == 3'b111) begin // TODO: should use smartfreeze to disable this part of circuit
                        if (lohalf == 1) begin // lower nibble of a pixel
                            pixel_idx <= pixel_idx + 1;
                            lohalf <= 0;
                            if (pixel_idx == 0) begin // we transmit a reference pixel every 33 pixels
                                write_en <= 1;
                                output_data[7:0] <= {hi_nibble[3:0], data_i[3:0]};
                                last_pixel <= {hi_nibble[3:0], data_i[3:0]};
                            end
                            else begin // for pixels between ref pixels, just transmit delta
                                if (pixel_idx == 32)
                                    pixel_idx <= 0;
                                if (buffer_state == 7) begin
                                    buffer_state <= 0;
                                    write_en <= 1;
                                end else begin
                                    buffer_state <= buffer_state + 1;
                                    write_en <= 0;
                                end
                                if ({hi_nibble[3:0], data_i[3:0]} > last_pixel) begin
                                    output_data[7:1] <= output_data[6:0];
                                    output_data[0] <= 1;
                                    if (last_pixel < 240)   // saturate logic
                                        last_pixel <= last_pixel + 16;
                                    else
                                        last_pixel <= 255;
                                end else begin
                                    output_data[7:1] <= output_data[6:0];
                                    output_data[0] <= 0;
                                    if (last_pixel > 15)
                                        last_pixel <= last_pixel - 16;
                                    else
                                        last_pixel <= 0;
                                end
                            end
                        end else begin // higher nibble of a pixel
                            write_en <= 0;
                            hi_nibble[3:0] <= data_i[3:0];  // latch higher nibble
                            lohalf <= 1;
                        end
                    end else if (compress_mode == 3'b100) begin // downsampling
                        buffer_state <= buffer_state + 1;
                        write_en <= 0;
                        if (buffer_state == 0)
                            output_data[7:4] <= data_i[3:0];
                        else if (buffer_state == 2)
                            output_data[3:0] <= data_i[3:0];
                        else if (buffer_state == 3) begin
                            write_en <= 1;
                            buffer_state <= 0;
                        end 
                    end else if (compress_mode == 3'b000) begin
                        if (buffer_state == 0) begin // higher nibble
                            write_en <= 0;
                            output_data[7:4] <= data_i[3:0];
                            buffer_state <= 1;
                        end else begin  // lower nibble
                            write_en <= 1;
                            output_data[3:0] <= data_i[3:0];
                            buffer_state <= 0;
                        end
                    end

            end else begin // if in between of two pixel rows
                write_en <= 0;  // disable fifo read, since we are in between valid lines
            end
        end else begin
        /* vsync low, not in the middle of a frame
           COND = 1*/
            frame_flag <= 0;    // record that this cycle vsync is low
            write_en <= 0;
        end
    end
end

endmodule

