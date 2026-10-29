from pathlib import Path
import re
root=Path.cwd()
# Quartus exports the LPM_ROM as a black box. Model its configured registered
# address and use the same MIF contents; all CPU/gate logic stays exported RTL.
s=(root/"ROM/rom.v").read_text()
s=s[:s.index("module lpm_rom_0")]
s+="""
module lpm_rom_0(input inclock, input memenab, input [5:0] address, output [15:0] q);
reg [15:0] mem [0:63];
reg [5:0] addr_q;
initial $readmemh("program.hex", mem);
always @(posedge inclock) addr_q <= address;
assign q = memenab ? mem[addr_q] : 16'hzzzz;
endmodule
"""
(root/"ROM/rom_sim.v").write_text(s)
mif=(root/"ROM/microcpu_teste.mif").read_text()
mem=[0xf000]*64
for addr,data in re.findall(r'^\s*([0-9A-F]+)\s*:\s*([0-9A-F]+)\s*;',mif,re.M):
    mem[int(addr,16)]=int(data,16)
(root/"program.hex").write_text("\n".join(f"{v:04x}" for v in mem)+"\n")
