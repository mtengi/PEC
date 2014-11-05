%LIBGL_DEBUG='verbose'
pdata=csvread('house_race_matlab.csv');

clear foo
foo(:,1)=(pdata(:,2)+pdata(:,3))/2-datenum('31-dec-2013'); %midpoint dates
foo(:,2)=pdata(:,3)-datenum('31-dec-2013'); %ebd dates
foo(:,3)=pdata(:,6)-pdata(:,7); %margins
foo(:,4)=pdata(:,1); %pollster ID numbers
[foo2,inds]=sort(foo(:,1),1,'descend'); % going to sort by midpoint date

middates=foo(inds,1);
enddates=foo(inds,2);
margins=foo(inds,3);
pollsters=foo(inds,4);

tod=today-datenum('31-dec-2013'); % Julian date this year
Nback=21; %days back to look

% for a given date
dstart=-150; dfinish=tod; d=dstart:dfinish;

for id=1:length(d)
    %   first, find polls meeting date criterion
    iNback=intersect(find(enddates>=d(id)-Nback),find(enddates<=d(id)));
    %   then clean these up for pollster-ID
    [c,ia,ic]=unique(pollsters(iNback),'first');
    iNback=iNback(ia);
    %
    %   second, find last 3 polls from different pollsters
    iback3=min(find(middates<=d(id)));
    iback3=iback3:min(iback3+19,length(middates)); % last 20 (if it requires more, blech)
    [c,ia,ic]=unique(pollsters(iback3),'first');
    iback3=iback3(ia); %   take uniques
    iback3=iback3(1:min(3,length(iback3))); % last 3 or less
    %
    %   union of these two groups
    iback=union(iNback,iback3);
    %
    %   then calculate descriptive statistics
    pmedian(id)=median(margins(iback));
    psem(id)=mad(margins(iback),1)/sqrt(length(iback))/0.6745;
end

close
phandle=plot(d(length(d):-7:6),pmedian(length(d):-7:6),'-k','LineWidth',2)
hold on
axis([-120 330 -8 8])
%plot(enddates,margins,'.r')
grid on
plot([-120 330],[4.5 4.5],'-g'); % http://www.theguardian.com/commentisfree/2013/oct/17/democrats-winning-house-2014-midterms
plot([-120 330],[1.2 1.2],'-b')
plot([-120 330],[-6.8 -6.8],'-b')
[max(d) mean(pmedian(find(d>=1))) std(pmedian(find(d>=1)))]

% omedian=pmedian;oSEM=psem;od=d;

hmedian=pmedian;hSEM=psem;hd=d;

firsts=datenum(0,[1:12],1);
firsts=[firsts-365 firsts];
set(gca,'XTick',firsts)
set(gca,'XTickLabel',{'        Jan','        Feb','        Mar','        Apr','        May','        Jun','        Jul','       Aug','        Sep','        Oct','        Nov','        Dec'})
ylabel('2014 Congressional D-R poll margin (%)')
xlabel('2013                                               2014                      ')
text(170,-7.3,'election.princeton.edu','FontSize',12)
text(190,5.0,'Likely Dem control','FontSize',12)
text(190,4.0,'Likely GOP control','FontSize',12)
text(-105,0.8,'\color{blue}2012 vote','FontSize',10)
text(-105,-6.4,'\color{blue}2010 vote','FontSize',10)
set(gcf, 'InvertHardCopy', 'off');
title('House generic Congressional preference, 2014','FontSize',14)


csvwrite('House_median_history.csv',[d pmedian psem])
%set(gcf,'PaperPositionMode','auto')
print -djpeg House_generic_history.jpg
%close
