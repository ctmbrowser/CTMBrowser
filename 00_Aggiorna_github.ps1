
$ErrorActionPreference = "Stop"

$Origine = $PSScriptRoot
$Destinazione = Join-Path $Origine "CTM_UPLOAD"

# Legge le regole del .gitignore usando Git
if (!(Test-Path (Join-Path $Origine ".gitignore"))) {
    Write-Host "ERRORE: .gitignore non trovato."
    Read-Host "Premi INVIO per uscire"
    exit 1
}

if (!(Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host "ERRORE: Git non installato."
    Read-Host "Premi INVIO per uscire"
    exit 1
}

# Crea la cartella di destinazione
New-Item -ItemType Directory -Path $Destinazione -Force | Out-Null

# Elenca tutti i file tracciati o non tracciati, escludendo .git
$FileDaCopiare = Get-ChildItem -LiteralPath $Origine -Force -Recurse -File |
    Where-Object {
        $_.FullName -notlike "$Destinazione\*" -and
        $_.FullName -notmatch '[\\/]\.git[\\/]' -and
        $_.Name -ne ".git"
    }

$Copiati = 0
$Esclusi = 0

foreach ($File in $FileDaCopiare) {
    $Relativo = $File.FullName.Substring($Origine.Length).TrimStart('\','/')
    $RelativoGit = $Relativo.Replace('\','/')

    # Rispetta il .gitignore, anche per file non ancora tracciati
    git check-ignore --no-index -q -- "$RelativoGit" 2>$null
    if ($LASTEXITCODE -eq 0) {
        $Esclusi++
        continue
    }

    $PercorsoDest = Join-Path $Destinazione $Relativo
    $CartellaDest = Split-Path -Parent $PercorsoDest

    New-Item -ItemType Directory -Path $CartellaDest -Force | Out-Null
    Copy-Item -LiteralPath $File.FullName -Destination $PercorsoDest -Force

    $Copiati++
}

Write-Host ""
Write-Host "Operazione completata."
Write-Host "File copiati: $Copiati"
Write-Host "File esclusi dal .gitignore: $Esclusi"
Write-Host "Cartella: $Destinazione"
Write-Host ""

Read-Host "Premi INVIO per chiudere"
