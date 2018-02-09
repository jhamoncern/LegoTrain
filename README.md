# LEGO train tool


## Objective:

The script is aimed to help ALICE analysers to get their LEGO train outputs.

Downloading train outputs of several child sets and/or several runlists by hand, with potentially local merging to be performed when train failed at merging stage, can be tough. This tool is aimed to make your life easier, taking care of getting your train outputs.

The script addresses automatically the two following cases:

1. *Train merging successful*: train outputs (one per child and runlist) can be collected directly.

2. *Train merging failed*: outputs have to be merged locally

* Local merging performed at "Stage_*" level
* Local merging performed at "processing" level **&rarr; not yet implemented**
* Local merging performed on a per-run basis **&rarr; not yet implemented**


## Script usage:

```sh
$ ./CollectLEGOTrainOutputs.sh --train [name] --number [nb]
```
- ```--train```:  train name, in the form of *PAG_system*
- ```--number```:  train number
- ```--help```:  script documentation

Example:
```sh
$ ./CollectLEGOTrainOutputs.sh --train D2H_pp_MC --number 840
```


## Coding constraints:

- Bash script to be written in a portable way (if possible)
- Make use of AliEn/AliRoot environment


## Author:

Julien Hamon (IPHC, Strasbourg)