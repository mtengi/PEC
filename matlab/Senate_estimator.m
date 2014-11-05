%%%  Senate_estimator.m - a MATLAB script
%%%  Copyright 2008, 2014 by Samuel S.-H. Wang
%%%  Noncommercial-use-only license: 
%%%  You may use or modify this software, but only for noncommercial purposes. 
%%%  To seek a commercial-use license, contact the author at sswang@princeton.edu.

% Likelihood analysis of all possible outcomes of election based 
% on the meta-analytical methods of Prof. Sam Wang, Princeton University.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Senate_estimator.m
% 
% This script loads '2014.Senate.polls.median.txt' and generates or updates/replaces 4 CSV files:
% 
% Senate_estimates.csv
%    all in one line:
%    1 value - date of analysis
%    1 value - median_seats for Democrats/Independents (integer)
%    1 value - mean_seats for Democrats/Independents (round to 0.01)
%    1 value - Democratic/Independent control probability (round to 1%)
%    3 values - assigned (>95% prob) seats for each party (integers) and
%    uncertain
%    1 value - number of state polls used to make the estimates (integer)
%    1 value - +/-1 sigma CI for Democratic/Independent Senate seats (integers)
%    1 value - (calculated by Senate_metamargin and appended) the meta-margin
% 
% Another file, Senate_estimate_history, is updated with the same
% information as Senate_estimates.csv plus 1 value for the date.
%
% stateprobs.csv
%    An N-line file giving percentage probabilities for Dem/Ind win of the popular vote, state by state. 
%    Note that this is the same as the 2012 EV calculation, except 1 seat per race
%    The second field on each line is the current median polling margin.
%    The third field on each line is the two-letter postal abbreviation.
% 
% Senate_histogram.csv
%    A 100-line file giving the probability histogram of each seat-count outcome. Line 1 is 
%    the probability of party #1 (Democrats/Independents) getting 1 seat. Line 2 is 2 seat, and so on. 
%    Note that 0 seat is left out of this histogram for ease of indexing.
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This routine expects the global variables biaspct and analysisdate

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% Initialize variables %%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% polls.state=[
% 'AL,AK,AZ,AR,CA,CO,CT,DC,DE,FL,GA,HI,ID,IL,IN,IA,KS,KY,LA,ME,MD,MA,MI,MN,MS,MO,MT,NE,NV,NH,NJ,NM,NY,NC,ND,OH,OK,OR,PA,RI,SC,SD,TN,TX,UT,VT,VA,WA,WV,WI,WY '];
polls.state=['AK,AR,CO,GA,IA,KS,KY,LA,MI,MN,MS,MT,NC,NH,OR,SD,VA,WV ']; % 19 races
%1 AK Begich Sullivan
%2 AR Pryor Cotton
%3 CO Udall Gardner
%4 GA Nunn Kingston
%5 IA Braley Ernst
%6 KS Orman Roberts
%7 KY Grimes McConnell
%8 LA Landrieu Cassidy
%9 MI Peters Land
%10 MN Franken McFadden
%11 MS Childers Cochran
%12 MT Curtis Daines
%13 NC Hagan Tillis
%14 NH Shaheen Brown
%15 OR Merkley Wehby
%16 SD Weiland Rounds
%17 VA Warner Gillespie
%18 WV Tennant Capito
contested=[1 2 3 4 5 7 8 9 13]; % races in serious question
polls.EV=ones(1, length(polls.state)/3);
num_states=size(polls.EV,2);

assignedEV(3)=sum(polls.EV);
assignedEV(1)=41; assignedEV(2)=41; % these are the seats not up for election
Demsafe=assignedEV(1);
% 1=Dem, 2=GOP, 3=up for election
% checksum to make sure no double assignment or missed assignment
if (sum(assignedEV)~=100)
    warning('Warning: Senate seats do not sum to 100!')
    assignedEV
end

if ~exist('biaspct','var')
    biaspct=0;
end
forhistory=biaspct==0;

if ~exist('analysisdate','var')
    analysisdate=0;
end

if ~exist('metacalc','var')
    metacalc=1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% Load and parse polling data %%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
polldata=load('2014.Senate.polls.median.txt');
% column 1 - numpolls
% column 2 - lastdate
% column 3 - median margin
% column 4 - SEM 
% column 5 - date of monitoring
% column 6 - state index
% column 7 (not implemented yet)
% column 8 (not implemented yet)

numlines = size(polldata,1);
if mod(numlines,num_states)>0
    warning('Warning: polls.median.2014Senate.txt is not a multiple of num_states lines long');
end
% Currently we are using median and effective SEM of the last 3 polls.
% To de-emphasize extreme outliers, in place of SD we use (median absolute deviation)/0.6745

% find the desired data within the file
if analysisdate>0 && numlines>num_states
    foo=find(polldata(:,5)==analysisdate,1,'first'); % find the start of the entry matching analysisdate
 %   ind=min([size(polldata,1)-num_states+1 foo']);
    foo2=find(polldata(:,5)==max(polldata(:,5)),1,'first'); % find the start of the freshest entry
    ind=max([foo2 foo]); %assume reverse time order, take whichever of the two was done earlier, also protect against no data for analysisdate
    polldata=polldata(ind:ind+num_states-1,:);
    clear foo2 foo ind
elseif numlines>num_states
%    polldata = polldata(numlines-num_states+1:numlines,:); % end of file
    polldata = polldata(1:num_states,:); % top of file
end

% hard-code Orman lead until HuffPost (and ballot format) are stable
% polldata(6,3)=median([5 0 10 7 5 -1 -5]); polldata(6,4)=mad([5 0 10 7 5 -1 -5],1)/sqrt(7)/0.6745; % decommissioned on 10 Oct 2014. 
% force Montana while we wait for polls
polldata(12,3)=-19; polldata(12,4)=6;

% Use statistics from data file
polls.margin=polldata(:,3)';
polls.SEM=polldata(:,4)';
polls.SEM=max(polls.SEM,zeros(1,num_states)+2) % minimum uncertainty of 2%
totalpollsused=sum(polldata(:,1))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%% Where the magic happens! %%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Senate_median
stateprobs
Dcontrolprobs(1)=D_Senate_control_probability;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% Plot the histogram %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
close
phandle=plot([49.5 49.5],[0 max(histogram)*105],'-r','LineWidth',1.5);
EVticks=200:20:380;
grid on
hold on
%
% now plot snapshot histogram
%
bar(Senateseats(3:8),histogram(3:8)*100,'r')
bar(Senateseats(9:14),histogram(9:14)*100,'b')
obar=find(Senateseats==50); %Orman factor
bar(Senateseats(obar),histogram(obar)*stateprobs(6),'g')
axis([Senateseats(3)-0.5 Senateseats(14)+0.5 0 max(histogram)*105])
xlabel('Democratic+Independent Senate seats','FontSize',14);
ylabel('Probability (%)','FontSize',14)
set(gcf, 'InvertHardCopy', 'off');
title('Distribution of all possible outcomes','FontSize',14)

Dstr=['D control: ',num2str(round(D_Senate_control_probability*100)),'%'];
Rstr=['R control: ',num2str(round(R_Senate_control_probability*100)),'%'];
% text(Senateseats(3)-0.35,max(histogram)*99,Rstr,'FontSize',18)
% text(Senateseats(13)-2.3,max(histogram)*99,Dstr,'FontSize',18)
if analysisdate==0
    datelabel=datestr(now);
else
    datelabel=datestr(analysisdate);
end
text(43.6,max(histogram)*92,datelabel(1:6),'FontSize',12)
text(43.6,max(histogram)*86,'election.princeton.edu','FontSize',12)
if biaspct==0
%    set(gcf,'PaperPositionMode','auto')
    print -djpeg EV_histogram_today.jpg
end
%
% end plot
%

%
%    Start calculating some outputs
%
confidenceintervals(3)=Senateseats(find(cumulative_prob<=0.025,1,'last')); % 95-pct lower limit
confidenceintervals(1)=Senateseats(find(cumulative_prob<=0.15865,1,'last')); % 1-sigma lower limit
confidenceintervals(2)=Senateseats(find(cumulative_prob>=0.84135,1,'first')); % 1-sigma upper limit
confidenceintervals(4)=Senateseats(find(cumulative_prob>=0.975,1,'first')); % 95-pct upper limit

% Re-calculate safe EV for each party
assignedEV(1)=assignedEV(1)+sum(polls.EV(find(stateprobs>=95)));
assignedEV(2)=assignedEV(2)+sum(polls.EV(find(stateprobs<=5)));
assignedEV(3)=100-assignedEV(1)-assignedEV(2);

uncertain=intersect(find(stateprobs<95),find(stateprobs>5));
uncertainstates='';
for i=1:max(size(uncertain))
    uncertainstates=[uncertainstates statename2(uncertain(i),polls.state) ' '];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% Daily file update %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% These are files that are based on a pure polling snapshot.
% Only write histogram and statewise probabilities if biaspct==0
%
%    1 value - date of analysis
%    1 value - median_seats for Democrats/Independents (integer)
%    1 value - mean_seats for Democrats/Independents (round to 0.01)
%    1 value - Democratic/Independent control probability (round to 1%)
%    3 values - assigned (>95% prob) seats for each party (integers) and
%    uncertain
%    1 value - number of state polls used to make the estimates (integer)
%    1 value - +/-1 sigma CI for Democratic/Independent Senate seats (integers)
%    1 value - (calculated by Senate_metamargin and appended) the meta-margin
%    1 value - mean margin in contested states
% 
outputs=[median_seats mean_seats Dcontrolprobs assignedEV totalpollsused confidenceintervals(1:2) mean(polldata(contested,3))];    

if biaspct==0
%   Export probability histogram:
    dlmwrite('Senate_histogram.csv',histogram')
%   Export state-by-state percentage probabilities as CSV, with 2-letter state abbreviations:
%   Each line includes hypothetical probabilities for D+2% and R+2% biases
%   Also give margin
    if exist('stateprobs.csv','file')
        delete('stateprobs.csv')
    end
    
% old calculation, purely a snapshot with drift, used until October 11:
%    foo=(polls.margin)./sqrt(polls.SEM.^2+25);
%    statenovprobs=round((erf(foo/sqrt(2))+1)*50);
%    foo=(polls.margin+2)./polls.SEM;
%    D2probs=round((erf(foo/sqrt(2))+1)*50);
%    foo=(polls.margin-2)./polls.SEM;
%    R2probs=round((erf(foo/sqrt(2))+1)*50);

% NEW CALCULATION OF NOVEMBER PROBABILITIES - OCTOBER 12 BY SAM    
    sep_oct_margins=[-5 -4 -1 -2 0 5 -4.5 -3 7 8 -14 -20 3 6 13 -10 12 -23]; % hardcode margins. could softcode it, but why with so little time left?
    h=datenum('04-Nov-2014')-today; % days until election (note: November 4 is Julian 309)
    maxdrift=5; 
    systematic=2; % from 2010 and 2012 performance; with 3 d.f. gives 67% for margin of 1%, 91% for margin of 2%, OK. Also 18.5/21 correct, matching record of 19/21
    if and(h<=35,h>0) % election is soon, so combine current and long-term
        novmargins=(sep_oct_margins*h+polls.margin*(35-h))/35; % weighted average
        drift=h/35*maxdrift;
        novsem=sqrt(drift^2+systematic^2); %ignore state-by-state SEM, too small
    else % election is far off, so use the long-term prediction
        novmargins=polls.margin;
        novsem=sqrt(maxdrift^2+systematic^2);  %ignore state-by-state SEM, too small
    end
    foo=novmargins/novsem; % foo is the November z-score
    statenovprobs=round(tcdf(foo,3)*100);
    foo=(novmargins+2)/novsem;
    D2probs=round(tcdf(foo,3)*100);
    foo=(novmargins-2)/novsem;
    R2probs=round(tcdf(foo,3)*100);
% END CALCULATION OF NOVEMBER PROBABILITIES - OCTOBER 12 BY SAM

% column 1: Today's snapshot D win probability
% column 2: November D win probability
% column 3: median margin (positive indicates D is front-runner)
% column 4: November win probability adding 2% to margin for D
% column 5: November win probability adding 2% to margin for R
% column 6: Two-letter postal abbreviation of state
for ii=1:num_states
        foo=[num2str(stateprobs(ii)) ',' num2str(statenovprobs(ii)) ',' num2str(polls.margin(ii)) ',' num2str(D2probs(ii)) ',' num2str(R2probs(ii)) ',' statename2(ii,polls.state)];
        dlmwrite('stateprobs.csv',foo,'-append','delimiter','')
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%% The meta-margin %%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

reality=1-Dcontrolprobs(1);

if metacalc==0
    metamargin=-999;
else
    foo=biaspct;
    biaspct=-7; % just brute force - might have to change this guess later
    Senate_median
    while median_seats < 50
        biaspct=biaspct+.02;
        Senate_median
    end
    metamargin=-biaspct
    biaspct=foo; 
    clear foo
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% Daily and History Update %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
outputs = [outputs metamargin];
dlmwrite('Senate_estimates.csv', outputs) % just today's estimate
if forhistory
   dlmwrite('Senate_estimate_history.csv',[polldata(1,5) outputs],'-append')
end
