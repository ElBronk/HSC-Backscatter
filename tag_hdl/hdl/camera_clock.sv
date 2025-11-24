/*
 * clk_i divider for camera
 */
 
module camera_clock( 
    input clk_i, 
    input reset_i, 
    output logic clk_o
    );
// input clk_i;    // input clk_i (100MHz, will be 50MHz in new low-power design
// input reset_i;    // reset_i signal

// output reg clk_o;   // 1MHz clk_i to TX components, will sync with trigger rising edge

logic [5:0] counter;  

always_ff @(posedge clk_i /*or negedge reset_i*/) begin
    if (!reset_i) begin
        counter <= 0;
        clk_o <= 0;
    end else begin
        if (counter == 0) begin
            clk_o <= ~clk_o;    // flip the clk_i output
            counter <= counter + 1;     // increase clk_i cycle no.
        end if (counter == 5)               // flip the clk_i every 6 cycles. resulting in 4.16MHz
            counter <= 0;
        else
            counter <= counter + 1;
    end
end

endmodule
