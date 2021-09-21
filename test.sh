#!/bin/bash

# COLORS
BOLD="\033[0;1m"
RED="\033[0;31m"
CYAN="\033[0;36m"
PURP="\033[0;35m"
GREEN="\033[0;72m"
BLUE="\033[0;34m"
BLUEBG="\033[44m"
WHITE="\033[1;97m"
RESET="\033[0m"

# checks params. If none given, assumes philo executable is in same directory as tester directory.
if [ "$#" -gt 1 ]; then
    printf "Too many parameters. Please only provide path to philo executable.\n"
    exit
elif [ "$#"  -lt 1 ]; then
    set $1 ../philo
fi

# checks if given executable path and file is valid.
if [ ! -f "$1" ]; then
    printf "$1 not found or invalid file. Please (re)make philo executable first.\n"
    exit
fi

die_test () {
    printf "\n${CYAN}=== Starting tests where a philosopher should die ===\n${RESET}"
    while IFS="" read -u 3 input || [ -n "$input" ] # read input from fd 3
    do
        read -u 3 result # read desired result description from input.txt
        printf "\nTest: ${BLUEBG}${WHITE}[$input]${RESET} | ${PURP}$result${RESET}\n\n"
        read -s -n 1 -p $'Press ENTER to start test, press any other key to exit tester...\n' KEY  # read from stdin, accepting only 1 char
        if [[ $KEY == "" ]] ; then
            printf "\n"
            $1 $input
        else
            exit 0
        fi
    done 3< ./yes-die.txt   # open file is assigned fd 3
    exec 3<&-
}

no_die_test () {
    printf "\n${CYAN}=== Starting tests where a philosopher should NOT die ===\n${RESET}"
    while IFS="" read -u 3 input || [ -n "$input" ] # read input from fd 3
    do
        read -u 3 result # read desired result description from input.txt
        printf "\nTest: ${BLUEBG}${WHITE}[$input]${RESET} | ${PURP}$result${RESET}\n\n"
        read -s -n 1 -p $'Press ENTER to start test, press any other key to exit tester...\n' KEY  # read from stdin, accepting only 1 char
        if [[ $KEY == "" ]] ; then
            printf "\n"
            printf "bleep bloop\n"
        else
            exit 0
        fi
    done 3< ./no-die.txt   # open file is assigned fd 3
}

choose_test () {
    read -s -n 1 -p $'\nChoose test to run:\n\t[0] all tests\n\t[1] die tests\n\t[2] no-die tests\n\t[ESC] exit tester\n' CHOICE
    case $CHOICE in
        0)
            die_test $1
            no_die_test $1
            ;;
        1)
            die_test $1
            ;;
        2)
            no_die_test $1
            ;;
        $'\e')
            exit 0
            ;;
        *)
            printf "${RED}Invalid choice\n${RESET}"
            choose_test
            ;;
    esac
}

printf "${BOLD}\n💭 The Lazy Philosophers Tester 💭\n${RESET}"
choose_test $1