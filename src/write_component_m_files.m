function files=write_component_m_files(componentFolder,catalog,componentType)
%WRITE_COMPONENT_M_FILES Store each catalog row as one MATLAB data script.
arguments
    componentFolder (1,1) string
    catalog table
    componentType (1,1) string {mustBeMember(componentType,["Battery","Motor"])}
end

if ~isfolder(componentFolder),mkdir(componentFolder);end

dataVariable=componentType+"Data";
files=strings(height(catalog),1);
for index=1:height(catalog)
    componentID=string(catalog.ComponentID(index));
    validateComponentID(componentID);
    safeName=regexprep(componentID,'[^A-Za-z0-9_]','_');
    files(index)=fullfile(componentFolder,safeName+'.m');
    schemaVersion="1.0.0";
    if componentType=="Battery",schemaVersion="4.0.0";end
    if componentType=="Motor",schemaVersion="2.0.0";end
    lines=[ ...
        "% "+componentID+" — generated "+lower(componentType)+" component data"; ...
        dataVariable+"=struct;"; ...
        dataVariable+".SchemaVersion="""+schemaVersion+""";"; ...
        dataVariable+".StorageOrder="+index+";"; ...
        dataVariable+".Component=struct;"];
    for column=1:width(catalog)
        field=string(catalog.Properties.VariableNames{column});
        value=catalog{index,column};
        if iscell(value),value=value{1};end
        lines(end+1)=dataVariable+".Component."+field+"="+matlabLiteral(value)+";"; %#ok<AGROW>
    end
    if componentType=="Battery"
        maps=batteryMaps(catalog(index,:));
        lines=[lines; ...
            "% Dynamic battery maps: rows are temperature, columns are SOE."; ...
            dataVariable+".SOEBreakpoints="+matrixLiteral(maps.SOEBreakpoints)+";"; ...
            dataVariable+".SOCBreakpoints="+matrixLiteral(maps.SOCBreakpoints)+";"; ...
            dataVariable+".TemperatureBreakpoints_C="+matrixLiteral(maps.TemperatureBreakpoints_C)+";"; ...
            dataVariable+".MaxDischargeCurrentMap_A="+matrixLiteral(maps.MaxDischargeCurrentMap_A)+";"; ...
            dataVariable+".MaxChargeCurrentMap_A="+matrixLiteral(maps.MaxChargeCurrentMap_A)+";"; ...
            dataVariable+".OpenCircuitVoltageMap_V="+matrixLiteral(maps.OpenCircuitVoltageMap_V)+";"; ...
            dataVariable+".InternalResistanceMap_Ohm="+matrixLiteral(maps.InternalResistanceMap_Ohm)+";"; ...
            dataVariable+".MapBasis=""Synthetic LFP current-limit, OCV, and resistance envelope; replace with supplier test data"";"]; %#ok<AGROW>
    elseif componentType=="Motor"
        maps=motorMaps(catalog(index,:));
        lines=[lines; ...
            "% Motor loss map: rows are speed, columns are absolute torque."; ...
            dataVariable+".TorqueBreakpoints_Nm="+matrixLiteral(maps.TorqueBreakpoints_Nm)+";"; ...
            dataVariable+".SpeedBreakpoints_rpm="+matrixLiteral(maps.SpeedBreakpoints_rpm)+";"; ...
            dataVariable+".MotorLossMap_kW="+matrixLiteral(maps.MotorLossMap_kW)+";"; ...
            dataVariable+".MapBasis=""Synthetic per-motor electromagnetic, copper, iron, and mechanical loss envelope; replace with dynamometer data"";"]; %#ok<AGROW>
    end
    writelines(lines,files(index));
end


function validateComponentID(id)
assert(~isempty(regexp(id,'^[A-Za-z][A-Za-z0-9._-]*$','once')), ...
    'HybridBus:ComponentID', ...
    'Invalid ComponentID %s. Use letters, digits, dot, underscore, or hyphen.',id);
end
end

function maps=batteryMaps(row)
soe=[0.10 0.20 0.30 0.50 0.70 0.85 0.95];
temperature=[-20 0 10 25 40 50];
dischargeSOE=[0.20 0.55 0.80 1.00 1.00 0.95 0.80];
dischargeTemperature=[0.35 0.65 0.85 1.00 0.95 0.80];
chargeSOE=[0.75 0.90 1.00 1.00 0.85 0.45 0.00];
chargeTemperature=[0.00 0.20 0.60 1.00 0.85 0.45];
resistanceSOE=[1.80 1.35 1.10 0.95 0.95 1.05 1.30];
resistanceTemperature=[2.20 1.50 1.20 1.00 0.95 1.05];
ocvSOEFraction=[0.22 0.34 0.43 0.53 0.62 0.72 0.80];
ocvTemperatureFraction=[-0.025 -0.012 -0.005 0.000 0.004 0.002];
referenceResistance=0.02*row.NominalVoltage_V/row.ReferenceDischargeCurrent_A;
ocv25=row.MinVoltage_V+(row.MaxVoltage_V-row.MinVoltage_V)*ocvSOEFraction;
ocvMap=ocv25+row.NominalVoltage_V*ocvTemperatureFraction(:);
maps=struct('SOEBreakpoints',soe, ...
    'SOCBreakpoints',soe, ...
    'TemperatureBreakpoints_C',temperature, ...
    'MaxDischargeCurrentMap_A',row.ReferenceDischargeCurrent_A*(dischargeTemperature(:)*dischargeSOE), ...
    'MaxChargeCurrentMap_A',row.ReferenceChargeCurrent_A*(chargeTemperature(:)*chargeSOE), ...
    'OpenCircuitVoltageMap_V',ocvMap, ...
    'InternalResistanceMap_Ohm',referenceResistance*(resistanceTemperature(:)*resistanceSOE));
end

function maps=motorMaps(row)
torqueFraction=[0 0.20 0.40 0.60 0.80 1.00];
speedFraction=[0 0.20 0.40 0.60 0.80 1.00];
[torqueGrid,speedGrid]=meshgrid(torqueFraction,speedFraction);
lossFraction=0.025*torqueGrid.^2+0.012*speedGrid.^1.5+ ...
    0.008*torqueGrid.*speedGrid;
maps=struct('TorqueBreakpoints_Nm',row.PeakTorque_Nm*torqueFraction, ...
    'SpeedBreakpoints_rpm',row.MaxSpeed_rpm*speedFraction, ...
    'MotorLossMap_kW',row.PeakPower_kW*lossFraction);
end

function literal=matrixLiteral(value)
literal=string(mat2str(value,15));
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
    error('HybridBus:ComponentMValue', ...
        'Unsupported component data type %s.',class(value));
end
end
