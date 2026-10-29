# Uso da miniCPU na DE0-CV

A configuração de pinos existente corresponde à DE0-CV:
- **KEY1 (W9): clock manual.** Pressionar busca a instrução; soltar executa.
- **KEY0 (U7): reset ativo em nível baixo, síncrono.**
- HEX0 mostra R0, HEX1 mostra R1, HEX2 mostra R2 e HEX3 mostra R3.

## Inicialização

1. Compile miniCPU.qpf ou use o SOF validado em validation/sim-20261029-165912/output_files/miniCPU.sof.
2. Grave pelo Programmer do Quartus.
3. Segure KEY0 e pressione e solte KEY1 uma vez.
4. Solte KEY0.
5. Pressione e solte KEY1 para executar cada instrução.

O reset precisa permanecer pressionado na borda de soltura do clock. Não basta pressionar apenas KEY0 enquanto o clock fica parado.

| Ciclos após o reset | R0 | R1 | R2 | R3 |
| --- | --- | --- | --- | --- |
| 0 | 0 | 0 | 0 | 0 |
| 1 | 5 | 0 | 0 | 0 |
| 2 | 5 | 3 | 0 | 0 |
| 3 | 5 | 3 | 8 | 0 |
| 4 e seguintes | 5 | 3 | 8 | 6 |

O quinto ciclo executa JMP 04; os seguintes repetem esse endereço.

Os displays são hexadecimais. Multiplicação, soma e subtração retêm os quatro bits inferiores. Divisão por zero retorna 0. A instrução RST limpa os quatro registradores e volta ao endereço 0 na borda de execução.

## Compilação e testes

No PowerShell, na raiz do projeto:

    & 'C:/intelFPGA_lite/24.1std/quartus/bin64/quartus_sh.exe' --flow compile miniCPU
    ./tests/run.ps1

O roteiro de testes usa Quartus 24.1 e ModelSim Intel FPGA 19.1 disponíveis nesta máquina; aceite caminhos diferentes pelos parâmetros -QuartusBin e -ModelSimBin. Os testes copiam os fontes para validation/sim-<data-hora>, convertem os BDF e exigem a mensagem PASS: 1114 checks. A ROM recebe um modelo funcional configurado como o BDF; os demais circuitos vêm do Verilog exportado pelo Quartus.

A compilação validada não inclui uma execução física na placa. As imagens existentes no relatório são da revisão inicial.

## Referência da placa

[Manual da Terasic DE0-CV, páginas 21 a 26](https://pages.hmc.edu/harris/class/e85/old/fall24/de0_manual.pdf): polaridade, tratamento de repique, pinagem dos botões e displays. A identificação da placa foi inferida pela correspondência dos pinos e do FPGA no projeto.

Os botões da placa já possuem tratamento de repique; não foi acrescentado um circuito de debounce no FPGA. A restrição de 1 MHz em miniCPU.sdc verifica pulsos estáveis e não define a frequência humana de acionamento.
