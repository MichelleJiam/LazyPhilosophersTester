#!/usr/bin/env python3

import subprocess
import fcntl
import time
import os
import signal
import sys

if len(sys.argv) < 2:
	print("Please give command uWu")
	exit(1)

# === CHANGE THIS ===
command = sys.argv[1]
timeout = int(sys.argv[2]) if len(sys.argv) > 2 else 10
# === NO TOUCHY ===

# Vars
pipe = None
pid = 0

# Create datastream from demodulator
pipe = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True)

# Make subprocess non-blocking
fcntl.fcntl(pipe.stdout.fileno(), fcntl.F_SETFL, os.O_NONBLOCK)

time.sleep(1)

# If cannot open:
if pipe.poll() != None:
	print("Never started...")
	exit(1)
else:
	pid = pipe.pid
	print("PID: %s" % (pid))

# Do some counting
for x in range(0, timeout):
	print(timeout - x)
	if pipe.poll() != None:
		print("Died :(")
		exit(1)
	time.sleep(1)

# Kill dem!
if pipe != None:
	os.system("killall philo SIGTERM")
	pipe.kill()
	pipe = None

# STONKS!
print("Worked! :D")
