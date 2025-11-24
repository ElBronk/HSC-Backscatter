/* generate signal to be sent to RF switch */

module switch_encoder( 
  input clock, 
  input trigger, 
  input data, 
  output signal_to_switch
  );
// input clock, trigger, data;
// output signal_to_switch;

/* assign signal_to_switch = (trigger & ((data & clock) | ((~data) & (~clock)))) | ((~trigger) & clock); */
assign signal_to_switch = (trigger & data) ^ trigger ^ clock;
/*
  1. if we have no data to encode, output the clock signal (trigger is zero)
  2. if we do have data to encode, flip the clock signal for 0's, normal clock signal for 1's
  possibly look at QPSK, see how feasible that for us
*/
endmodule

