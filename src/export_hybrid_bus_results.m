function files = export_hybrid_bus_results(Results,resultsFolder)
%EXPORT_HYBRID_BUS_RESULTS Save complete MAT result plus summary CSV.
arguments
    Results (1,1) struct
    resultsFolder (1,1) string = fullfile(hybrid_bus_project_root(),"results")
end
if ~isfolder(resultsFolder), mkdir(resultsFolder); end
stamp=string(datetime('now','Format','yyyyMMdd_HHmmss_SSS'));
matFile=fullfile(resultsFolder,"HybridBus_Results_"+stamp+".mat");
csvFile=fullfile(resultsFolder,"HybridBus_Summary_"+stamp+".csv");
save(matFile,'Results','-v7.3');
writetable(postprocess_hybrid_bus_results(Results),csvFile);
files=struct('MAT',matFile,'CSV',csvFile);
end
