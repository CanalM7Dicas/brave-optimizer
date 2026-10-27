<#
Brave Optimizer: optional, reversible policies for the current Windows user.
#>
param(
    [ValidateSet('Menu', 'Preview', 'Apply', 'Restore')]
    [string]$Action = 'Menu'
)

$ErrorActionPreference = 'Stop'
$policyPath = 'HKCU:\SOFTWARE\Policies\BraveSoftware\Brave'
$machinePolicyPath = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'
$stateDir = Join-Path $env:LOCALAPPDATA 'BraveOptimizer'
$statePath = Join-Path $stateDir 'policy-state.json'

# Only these Brave-specific policies are changed. An existing policy is never overwritten.
$policies = @(
    [pscustomobject]@{ Name = 'BraveRewardsDisabled'; Value = 1; Label = 'Brave Rewards' }
    [pscustomobject]@{ Name = 'BraveWalletDisabled'; Value = 1; Label = 'Brave Wallet' }
    [pscustomobject]@{ Name = 'BraveVPNDisabled'; Value = 1; Label = 'Brave VPN' }
    [pscustomobject]@{ Name = 'BraveAIChatEnabled'; Value = 0; Label = 'Brave Leo' }
    [pscustomobject]@{ Name = 'BraveNewsDisabled'; Value = 1; Label = 'Brave News' }
)

function Get-PolicyValue {
    param([string]$Path, [string]$Name)
    if (-not (Test-Path -LiteralPath $Path)) {
        return [pscustomobject]@{ Exists = $false; Value = $null }
    }
    $key = Get-Item -LiteralPath $Path
    if ($key.GetValueNames() -contains $Name) {
        return [pscustomobject]@{ Exists = $true; Value = $key.GetValue($Name) }
    }
    return [pscustomobject]@{ Exists = $false; Value = $null }
}

function Save-State {
    param([string[]]$Names)
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    $temporaryPath = Join-Path $stateDir 'policy-state.tmp'
    [pscustomobject]@{
        SchemaVersion = 1
        RegistryPath = $policyPath
        CreatedNames = @($Names)
    } | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath $temporaryPath -Encoding UTF8
    Move-Item -LiteralPath $temporaryPath -Destination $statePath -Force
}

function Show-Preview {
    Write-Host 'Brave Optimizer: pre-visualizacao' -ForegroundColor Cyan
    Write-Host 'As alteracoes atingem apenas o usuario atual. O Brave pode precisar reiniciar.'
    foreach ($policy in $policies) {
        $machine = Get-PolicyValue -Path $machinePolicyPath -Name $policy.Name
        $current = Get-PolicyValue -Path $policyPath -Name $policy.Name
        if ($machine.Exists) {
            $status = 'ja definida para o computador; sera preservada'
        } elseif ($current.Exists) {
            $status = "ja definida para este usuario ($($current.Value)); sera preservada"
        } else {
            $status = "sera definida como $($policy.Value)"
        }
        Write-Host ("- {0}: {1}" -f $policy.Label, $status)
    }
    if (Test-Path -LiteralPath $statePath) {
        Write-Host 'Ha um registro de aplicacao anterior. Use Restaurar antes de aplicar novamente.' -ForegroundColor Yellow
    }
    Write-Host 'Politicas aplicadas aparecerao em brave://policy e podem mostrar "gerenciado pela organizacao".'
}

function Apply-Policies {
    if (Test-Path -LiteralPath $statePath) {
        Write-Warning 'Ja existe um registro de aplicacao. Restaure antes de aplicar novamente.'
        return
    }

    $toCreate = @()
    foreach ($policy in $policies) {
        $machine = Get-PolicyValue -Path $machinePolicyPath -Name $policy.Name
        $current = Get-PolicyValue -Path $policyPath -Name $policy.Name
        if (-not $machine.Exists -and -not $current.Exists) {
            $toCreate += $policy
        } else {
            Write-Host ("Preservada: {0} (politica existente)." -f $policy.Label)
        }
    }
    if ($toCreate.Count -eq 0) {
        Write-Host 'Nenhuma alteracao necessaria.'
        return
    }

    # Record the exact names before writing, so an interrupted run remains reversible.
    Save-State -Names @($toCreate | ForEach-Object { $_.Name })
    New-Item -Path $policyPath -Force | Out-Null
    foreach ($policy in $toCreate) {
        # Recheck in case another process added a policy since the preview.
        $current = Get-PolicyValue -Path $policyPath -Name $policy.Name
        if ($current.Exists) {
            Write-Warning ("Ignorada: {0} mudou durante a aplicacao." -f $policy.Label)
            continue
        }
        New-ItemProperty -LiteralPath $policyPath -Name $policy.Name -PropertyType DWord -Value $policy.Value -Force | Out-Null
        Write-Host ("Aplicada: {0}" -f $policy.Label) -ForegroundColor Green
    }
    Write-Host 'Concluido. Reinicie o Brave quando for conveniente e confira brave://policy.'
    Write-Host "Registro para restauracao: $statePath"
}

function Restore-Policies {
    if (-not (Test-Path -LiteralPath $statePath)) {
        Write-Host 'Nao ha alteracoes registradas por esta versao para restaurar.'
        return
    }
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    if ($state.SchemaVersion -ne 1 -or $state.RegistryPath -ne $policyPath) {
        throw 'Registro de restauracao invalido. Nenhuma politica foi alterada.'
    }
    $names = @($state.CreatedNames)
    foreach ($name in $names) {
        $policy = $policies | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        if (-not $policy) {
            throw "Nome inesperado no registro de restauracao: $name"
        }
    }
    $remaining = @()
    foreach ($name in $names) {
        $policy = $policies | Where-Object { $_.Name -eq $name } | Select-Object -First 1
        $current = Get-PolicyValue -Path $policyPath -Name $name
        if (-not $current.Exists) {
            continue
        }
        $numericValue = 0
        if (-not [int]::TryParse([string]$current.Value, [ref]$numericValue) -or $numericValue -ne [int]$policy.Value) {
            Write-Warning ("Preservada: {0} foi modificada depois da aplicacao." -f $policy.Label)
            $remaining += $name
            continue
        }
        Remove-ItemProperty -LiteralPath $policyPath -Name $name
        Write-Host ("Restaurada: {0}" -f $policy.Label) -ForegroundColor Green
    }
    if ($remaining.Count -eq 0) {
        Remove-Item -LiteralPath $statePath -Force
        Write-Host 'Restauracao concluida. Reinicie o Brave quando for conveniente.'
    } else {
        Save-State -Names $remaining
        Write-Warning 'Algumas politicas foram preservadas por terem sido alteradas depois.'
    }
}

try {
    if ($Action -eq 'Menu') {
        Write-Host 'Brave Optimizer' -ForegroundColor Cyan
        Write-Host '1. Ver alteracoes planejadas'
        Write-Host '2. Aplicar politicas opcionais'
        Write-Host '3. Restaurar alteracoes desta ferramenta'
        Write-Host '4. Sair'
        $choice = Read-Host 'Escolha uma opcao'
        $Action = switch ($choice) {
            '1' { 'Preview' }
            '2' { 'Apply' }
            '3' { 'Restore' }
            default { 'Exit' }
        }
    }
    switch ($Action) {
        'Preview' { Show-Preview }
        'Apply' { Apply-Policies }
        'Restore' { Restore-Policies }
    }
} catch {
    Write-Error "Falha: $($_.Exception.Message)"
    exit 1
}
