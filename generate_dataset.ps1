Write-Host "======================================================" -ForegroundColor Cyan
Write-Host " highly-practical dataset generator (Windows)         " -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "This script automatically generates a highly diverse"
Write-Host "dataset of 10 object-oriented instance XML skeletons,"
Write-Host "randomly distributing elements within natural bounds."
Write-Host "======================================================"

# You can tweak these defaults depending on how large you want the dataset.
# The generator will randomly pick sizes within these ranges for EACH instance,
# significantly increasing the diversity and naturalness of the dataset.

$CLASSES_BOUND = "5-15"
$METHODS_BOUND = "10-30"
$ATTRS_BOUND = "5-20"
$MIN_DEPTH = "2"
$INSTANCES = "10"
$FORMAT = "xml"

Write-Host "Generating $INSTANCES instances with:"
Write-Host "Classes: $CLASSES_BOUND, Methods: $METHODS_BOUND, Attributes: $ATTRS_BOUND" -ForegroundColor Yellow
Write-Host ""

.\run.ps1 --classes "$CLASSES_BOUND" `
          --methods "$METHODS_BOUND" `
          --attributes "$ATTRS_BOUND" `
          --min-depth "$MIN_DEPTH" `
          --instances "$INSTANCES" `
          --format "$FORMAT"

Write-Host ""
Write-Host "Done! Check the output/ folder for the files with their metadata headers." -ForegroundColor Green
