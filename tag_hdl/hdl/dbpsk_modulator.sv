module dbpsk_modulator( 
    input clk_i, 
    input reset_i, 
    input data_i, 
    input trigger_i, 
    output logic data_o);
// input clk_i, reset_i;
// input trigger_i;
// input data_i;
// output reg data_o;

always @(posedge clk_i /*or negedge reset_i*/) begin
    if (!reset_i) begin
        data_o <= 0; //output to 0
    end else if (trigger_i) begin //when we get switch signal from clock control
        if (data_i == 0)
            data_o <= data_o; //hold signal constant
        else
            data_o <= ~data_o; //invert it
    end else begin
        data_o <= 0; //no trigger_i, output nothing
    end
end
endmodule
