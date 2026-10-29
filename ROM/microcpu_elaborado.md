# Programa elaborado da miniCPU

Arquivo de memória: [microcpu_elaborado.mif](microcpu_elaborado.mif).

O programa exercita ADD, SUB, MUL, DIV, as quatro variantes com imediato, MOV, MOVI e JMP. Inclui truncamento de resultados, divisão inteira, divisão por zero e um salto que ignora duas instruções. O resultado final é **588A**, na ordem dos displays **R3 R2 R1 R0**.

O registrador de destino aparece primeiro nas instruções abaixo. Os operandos são valores sem sinal de quatro bits. Os endereços e palavras de máquina são hexadecimais; o sufixo h identifica constantes hexadecimais na descrição das instruções.

## Como selecionar

No Quartus, abra ROM/rom.bdf e altere o parâmetro LPM_FILE da memória para **ROM/microcpu_elaborado.mif**. Adicione esse MIF aos arquivos do projeto, se necessário. Faça uma compilação completa e grave o novo SOF na placa.

O programa original e a seleção atual da ROM foram preservados. Adicionar o arquivo ao projeto, isoladamente, não altera o parâmetro LPM_FILE.

## Instruções

| Endereço | Palavra | Instrução | Descrição |
| --- | --- | --- | --- |
| 00 | 9009 | MOVI R0, 9 | Carrega 9 em R0. |
| 01 | 9403 | MOVI R1, 3 | Carrega 3 em R1. |
| 02 | 0840 | ADD R2, R0, R1 | R2 recebe 9 + 3 = 12 (C). |
| 03 | 1C40 | SUB R3, R0, R1 | R3 recebe 9 - 3 = 6. |
| 04 | 2940 | MUL R2, R1, R1 | R2 recebe 3 vezes 3 = 9. |
| 05 | 3C40 | DIV R3, R0, R1 | R3 recebe 9 / 3 = 3. |
| 06 | 4006 | ADDI R0, R0, 6 | R0 recebe 9 + 6 = 15 (F). |
| 07 | 5408 | SUBI R1, R0, 8 | R1 recebe 15 - 8 = 7. |
| 08 | 6903 | MULI R2, R1, 3 | R2 recebe os quatro bits inferiores de 7 vezes 3: 21 mod 16 = 5. |
| 09 | 7C02 | DIVI R3, R0, 2 | R3 recebe o quociente inteiro de 15 / 2 = 7. |
| 0A | 8200 | MOV R0, R2 | Copia o valor 5 de R2 para R0. |
| 0B | 0840 | ADD R2, R0, R1 | R2 recebe 5 + 7 = 12 (C). |
| 0C | 9400 | MOVI R1, 0 | Zera R1 para testar divisão por zero. |
| 0D | 3C40 | DIV R3, R0, R1 | Divisor em registrador igual a zero: o módulo Verilog retorna 0. |
| 0E | 7800 | DIVI R2, R0, 0 | Divisor imediato igual a zero: retorna 0. |
| 0F | 9404 | MOVI R1, 4 | Carrega 4 em R1. |
| 10 | 5905 | SUBI R2, R1, 5 | R2 recebe 4 - 5, representado módulo 16 como F. |
| 11 | 4E01 | ADDI R3, R2, 1 | R3 recebe F + 1, truncado para 0. |
| 12 | A015 | JMP 15h | Salta para 15h, sem executar 13h ou 14h. |
| 13 | 900E | MOVI R0, Eh | Instrução que deve ser ignorada pelo salto. |
| 14 | B000 | RST | Também deve ser ignorada pelo salto. |
| 15 | 900A | MOVI R0, Ah | Carrega 10 (A) em R0. |
| 16 | 2840 | MUL R2, R0, R1 | R2 recebe 10 vezes 4 = 40, truncado para 8. |
| 17 | 3C40 | DIV R3, R0, R1 | R3 recebe o quociente inteiro de 10 / 4 = 2. |
| 18 | 8600 | MOV R1, R2 | Copia 8 para R1. |
| 19 | 4F03 | ADDI R3, R3, 3 | R3 recebe 2 + 3 = 5. |
| 1A | A01A | JMP 1Ah | Mantém a execução no endereço 1Ah e preserva o estado final. |
| 3F | B000 | RST | Rotina opcional de reinicialização; não é alcançada pelo fluxo normal. |

Os endereços de 1Bh a 3Eh contêm F000, cujo opcode reservado não habilita escrita, salto ou reset.

## Sequência esperada

Partindo de R0 = R1 = R2 = R3 = 0 e PC = 00h, a interpretação das palavras de máquina produz a sequência abaixo. Os passos são instruções executadas no modelo arquitetural; a relação com os acionamentos do botão depende da sincronização do circuito.

| Passo | Endereço executado | Instrução | Displays (R3 R2 R1 R0) |
| --- | --- | --- | --- |
| 1 | 00 | MOVI R0, 9 | 0009 |
| 2 | 01 | MOVI R1, 3 | 0039 |
| 3 | 02 | ADD R2, R0, R1 | 0C39 |
| 4 | 03 | SUB R3, R0, R1 | 6C39 |
| 5 | 04 | MUL R2, R1, R1 | 6939 |
| 6 | 05 | DIV R3, R0, R1 | 3939 |
| 7 | 06 | ADDI R0, R0, 6 | 393F |
| 8 | 07 | SUBI R1, R0, 8 | 397F |
| 9 | 08 | MULI R2, R1, 3 | 357F |
| 10 | 09 | DIVI R3, R0, 2 | 757F |
| 11 | 0A | MOV R0, R2 | 7575 |
| 12 | 0B | ADD R2, R0, R1 | 7C75 |
| 13 | 0C | MOVI R1, 0 | 7C05 |
| 14 | 0D | DIV R3, R0, R1 | 0C05 |
| 15 | 0E | DIVI R2, R0, 0 | 0005 |
| 16 | 0F | MOVI R1, 4 | 0045 |
| 17 | 10 | SUBI R2, R1, 5 | 0F45 |
| 18 | 11 | ADDI R3, R2, 1 | 0F45 |
| 19 | 12 | JMP 15h | 0F45 |
| 20 | 15 | MOVI R0, Ah | 0F4A |
| 21 | 16 | MUL R2, R0, R1 | 084A |
| 22 | 17 | DIV R3, R0, R1 | 284A |
| 23 | 18 | MOV R1, R2 | 288A |
| 24 | 19 | ADDI R3, R3, 3 | 588A |
| 25 | 1A | JMP 1Ah | 588A |

Após 25 instruções, R0 = A, R1 = 8, R2 = 8 e R3 = 5. JMP 1Ah mantém esse estado. Como o conjunto atual não possui salto condicional, o laço final é incondicional.

## Reinicialização opcional por instrução

Para executar RST ao final, substitua apenas a palavra do endereço 1Ah, de **A01A** por **A03F**. Assim, o programa salta para 3Fh, executa RST e reinicia no endereço 00h. Na versão fornecida, RST fica fora do caminho executado para permitir observar o resultado final.

## Verificação e limite

As palavras de máquina foram geradas conforme os campos de UC/UC.v e verificadas por um modelo arquitetural que decodifica o conteúdo gerado. Esse modelo confirmou a sequência de 25 instruções, o desvio de 12h para 15h e o estado final 588A.

Essa verificação não é uma simulação do circuito nem um teste na placa. Como counter.bdf e reg4.bdf foram restaurados às versões originais, os testes anteriores da CPU corrigida não comprovam o comportamento temporal da configuração atual. Use a tabela para comparar os estados durante a execução e conferir salto e reset.
