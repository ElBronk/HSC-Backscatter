/*
 * Provides switch_o signal and low frequency clk_i to other components in TX logic
 */
 
`define TX_DELAY 440 // delay between envelope detector to first control signal, unit is NOT microsecond

module clk_i_control( 
    input clk_i, 
    input reset_i, 
    input trigger_i,
    output logic clk_o, //1/50th of input clk
    output switch_o //on after TX Delay
    );
// input clk_i;    // input clk_i (50MHz)
// input reset_i;    // reset_i signal
// input trigger_i;  // trigger_i signal from envelope detector

// output logic clk_o;   // 1MHz clk_i to TX components, will sync with trigger_i rising edge
// output logic switch_o;      // control signal to be fed into TX components

logic [5:0] counter;       // clk_i divider
logic [11:0] delay_counter; // count delay between trigger_i rising and switch_o rising

always_ff @(posedge clk_i /*or negedge reset_i*/) begin
    if (!reset_i) begin
        counter <= 0;
        clk_o <= 0;
        switch_o <= 0;
        delay_counter <= 0;
    end else if (trigger_i) begin
    // trigger_i high, wifi packet in the air
        if (counter == 0) begin
        // beginning cycle 0, time to flip the clk_i output
        // TODO: potential problem here. clk_i rises up to one cycle later than trigger_i
        // because clk_i only toggles at rising edge of input clk_i
            delay_counter <= delay_counter + 1; // increase delay counter
            clk_o <= ~clk_o;    // flip the clk_i output
            counter <= counter + 1;     // increase clk_i cycle no.
            if (delay_counter > (`TX_DELAY * 2 - 1))    
                // we do DELAYx2-1 because this counter is increased every rising AND falling edge of clk_i
                switch_o <= 1;            // if we've delayed `TX_DELAY bytes 
            else
                switch_o <= 0;
        end
        if (counter == 24)
        // now beginning cycle 24, next cycle will be 0. So we are toggling the clk_i every 25 cycles
            counter <= 0;
        else
        // just increase clk_i divider counter
            counter <= counter + 1;
    end else begin
    // trigger_i low, no wifi packet
        counter <= 0;
        clk_o <= 0; // it means that we get at most a falling edge after trigger_i falls
        switch_o <= 0;
        delay_counter <= 0;
    end
end

endmodule
