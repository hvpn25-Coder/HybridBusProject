function [displayX,axisLabel,tickFormat] = select_plot_x_axis(time_s,distance_m,mode)
%SELECT_PLOT_X_AXIS Select time or distance for app signal plots.
arguments
    time_s (:,1) double {mustBeFinite,mustBeNonnegative}
    distance_m (:,1) double {mustBeFinite,mustBeNonnegative}
    mode (1,1) string {mustBeMember(mode,["Time","Distance"])}
end
assert(numel(time_s)==numel(distance_m),'HybridBus:PlotXAxisSize', ...
    'Time and distance vectors must have the same number of samples.');

if mode=="Time"
    [displayX,axisLabel,tickFormat]=scale_time_for_display(time_s);
else
    displayX=distance_m/1000;
    axisLabel='Distance (km)';
    if max(displayX)>=100
        tickFormat='%.0f';
    else
        tickFormat='%.1f';
    end
end
end
