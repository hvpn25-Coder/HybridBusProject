function [displayTime,axisLabel,tickFormat] = scale_time_for_display(time_s)
%SCALE_TIME_FOR_DISPLAY Select a human-readable simulation time unit.
arguments
    time_s (:,1) double {mustBeFinite,mustBeNonnegative}
end

duration_s=max(time_s)-min(time_s);
if duration_s>=2*3600
    displayTime=time_s/3600;
    axisLabel='Time (h)';
    tickFormat='%.1f';
else
    displayTime=time_s/60;
    axisLabel='Time (min)';
    tickFormat='%.0f';
end
end
