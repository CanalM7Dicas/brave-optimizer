<#
Brave Optimizer: optional, reversible policies for the current Windows user.
#>
param(
    [ValidateSet('Menu', 'Preview', 'Apply', 'Registry', 'Cache', 'All', 'Restore')]
    [string]$Action = 'Menu'
)

$ErrorActionPreference = 'Stop'
$policyPath = 'HKCU:\SOFTWARE\Policies\BraveSoftware\Brave'
$machinePolicyPath = 'HKLM:\SOFTWARE\Policies\BraveSoftware\Brave'
$stateDir = Join-Path $env:LOCALAPPDATA 'BraveOptimizer'
$statePath = Join-Path $stateDir 'policy-state.json'
$preferencesStatePath = Join-Path $stateDir 'preferences-state.json'
$userDataPath = Join-Path $env:LOCALAPPDATA 'BraveSoftware\Brave-Browser\User Data'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# Apenas preferencias com nomes confirmados no codigo do Brave/Chromium.
# Cada item e alterado somente quando o valor atual difere do desejado.
$internalSettings = @(
    [pscustomobject]@{ Path = 'brave.new_tab_page.show_clock'; Value = $false; Label = 'Relogio da nova aba' }
    [pscustomobject]@{ Path = 'brave.new_tab_page.show_stats'; Value = $false; Label = 'Estatisticas da nova aba' }
    [pscustomobject]@{ Path = 'brave.new_tab_page.show_rewards'; Value = $false; Label = 'Rewards da nova aba' }
    [pscustomobject]@{ Path = 'brave.new_tab_page.show_brave_news'; Value = $false; Label = 'Brave News na nova aba' }
    [pscustomobject]@{ Path = 'brave.new_tab_page.show_background_image'; Value = $false; Label = 'Imagem de fundo da nova aba' }
    [pscustomobject]@{ Path = 'brave.new_tab_page.hide_all_widgets'; Value = $true; Label = 'Widgets da nova aba' }
    [pscustomobject]@{ Path = 'brave.location_bar_is_wide'; Value = $false; Label = 'Barra de endereco larga' }
    [pscustomobject]@{ Path = 'brave.tabs.compact_horizontal_tabs'; Value = $false; Label = 'Modo compacto de guias' }
    [pscustomobject]@{ Path = 'brave.autocomplete_enabled'; Value = $true; Label = 'Sugestoes na barra de endereco' }
    [pscustomobject]@{ Path = 'brave.top_site_suggestions_enabled'; Value = $false; Label = 'Sugestoes locais na barra de endereco' }
    [pscustomobject]@{ Path = 'brave.omnibox.history_suggestions_enabled'; Value = $true; Label = 'Historico na barra de endereco' }
    [pscustomobject]@{ Path = 'brave.omnibox.bookmark_suggestions_enabled'; Value = $true; Label = 'Favoritos na barra de endereco' }
    [pscustomobject]@{ Path = 'brave.omnibox.commander_suggestions_enabled'; Value = $false; Label = 'Comandos rapidos na barra de endereco' }
    [pscustomobject]@{ Path = 'brave.ai_chat.show_toolbar_button'; Value = $false; Label = 'Botao do Leo' }
    [pscustomobject]@{ Path = 'brave.ai_chat.autocomplete_provider_enabled'; Value = $false; Label = 'Sugestoes do Leo' }
    [pscustomobject]@{ Path = 'brave.ai_chat.context_menu_enabled'; Value = $false; Label = 'Leo no menu de contexto' }
    [pscustomobject]@{ Path = 'brave.rewards.show_brave_rewards_button_in_location_bar'; Value = $false; Label = 'Botao do Rewards' }
    [pscustomobject]@{ Path = 'brave.wallet.show_wallet_icon_on_toolbar'; Value = $false; Label = 'Botao da Wallet' }
    [pscustomobject]@{ Path = 'brave.brave_vpn.show_button'; Value = $false; Label = 'Botao da VPN' }
    [pscustomobject]@{ Path = 'brave.containers.enabled'; Value = $false; Label = 'Containers' }
    [pscustomobject]@{ Path = 'brave.speedreader.feature_enabled'; Value = $false; Label = 'Speedreader' }
    [pscustomobject]@{ Path = 'brave.shields.stats_badge_visible'; Value = $false; Label = 'Contador no icone dos Escudos' }
    [pscustomobject]@{ Path = 'brave.stats.reporting_enabled'; Value = $false; Label = 'Envio de estatisticas anonimas' }
    [pscustomobject]@{ Path = 'brave.web_discovery_enabled'; Value = $false; Label = 'Web Discovery' }
    [pscustomobject]@{ Path = 'brave.enable_window_closing_confirm'; Value = $false; Label = 'Aviso antes de fechar janela' }
    [pscustomobject]@{ Path = 'brave.enable_closing_last_tab'; Value = $false; Label = 'Fechar janela ao fechar ultima guia' }
    [pscustomobject]@{ Path = 'background_mode.enabled'; Value = $false; Label = 'Brave em segundo plano apos fechar' }
    [pscustomobject]@{ Path = 'download.prompt_for_download'; Value = $false; Label = 'Perguntar onde salvar cada download' }
)

# Politicas opcionais. Nenhuma politica preexistente e sobrescrita.
$policies = @(
    [pscustomobject]@{ Name = 'BraveRewardsDisabled'; Value = 1; Label = 'Brave Rewards' }
    [pscustomobject]@{ Name = 'BraveWalletDisabled'; Value = 1; Label = 'Brave Wallet' }
    [pscustomobject]@{ Name = 'BraveVPNDisabled'; Value = 1; Label = 'Brave VPN' }
    [pscustomobject]@{ Name = 'BraveAIChatEnabled'; Value = 0; Label = 'Brave Leo' }
    [pscustomobject]@{ Name = 'BraveNewsDisabled'; Value = 1; Label = 'Brave News' }
    [pscustomobject]@{ Name = 'BraveStatsPingEnabled'; Value = 0; Label = 'Ping anonimo do Brave' }
    [pscustomobject]@{ Name = 'BraveP3AEnabled'; Value = 0; Label = 'Metricas P3A' }
    [pscustomobject]@{ Name = 'BraveWebDiscoveryEnabled'; Value = 0; Label = 'Web Discovery' }
    [pscustomobject]@{ Name = 'BackgroundModeEnabled'; Value = 0; Label = 'Apps em segundo plano' }
    [pscustomobject]@{ Name = 'HardwareAccelerationModeEnabled'; Value = 1; Label = 'Aceleracao grafica' }
    [pscustomobject]@{ Name = 'HighEfficiencyModeEnabled'; Value = 1; Label = 'Economizador de memoria' }
    [pscustomobject]@{ Name = 'MemorySaverModeSavings'; Value = 2; Label = 'Economizador de memoria no maximo' }
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

function Get-ProfileFiles {
    if (-not (Test-Path -LiteralPath $userDataPath)) { return @() }
    @(
        Get-ChildItem -LiteralPath $userDataPath -Directory |
            Where-Object { ($_.Name -eq 'Default' -or $_.Name -match '^Profile [0-9]+$') -and -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) } |
            ForEach-Object {
                $file = Join-Path $_.FullName 'Preferences'
                if (Test-Path -LiteralPath $file) { $file }
            }
    )
}

function Get-PrefValue {
    param([psobject]$Root, [string]$Path)
    $node = $Root
    foreach ($part in $Path.Split('.')) {
        if ($null -eq $node -or $node -isnot [pscustomobject]) {
            return [pscustomobject]@{ Exists = $false; Value = $null }
        }
        $property = $node.PSObject.Properties[$part]
        if ($null -eq $property) {
            return [pscustomobject]@{ Exists = $false; Value = $null }
        }
        $node = $property.Value
    }
    [pscustomobject]@{ Exists = $true; Value = $node }
}

function Set-PrefValue {
    param([psobject]$Root, [string]$Path, $Value)
    $node = $Root
    $parts = $Path.Split('.')
    for ($i = 0; $i -lt $parts.Length - 1; $i++) {
        $property = $node.PSObject.Properties[$parts[$i]]
        if ($null -eq $property) {
            $child = New-Object psobject
            Add-Member -InputObject $node -MemberType NoteProperty -Name $parts[$i] -Value $child
            $node = $child
        } else {
            if ($property.Value -isnot [pscustomobject]) { throw "Estrutura inesperada: $Path" }
            $node = $property.Value
        }
    }
    $leaf = $parts[$parts.Length - 1]
    if ($null -eq $node.PSObject.Properties[$leaf]) {
        Add-Member -InputObject $node -MemberType NoteProperty -Name $leaf -Value $Value
    } else {
        $node.$leaf = $Value
    }
}

function Remove-PrefValue {
    param([psobject]$Root, [string]$Path)
    $parts = $Path.Split('.')
    $node = $Root
    for ($i = 0; $i -lt $parts.Length - 1; $i++) {
        $property = $node.PSObject.Properties[$parts[$i]]
        if ($null -eq $property) { return }
        $node = $property.Value
    }
    $node.PSObject.Properties.Remove($parts[$parts.Length - 1])
}

function Read-Preferences {
    param([string]$Path)
    $prefs = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($prefs -isnot [pscustomobject]) { throw "JSON invalido: $Path" }
    $prefs
}

function Write-Preferences {
    param([string]$Path, [psobject]$Preferences, [string]$BackupPath)
    $temporaryPath = "$Path.braveoptimizer.tmp"
    $json = ConvertTo-Json -InputObject $Preferences -Depth 100 -Compress
    [System.IO.File]::WriteAllText($temporaryPath, $json, $utf8NoBom)
    $null = Read-Preferences -Path $temporaryPath
    $temporaryBackup = "$Path.braveoptimizer.before-write.bak"
    [System.IO.File]::Replace($temporaryPath, $Path, $temporaryBackup, $true)
    Remove-Item -LiteralPath $temporaryBackup -Force
}

function Assert-BraveClosed {
    if (Get-Process -Name brave -ErrorAction SilentlyContinue) {
        throw 'Feche o Brave antes de aplicar ou restaurar. As abas nao serao encerradas pela ferramenta.'
    }
}

function Clear-BraveCaches {
    Assert-BraveClosed
    $cacheNames = @('Cache', 'Code Cache', 'GPUCache', 'ShaderCache', 'GrShaderCache', 'Service Worker\ScriptCache')
    $cleared = 0
    foreach ($file in @(Get-ProfileFiles)) {
        $profileDir = Split-Path $file -Parent
        $profileName = Split-Path $profileDir -Leaf
        if ((Split-Path $profileDir -Parent) -ne $userDataPath -or $profileName -notmatch '^(Default|Profile [0-9]+)$') {
            throw 'Caminho de perfil inesperado. Cache preservado.'
        }
        foreach ($name in $cacheNames) {
            $target = Join-Path $profileDir $name
            $parent = Split-Path $target -Parent
            if ($parent -ne $profileDir -and (Test-Path -LiteralPath $parent) -and ((Get-Item -LiteralPath $parent).Attributes -band [IO.FileAttributes]::ReparsePoint)) {
                Write-Warning "Cache preservado por estar em um link: $target"
                continue
            }
            if (Test-Path -LiteralPath $target -PathType Container) {
                if ((Get-Item -LiteralPath $target).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                    Write-Warning "Cache preservado por ser um link: $target"
                    continue
                }
                Remove-Item -LiteralPath $target -Recurse -Force
                Write-Host ("Cache limpo: {0}\{1}" -f $profileName, $name) -ForegroundColor Green
                $cleared++
            }
        }
    }
    Write-Host ("Pastas de cache removidas: {0}. O Brave as recriara quando necessario." -f $cleared)
}

function Show-InternalPreview {
    $files = @(Get-ProfileFiles)
    Write-Host ("Opcoes internas em {0} perfil(is):" -f $files.Count) -ForegroundColor Cyan
    foreach ($setting in $internalSettings) { Write-Host ("- {0}" -f $setting.Label) }
    Write-Host 'O Brave deve estar fechado para aplicar ou restaurar. Nenhuma aba, senha ou extensao sera apagada.'
}

function Apply-InternalSettings {
    $files = @(Get-ProfileFiles)
    if ($files.Count -eq 0) { throw 'Nenhum perfil do Brave foi encontrado.' }
    $plans = @()
    foreach ($file in $files) {
        $prefs = Read-Preferences -Path $file
        $changes = @()
        foreach ($setting in $internalSettings) {
            $current = Get-PrefValue -Root $prefs -Path $setting.Path
            if ($current.Exists -and $current.Value -isnot [bool]) {
                Write-Warning "Valor inesperado preservado em $($setting.Path)."
                continue
            }
            if ($current.Exists -and $current.Value -eq $setting.Value) { continue }
            $changes += [pscustomobject]@{
                Path = $setting.Path
                HadValue = [bool]$current.Exists
                OldValue = $current.Value
                AppliedValue = $setting.Value
            }
            Set-PrefValue -Root $prefs -Path $setting.Path -Value $setting.Value
        }
        if ($changes.Count -gt 0) {
            $plans += [pscustomobject]@{ File = $file; Changes = $changes; Preferences = $prefs }
        }
    }
    if ($plans.Count -eq 0) { Write-Host 'As opcoes internas ja estavam ajustadas.'; return }
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
    $state = [pscustomobject]@{
        SchemaVersion = 1
        UserDataPath = $userDataPath
        Profiles = @($plans | ForEach-Object { [pscustomobject]@{ File = $_.File; Changes = $_.Changes } })
    }
    $tempState = "$preferencesStatePath.tmp"
    [System.IO.File]::WriteAllText($tempState, (ConvertTo-Json -InputObject $state -Depth 20), $utf8NoBom)
    Move-Item -LiteralPath $tempState -Destination $preferencesStatePath -Force
    for ($i = 0; $i -lt $plans.Count; $i++) {
        $plan = $plans[$i]
        Write-Preferences -Path $plan.File -Preferences $plan.Preferences -BackupPath $null
        Write-Host ("Perfil atualizado: {0} ({1} opcoes)." -f (Split-Path (Split-Path $plan.File -Parent) -Leaf), $plan.Changes.Count) -ForegroundColor Green
    }
}

function Restore-InternalSettings {
    if (-not (Test-Path -LiteralPath $preferencesStatePath)) { return }
    $state = Get-Content -LiteralPath $preferencesStatePath -Raw | ConvertFrom-Json
    if ($state.SchemaVersion -ne 1 -or $state.UserDataPath -ne $userDataPath) {
        throw 'Registro de preferencias invalido. Nada foi alterado.'
    }
    $remainingProfiles = @()
    foreach ($entry in @($state.Profiles)) {
        $profileDir = Split-Path $entry.File -Parent
        $profileName = Split-Path $profileDir -Leaf
        if ((Split-Path $profileDir -Parent) -ne $userDataPath -or $profileName -notmatch '^(Default|Profile [0-9]+)$' -or (Split-Path $entry.File -Leaf) -ne 'Preferences') {
            throw 'Caminho inesperado no registro de preferencias.'
        }
        if (-not (Test-Path -LiteralPath $entry.File)) { $remainingProfiles += $entry; continue }
        $prefs = Read-Preferences -Path $entry.File
        $remainingChanges = @()
        $changed = $false
        foreach ($change in @($entry.Changes)) {
            $setting = $internalSettings | Where-Object { $_.Path -eq $change.Path } | Select-Object -First 1
            if (-not $setting) { throw "Opcao inesperada: $($change.Path)" }
            $current = Get-PrefValue -Root $prefs -Path $change.Path
            if (-not $current.Exists) { continue }
            if ($current.Value -isnot [bool] -or $current.Value -ne $change.AppliedValue) {
                Write-Warning "Preservada: $($setting.Label) foi alterada depois."
                $remainingChanges += $change
                continue
            }
            if ($change.HadValue) { Set-PrefValue -Root $prefs -Path $change.Path -Value $change.OldValue }
            else { Remove-PrefValue -Root $prefs -Path $change.Path }
            $changed = $true
        }
        if ($changed) { Write-Preferences -Path $entry.File -Preferences $prefs -BackupPath $null }
        if ($remainingChanges.Count -gt 0) {
            $remainingProfiles += [pscustomobject]@{ File = $entry.File; Changes = $remainingChanges }
        }
    }
    if ($remainingProfiles.Count -eq 0) {
        Remove-Item -LiteralPath $preferencesStatePath -Force
        Write-Host 'Opcoes internas restauradas.' -ForegroundColor Green
    } else {
        $state.Profiles = @($remainingProfiles)
        [System.IO.File]::WriteAllText($preferencesStatePath, (ConvertTo-Json -InputObject $state -Depth 20), $utf8NoBom)
        Write-Warning 'Algumas opcoes foram preservadas porque mudaram depois.'
    }
}

try {
    if ($Action -eq 'Menu') {
        Write-Host 'Brave Optimizer' -ForegroundColor Cyan
        Write-Host '1. Ver alteracoes planejadas'
        Write-Host '2. Aplicar opcoes internas do Brave'
        Write-Host '3. Tweaks de Registro (cuidado: mostra "gerenciado pela organizacao")'
        Write-Host '4. Limpar caches (nao reversivel)'
        Write-Host '5. Aplicar tudo: opcoes internas, Registro e caches'
        Write-Host '6. Restaurar opcoes e Registro desta ferramenta'
        Write-Host '7. Sair'
        $choice = Read-Host 'Escolha uma opcao'
        $Action = switch ($choice) {
            '1' { 'Preview' }
            '2' { 'Apply' }
            '3' { 'Registry' }
            '4' { 'Cache' }
            '5' { 'All' }
            '6' { 'Restore' }
            default { 'Exit' }
        }
        if ($Action -in @('Apply', 'Registry', 'Cache', 'All', 'Restore')) {
            Write-Host ''
            if ($Action -eq 'All') { Write-Host 'O modo completo limpa caches, altera preferencias e cria politicas no Registro.' -ForegroundColor Yellow }
            if ($Action -eq 'Cache') { Write-Host 'A limpeza de cache nao pode ser desfeita.' -ForegroundColor Yellow }
            $confirmation = Read-Host 'Feche o Brave. Digite SIM para continuar'
            if ($confirmation -cne 'SIM') { $Action = 'Exit' }
        }
    }
    switch ($Action) {
        'Preview' { Show-Preview; Show-InternalPreview }
        { $_ -in @('Apply', 'Registry', 'All') } {
            Assert-BraveClosed
            if ($Action -in @('Apply', 'All') -and (Test-Path -LiteralPath $preferencesStatePath)) {
                throw 'Ja existe um registro de preferencias. Restaure antes de aplicar novamente.'
            }
            if ($Action -in @('Registry', 'All') -and (Test-Path -LiteralPath $statePath)) {
                throw 'Ja existe um registro de politicas. Restaure antes de aplicar novamente.'
            }
            if ($Action -in @('Apply', 'All') -and @(Get-ProfileFiles).Count -eq 0) { throw 'Nenhum perfil do Brave foi encontrado.' }
            if ($Action -in @('Apply', 'All')) { Apply-InternalSettings }
            if ($Action -in @('Registry', 'All')) { Apply-Policies }
            if ($Action -eq 'All') { Clear-BraveCaches }
            Write-Host 'Concluido. Abra o Brave e confira as configuracoes e brave://policy.' -ForegroundColor Green
        }
        'Cache' { Clear-BraveCaches }
        'Restore' {
            Assert-BraveClosed
            Restore-InternalSettings
            Restore-Policies
        }
    }
} catch {
    Write-Error "Falha: $($_.Exception.Message)"
    exit 1
}

