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
   printf "==================================================\n"
   echo "Clean up temporary files..."
   echo "... Done!"
   printf "==================================================\n"
}
trap cleanup EXIT



# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"








### ====================================================================================================
### Function:  Documentation of the script
###            How to use it
show_usage()
{
   printf "\n================   Script usage   ================\n"
   printf "./${__base}.sh --train [name] --number [nb]\n"
   printf "   --train:  D2H_pp\n"
   printf "   --number: 2589\n"
   printf "==================================================\n"
   printf "\n"
   exit 1
}






### ====================================================================================================
### Function:  check pre-requists
###            Script arguments, AliRoot, AliEn
check_prerequists()
{
   printf "\n"
   echo "--- Starting the script"
   echo "o-- Check pre-requists"

   if [[ ${#} -eq 0 ]]
   then
      echo "WARNING: The script expects arguments!"
      show_usage
   fi

   # if [[ -z ${ALICE_PHYSICS} ]]
   # then
   #    echo "WARNING: AliRoot should be loaded to merge outputs"
   #    show_usage
   # fi

   # if grep --quiet "No Token found!" <<< "$(alien-token-info)"
   # then
   #    echo "WARNING: An access to AliEn is required. Please get a token: alien-token-init username"
   #    show_usage
   # fi
}






### ====================================================================================================
### Function:  manually parsing options in a flexible approach
###            Source: http://mywiki.wooledge.org/BashFAQ/035#Manual_loop
parse_arguments()
{
   echo "oo- Parse script arguments"


   while :; do

      # Break out the loop if there are no more options
      [[ -n ${1:-} ]] || break

      case ${1} in

         # Documentation
         --help | -h | -\?)
            show_usage
            ;;

         # Get the LEGO train number
         --number)
            if [[ -n ${2:-} ]] && grep --quiet -E '^[0-9]{1,4}$' <<< ${2}
            then
               # Do something...
               shift
            else
               echo "WARNING: --number expects a value" >&2
               show_usage
            fi
            ;;

         # In case of unknown options
         -?*)
            printf 'WARNING: Unknown option %s\n' "${1}" >&2
            show_usage
            ;;

         # Default case: break out the loop if there are no more options
         *)
            break
            ;;

      esac

      # Shift the script argument to the left
      shift

   done
}








### ====================================================================================================
### Main:  default use of the script
###        Check, parse
check_prerequists "$@"
parse_arguments "$@"