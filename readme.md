Princeton Election Consortium
==

Basic Senate 2014 Technical Rundown
--

The code for PEC is housed in several directories, one for each type of code.
Several times per day, the cron daemon runs bin/nightly.sh to generate the
output which is shown on the site for that day. The first step is to get the
new polls for the day by calling python/update_polls.py. We then get polling
data for Obama and the House, which is unrelated to the main Senate
operations. We then switch to the matlab/ directory and run Senate_runner.m
and Obama_House_runner.m. These are run with Xvfb, the X virtual framebuffer,
acting as the X server. MATLAB needs an X server in order to render the
grphics correctly, but the election server is headless and doesn't always have
an X server running. Hence, the virtual framebuffer is used. After the MATLAB
runs, we switch back to the python/ directory to run current_senate.py and
jerseyvotes.py to generate the top banner and sidebar content, respectively.
Finally, we move the generated html and graphics to the autotext/ and
autographics/ directories, respectively, where WordPress finds them. There is
also an output/ directory that contains all of the generated output for the
day in one place.
