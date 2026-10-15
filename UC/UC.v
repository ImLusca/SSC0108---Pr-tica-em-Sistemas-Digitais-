
module controlUnit (
    input wire [15:0] Instr,

    // Banco de registradores
    output wire [1:0] RegTo,
    output wire [1:0] ReadA,
    output wire [1:0] ReadB,
    output reg WRT_EN,

    // ULA
    output reg [1:0] AluSelect,

    // Multiplexadores externos
    output reg UseImmediate,
    output reg [1:0] WriteSource,

    // Valor imediato
    output wire [3:0] Immediate,

    // Contador de programa
    output reg JMP,
    output wire [5:0] JumpAddr,
    output reg RST
);

    wire [3:0] opcode;

    assign opcode   = Instr[15:12];
    assign RegTo    = Instr[11:10];
    assign ReadA    = Instr[9:8];
    assign ReadB    = Instr[7:6];
    assign Immediate = Instr[3:0];
    assign JumpAddr = Instr[5:0];

    // Fonte de escrita:
    // 00 = ULA
    // 01 = saída RESA
    // 10 = imediato
    // 11 = reservado

    always @(*) begin
        // Valores padrão
        WRT_EN       = 1'b0;
        AluSelect    = 2'b00;
        UseImmediate = 1'b0;
        WriteSource  = 2'b00;
        JMP          = 1'b0;
        RST          = 1'b0;

        case (opcode)

            // ADD: Rd = Ra + Rb
            4'h0: begin
                WRT_EN    = 1'b1;
                AluSelect = 2'b00;
            end

            // SUB: Rd = Ra - Rb
            4'h1: begin
                WRT_EN    = 1'b1;
                AluSelect = 2'b01;
            end

            // MUL: Rd = Ra * Rb
            4'h2: begin
                WRT_EN    = 1'b1;
                AluSelect = 2'b10;
            end

            // DIV: Rd = Ra / Rb
            4'h3: begin
                WRT_EN    = 1'b1;
                AluSelect = 2'b11;
            end

            // ADDI: Rd = Ra + Immediate
            4'h4: begin
                WRT_EN       = 1'b1;
                AluSelect    = 2'b00;
                UseImmediate = 1'b1;
            end

            // SUBI: Rd = Ra - Immediate
            4'h5: begin
                WRT_EN       = 1'b1;
                AluSelect    = 2'b01;
                UseImmediate = 1'b1;
            end

            // MULI: Rd = Ra * Immediate
            4'h6: begin
                WRT_EN       = 1'b1;
                AluSelect    = 2'b10;
                UseImmediate = 1'b1;
            end

            // DIVI: Rd = Ra / Immediate
            4'h7: begin
                WRT_EN       = 1'b1;
                AluSelect    = 2'b11;
                UseImmediate = 1'b1;
            end

            // MOV: Rd = Ra
            4'h8: begin
                WRT_EN      = 1'b1;
                WriteSource = 2'b01;
            end

            // MOVI: Rd = Immediate
            4'h9: begin
                WRT_EN      = 1'b1;
                WriteSource = 2'b10;
            end

            // JMP: PC = JumpAddr
            4'hA: begin
                JMP = 1'b1;
            end

            // RST
            4'hB: begin
                RST = 1'b1;
            end

            default: begin
                // Nenhuma operação
            end

        endcase
    end

endmodule
