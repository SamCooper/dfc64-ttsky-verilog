 `ifndef INT_CTRL
   `define INT_CTRL 1
module dfc64_interrupt_controller (
    input  clk,
    input  rst_n,
    
    // External Physical Pin
    input  irq_n,          // The asynchronous interrupt request (active-low)
    
    // Microcode Interface
    input  clear_irq,      // Control wire from Microcode to acknowledge/clear the latch
    output reg irq_pending // Sent to the Micro-Sequencer to trigger the ISR jump
);

    // 1. The Synchronizer Chain
    // Two flip-flops to stabilize the asynchronous signal
    reg sync1;
    reg sync2;

    // 2. The Edge Detector History
    // Remembers what the synchronized signal was on the *previous* clock cycle
    reg prev_irq;

    always @(posedge clk) begin
        if (!rst_n) begin
            // Default active-low signals to 1 (Not Pressed)
            sync1       <= 1'b1; 
            sync2       <= 1'b1;
            prev_irq    <= 1'b1;
            irq_pending <= 1'b0;
        end else begin
            
            // --- STAGE 1: Synchronization ---
            // Shift the raw pin value into the synchronized clock domain
            sync1 <= irq_n;
            sync2 <= sync1;
            
            // --- STAGE 2: History ---
            prev_irq <= sync2;

            // --- STAGE 3: Detect & Latch ---
            // A negative edge means the signal WAS high, and is NOW low.
            if (prev_irq == 1'b1 && sync2 == 1'b0) begin
                irq_pending <= 1'b1; // Latch the interrupt!
            end 
            // Only clear it if the microcode explicitly tells us to.
            // (The else-if prioritizes new incoming interrupts over clear commands)
            else if (clear_irq == 1'b1) begin
                irq_pending <= 1'b0;
            end
            
        end
    end

endmodule
`endif
