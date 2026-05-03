# ============================================================================
# SCRIPT: DirOverFixRoot.ps1
# DESCRIPCIÓN: Overwrite + Fix global de rutas, sintaxis y legacy
# PROYECTO: Madame-MaTe | Pipeline: Leviatan
# AUTOR: OSTP @echoShift
# EJECUCIÓN: powershell -ExecutionPolicy Bypass -File DirOverFixRoot.ps1
# ============================================================================

param(
    [string]$ProjectRoot = "C:\Proyectos\madame-mate",
    [switch]$DryRun = $false,
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"
$startTime = Get-Date

# ── Logging estandarizado ──
function Write-Log {
    param([string]$Level, [string]$Message)
    $colors = @{ INFO='Cyan'; OK='Green'; WARN='Yellow'; ERR='Red'; BUILD='Magenta'; FIX='White' }
    $color = if($colors.ContainsKey($Level)) { $colors[$Level] } else { 'White' }
    $tag = if($DryRun) { "[DRY] " } else { "" }
    Write-Host "[$Level] $tag$Message" -ForegroundColor $color
}

Write-Log BUILD "=== MADAME-MATE: OVER-FIX ROOT ==="
Write-Log INFO "Ruta: $ProjectRoot"
Write-Log INFO "Modo: $(if($DryRun){'DRY-RUN'}else{'REAL'})"

# ── 1. PATRONES DE REEMPLAZO (Legacy → Oficial) ──
$Replacements = @(
    # Identidad
    @{ Pattern = '(?i)Infantil Muebles JR|Infantiles y Muebles JR|IMJR'; Replacement = 'Madame-MaTe' },
    @{ Pattern = '(?i)JR-'; Replacement = 'MM-' },
    @{ Pattern = 'Madme-MaTe'; Replacement = 'Madame-MaTe' },
    
    # Rutas de assets
    @{ Pattern = 'assets/img/avatar/mona\.svg'; Replacement = 'assets/img/logo/avatar.svg' },
    @{ Pattern = 'assets/img/logo/logo-oficial\.svg'; Replacement = 'assets/img/og/background.svg' },
    
    # CSS Tokens legacy
    @{ Pattern = '--jr-primary'; Replacement = '--vz-primary' },
    @{ Pattern = '--jr-dark'; Replacement = '--vz-primary-dark' },
    @{ Pattern = '--jr-white'; Replacement = '--vz-bg' },
    
    # JS Syntax fixes (tipografía rota)
    @{ Pattern = '\.the\s+n\s*\(\s*r\s*=\s*>'; Replacement = '.then(r =>' },
    @{ Pattern = '\.th e n\s*\(\s*r'; Replacement = '.then(r' },
    
    # Normalización de textos
    @{ Pattern = 'ENSEREDEL HOGAR'; Replacement = 'ENSERES DEL HOGAR' }
)

# ── 2. ARCHIVOS Y EXTENSIONES A PROCESAR ──
$Extensions = @("*.html", "*.css", "*.js", "*.json", "*.md")
$ExcludeRegex = '_backup_|_ostp|node_modules|\.git|docs\\log|\.bak$'

# ── 3. PROCESAMIENTO DE ARCHIVOS ──
$filesProcessed = 0
$filesModified = 0

Get-ChildItem -Path "$ProjectRoot\*" -Recurse -Include $Extensions |
Where-Object { $_.FullName -notmatch $ExcludeRegex } |
ForEach-Object {
    $filesProcessed++
    try {
        $content = Get-Content $_.FullName -Raw -Encoding UTF8
        $original = $content
        $changed = $false
        
        foreach($rule in $Replacements) {
            if($content -match $rule.Pattern) {
                $content = $content -replace $rule.Pattern, $rule.Replacement
                $changed = $true
                if($Verbose -and -not $DryRun) {
                    Write-Log FIX "[$($_.Name)] $($rule.Pattern) → $($rule.Replacement)"
                }
            }
        }
        
        if($changed -and -not $DryRun) {
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($_.FullName, $content, $utf8NoBom)
            $filesModified++
            Write-Log OK "✓ $($_.Name)"
        } elseif($changed -and $DryRun) {
            Write-Log WARN "[DRY] $($_.Name) sería modificado"
        }
    } catch {
        Write-Log WARN "⚠ No se pudo procesar $($_.Name): $($_.Exception.Message)"
    }
}

# ── 4. VALIDACIÓN POST-FIX ──
Write-Log BUILD "--- VALIDACIÓN POST-FIX ---"
$CriticalFiles = @(
    "assets/css/tokens.css",
    "assets/css/main.css", 
    "assets/css/components.css",
    "assets/js/main.js",
    "assets/js/cart-logic.js",
    "assets/img/logo/avatar.svg",
    "assets/img/og/background.svg",
    "data/config.json"
)

$validationErrors = 0
foreach($file in $CriticalFiles) {
    $path = Join-Path $ProjectRoot $file
    if(Test-Path $path) {
        Write-Log OK "[OK] $file"
    } else {
        Write-Log ERR "[!!] FALTA: $file"
        $validationErrors++
    }
}

# ── 5. REPORTE FINAL ──
$elapsed = (Get-Date) - $startTime
Write-Log BUILD "=== RESUMEN ==="
Write-Log INFO "Tiempo: $($elapsed.TotalSeconds.ToString('0.00'))s"
Write-Log INFO "Archivos escaneados: $filesProcessed"
Write-Log INFO "Archivos modificados: $filesModified"
Write-Log INFO "Errores de validación: $validationErrors"

if($validationErrors -eq 0) {
    Write-Log OK "✓ OVER-FIX EXITOSO - PIPELINE LISTO"
    exit 0
} else {
    Write-Log ERR "✗ REVISAR ERRORES ANTES DE CONTINUAR"
    exit 1
}