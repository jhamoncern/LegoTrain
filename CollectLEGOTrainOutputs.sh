#!/usr/bin/env bash
###
### Objective:
### The macro is aimed to help analysers to get their LEGO train outputs. Two cases are addressed:
###   1. "Train merging successful", outputs can be collected directly
###      -> IMPLEMENTED
###   2. "Train merging failed", outputs have to be merged locally:
###     a. merging is performed at "Stage_*" level    -> IMPLEMENTED
###     b. merging is performed at "processing" level -> NOT YET IMPLEMENTED
###     c. merging is performed on a per-run basis    -> NOT YET IMPLEMENTED
###
### Constraints:
###   - Bash scripting written in a portable way (if possible)
###   - Making use of AliEn/AliRoot environment
###
### Notes:
###   - alien_<cmd> outputs are redirected to the trash (&> /dev/null) to silent them
###   - alien_ls -F : list directories with a trailing '/'
###
### Author:
###    Julien Hamon (IPHC, Strasbourg)
###

develop=false
###
### Example of train with 2 runlists:
###   - Runlit 1: failed during merging
###   - Runlit 2: merging successful
### --train D2H_pp_MC --number 840
###
### Example of META train with 7 children:
### --train D2H_pp --number 2077
###


set -o errexit
set -o nounset
# cleanup() {
#    printf "==================================================\n"
#    echo "Clean up temporary files..."
#    echo "... Done!"
#    printf "==================================================\n"
# }
# trap cleanup EXIT



# Set magic variables for current file & dir
__dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
__base="$(basename ${__file} .sh)"








### ====================================================================================================
### Function:  Documentation of the script
###            How to use it
###
show_usage()
{
   # Script short description
   printf "\n================   Description    ================\n"
   printf "The macro is aimed to help analysers to get their LEGO train outputs.\n"
   printf "Two cases are addressed:\n"
   printf "   1. 'Train merging successful', outputs can be collected directly\n"
   printf "      -> IMPLEMENTED\n"
   printf "   2. 'Train merging failed', outputs have to be merged locally:\n"
   printf "     a. merging is performed at 'Stage_*' level    -> IMPLEMENTED\n"
   printf "     b. merging is performed at 'processing' level -> NOT YET IMPLEMENTED\n"
   printf "     c. merging is performed on a per-run basis    -> NOT YET IMPLEMENTED\n"
   printf "==================================================\n"

   # Script usage
   printf "\n================   Script usage   ================\n"
   printf "./${__base}.sh --train [name] --number [nb]\n"
   printf "   --train:  train name of the form PAG_system\n"
   printf "   --number: train number\n"
   printf "\nExample:\n"
   printf "./${__base}.sh --train D2H_pp_MC --number 840\n"
   printf "==================================================\n"
   printf "\n"
   exit 1
}






### ====================================================================================================
### Function:  Check pre-requists: script arguments, AliRoot, AliEn
###            Print documentation if needed.
###
check_prerequists()
{
   # First check if documentation needs to be printed
   case ${1:-} in
      --help | -h | -\?)
         show_usage
         ;;
   esac


   # Start the script checking pre-requist
   printf "\n"
   echo "--- Starting the script"
   echo "o-- Check pre-requists"

   if [[ ${#} -eq 0 ]]
   then
      echo "WARNING: The script expects arguments!"
      show_usage
   fi

   if [[ -z ${ALICE_PHYSICS:-} ]]
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
###
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

   if [[ -z ${__trainPWG:-} ]]
   then
      printf "WARNING: the train name (${__trainName}) does not match any available PWG:"
      printf " $(for ipwg in ${__list_PWG[@]} ; do printf "${ipwg} " ; done)\n"
      show_usage
   fi


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
   if grep --quiet -E '[a-zA-Z]{2,4}MC$' <<< ${__trainName}
   then
      __trainName=$(sed -e 's/MC/_MC/' <<< ${__trainName})
   fi
}






### ====================================================================================================
### Function:  manually parsing options in a flexible approach
###            Source: http://mywiki.wooledge.org/BashFAQ/035#Manual_loop
###
parse_arguments()
{
   echo "oo- Parse script arguments"


   while :; do

      # Break out the loop if there are no more options
      [[ -n ${1:-} ]] || break

      case ${1} in

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
### Function:  Collect train outputs within the provided directory
###            1. "Train merging successful" -> IMPLEMENTED
###            2. "Train merging failed"
###              a. merging performed at "Stage_*" level -> IMPLEMENTED
###
collect_outputs_inDirectory()
{
   # Check if a train directory is provided
   local __alien_trainDirectory="${1:-}"

   if [[ -z ${__alien_trainDirectory:-} ]]
   then
      echo "WARNING: no directory provided to collect_outputs_inDirectory()"
      return 0
   fi


   # Check if the output suffix is provided
   local output_suffix="${2:-}"
   if [[ -z ${output_suffix:-} ]]
   then
      echo "WARNING: no output suffix provided to collect_outputs_inDirectory()"
      return 0
   fi


   # Merging successful
   if alien_ls ${__alien_trainDirectory}/AnalysisResults.root &> /dev/null
   then
      alien_cp alien:${__alien_trainDirectory}/AnalysisResults.root file:AnalysisResults_${output_suffix}.root
      return 0
   fi


   # Merging failed
   local nMergingStage=($(alien_ls -F ${__alien_trainDirectory}/ | grep -E -c "^Stage_[0-9]/$"))
   __alien_trainDirectory="${__alien_trainDirectory}Stage_${nMergingStage}/"


   local mergingCmd="alihadd -k AnalysisResults_${output_suffix}.root"

   alien_ls -F ${__alien_trainDirectory} | while read -r ; do

      local finput="${__alien_trainDirectory}/${REPLY}/AnalysisResults.root"
      ! alien_ls ${finput} &> /dev/null && continue
      alien_cp alien:${__alien_trainDirectory}/${REPLY}/AnalysisResults.root file:AnalysisResults_${output_suffix}_tmp${REPLY}.root
      mergingCmd="${mergingCmd} AnalysisResults_${output_suffix}_tmp${REPLY}.root"

   done

   eval ${mergingCmd[@]}
   if [[ -e AnalysisResults_${output_suffix}.root ]]
   then
      rm -f AnalysisResults_${output_suffix}_tmp*
      return 0
   else
      return 0
   fi


   return 0
}






### ====================================================================================================
### Function:  Collect train outputs - Main method
###            Find the train directories on AliEn (META or Standard trains)
###
collect_outputs_main()
{
   echo "ooo Collect train outputs"


   # Build suffix for outputs
   local __trainOutput_suffix="$(sed 's/_//g' <<< ${__trainName})"
   __trainOutput_suffix="${__trainOutput_suffix}_${__trainNumber}"


   # Path of the train mother directory on AliEn
   local __alien_trainPath="/alice/cern.ch/user/a/alitrain/${__trainPWG}/${__trainName}/"

   if ! alien_ls ${__alien_trainPath} &> /dev/null
   then
      echo "WARNING: the train mother directory has not been found on AliEn: ${__alien_trainPath}"
      show_usage
   fi


   # Find the specific directory of the train
   #   a. META train:     trainNumber_date-time (merged children) + trainNumber_date-time_child_x (one per children)
   #   b. Standard train: trainNumber_date-time

   local __alien_trainID=$(alien_ls ${__alien_trainPath} | grep -E -o "^${__trainNumber}_[0-9]{8}-[0-9]{4}[_,child,0-9]{0,8}$")

   if [[ -z ${__alien_trainID:-} ]]
   then
      echo "WARNING: cannot find the specific directory of the train with format ${__trainNumber}_date-time*"
      show_usage
   fi


   local nTrainID=$(wc -w <<< ${__alien_trainID} | tr -d ' ')
   if [[ ${nTrainID:-} = 1 ]]
   then
      echo "   -> The train ran on standard (non-META) dataset"
   else
      echo "   -> The train ran on META dataset containing $((${nTrainID}-1)) children"
   fi


   # Loop over the train mother directories (trainNumber_date-time + potential children)
   for idir in ${__alien_trainID[@]} ; do

      # Update the train mother directory
      local trainDirPath="${__alien_trainPath}${idir}/"
      local extraSuffix=$(grep -E -o "[_,child,0-9]{8}$" <<< ${idir})
      local output_suffix="${__trainOutput_suffix}${extraSuffix}"


      # Case where there is a SINGLE runlist
      if alien_ls -F ${trainDirPath} | grep --quiet -E -o "^merge/$"
      then
         echo "   -> Directory ${idir} has a single runlist"
         [[ ${develop} = false ]] && collect_outputs_inDirectory "${trainDirPath}/merge/" "${output_suffix}"
         continue
      fi


      # Search for several runlists
      local __alien_trainRunlist=($(alien_ls -F ${trainDirPath} | grep -E "^merge_runlist_[1-9]{1,2}/$"))

      if [[ -z ${__alien_trainRunlist:-} ]]
      then
         echo "   -> WARNING: cannot find output files or directories in ${trainDirPath}"
         continue
      fi


      # Case where there are SEVERAL runlist
      echo "   -> Directory ${idir} has $(wc -w <<< ${__alien_trainRunlist[@]} | tr -d ' ') runlists"

      for irun in ${!__alien_trainRunlist[@]} ; do
         local iRunlist=$((${irun}+1))
         [[ ${develop} = false ]] && collect_outputs_inDirectory "${trainDirPath}/merge_runlist_${iRunlist}/" "${output_suffix}_runlist${iRunlist}"
      done


   done


   # Say goodbye
   echo "ooo Files have been collected successfully. Exit..."
}






### ====================================================================================================
### Main:  default use of the script
###        Check pre-requists, parse arguments, collect outputs.
###
check_prerequists "$@"
parse_arguments "$@"
collect_outputs_main

exit 0