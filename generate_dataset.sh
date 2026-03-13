#!/bin/bash

echo "======================================================"
echo " highly-practical dataset generator (Linux / macOS)   "
echo "======================================================"
echo "This script automatically generates a highly diverse"
echo "dataset of 10 object-oriented instance XML skeletons,"
echo "randomly distributing elements within natural bounds."
echo "======================================================"

# You can tweak these defaults depending on how large you want the dataset.
# The generator will randomly pick sizes within these ranges for EACH instance,
# significantly increasing the diversity and naturalness of the dataset.

CLASSES_BOUND="5-15"
METHODS_BOUND="10-30"
ATTRS_BOUND="5-20"
MIN_DEPTH="2"
INSTANCES="10"
FORMAT="xml"

echo "Generating $INSTANCES instances with:"
echo "Classes: $CLASSES_BOUND, Methods: $METHODS_BOUND, Attributes: $ATTRS_BOUND"
echo ""

./run.sh --classes "$CLASSES_BOUND" \
         --methods "$METHODS_BOUND" \
         --attributes "$ATTRS_BOUND" \
         --min-depth "$MIN_DEPTH" \
         --instances "$INSTANCES" \
         --format "$FORMAT"

echo ""
echo "Done! Check the output/ folder for the files with their metadata headers."
