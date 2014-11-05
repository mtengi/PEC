Princeton Election Consortium
==

Basic Senate 2014 Technical Rundown
--

The code for PEC is housed in several directories, one for each type of code.
Several times per day, the cron daemon runs bin/nightly.sh to generate the
output which is shown on the site for that day. The first step is to get the
most recent polls from Huffington Post by calling python/update_polls.py. (We
also get polling data for Obama and the House, and this is handled separately
from the Senate data,) We then switch to the matlab/ directory and run
Senate_runner.m and Obama_House_runner.m to process the polling data and
produce the graphics. These are run with Xvfb, the X virtual framebuffer,
acting as the X server. MATLAB needs an X server in order to render the grphics
correctly, but the election server is headless and doesn't have an X server
running. Hence, the virtual framebuffer is used. After the MATLAB runs, we
switch back to the python/ directory to run current_senate.py and
jerseyvotes.py to generate the top banner and sidebar content, respectively.
Finally, we move the generated html and graphics to the autotext/ and
autographics/ directories, respectively, where WordPress finds them and
includes them in the page. There is also an output/ directory that contains all
of the generated output for the day in one place.
