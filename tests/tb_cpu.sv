
`timescale 1ns/1ps
module tb_cpu;
reg [3:0] a,b;
reg [1:0] sel;
wire [3:0] result;
ULA alu(.A(a),.B(b),.Selet(sel),.Res(result));
reg clk=1, reset_n=0;
miniCPU dut(.CLK(clk),.BRST(reset_n));
integer ai,bi,op,expected,checks=0,i;
task pulse;
begin #500 clk=0; #500 clk=1; #20; end
endtask
task check;
input [15:0] regs;
input [5:0] pc;
begin
 if(dut.DispOut !== regs || dut.b2v_inst3.S !== pc)
   $fatal(1,"CPU expected regs=%h pc=%d; got regs=%h pc=%d",regs,pc,dut.DispOut,dut.b2v_inst3.S);
 checks=checks+1;
end
endtask
task write_instr;
input integer addr,opcode,rd,ra,rb,imm;
begin dut.b2v_inst2.b2v_rom.mem[addr]=(opcode<<12)|(rd<<10)|(ra<<8)|(rb<<6)|imm; end
endtask
initial begin
 for(op=0;op<4;op=op+1)
  for(ai=0;ai<16;ai=ai+1)
   for(bi=0;bi<16;bi=bi+1) begin
    a=ai; b=bi; sel=op; #10;
    case(op)
     0: expected=(ai+bi)&15;
     1: expected=(ai-bi)&15;
     2: expected=(ai*bi)&15;
     3: expected=bi==0 ? 0 : ai/bi;
    endcase
    if(result !== expected[3:0]) $fatal(1,"ALU op=%0d a=%0d b=%0d got=%h expected=%h",op,ai,bi,result,expected[3:0]);
    checks=checks+1;
   end
 $display("PASS: all 1024 ALU combinations, including all zero divisors");
 // Reset requires KEY1 held across a release/execution edge.
 pulse; check(16'h0000,0); reset_n=1;
 pulse; check(16'h0005,1);
 pulse; check(16'h0035,2);
 pulse; check(16'h0835,3);
 pulse; check(16'h6835,4);
 repeat(4) begin pulse; check(16'h6835,4); end
 // Replace ROM contents for instruction integration tests.
 reset_n=0; pulse; check(0,0);
 for(i=0;i<64;i=i+1) dut.b2v_inst2.b2v_rom.mem[i]=16'hf000;
 write_instr(0,9,0,0,0,15); // R0=15
 write_instr(1,9,1,0,0,4); // R1=4
 write_instr(2,0,2,0,1,0); // R2=15+4=3
 write_instr(3,1,3,1,0,0); // R3=4-15=5 mod16
 write_instr(4,2,2,0,1,0); // R2=15*4=12
 write_instr(5,3,3,0,1,0); // R3=15/4=3
 write_instr(6,4,0,1,0,7); // R0=4+7=11
 write_instr(7,5,1,0,0,12); // R1=11-12=15
 write_instr(8,6,2,1,0,15); // R2=15*15=1
 write_instr(9,7,3,0,0,2); // R3=11/2=5
 write_instr(10,8,0,2,0,0); // R0=R2=1
 write_instr(11,9,1,0,0,0); // R1=0
 write_instr(12,3,3,0,1,0); // R3=1/0=0
 write_instr(13,10,0,0,0,15); // JMP 15
 write_instr(14,9,0,0,0,9); // must be skipped
 write_instr(15,11,0,0,0,0); // RST
 reset_n=1;
 pulse; check(16'h000f,1);
 pulse; check(16'h004f,2);
 pulse; check(16'h034f,3);
 pulse; check(16'h534f,4);
 pulse; check(16'h5c4f,5);
 pulse; check(16'h3c4f,6);
 pulse; check(16'h3c4b,7);
 pulse; check(16'h3cfb,8);
 pulse; check(16'h31fb,9);
 pulse; check(16'h51fb,10);
 pulse; check(16'h51f1,11);
 pulse; check(16'h5101,12);
 pulse; check(16'h0101,13);
 pulse; check(16'h0101,15);
 pulse; check(16'h0000,0);
 pulse; check(16'h000f,1);
 // Reserved opcodes do not write, and PC wraps from 63 to 0.
 reset_n=0; pulse; reset_n=1;
 for(i=0;i<64;i=i+1) dut.b2v_inst2.b2v_rom.mem[i]=16'hf000;
 for(i=1;i<=64;i=i+1) begin pulse; check(0,i%64); end
 $display("PASS: %0d checks; example ROM, all 12 instructions, JMP skip, RST restart, reserved opcode, PC wrap",checks);
 $finish;
end
initial begin #1000000; $fatal(1,"Timeout"); end
endmodule
