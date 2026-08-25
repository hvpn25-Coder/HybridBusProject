function SummaryTable = postprocess_hybrid_bus_results(Results)
%POSTPROCESS_HYBRID_BUS_RESULTS Convert scalar summary values to a table.
SummaryTable=struct2table(Results.Summary,'AsArray',true);
end

