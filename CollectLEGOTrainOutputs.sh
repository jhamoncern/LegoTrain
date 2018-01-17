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

develop=true


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

   [[ ${develop:-} = true ]] && return

   if [[ -z ${ALICE_PHYSICS} ]]
   then
      echo "WARNING: AliRoot should be loaded to merge outputs"
      show_usage
   fi

   if grep --quiet "No Token found!" <<< "$(alien-token-info)"
   then
      echo "WARNING: An access to AliEn is required. Please get a token: alien-token-init username"
      show_usage
   fi
}






### ====================================================================================================
### Function:  format train name
###            PAG_System or PAG_System_MC
format_train_name()
{
   __trainName="${1}"


   # Find PAG name of the train
   local __list_PAG=("CF" "DQ" "GA" "D2H" "Electrons" "HFCJ" "HM" "Jets" "LF")

   local __trainPAG=
   for ipag in ${__list_PAG[@]} ; do
      [[ "${ipag}_" =~ $(grep -o -E "^[a-zA-Z2]{1,9}_" <<< ${__trainName}) ]] && __trainPAG="${ipag}" && break
   done

   if [[ -z ${__trainPAG:-} ]]
   then
      printf "WARNING: the train name (${__trainName}) does not match any available PAG:"
      printf " $(for ipag in ${__list_PAG[@]} ; do printf "${ipag} " ; done)\n"
      show_usage
   fi


   # Find PWG name of the train
   local __trainPWG=
   case "${__trainPAG}" in
      "CF")
         __trainPWG="PWGCF"
         ;;
      "DQ")
         __trainPWG="PWGDQ"
         ;;
      "GA")
         __trainPWG="PWGGA"
         ;;
      "D2H" | "Electrons" | "HFCJ")
         __trainPWG="PWGHF"
         ;;
      "HM")
         __trainPWG="PWGHM"
         ;;
      "LF")
         __trainPWG="PWGLF"
         ;;
      *)
         echo "WARNING: the train PAG (${__trainPAG}) does not match any PWG"
         show_usage
         ;;
   esac


   # Find the collision system
   local __list_ColSyst=("pp" "pPb" "PbPb")

   for icol in ${__list_ColSyst[@]} ; do
      [[ "_${icol}" =~ $(grep -o -E "_[pPb]{2,4}" <<< ${__trainName}) ]] && __trainColSyst="${icol}" && break
   done

   if [[ -z ${__trainColSyst:-} ]]
   then
      printf "WARNING: the train name (${__trainName}) does not match any available collision system:"
      printf " $(for icol in ${__list_ColSyst[@]} ; do printf "${icol} " ; done)\n"
      show_usage
   fi


   # Add underscore to "MC" trains, if missing: e.g. ppMC -> pp_MC
   grep --quiet -E '[a-zA-Z]{2,4}MC$' <<< ${__trainName} && __trainName=$(sed -e 's/MC/_MC/' <<< ${__trainName})
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

         # Get the LEGO train name
         --train)
            if [[ -n ${2:-} ]] && grep --quiet -E '^[0-9a-zA-Z_]{1,}$' <<< ${2}
            then
               format_train_name "${2}"
               shift
            else
               echo "WARNING: --train expects a value"
               show_usage
            fi
            ;;

         # Get the LEGO train number
         --number)
            if [[ -n ${2:-} ]] && grep --quiet -E '^[0-9]{1,4}$' <<< ${2}
            then
               __trainNumber=${2}
               shift
            else
               echo "WARNING: --number expects a value"
               show_usage
            fi
            ;;

         # In case of unknown options
         -?*)
            echo "WARNING: Unknown option ${1}"
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


   # Check that all the required arguments are provided
   [[ -z ${__trainName:-} ]]   && echo "WARNING: you should provide the train name"   && show_usage
   [[ -z ${__trainNumber:-} ]] && echo "WARNING: you should provide the train number" && show_usage


   # Print out the list of arguments
   echo "   -> Train name:   ${__trainName}"
   echo "   -> Train number: ${__trainNumber}"
}








### ====================================================================================================
### Main:  default use of the script
###        Check, parse
check_prerequists "$@"
parse_arguments "$@"