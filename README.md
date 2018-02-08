Objective:

The macro is aimed to help analysers to get their LEGO train outputs. Two cases are addressed:


  1. "Train merging successful", outputs can be collected directly

     -> IMPLEMENTED


  2. "Train merging failed", outputs have to be merged locally:

    a. merging is performed at "Stage_*" level    -> IMPLEMENTED

    b. merging is performed at "processing" level -> NOT YET IMPLEMENTED

    c. merging is performed on a per-run basis    -> NOT YET IMPLEMENTED




Constraints:

  - Bash scripting written in a portable way (if possible)

  - Making use of AliEn/AliRoot environment




Script usage:

   ./CollectLEGOTrainOutputs.sh --train [name] --number [nb]

      --train:  train name of the form PAG_system

      --number: train number


   Example:

   ./CollectLEGOTrainOutputs.sh --train D2H_pp_MC --number 840




Author:

   Julien Hamon (IPHC, Strasbourg)