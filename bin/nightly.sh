#!/bin/sh

############################################################################
#
# This script is run several times per day by the Unix cron daemon to
# update the site. It first uses the Python update_polls.py script to
# prepare the summary statistics which are used by the MATLAB scripts it
# calls next. Then, it updates the automatically generated text and graphics
# which display the calculations using additional Python scripts.
#
# Author: Mark Tengi <markat@princeton.edu>
# Originally by: Andrew Ferguson <adferguson@alumni.princeton.edu>
#
# Script written for election.princeton.edu run by Samuel S.-H. Wang under
# noncommercial-use-only license:
# You may use or modify this software, but only for noncommericial purposes.
# To seek a commercial-use license, contact sswang@princeton.edu
#
############################################################################

# For debugging cron issues
/bin/date

POLLS=2014.Senate.polls.median.txt 

cd /web/python/
./update_polls.py

# Auxiliary stuff
wget http://elections.huffingtonpost.com/pollster/obama-job-approval.csv
wget http://elections.huffingtonpost.com/pollster/2014-national-house-race.csv
python convert_huffpost_csv.py obama-job-approval.csv obama_approval_matlab.csv pollsters.p
python convert_huffpost_csv.py 2014-national-house-race.csv house_race_matlab.csv pollsters.p
mv obama-job-approval.csv archive/
mv 2014-national-house-race.csv archive/
mv obama_approval_matlab.csv ../matlab/
mv house_race_matlab.csv ../matlab/
cd ..

cp -f python/$POLLS matlab/

cd matlab/

# If this has already run today, trim off the last line
HISTORY=Senate_estimate_history.csv
if cat $HISTORY | grep -e ^`date +%j`
then
mv $HISTORY SEH.tmp
head -n -1 SEH.tmp > $HISTORY
rm -f SEH.tmp
fi

# Use Xvfb to appease MATLAB -- graphics won't render correctly without
# an X display
echo 'Starting Xvfb'
XVFB_DISPLAY=99
Xvfb :$XVFB_DISPLAY -screen 0 1280x1024x24 &
XVFB_PID=$!
export DISPLAY=:$XVFB_DISPLAY
echo 'Running MATLAB'
matlab -r Senate_runner

matlab -r Obama_House_runner
echo "Killing Xvfb with PID $XVFB_PID"
kill $XVFB_PID
cd ..

cd python/
echo 'Running final Python stuff'
./current_senate.py
./jerseyvotes.py

./stateprobs.py
cd ..

echo 'Moving output'

cp -f python/*.html autotext/
mv -f python/*.html output/
mv -f python/*.txt output/

cp -f matlab/*.jpg autographics/
mv -f matlab/*.jpg output/
mv -f matlab/*.csv output/
cp output/Senate_estimate_history.csv matlab/ # put this back -- it's needed for next time
#chmod a+r autotext/*
#chmod a+r autographics/*

# For debugging cron issues
/bin/date
