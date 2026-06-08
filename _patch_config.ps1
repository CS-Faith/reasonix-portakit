param([string]$ConfigPath)

# === 1. Determine paths ===
$rxRoot = if ($env:RX_ROOT) { $env:RX_ROOT } else { $PSScriptRoot }
$hostProfile = [Environment]::GetFolderPath('UserProfile')
$hostRx = "$hostProfile\.reasonix"
$syncRx = "$rxRoot\.reasonix"

# === 2. Compute project hash ===
Add-Type -AssemblyName System.Security
$sha1 = [Security.Cryptography.HashAlgorithm]::Create('SHA1')
$hash = [BitConverter]::ToString($sha1.ComputeHash([Text.Encoding]::UTF8.GetBytes($rxRoot)))
$hash = $hash.Replace('-', '').ToLower().Substring(0, 16)

Write-Host "=== Reasonix sync-disk setup ==="
Write-Host "  Sync-disk root : $rxRoot"
Write-Host "  Project hash   : $hash"

# === 3. Ensure directory structure ===
$dirs = @(
    "$syncRx\memory\$hash",
    "$syncRx\memory\global",
    "$syncRx\conversations\$hash",
    "$syncRx\conversations\global",
    "$syncRx\sessions"
)
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        New-Item -ItemType Directory -Path $d -Force | Out-Null
        Write-Host "  Created: $d"
    }
}

# === 3b. Rename old hash directories to current hash ===
foreach ($base in @("$syncRx\memory", "$syncRx\conversations")) {
    if (-not (Test-Path $base)) { continue }
    $oldDirs = Get-ChildItem $base -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne 'global' -and $_.Name -ne $hash }
    if ($oldDirs.Count -eq 1) {
        $oldHash = $oldDirs[0].Name
        $oldPath = Join-Path $base $oldHash
        $newPath = Join-Path $base $hash
        if (-not (Test-Path $newPath) -or (Get-ChildItem $newPath -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer }).Count -eq 0) {
            if (Test-Path $newPath) { Remove-Item $newPath -Recurse -Force }
            Rename-Item $oldPath $newPath
            Write-Host "  Renamed: $base\$oldHash -> $hash"
        }
    } elseif ($oldDirs.Count -gt 1) {
        # Multiple old hash dirs — merge into current hash
        foreach ($od in $oldDirs) {
            robocopy "$($od.FullName)" "$base\$hash" * /E /XO /NFL /NDL /NJH /NJS
            Remove-Item $od.FullName -Recurse -Force
        }
        Write-Host "  Merged $($oldDirs.Count) old hash dirs into $base\$hash"
    }
}

# === 4. Merge from host to sync-disk ===
if (Test-Path $hostRx) {
    # Merge host project memories into sync-disk hash dir (all host hash dirs -> sync hash dir)
    $hostMemDirs = Get-ChildItem "$hostRx\memory" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'global' }
    foreach ($d in $hostMemDirs) {
        robocopy "$($d.FullName)" "$syncRx\memory\$hash" *.md /E /XO /NFL /NDL /NJH /NJS
    }

    # Merge host global memories
    if (Test-Path "$hostRx\memory\global") {
        robocopy "$hostRx\memory\global" "$syncRx\memory\global" *.md /E /XO /NFL /NDL /NJH /NJS
    }

    # Merge host project conversations into sync-disk hash dir
    $hostConvDirs = Get-ChildItem "$hostRx\conversations" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -ne 'global' }
    foreach ($d in $hostConvDirs) {
        robocopy "$($d.FullName)" "$syncRx\conversations\$hash" * /E /XO /NFL /NDL /NJH /NJS
    }

    # Merge host global conversations
    if (Test-Path "$hostRx\conversations\global") {
        robocopy "$hostRx\conversations\global" "$syncRx\conversations\global" * /E /XO /NFL /NDL /NJH /NJS
    }

    # Merge host flat conversations (old format) into hash dir
    if (Test-Path "$hostRx\conversations\*.json") {
        robocopy "$hostRx\conversations" "$syncRx\conversations\$hash" *.json /XO /NFL /NDL /NJH /NJS
    }

    # Ensure conversation_history.json is also at root level (Reasonix reads from there)
    $convHash = "$syncRx\conversations\$hash\conversation_history.json"
    $convRoot = "$syncRx\conversations\conversation_history.json"
    if (Test-Path $convHash) {
        robocopy "$syncRx\conversations\$hash" "$syncRx\conversations" conversation_history.json /XO /NFL /NDL /NJH /NJS
    }

    # Merge sessions (flat, no hash split)
    if (Test-Path "$hostRx\sessions") {
        robocopy "$hostRx\sessions" "$syncRx\sessions" * /E /XO /NFL /NDL /NJH /NJS
    }

    Write-Host "  Merge: host -> sync-disk complete"
}

# === 5. Merge MEMORY.md indexes ===
function Merge-MemoryIndex($syncDir, $hostDirs) {
    $entries = @{}  # key = filename, value = line

    # Read existing sync-disk entries first (higher priority)
    $syncMd = "$syncDir\MEMORY.md"
    if (Test-Path $syncMd) {
        Get-Content $syncMd -Encoding UTF8 | Where-Object { $_ -match '\[([^\]]+)\]' } | ForEach-Object {
            if ($_ -match '\[([^\]]+)\]\(([^)]+)\)') {
                $entries[$Matches[2]] = $_
            }
        }
    }

    # Add host entries (only if filename not already present)
    foreach ($hd in $hostDirs) {
        $hostMd = Join-Path $hd 'MEMORY.md'
        if (Test-Path $hostMd) {
            Get-Content $hostMd -Encoding UTF8 | Where-Object { $_ -match '\[([^\]]+)\]' } | ForEach-Object {
                if ($_ -match '\[([^\]]+)\]\(([^)]+)\)') {
                    if (-not $entries.ContainsKey($Matches[2])) {
                        $entries[$Matches[2]] = $_
                    }
                }
            }
        }
    }

    # Write merged index
    $lines = @()
    # Host global entries
    $globalMd = "$hostRx\memory\global\MEMORY.md"
    if (Test-Path $globalMd) {
        Get-Content $globalMd -Encoding UTF8 | Where-Object { $_ -match '\[([^\]]+)\]' } | ForEach-Object {
            if ($_ -match '\[([^\]]+)\]\(([^)]+)\)') {
                if (-not $entries.ContainsKey($Matches[2])) {
                    $entries[$Matches[2]] = $_
                }
            }
        }
    }

    $entries.Values | Sort-Object | Set-Content $syncMd -Encoding UTF8
    Write-Host "  MEMORY.md merged: $($entries.Count) entries"
}

$hostMemDirsAll = @(Get-ChildItem "$hostRx\memory" -Directory -ErrorAction SilentlyContinue)
if ($hostMemDirsAll.Count -gt 0) {
    Merge-MemoryIndex "$syncRx\memory\$hash" $hostMemDirsAll
}

# === 6. Patch config.json paths ===
if ($ConfigPath -and (Test-Path $ConfigPath)) {
    $cfg = Get-Content $ConfigPath -Raw -Encoding UTF8
    if ($cfg) {
        $oldMatches = [regex]::Matches($cfg, '([A-Za-z]):\\\\Reasonix')
        $patched = $false
        $seen = @{}
        foreach ($m in $oldMatches) {
            $oldJson = $m.Value
            $oldPlain = $oldJson -replace '\\\\', '\'
            if ($oldPlain -eq $rxRoot) { continue }
            if ($seen.ContainsKey($oldJson)) { continue }
            $seen[$oldJson] = $true
            $rxJson = $rxRoot -replace '\\', '\\'
            Write-Host "  Config patch: $oldPlain -> $rxRoot"
            $cfg = $cfg -replace [regex]::Escape($oldJson), $rxJson
            $patched = $true
        }
        if ($patched) {
            Set-Content $ConfigPath -Value $cfg -Encoding UTF8 -NoNewline
        }
    }
}

# === 7. Fix session metadata (Node.js — handles BOM + JSON escaping properly) ===
$fixScript = Join-Path $rxRoot '_fix_sessions.js'
if (Test-Path $fixScript) {
    $nodeExe = Join-Path $rxRoot 'node.exe'
    if (-not (Test-Path $nodeExe)) { $nodeExe = 'node' }
    & $nodeExe $fixScript "$syncRx\sessions" $rxRoot 2>&1 | ForEach-Object { Write-Host "  $_" }
}

Write-Host "=== Setup complete ==="
