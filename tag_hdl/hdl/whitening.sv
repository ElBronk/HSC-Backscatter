module whitening( 
    input clk_i, 
    input reset_i, 
    input data_i, 
    input trigger_i, 
    output logic data_o );

logic [6:0] state;
//We can probably change this to a more normal LSFR, i.e. seed the state at reset_i and not rely on input data
always_ff @(posedge clk_i /*or negedge reset_i*/) begin//another async reset_i??
    if (!reset_i) begin
        state <= 7'b0000000;
    end
    else if (trigger_i) begin //shift up one bit and randomize, output one bit at a time
        state[6:1] <= state[5:0]; 
        //state[0]   <= data_i;
        state[0] <= data_i ^ state[3] ^ state[6]; //taps on data_i, 3rd bit and 6th
        data_o <= data_i ^ state[3] ^ state[6];
    end
    else begin
        state <= 7'b0000000;
    end
end

endmodule

