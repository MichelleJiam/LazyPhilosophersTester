#!/bin/bash

# Colours
BOLD="\033[0;1m"
RED="\033[0;31m"
CYAN="\033[0;36m"
PURP="\033[0;35m"
GREEN="\033[0;32m"
BLUE="\033[0;34m"
BLUEBG="\033[44m"
WHITE="\033[1;97m"
RESET="\033[0m"

# Counters
PASS=0
FAIL=0
TESTS=0

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

PROGRESS_BAR_WIDTH=50  # progress bar length in characters

draw_progress_bar() {
  # Arguments: current value, max value, unit of measurement (optional)
  local __value=$1
  local __max=$2
  local __unit=${3:-""}	# if unit is not supplied, do not display it

  # Calculate percentage
  if (( $__max < 1 )); then __max=1; fi # anti zero division protection
  local __percentage=$(( 100 - ($__max*100 - $__value*100) / $__max ))

  # Rescale the bar according to the progress bar width
  local __num_bar=$(( $__percentage * $PROGRESS_BAR_WIDTH / 100 ))

  # Draw progress bar
  printf "["
  for b in $(seq 1 $__num_bar); do printf "#"; done
  for s in $(seq 1 $(( $PROGRESS_BAR_WIDTH - $__num_bar ))); do printf " "; done
  printf "] $__percentage%% ($__value / $__max $__unit)\r"
}

die_test () {
	printf "\n${CYAN}=== Starting tests where program should end with death or enough eaten ===\n${RESET}"
	while IFS="" read -r -u 3 input || [ -n "$input" ]	# read input from fd 3
	do
		read -r -u 3 result	# read desired result description from input.txt
		printf "\nTest: ${BLUEBG}${WHITE}[$input]${RESET} | ${PURP}$result${RESET}\n\n"	
		read -rs -n 1 -p $'Press ENTER to start test, press any other key to exit tester...\n' key  # read from stdin, accepting only 1 char
		if [[ $key == "" ]] ; then
			printf "\n"
			$1 $input	# run ./philo with test case input
		else
			exit 0
		fi
	done 3< ./yes-die.txt   # open file is assigned fd 3
	exec 3<&-	# close fd 3
}

no_die_test () {
	printf "\n${CYAN}=== Starting tests where a philosopher should NOT die ===\n${RESET}"
	read -r -p $'\nPlease enter desired timer for tests or press ENTER to use default 10 seconds: ' timeout
	printf "\n"
	if [[ $timeout != *[[:digit:]]* ]]; then
		timeout=10
	fi
	while IFS="" read -r -u 3 input || [ -n "$input" ] # read input from fd 3
	do
		read -r -u 3 result    # read desired result description from input.txt
		printf "\nTest: ${BLUEBG}${WHITE}[$input]${RESET} | ${PURP}$result${RESET}\n\n"
		read -rs -n 1 -p $'Press ENTER to start test, press any other key to exit tester...\n' key   # read from stdin, accepting only 1 char
		if [[ $key == "" ]] ; then
			printf "\n"
			./PhilosophersChecker.py "$1 $input" $timeout > /dev/null & pid=$!   # silence checker output and run in bg
			local elapsed=0
			while ps -p $pid &>/dev/null; do    # check if checker script still running
				draw_progress_bar $elapsed $timeout "seconds" # TODO: fix extra space at end of progress bar, extra )
				if [[ $elapsed == $timeout ]]; then
					printf "\n\n${GREEN}OK${RESET}\n"
					(( PASS++ ))
					break;
				fi
				(( elapsed++ ))
				sleep 1
			done
			wait $pid
			status=$?
			if [[ $status != 0 ]]; then
				printf "\n\n${RED}KO${RESET} - program terminated prematurely\n"
				(( FAIL++ ))
			fi
		else
			printf "\n${GREEN}PASSED${RESET}: $PASS/$TESTS | ${RED}FAILED${RESET}: $FAIL/$TESTS\n"
			exit 0
		fi
		(( TESTS++ ))
	done 3< ./no-die.txt   # open file is assigned fd 3
	printf "\nNo-Die Tests: ${GREEN}PASSED${RESET}: $PASS/$TESTS | ${RED}FAILED${RESET}: $FAIL/$TESTS\n"
	exec 3<&-	# close fd 3
}

choose_test () {
	read -r -n 1 -p $'\nChoose test to run:\n\t[0] all tests\n\t[1] die tests\n\t[2] no-die tests (can take a while)\n\t[ESC] exit tester\n\n' choice
	printf "\n"
	case $choice in
		0)
			die_test "$1"
			no_die_test "$1"
			;;
		1)
			die_test "$1"
			;;
		2)
			no_die_test "$1"
			;;
		$'\e')	# ESC key
			exit 0
			;;
		*)
			printf "${RED}Invalid choice\n${RESET}"
			choose_test	"$1" # reprompt
			;;
	esac
}

printf "${BOLD}\n💭 The Lazy Philosophers Tester 💭\n${RESET}"
printf "\nThis tester allows you to test:\n\n"
printf "\t1. when your program should stop on death or when all philos have eaten enough\n"
printf "\t- to be checked manually by the user, based on the expected result listed in yes-die.txt.\n\n"
printf "\t2. when no philosophers should die\n"
printf "\t- this is checked automatically if the program runs for x seconds (default 10) without death.\n"
choose_test "$1"