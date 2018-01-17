#!/usr/bin/env bash
###
### Objective:
### The macro is aimed to help analysers to get their LEGO train outputs. Two cases are addressed:
###   1. "Train merging successful", outputs can be collectly directly
###   2. "Train merging failed", outputs have to be merged locally:
###     a. merging is performed at "Stage_*" level
###     b. merging is performed at "processing" level
###     c. merging is performed on a per-run basis
###
### Constraint:
###   - Bash scripting written in a portable way (if possible)
###   - Making use of AliEn/AliRoot environment
###
### Author:
###    Julien Hamon (IPHC, Strasbourg)
###


set -o errexit
set -o nounset
cleanup() {
   echo "Clean up temporary files..."
   echo "... Done!"
}
trap cleanup EXIT



# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"