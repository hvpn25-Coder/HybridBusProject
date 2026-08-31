function files=write_genset_m_files(componentFolder,gensetCatalog,engineCatalog, ...
        generatorCatalog,engineFuelMap,generatorEfficiencyMap)
%WRITE_GENSET_M_FILES Store each complete genset assembly in one MATLAB script.
arguments
    componentFolder (1,1) string
    gensetCatalog table
    engineCatalog table
    generatorCatalog table
    engineFuelMap table
    generatorEfficiencyMap table
end

assert(height(gensetCatalog)==height(engineCatalog) && ...
    height(gensetCatalog)==height(generatorCatalog), ...
    'HybridBus:GensetCatalogSize', ...
    'Genset, engine, and generator catalogs must have matching row counts.');
if ~isfolder(componentFolder),mkdir(componentFolder);end

files=strings(height(gensetCatalog),1);
for index=1:height(gensetCatalog)
    gensetID=string(gensetCatalog.ComponentID(index));
    validateComponentID(gensetID,"genset");
    engineRow=engineCatalog(index,:);
    generatorRow=generatorCatalog(index,:);
    validateComponentID(string(engineRow.ComponentID),"engine");
    validateComponentID(string(generatorRow.ComponentID),"generator");
    optimumLoad=min(0.9,max(0.4,gensetCatalog.OptimumPower_kW(index)/ ...
        gensetCatalog.MaxPower_kW(index)));
    assemblyFuelMap=engineMapForAssembly(engineFuelMap,engineRow,optimumLoad);
    assemblyGeneratorMap=generatorMapForAssembly( ...
        generatorEfficiencyMap,generatorRow,optimumLoad);

    safeName=regexprep(gensetID,'[^A-Za-z0-9_]','_');
    files(index)=fullfile(componentFolder,safeName+'.m');
    lines=[ ...
        "% "+gensetID+" — complete engine-generator set data"; ...
        "% One self-contained record: genset, engine, generator, and performance maps."; ...
        "GensetData=struct;"; ...
        "GensetData.SchemaVersion=""1.0.0"";"; ...
        "GensetData.StorageOrder="+index+";"; ...
        "GensetData.Genset=struct;"];
    lines=appendStruct(lines,"GensetData.Genset",gensetCatalog(index,:));
    lines(end+1)="GensetData.Engine=struct;"; %#ok<AGROW>
    lines=appendStruct(lines,"GensetData.Engine",engineRow);
    lines(end+1)="GensetData.Generator=struct;"; %#ok<AGROW>
    lines=appendStruct(lines,"GensetData.Generator",generatorRow);
    lines=[lines;tableLiteral("GensetData.EngineFuelMap",assemblyFuelMap); ...
        tableLiteral("GensetData.GeneratorEfficiencyMap",assemblyGeneratorMap)]; %#ok<AGROW>
    writelines(lines,files(index));
end


function validateComponentID(id,componentType)
assert(~isempty(regexp(id,'^[A-Za-z][A-Za-z0-9._-]*$','once')), ...
    'HybridBus:ComponentID', ...
    'Invalid %s ComponentID %s. Use letters, digits, dot, underscore, or hyphen.', ...
    componentType,id);
end
end

function map=engineMapForAssembly(template,engine,optimumLoad)
load=unique([template.NormalizedEngineLoad;optimumLoad]);
low=engine.LowLoadBSFC_g_kWh; best=engine.BestBSFC_g_kWh;
high=engine.HighLoadBSFC_g_kWh;
zeroLoad=low+0.35*(high-low);
bsfc=interp1([0;0.2;optimumLoad;1],[zeroLoad;low;best;high],load,'pchip');
map=table(load,bsfc,'VariableNames',{'NormalizedEngineLoad','BSFC_g_kWh'});
end

function map=generatorMapForAssembly(template,generator,optimumLoad)
load=unique([template.NormalizedGeneratorLoad;optimumLoad]);
low=generator.LowLoadEfficiency; peak=generator.PeakEfficiency;
zeroLoad=max(0.70,low-0.05); fullLoad=max(low,peak-0.01);
efficiency=interp1([0;0.2;optimumLoad;1], ...
    [zeroLoad;low;peak;fullLoad],load,'pchip');
map=table(load,efficiency, ...
    'VariableNames',{'NormalizedGeneratorLoad','Efficiency'});
end

function lines=appendStruct(lines,target,row)
for column=1:width(row)
    field=string(row.Properties.VariableNames{column});
    value=row{1,column};
    if iscell(value),value=value{1};end
    lines(end+1)=target+"."+field+"="+matlabLiteral(value)+";"; %#ok<AGROW>
end
end

function lines=tableLiteral(target,source)
assert(width(source)==2 && all(varfun(@isnumeric,source,'OutputFormat','uniform')), ...
    'HybridBus:GensetMapSchema','Genset performance maps must have two numeric columns.');
names=string(source.Properties.VariableNames);
first=vectorLiteral(source{:,1}); second=vectorLiteral(source{:,2});
lines=[target+"=table( ..."; ...
    "    "+first+", ..."; ...
    "    "+second+", ..."; ...
    "    'VariableNames',{'"+names(1)+"','"+names(2)+"'});" ];
end

function literal=vectorLiteral(value)
items=arrayfun(@(x)string(sprintf('%.15g',x)),value(:));
literal="["+join(items,";")+"]";
end

function literal=matlabLiteral(value)
if isstring(value) || ischar(value)
    quote=string(char(34));
    text=replace(string(value),quote,quote+quote);
    literal=""""+text+"""";
elseif islogical(value)
    literal=string(mat2str(value));
elseif isnumeric(value) && isscalar(value)
    literal=string(sprintf('%.15g',value));
else
    error('HybridBus:GensetMValue','Unsupported genset data type %s.',class(value));
end
end
