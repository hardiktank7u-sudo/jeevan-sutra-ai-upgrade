param(
  [Parameter(Mandatory=$true)][string]$JsonFile,
  [string]$Report = "build/plant_knowledge_audit.json"
)
$ErrorActionPreference = 'Stop'
$required = @('id','commonName','scientificName')
$listFields = @('partsUsed','traditionalReferences','traditionalUses','scientificEvidence','knownCompounds','evidenceLimitations','precautions','lookAlikes','sources','sourceDetails','keywords')
$allowedReview = @('draft','research_extracted','needs_review','reviewed','approved','rejected')
$allowedEvidence = @('not_assessed','traditional_use_only','preclinical','clinical_limited','clinical_moderate','clinical_strong','insufficient','mixed')
function Norm($v) { if ($null -eq $v) { return '' }; return ([string]$v).Trim() -replace '\s+',' ' | ForEach-Object { $_.ToLowerInvariant() } }
if (!(Test-Path -LiteralPath $JsonFile -PathType Leaf)) { throw "JSON file not found: $JsonFile" }
$data = Get-Content -LiteralPath $JsonFile -Raw -Encoding UTF8 | ConvertFrom-Json
if ($null -eq $data.plants -or $data.plants -isnot [System.Array]) { throw 'Expected a JSON object with a plants array.' }
$errors = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$ids = @{}; $scientific = @{}; $families = @{}; $reviewCounts = @{}; $evidenceCounts = @{}; $gaps = @{}
function AddCount([hashtable]$h,[string]$k) { if (!$h.ContainsKey($k)) { $h[$k]=0 }; $h[$k]++ }
for ($i=0; $i -lt $data.plants.Count; $i++) {
  $p = $data.plants[$i]; $at = "plants[$i]"
  if ($null -eq $p -or $p -is [string] -or $p -is [ValueType]) { $errors.Add("${at}: record must be an object"); continue }
  foreach ($f in $required) { if ([string]::IsNullOrWhiteSpace([string]$p.$f)) { $errors.Add("${at}: missing/blank required field '$f'") } }
  $id = Norm $p.id; $sci = Norm $p.scientificName
  if ($id) { if ($ids.ContainsKey($id)) { $errors.Add("${at}: duplicate id '$($p.id)' (also $($ids[$id]))") } else { $ids[$id]=$at } }
  if ($sci) { if ($scientific.ContainsKey($sci)) { $errors.Add("${at}: duplicate scientificName '$($p.scientificName)' (also $($scientific[$sci]))") } else { $scientific[$sci]=$at } }
  $family=Norm $p.family; if ($family) {$families[$family]=$true}
  foreach ($f in $listFields) {
    $v=$p.$f
    if ($null -ne $v -and $v -isnot [System.Array]) { $errors.Add("${at}: '$f' must be an array") }
    elseif ($null -ne $v) { foreach ($x in $v) { if ($null -ne $x -and $x -isnot [string] -and $x -isnot [System.Management.Automation.PSCustomObject]) { $errors.Add("${at}: '$f' contains unsupported value type") } } }
  }
  if (!$family) { AddCount $gaps 'missing_family' }
  if (!(Norm $p.identification)) { AddCount $gaps 'missing_identification' }
  if (!(Norm $p.safetySummary)) { AddCount $gaps 'missing_safety_summary' }
  if (!$p.sourceDetails -or $p.sourceDetails.Count -eq 0) { AddCount $gaps 'missing_source_details' }
  if (!$p.sources -or $p.sources.Count -eq 0) { AddCount $gaps 'missing_sources' }
  $status='draft'; if ($null -ne $p.reviewStatus) {$status=[string]$p.reviewStatus}
  if ($allowedReview -notcontains $status) {$errors.Add("${at}: unknown reviewStatus '$status'")}; AddCount $reviewCounts $status
  $ev='not_assessed'; if ($null -ne $p.evidenceLevel) {$ev=[string]$p.evidenceLevel}
  if ($allowedEvidence -notcontains $ev) {$warnings.Add("${at}: unrecognized evidenceLevel '$ev' (check controlled vocabulary)")}; AddCount $evidenceCounts $ev
  if ($null -ne $p.isToxic -and $p.isToxic -isnot [bool]) {$errors.Add("${at}: isToxic must be true, false, or null")}
  if ($null -eq $p.isToxic -and !(Norm $p.safetySummary)) {AddCount $gaps 'unknown_safety'}
  if ($p.sourceDetails -is [System.Array]) {
    for ($j=0; $j -lt $p.sourceDetails.Count; $j++) {
      $ref=$p.sourceDetails[$j]
      if ($ref -is [string]) {if ($ref.Trim()) {AddCount $gaps 'legacy_unstructured_source_notes'}; continue}
      if ($null -eq $ref -or $ref -isnot [System.Management.Automation.PSCustomObject]) {$errors.Add("${at}.sourceDetails[$j]: reference must be an object or legacy text note"); continue}
      if (!(Norm $ref.title)) {$errors.Add("${at}.sourceDetails[$j]: source title is required")}
      if ($ref.url) { try {$u=[uri]$ref.url; if ($u.Scheme -notin @('http','https') -or !$u.Host) {throw 'bad'}} catch {$errors.Add("${at}.sourceDetails[$j]: invalid source URL '$($ref.url)'")} }
    }
  }
}
if ($gaps.ContainsKey('legacy_unstructured_source_notes')) {$warnings.Add('Existing sourceDetails entries include legacy plain-text notes; convert them only after identifying the exact underlying source. Do not invent titles or URLs.')}
$reportObj=[ordered]@{databaseVersion=$data.databaseVersion;recordCount=$data.plants.Count;uniqueFamilies=$families.Count;uniqueIds=$ids.Count;uniqueScientificNames=$scientific.Count;reviewStatuses=$reviewCounts;evidenceLevels=$evidenceCounts;qualityGaps=$gaps;errorCount=$errors.Count;warningCount=$warnings.Count;errors=@($errors);warnings=@($warnings)}
$parent=Split-Path -Parent $Report; if ($parent -and !(Test-Path $parent)) {New-Item -ItemType Directory -Path $parent -Force | Out-Null}
$reportObj | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $Report -Encoding UTF8
$reportObj | ConvertTo-Json -Depth 10
if ($warnings.Count) {Write-Host "`nWARNINGS:" -ForegroundColor Yellow; $warnings | ForEach-Object {Write-Host "- $_"}}
if ($errors.Count) {Write-Host "`nERRORS:" -ForegroundColor Red; $errors | ForEach-Object {Write-Host "- $_"}; Write-Host "`nVALIDATION FAILED" -ForegroundColor Red; exit 1}
Write-Host "`nVALIDATION PASSED (quality warnings may remain). Report: $Report" -ForegroundColor Green
exit 0
