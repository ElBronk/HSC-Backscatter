/*
 * generates 1MHz clk_i for downlink
 */
 
module downlink_clock_divider ( 
    input clk_i, 
    input reset, 
    output logic clk_o );
// input clk_i;    // input clk_i (50MHz)
// input reset;    // reset signal

// output reg clk_o;
 
logic [5:0] divider_counter; //Kinda seems like this is the same clock period as clock control   

always_ff @(posedge clk_i /* or negedge reset */) begin // reception logic
    if (!reset) begin
        clk_o <= 0;
        divider_counter <= 0;
    end else begin
        if (divider_counter == 0) begin
            clk_o <= ~clk_o;
            divider_counter <= divider_counter + 1;
        end else if (divider_counter == 24) begin
            clk_o <= clk_o;
            divider_counter <= 0;
        end else begin
            clk_o <= clk_o;
            divider_counter <= divider_counter + 1;
        end
    end
end

endmodule