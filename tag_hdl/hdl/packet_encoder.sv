`define PACKET_LEN 64
//TODO  make a state diagram of whats going on here to potentially optimize?
module packet_encoder( 
    input clk_i, 
    input reset_i, 
    input trigger_i, 
    input data_i, 
    output logic data_o, 
    output logic fifo_ready_o, 
    input fifo_empty_i 
    );
// input clk_i, reset_i;
// input trigger;
// input fifo_empty;
// input [7:0] input_data;
// output logic output_data;
// output logic fifo_re;

logic [15:0] byte_counter; //counting bytes within packets
logic [23:0] seq_number; //sequence number for packets as fifo empties
logic [7:0] payload_size; //same as byte counter??
logic [7:0] current; //current byte we are trying to send out
logic [4:0] bit_state;  /* which bit is now transmitting */
logic packet_ended; //if the packet is ended

/*
 * Packet Format
 * 10010010 payload 10010010 metadata(6bytes) 10010010 10010010
 * metadata: 1byte payload size + 2byte seq number, Golay coded to 6bytes
 */

always @(posedge clk_i /* or negedge reset_i*/) begin //removing async reset
    if (!reset_i) begin
        payload_size <= 0;
        seq_number <= 16'd0;
        bit_state <= 0;
        byte_counter <= 0;
        data_o <= 0;
        fifo_ready_o <= 0;
        current <= 8'b10010010;
        packet_ended <= 0;
    end else if (trigger) begin
    /* start encoding packet */
        /* feed tx signal */
        output_data <= current[7];  /* feed tx data */
        /* We need to send each byte three times in a line, 8x3=24
           if we are sending the 24th bit of a byte, we need to move
           to the next byte in the next cycle by current <= input_data
           Also, we need to pull up fifo_re two cycles earlier to update
           the value of input_datan (fifo takes 2 cycles to output data) */

        if (bit_state == 21) begin       /* third last bit in a byte, we need to determine whether to pull data from fifo */
            if (byte_counter >= `PACKET_LEN-8) begin      /* if we are about to finish the last byte of payload */
                packet_ended <= 1;
                fifo_re <= 0;            
                /* don't pull data from fifo, 
                we are ending the packet fifo_re will be pull down at next clk rising edge,
                so we only pulled one byte */ 
            end else if (fifo_empty == 1) begin 
                 /* if fifo is empty */
                packet_ended <= 1;    
                fifo_re <= 0;         
            end else if (packet_ended == 1) begin  /* if packet has ended */
                packet_ended <= 1;
                fifo_re <= 0;
            end else begin                         /* if next byte should be normal payload */
                fifo_re <= 1;
            end
            bit_state <= bit_state + 1;
            current <= {current[6:0], current[7]};  /* left shift register */
        end else if (bit_state == 23) begin  /* last bit in a byte, we need to update "current byte" from fifo or use padding byte */
            fifo_re <= 0;
            byte_counter <= byte_counter + 1;   /* we just finished sending one byte */
            bit_state <= 0;
            if (packet_ended)  begin     /* if this packet is marked as finished earlier */
                if (byte_counter == `PACKET_LEN-7)      
                    current <= seq_number[23:16];
                else if (byte_counter == `PACKET_LEN-6) 
                    current <= seq_number[15:8];
                else if (byte_counter == `PACKET_LEN-5) 
                    current <= seq_number[7:0];
                else if (byte_counter == `PACKET_LEN-4) 
                    current <= payload_size;
                else                         /* position for a normal padding byte */
                    current <= 8'b10010010;  /* place tail padding */
            end else begin
                payload_size <= payload_size + 1;
                seq_number <= seq_number + 16'd1;   /* inc seq number */
                /* We are counting the leading 10010010 byte but we are not counting the
                   last payload byte. So seq_number ends up being the number of payload
                   byte transmitted, which is as expected. */
                current <= input_data;  /* feed data from fifo (input_data) */
            end
        end else begin
            fifo_re <= 0;
            bit_state <= bit_state + 1;
            current <= {current[6:0], current[7]};  /* left shift register */
        end
    end else begin
        /* seq_num needs to be continuous across packets, so don't reset here */
        payload_size <= 0;
        bit_state <= 0;
        byte_counter <= 0;
        output_data <= 0;
        fifo_re <= 0;
        current <= 8'b10010010;
        packet_ended <= 0;
    end
end

endmodule

