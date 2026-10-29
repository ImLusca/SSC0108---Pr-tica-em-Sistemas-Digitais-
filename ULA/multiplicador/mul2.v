// Unsigned four-bit multiplication; retain the low four product bits.
module mul2 (
    input  wire [3:0] A,
    input  wire [3:0] B,
    output wire [3:0] D
);
    wire [7:0] product;
    assign product = A * B;
    assign D = product[3:0];
endmodule
