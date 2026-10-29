// Unsigned integer division; division by zero is defined to return zero.
module div (
    input  wire [3:0] A,
    input  wire [3:0] B,
    output wire [3:0] D
);
    assign D = (B == 4'd0) ? 4'd0 : (A / B);
endmodule
