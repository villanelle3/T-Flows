#!/bin/bash

BLACK='\U001B[30m'
RED='\U001B[31m'
GREEN='\U001B[32m'
YELLOW='\U001B[33m'
BLUE='\U001B[34m'
MAGENTA='\U001B[35m'
CYAN='\U001B[36m'
WHITE='\U001B[37m'
RESET='\U001B[0m'

LIGHT_BLACK='\U001B[30;1m'
LIGHT_RED='\U001B[31;1m'
LIGHT_GREEN='\U001B[32;1m'
LIGHT_YELLOW='\U001B[33;1m'
LIGHT_BLUE='\U001B[34;1m'
LIGHT_MAGENTA='\U001B[35;1m'
LIGHT_CYAN='\U001B[36;1m'
LIGHT_WHITE='\U001B[37;1m'
RESET='\U001B[0m'

#------------------------------------------------------------------------------#
#   Global variables affecting the looks of the output
#------------------------------------------------------------------------------#
glo_indent="   "    # six characters wide
glo_separate="---"  # six characters wide, should be the same as glo_indent
glo_out_width=72    # should be multiple of indent and separator widhts

#==============================================================================#
#   Print the separator line
#------------------------------------------------------------------------------#
print_separator() {

  ind=$1  # current indentation
  lev=$2  # current level

  printf "%s" "$ind"
  end=`expr $glo_out_width / ${#glo_separate} - $lev`
  for (( c=1; c<=$end; c++ ))
  do
    echo -n $glo_separate
  done
  echo ""
}

#==============================================================================#
# Print_usage
#------------------------------------------------------------------------------#
print_usage() {
  echo "#======================================================================"
  echo "# Utility for extraction of module hierarchy/dependencies from T-Flows"
  echo "#----------------------------------------------------------------------"
  echo "# Proper usage: "
  echo "#"
  echo "# ./Utilities/extract_module_hierarchy.sh <Target_Mod> [-e <Exclude_Dir>]"
  echo "#"
  echo "# where Target_Mod is the module name for which you want to perform"
  echo "# the analysis, such as: Grid_Mod, Convert_Mod, Generate_Mod, hence"
  echo "# case sensitive, with the _Mod suffix, without the .f90 extension."
  echo "#"
  echo "# In cases where the same module name is used in more than one direc-"
  echo "# tory, you can use the second (always -e) and the third argument to "
  echo "# exclude some directories from the search.  At the time of writing "
  echo "# this, only Point_Mod is defined in Generate and in Process."
  echo "#"
  echo "# NOTE: The script is supposed to be executed from: T-Flows/Sources!"
  echo "#----------------------------------------------------------------------"
}

#------------------------------------------------------------------------------#
# Browse through all directories looking for module dependencies
#------------------------------------------------------------------------------#
extract_hierarchy() {

  #-----------------------
  #   Handle parameters
  #-----------------------

  # First parameter is the module name you seek
  module_name_you_seek="$1"
  module_file_you_seek="$module_name_you_seek"".f90"

  # Second parameter is the level at which you currently are
  local next_level=`expr $next_level + 1`
  local this_level=`expr $next_level - 1`

  if [ "$this_level" -eq 0 ]; then
    echo "#======================================================================="
    echo "# Extracting module hierarchy for "$module_name_you_seek
    echo "#"
    echo "# Legend:"
    echo "#"
    echo -n "# - modules using other modules:    "
    echo -e "${LIGHT_CYAN}${indent}"• Higher_Level_Mod "(level)${RESET}"
    echo -n "#                                   "
    echo -e "${WHITE}${indent}"• Lower_Level_Mod "(level)${RESET}"
    echo -n "# - modules not using any other:    "
    echo -e "${LIGHT_BLACK}${indent}"⨯ Not_A_User_Mod "(level)${RESET}"
    echo "#-----------------------------------------------------------------------"
  fi

  #----------------------------------------------#
  #   Get the full path of the module you seek   #
  #----------------------------------------------#
  if [ $exclude_dir ]; then
    local full_path_you_seek=$(find . -name $module_file_you_seek | grep -v $exclude_dir)
  else
    local full_path_you_seek=$(find . -name $module_file_you_seek)
  fi

  # This command counts number of occurrences of modules name in the result of
  # command find. If it is more than one, the same file is in more directories
  n=$(echo "$full_path_you_seek" | tr " " "\n" | grep -c "$module_name_you_seek")
  if [ $n -gt 1 ]; then
    echo "Ambiguity: module "$module_name_you_seek" found in more than one directory, here is the list:"
    for path in ${full_path_you_seek[*]}; do
      echo $path
    done
    echo "Exclude all but one directory with the command line argument -e <directory>"
    exit
  fi

  #-----------------------------------------------------
  #   Storing results of the grep command in an array
  #-----------------------------------------------------
  local used_modules=($(grep '\ \ use' $full_path_you_seek | awk '{print $2}' | tr -d ,))

  #------------------------------------------------------------------
  #   Print out the name of the module you are currently analysing
  #------------------------------------------------------------------
  if [ ! -z "$used_modules" ]; then
    if [ $this_level -lt 99 ]; then
      print_separator "$indent" $this_level
      echo -e "${LIGHT_CYAN}${indent}"• $module_name_you_seek "("$this_level")${RESET}"
    else
      echo -e "${indent}"• $module_name_you_seek "("$this_level")"
    fi
  else
    echo -e "${LIGHT_BLACK}${indent}"⨯ $module_name_you_seek "("$this_level")${RESET}"
  fi

  # Increase indend for the next level by appending spaces to it
  local indent="${indent}"$glo_indent

  #--------------------------------------------------------
  #   If the list of used modules in not empty, carry on
  #--------------------------------------------------------
  if [ ! -z "$used_modules" ]; then

    # Print the modules you have found here
    for mod in "${!used_modules[@]}"; do

      #-------------------------------------------------------#
      #                                                       #
      #   The very important recursive call to its own self   #
      #                                                       #
      #-------------------------------------------------------#
      if [[ "${used_modules[mod]}" == *"_Mod"* ]]; then   # only standard T-Flows modules
        extract_hierarchy "${used_modules[mod]}" $2 $3
      fi
    done
  fi
}

#----------------------------------------------------------------------------
#  Three command line arguments are sent - process the second and carry on
#----------------------------------------------------------------------------
if [ $3 ]; then
  if [ $2 == "-e" ]; then
    exclude_dir=""
    if [ "$3" ]; then
      exclude_dir="$3"
    fi
    extract_hierarchy $1
  else
    print_usage
  fi

#---------------------------------------------------------------------
#  One command line argument is sent - must be the module name
#  Use the names without extension - say Grid_Mod, Convert_Mod ...
#---------------------------------------------------------------------
elif [ $1 ]; then
  extract_hierarchy $1

#-----------------------------------------------------------------------
#  Wrong number of command line argument is sent - describe the usage
#-----------------------------------------------------------------------
else
  print_usage
fi

