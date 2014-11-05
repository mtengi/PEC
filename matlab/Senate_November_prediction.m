Senate_history=load('Senate_estimate_history.csv');
d=Senate_history(:,1);
mm=Senate_history(:,12);

if today>=datenum('03-Sep-2014')
    O_fraction=(today-datenum('01-Sep-2014'))/(today-datenum('31-May-2014'));
    Orman_offset=0.47*(1-O_fraction);
else
    Orman_offset=0
end
% Orman offset is the shift in Meta-Margin caused by Kansas change
% An offset of 0.47 assumes a tie in KS-Sen on Election Day
% An offset of 0.83 assumes Orman leads by 1 sigma on Election Day
% calculated by Sam Wang based on June-September 2014 polls

systematic=2.5; % Guess at systematic error this year

blackswanfactor=1; % a 30% probability of >2 sigma event; allows the fundamentals-type argument

%%%%% Calculate November prediction based on Meta-Margin history
[C,IA,IC] = unique(d,'stable'); % Find unique entries in the history
mean_mm=mean(mm(IA(find(d(IA)>=153))))+Orman_offset; % This is the long-term prediction...
sd_mm=std(mm(IA(find(d(IA)>=153)))); % ...based on data after June 1 (Julian 153)
sd_mm=sqrt(sd_mm*sd_mm+Orman_offset*(1-Orman_offset)); % stuff happens between now and November
h=datenum('04-Nov-2014')-today; % days until election (note: November 4, Julian 309)

if and(h<=35,h>=0) % election is soon, so combine current and long-term
    blackswanfactor=2;
    current_mm=mm(max(find(d==max(d)))); % Find the most recent Meta-Margin
    predicted_mm=mean_mm*(1-sqrt(1-h/35))+current_mm*sqrt(1-h/35); %random walk-like
    predicted_sd=sqrt((sd_mm*h/35)^2+systematic^2);
    D_November_control_probability = 100*tcdf(predicted_mm/predicted_sd,blackswanfactor) 
else % election is far off, so use the long-term prediction
    predicted_mm=mean_mm;
    predicted_sd=sqrt(sd_mm^2+systematic^2);
    D_November_control_probability = 100*tcdf((mean_mm)/predicted_sd,blackswanfactor) 
end
dlmwrite('Senate_D_November_control_probability.csv',[today-datenum('31-Dec-2013') D_November_control_probability predicted_mm])
%%%%% end November prediction calculation