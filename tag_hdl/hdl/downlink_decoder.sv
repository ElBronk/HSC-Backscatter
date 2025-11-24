/*
 * Measures the length of each packet and decodes the downlink
 * downlink format: 15 [preamble 11011101 x 8] 7 [resolution x 1] 6 [compression x 3] 3 [repetition x 3] 0
 */
 
`define BIT_1_LENGTH 2416    /* length of a '1' bit, unit is us.  */
`define BIT_0_LENGTH 2016    /* length of a '0' bit, unit is us.  */
`define ALLOWED_DIFF 80      /* allowed difference in packet length, unit is us */
                             /* i.e. packet sized BIT_1_LENGTH +- ALLOWED_DIFF will be considered as 1 */

module downlink_decoder ( 
    input clk_i, 
    input reset_i, 
    input trigger_i, 
    output logic detected_o, //detected a packet in the air, outputs at the end of it
    output logic dl_bit_o //bit output of detected packet
    );
// input clk_i;    // input clk_i (1MHz)
// input reset_i;    // reset_i signal
// input trigger_i;  // trigger_i signal from envelope detector

// output reg dl_bit_o;
// output reg detected_o;
 
logic trigger_state;          // trigger_i state at previous cycle
logic [11:0] packet_length;    // measures the length of the current wifi packet

always_ff @(posedge clk_i /* or negedge reset_i*/) begin
// reception logic
    if (!reset_i) begin
        /* reset_i */
        packet_length <= 0;
        trigger_state <= 0;
        dl_bit_o <= 0;
        detected_o <= 0;
    end else begin
        if (trigger_i == 1) begin // wifi packet in air
            packet_length <= packet_length + 1;
            trigger_state <= 1;
            detected_o <= 0;
            dl_bit_o <= 0;
        end else begin
            if (trigger_state == 0) begin   // no wifi packet
                packet_length <= 0;
                trigger_state <= 0;
                detected_o <= 0;
                dl_bit_o <= 0;
            end else begin            // wifi packet just ended
                if ((packet_length > (`BIT_1_LENGTH - `ALLOWED_DIFF)) &&
                    (packet_length < (`BIT_1_LENGTH + `ALLOWED_DIFF))) begin // detected_o an '1' bit
                    detected_o <= 1;
                    dl_bit_o <= 1;
                    packet_length <= 0;
                    trigger_state <= 0;
                end else if ((packet_length > (`BIT_0_LENGTH - `ALLOWED_DIFF)) &&
                         (packet_length < (`BIT_0_LENGTH + `ALLOWED_DIFF))) begin // detected_o a '0' bit
                    detected_o <= 1;
                    dl_bit_o <= 0;
                    packet_length <= 0;
                    trigger_state <= 0;
                end else begin// not a downlink packet
                    detected_o <= 0;
                    dl_bit_o <= 0;
                    packet_length <= 0;
                    trigger_state <= 0;
                end
            end
        end
    end
end

endmodule
