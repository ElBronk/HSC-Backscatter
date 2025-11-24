/*
 * parse decoded downlink data
 */
 

module downlink_parser ( 
    input clk_i, 
    input reset_i, 
    input wr_enable_i, 
    input dl_bit_i, 
    output logic compression_o, //not used
    output logic repetition_o, //not used
    output logic resolution_o 
    );
// input clk_i;      // input clk_i (1MHz)
// input reset_i;      // reset_i signal
// input wr_enable_i;    // write enable signal from downlink decoder
// input dl_bit_i; // data demodulated from downlink 

// output reg resolution_o;          // decoded resolution_o bit, 0=low, 1=high
//                                 // for now, it goes to F4 and F5 pin and triggers interrupt to reconfigure camera
// output reg[2:0] compress_o;    // decoded compress_o control bit
//                                 // 000=no compress_o, 111=strongest compress_o, no use for now
// output reg[2:0] repetition_o;     // decoded repetition_o control bit
//                                 // no use for now
logic [14:0] downlink_buffer;  // shift register, holds downlink decoded so far; LSB=most recently decoded

always_ff @(negedge clk_i /* or negedge reset_i*/) begin //ff for 1 bit buffer, depth of 15
    if (!reset_i) begin
        downlink_buffer <= '0;
    end else if (wr_enable_i == 1) begin
        downlink_buffer <= {downlink_buffer[13:0], dl_bit_i};
    end else begin
        downlink_buffer <= downlink_buffer;
    end
end

always_ff @(posedge clk_i /*or negedge reset_i*/) begin //once we recognize a certain downlink pattern (0xDD or 221?) adjust resolution
    if (!reset_i) begin
        resolution_o <= 0;
        compress_o <= 0;
        repetition_o <= 0;
    end else begin
        if (downlink_buffer[14:7] == 8'b11011101) begin
            resolution_o <= downlink_buffer[6];
            compress_o <= 3'b000;  // unused for now
            repetition_o <= 3'b000;   // unused for now
        end else begin
            resolution_o <= resolution_o;
            compress_o <= compress_o;
            repetition_o <= repetition_o;
        end
    end
end

endmodule