param(
    [string]$QuartusBin = 'C:/intelFPGA_lite/24.1std/quartus/bin64',
    [string]$ModelSimBin = 'C:/intelFPGA/19.1/modelsim_ase/win32aloem',
    [string]$SourceRoot = (Split-Path -Parent $PSScriptRoot)
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$simulationRoot = Join-Path $projectRoot ('validation/sim-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $simulationRoot | Out-Null
$sourceExtensions = @('.bdf', '.bsf', '.v', '.qsf', '.qpf', '.qip', '.mif', '.sdc')
Get-ChildItem -LiteralPath $SourceRoot -Recurse -File | ForEach-Object {
    $relativePath = $_.FullName.Substring($SourceRoot.Length + 1)
    if ($relativePath -match '^(validation|tests|db|incremental_db|output_files|simulation|\.git)\\' -or $relativePath -match '(^|\\)greybox_tmp\\') { return }
    if ($_.Extension -in $sourceExtensions) {
        $targetPath = Join-Path $simulationRoot $relativePath
        New-Item -ItemType Directory -Path (Split-Path -Parent $targetPath) -Force | Out-Null
        Copy-Item -LiteralPath $_.FullName -Destination $targetPath
    }
}
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'tb_cpu.sv') -Destination $simulationRoot
Push-Location $simulationRoot
try {
    $bdfSources = @('miniCPU.bdf','ULA/ULA.bdf','ULA/adder/add1.bdf','ULA/adder/add4.bdf','ULA/subtractor/sub1.bdf','ULA/subtractor/sub4.bdf','COUNTER/counter.bdf','REGISTER/reg4.bdf','REGISTER/regBank.bdf','ROM/rom.bdf')
    foreach ($bdfSource in $bdfSources) {
        & (Join-Path $QuartusBin 'quartus_map.exe') miniCPU "--convert_bdf_to_verilog=$bdfSource" | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "BDF conversion failed: $bdfSource" }
    }
    & py (Join-Path $PSScriptRoot 'prepare_simulation.py')
    if ($LASTEXITCODE -ne 0) { throw 'ROM model preparation failed' }
    & (Join-Path $ModelSimBin 'vlib.exe') work
    if ($LASTEXITCODE -ne 0) { throw 'Simulation library creation failed' }
    $simLibrary = Join-Path $QuartusBin '../eda/sim_lib/220model.v'
    $rtlSources = @('miniCPU.v','ULA/ULA.v','ULA/adder/add1.v','ULA/adder/add4.v','ULA/subtractor/sub1.v','ULA/subtractor/sub4.v','ULA/multiplicador/mul2.v','ULA/divisor/div.v','ULA/ula_mux.v','COUNTER/counter.v','REGISTER/reg4.v','REGISTER/regBank.v','REGISTER/bankmux.v','REGISTER/decoder.v','cpumux.v','res_mux.v','UC/UC.v','display.v','ROM/rom_sim.v','tb_cpu.sv')
    & (Join-Path $ModelSimBin 'vlog.exe') -sv $simLibrary @rtlSources
    if ($LASTEXITCODE -ne 0) { throw 'RTL compilation failed' }
    & (Join-Path $ModelSimBin 'vsim.exe') -c -onfinish exit work.tb_cpu -do 'run -all; quit -code 0'
    if ($LASTEXITCODE -ne 0) { throw 'Simulation failed' }
    $transcriptText = Get-Content -LiteralPath 'transcript' -Raw
    if ($transcriptText -notmatch 'PASS: 1114 checks') { throw 'Simulation did not reach its success marker' }
    Write-Output "Verified simulation artifacts: $simulationRoot"
} finally {
    Pop-Location
}
