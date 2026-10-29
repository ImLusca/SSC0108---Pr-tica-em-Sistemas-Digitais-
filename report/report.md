# Projeto miniCPU

**Autores:**
Lucas Pereira Pacheco — 12543930
Philippe Sardenberg Castro Couto - 16897421

## 1. Objetivo

O projeto consiste na construção de uma CPU didática capaz de buscar instruções em uma memória ROM, decodificá-las e realizar operações sobre um banco de registradores. Conforme o enunciado, as palavras de instrução devem ter pelo menos 16 bits, enquanto os registradores e a unidade lógica e aritmética devem possuir pelo menos 4 bits. O conteúdo dos registradores deve ser apresentado em displays após a execução das instruções.

A arquitetura desenvolvida utiliza quatro registradores de 4 bits, uma ULA de 4 bits, um contador de programa de 6 bits e uma ROM de 64 palavras de 16 bits. O conjunto decodificado inclui soma, subtração, multiplicação, divisão, movimentação de dados, salto incondicional e reinicialização. Este relatório descreve a implementação corrigida e os resultados de compilação e simulação. As oito capturas preservadas são da versão inicial; os trechos seguintes identificam as alterações posteriores.

## 2. Arquitetura geral

![Visão geral da miniCPU no Quartus](images/report/1793301561576.png)

*Figura 1 — Integração da ROM, contador, unidade de controle, banco de registradores, ULA e displays.*

O contador de programa fornece o endereço da instrução para a ROM. A palavra lida chega à unidade de controle, que seleciona os registradores de origem e destino, a operação aritmética e a origem do dado que será escrito. O banco disponibiliza duas saídas de leitura, RESA e RESB, e recebe um barramento de escrita de 4 bits.

O multiplexador `cpumux` escolhe entre RESB e o imediato da instrução para formar o segundo operando da ULA. O primeiro operando vem de RESA. O multiplexador `res_mux` seleciona o resultado da ULA, RESA ou o imediato para retornar ao banco. Assim, MOV e MOVI podem escrever dados sem depender de uma operação aritmética.

A saída `DispOUT[15..0]` reúne os quatro registradores: R0 ocupa os bits 3 a 0, R1 os bits 7 a 4, R2 os bits 11 a 8 e R3 os bits 15 a 12. Cada grupo de quatro bits alimenta um decodificador hexadecimal para display de sete segmentos. O arquivo `display.v` representa os valores de 0 a F com segmentos ativos em nível baixo. Seis saídas LD também estão declaradas no nível superior.

## 3. Contador de programa e salto

![Contador de programa de seis bits](images/report/1793301600708.png)

*Figura 2 — Contador construído com seis flip-flops T e lógica de habilitação.*

A Figura 2 mostra a versão inicial, com seis flip-flops T. Na versão corrigida de `COUNTER/counter.bdf`, o contador usa seis flip-flops D e lógica combinacional para incremento, seleção do endereço de salto e reset síncrono. A lógica de incremento equivale ao contador binário: o bit menos significativo alterna a cada pulso e os seguintes dependem dos bits inferiores. O multiplexador de cada bit escolhe entre o incremento e JumpAddr. O reset síncrono, ativo em nível alto, tem prioridade sobre salto e incremento. No avanço sequencial, o contador percorre os endereços de 0 a 63, retornando a zero após o último endereço.

Na versão inicial, cada bit recebia sinais de preset e clear de uma instância de `jmpr`. Esse caminho foi substituído pelo carregamento síncrono do endereço, evitando saltos por entradas assíncronas. O arquivo jmpr foi preservado como parte do desenvolvimento, mas não é instanciado no contador corrigido.

![Lógica de preset e clear do salto](images/report/1793301624611.png)

*Figura 3 — Circuito jmpr para um bit do endereço.*

No circuito original da Figura 3, `Op` é o bit do endereço e `Jmp` habilita o salto. As saídas dirigem as entradas assíncronas, ativas em nível baixo, dos flip-flops. As equações implementadas são:

- `Set = NOT(Op AND Jmp)`;
- `Clear = (Op OR NOT Jmp) AND Clr`.

Com `Clr = 1` e `Jmp = 0`, as duas saídas ficam inativas. Durante um salto, um bit de endereço igual a 1 ativa o preset; um bit igual a 0 ativa o clear. O clear global deve ser aplicado com a polaridade exigida pelo circuito. Como o carregamento usa entradas assíncronas, é necessário verificar a prioridade entre salto e reset, além dos tempos de recuperação e remoção.

## 4. Banco de registradores

![Banco com quatro registradores e duas portas de leitura](images/report/1793301725722.png)

*Figura 4 — Banco de registradores regBank.*

O banco contém quatro instâncias de `reg4`. O campo `RegTo[1..0]` passa por um decodificador que identifica o destino. Cada saída do decodificador é combinada com `WRT_EN`, produzindo a habilitação de carga de apenas um registrador. Quando a escrita está desabilitada, todos preservam seu conteúdo.

Dois multiplexadores independentes selecionam as saídas RESA e RESB a partir de `ReadA` e `ReadB`. Dessa forma, uma instrução pode ler dois registradores e escolher um destino. A concatenação dos quatro conteúdos é exposta em `DispOUT` para visualização.

![Registrador de quatro bits com realimentação](images/report/1793301747158.png)

*Figura 5 — Estrutura interna de reg4.*

Cada registrador usa quatro flip-flops D. Um multiplexador por bit escolhe entre o dado externo e a própria saída do flip-flop. Com `LOAD = 1`, a entrada é carregada na borda de subida do clock; com `LOAD = 0`, a realimentação mantém o valor. A Figura 5 mostra o clear assíncrono da versão inicial. Na versão corrigida, os presets e clears físicos dos flip-flops ficam inativos; uma porta AND por bit aplica o reset ao próximo dado. A entrada CLR do bloco passa a ser síncrona e ativa em nível alto. Esse comportamento também permite executar RST sem criar um laço de reset assíncrono.

## 5. Unidade lógica e aritmética

![ULA com quatro blocos aritméticos e multiplexador de saída](images/report/1793301803161.png)

*Figura 6 — ULA de quatro bits.*

A ULA recebe dois operandos de 4 bits e calcula, em blocos separados, soma, subtração, multiplicação e divisão. O multiplexador `ula_mux` escolhe o resultado encaminhado à saída de 4 bits.

Na versão inicial da Figura 6, havia uma divergência entre a ligação do multiplexador e a unidade de controle. A tabela registra o problema encontrado:


| Select | Operação solicitada por UC.v | Entrada selecionada no esquema da ULA |
| ------ | ------------------------------ | ------------------------------------- |
| 00     | Soma                           | Divisão (`data0x`)                   |
| 01     | Subtração                    | Multiplicação (`data1x`)            |
| 10     | Multiplicação                | Subtração (`data2x`)                |
| 11     | Divisão                       | Soma (`data3x`)                       |

O módulo gerado `ula_mux.v` utiliza a seleção convencional das entradas de um LPM_MUX. Na versão corrigida, as entradas foram reordenadas: data0x = Add, data1x = Sub, data2x = Mul e data3x = Div. Os dois multiplexadores de leitura do banco também foram reordenados para que os índices 0, 1, 2 e 3 correspondam a R0, R1, R2 e R3. Os barramentos RESA e RESB receberam os intervalos explícitos [3..0].

### 5.1. Somador de quatro bits

![Somador de quatro bits em cascata](images/report/1793301836343.png)

*Figura 7 — add4 formado por quatro somadores completos.*

O módulo `add4` encadeia quatro instâncias de `add1`. O carry inicial é zero, e cada estágio transmite seu carry ao próximo. Trata-se de um somador com propagação de carry, cujo atraso depende da passagem desse sinal pelos estágios. Como a saída tem quatro bits, a soma armazenada corresponde aos quatro bits menos significativos; o carry final não compõe o resultado arquitetural.

![Somador completo de um bit](images/report/1793301852770.png)

*Figura 8 — add1 implementado com portas XOR, AND e OR.*

Para os operandos A e B e o carry de entrada Cin, o somador completo implementa:

- `S = A XOR B XOR Cin`;
- `Cout = (A AND B) OR (Cin AND (A XOR B))`.

### 5.2. Demais operações e limites

Os arquivos `ULA/subtractor/sub1.bdf` e `sub4.bdf` implementam a subtração hierarquicamente. Multiplicação e divisão são descritas nos esquemas `ULA/multiplicador/mul2.bdf` e `ULA/divisor/div.bdf`. Apesar das interfaces de quatro bits, os circuitos iniciais usavam apenas A[1..0] e B[1..0]. Ambos foram reconstruídos com portas lógicas para operar sobre os quatro bits. O multiplicador soma os produtos parciais de peso inferior a 16. O divisor usa quatro estágios de divisão restauradora, com resto temporário de cinco bits.

Os dados são tratados como valores sem sinal, entre 0 e 15. A largura do caminho de dados não permite armazenar resultados maiores que quatro bits e não há flags arquiteturais de carry ou overflow na unidade de controle. Foi definido que a divisão por zero retorna 0. A subtração e o produto são armazenados módulo 16. Todas as 256 combinações de operandos de cada uma das quatro operações foram verificadas em simulação, incluindo os 16 divisores nulos.

## 6. Unidade de controle e formato das instruções

O módulo combinacional `UC/UC.v` extrai os campos da palavra de 16 bits da seguinte forma:


| Bits    | Campo     | Finalidade                      |
| ------- | --------- | ------------------------------- |
| 15 a 12 | opcode    | Identifica a instrução        |
| 11 a 10 | RegTo     | Registrador de destino          |
| 9 a 8   | ReadA     | Primeiro registrador de origem  |
| 7 a 6   | ReadB     | Segundo registrador de origem   |
| 3 a 0   | Immediate | Constante de quatro bits        |
| 5 a 0   | JumpAddr  | Endereço de salto de seis bits |

Immediate e JumpAddr reutilizam bits da palavra, pois pertencem a formatos diferentes de instrução. Nas operações aritméticas com imediato, os bits 5 e 4 não são usados pela unidade de controle.

A tabela abaixo documenta a semântica pretendida pelo decodificador. `Rd`, `Ra` e `Rb` representam os registradores selecionados; `imm` representa o imediato.


| Opcode hexadecimal | Instrução | Operação pretendida                 |
| ------------------ | ----------- | ------------------------------------- |
| 0                  | ADD         | Rd ← Ra + Rb                         |
| 1                  | SUB         | Rd ← Ra − Rb                        |
| 2                  | MUL         | Rd ← Ra × Rb                        |
| 3                  | DIV         | Rd ← Ra / Rb                         |
| 4                  | ADDI        | Rd ← Ra + imm                        |
| 5                  | SUBI        | Rd ← Ra − imm                       |
| 6                  | MULI        | Rd ← Ra × imm                       |
| 7                  | DIVI        | Rd ← Ra / imm                        |
| 8                  | MOV         | Rd ← Ra                              |
| 9                  | MOVI        | Rd ← imm                             |
| A                  | JMP         | Solicita salto para JumpAddr          |
| B                  | RST         | Ativa o sinal de reinicialização    |
| C a F              | Reservado   | Não habilita escrita, salto ou reset |

Nas oito instruções aritméticas, `WRT_EN` habilita a escrita. `UseImmediate` diferencia as variantes com constante. Em MOV, `WriteSource = 01` seleciona RESA; em MOVI, `WriteSource = 10` seleciona o imediato. Nas operações aritméticas, `WriteSource = 00` seleciona a ULA. O decodificador atribui valores padrão a todas as saídas do bloco combinacional.

As instruções avançadas JZ, CMP e JE mencionadas no enunciado não estão implementadas em `UC.v`.

## 7. Memória e programa de exemplo

A ROM possui 64 endereços e palavras de 16 bits, totalizando 1.024 bits de conteúdo lógico. Em `ROM/rom.bdf`, o parâmetro `LPM_FILE` referencia `microcpu_teste.mif`, presente na pasta ROM. O endereço está configurado como registrado e a saída como não registrada, usando inclock. O clock da ROM é o inverso do clock externo. Ao pressionar KEY1, a borda de descida captura o endereço na ROM; ao soltar KEY1, a borda de subida grava o resultado e atualiza o contador. Assim, cada ciclo completo do botão executa uma instrução.

O arquivo `ROM/Mif.mif` também existe, mas não é o arquivo referenciado pelo parâmetro atual da ROM.


| Endereço hexadecimal | Palavra hexadecimal | Interpretação pela UC | Resultado pretendido    |
| --------------------- | ------------------- | ----------------------- | ----------------------- |
| 00                    | 9005                | MOVI R0, 5              | R0 = 5                  |
| 01                    | 9403                | MOVI R1, 3              | R1 = 3                  |
| 02                    | 0840                | ADD R2, R0, R1          | R2 = 8                  |
| 03                    | 6D02                | MULI R3, R1, 2          | R3 = 6                  |
| 04                    | A004                | JMP 04                  | Retorno ao endereço 04 |
| 05 a 3F               | F000                | Opcode reservado        | Nenhuma escrita         |

Essa sequência foi executada em simulação e deixou R0 = 5, R1 = 3, R2 = 8 e R3 = 6. Quatro ciclos adicionais confirmaram a manutenção dos conteúdos e do contador no endereço 04. Ainda não foi realizada uma medição na placa.

durante a execução
![1793303115146](images/report/1793303115146.png)

![1793303131426](images/report/1793303131426.png)

## 8. Operação manual


Os pinos definidos no projeto correspondem aos botões da DE0-CV: CLK em W9 (KEY1) e BRST em U7 (KEY0). Os botões são ativos em nível baixo e possuem tratamento de repique por circuito Schmitt Trigger.

Para inicializar, mantenha KEY0 pressionado e faça um ciclo completo de pressionar e soltar KEY1. Solte KEY0. Cada novo ciclo de KEY1 executa uma instrução, com atualização dos displays na soltura. O resultado esperado após as primeiras quatro instruções é R0 = 5, R1 = 3, R2 = 8 e R3 = 6; o salto seguinte mantém esses valores.
