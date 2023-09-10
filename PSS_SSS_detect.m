function [NID2,NID1,ncellid] = PSS_SSS_detect(Receive_data)
Receive_data = double(Receive_data);
Receive_data = Receive_data';
%% parems_set:txBurst、ofdmInfo、cfgDL
prm.FreqRange = 'FR1';                        % Frequency range: 'FR1' or 'FR2'
prm.CenterFreq = 5.5e9;                       % Hz 载频
prm.SSBlockPattern = 'Case B';                % Case A/B/C/D/E
prm.SSBTransmitted = [ones(1,8) zeros(1,0)];  % 4/8 or 64 in length
prm.RSRPMode = 'SSSwDMRS';                    % {'SSSwDMRS', 'SSSonly'}
prm = validateParams(prm);
% SSB参数配置
txBurst = nrWavegenSSBurstConfig;                % 官方配置函数 
txBurst.BlockPattern = prm.SSBlockPattern;       % 'Case B'
txBurst.TransmittedBlocks = prm.SSBTransmitted;  %  L = 8
txBurst.SubcarrierSpacingCommon = prm.SubcarrierSpacingCommon;    % SIB1的SCS（即scsCommon）
cfgDL = configureWaveformGenerator(prm,txBurst);
ofdmInfo = nrOFDMInfo(cfgDL.SCSCarriers{1}.NSizeGrid,prm.SCS);     % 官方配置函数

% Get the set of OFDM symbols occupied by each SSB
numBlocks = length(txBurst.TransmittedBlocks);
burstStartSymbols = ssBurstStartSymbols(txBurst.BlockPattern,numBlocks);
burstStartSymbols_1 = burstStartSymbols(txBurst.TransmittedBlocks==1);
burstOccupiedSymbols = burstStartSymbols_1.' + (1:4);


%% --------------------------- PSS检测:方法一 --------------------------- %%
% openExample('5g/NRCellSearchMIBAndSIB1RecoveryExample')
disp(' -- Frequency correction and timing estimation --')
% Specify the frequency offset search bandwidth in kHz
searchBW = 6*txBurst.SubcarrierSpacingCommon;
[NID2] = hSSBurstFrequencyCorrect(Receive_data,txBurst.BlockPattern,ofdmInfo.SampleRate,searchBW);

% ——————————————————————————————————————————
carrier = nrCarrierConfig('NCellID',NID2);
carrier.NSizeGrid = cfgDL.SCSCarriers{1}.NSizeGrid;
carrier.SubcarrierSpacing = cfgDL.SCSCarriers{1, 1}.SubcarrierSpacing;
pssRef = nrPSS(carrier.NCellID);
pssInd = nrPSSIndices;    % 频域索引（子载波索引）
% ibar_SSB = 0;
% pbchdmrsRef = nrPBCHDMRS(carrier.NCellID,ibar_SSB);
% pbchDMRSInd = nrPBCHDMRSIndices(carrier.NCellID);
pssGrid = zeros([240 4]);
pssGrid(pssInd) = pssRef;
% pssGrid(pbchDMRSInd) = pbchdmrsRef;
refGrid_pss = zeros([12*carrier.NSizeGrid ofdmInfo.SymbolsPerSlot]);
burstOccupiedSubcarriers = carrier.NSizeGrid*6 + (-119:120).';
refGrid_pss(burstOccupiedSubcarriers, ...
    burstOccupiedSymbols(1,:)) = pssGrid;    % PSS频域表达

%% ------------------------------- 定时同步 -----------------------------%%
% timingOffset = nrTimingEstimate(carrier,rxWaveform(1:ofdmInfo.SampleRate*1e-3,:),refGrid_pss);
timingOffset = nrTimingEstimate(carrier,Receive_data,refGrid_pss(:,5));
timingOffset = timingOffset-ofdmInfo.SymbolLengths(2)+ofdmInfo.SymbolLengths(1);

%% ------------------------------- OFDM解调 -----------------------------%%
strRxWaveformS = Receive_data(1+timingOffset-ofdmInfo.SymbolLengths(1):end,:);
rxGrid = nrOFDMDemodulate(carrier,strRxWaveformS);
% rxSSBGrid = rxGrid(burstOccupiedSubcarriers, ...
%             burstOccupiedSymbols(ssb,:),:);
rxSSBGrid = rxGrid(burstOccupiedSubcarriers, ...
            2:5,:);
%% ------------------------------- SSS检测 ----------------------------- %%
sssIndices = nrSSSIndices;
sssRx = nrExtractResources(sssIndices,rxSSBGrid);

% Correlate received SSS symbols with each possible SSS sequence
sssEst = zeros(1,336);
for NID1 = 0:335
    ncellid = (3*NID1) + NID2;
    sssRef = nrSSS(ncellid);
    sssEst(NID1+1) = sum(abs(mean(sssRx .* conj(sssRef),1)).^2);
end

% Determine NID1 by finding the strongest correlation
NID1 = find(sssEst==max(sssEst)) - 1;
% Form overall cell identity from estimated NID1 and NID2
ncellid = (3*NID1) + NID2;

end


%%
function prm = validateParams(prm)
% Validate user specified parameters and return updated parameters
%
% Only cross-dependent checks are made for parameter consistency.

    if strcmpi(prm.FreqRange,'FR1')
        if prm.CenterFreq > 7.125e9 || prm.CenterFreq < 410e6
            error(['Specified center frequency is outside the FR1 ', ...
                   'frequency range (410 MHz - 7.125 GHz).']);
        end
        if strcmpi(prm.SSBlockPattern,'Case D') ||  ...
           strcmpi(prm.SSBlockPattern,'Case E')
            error(['Invalid SSBlockPattern for selected FR1 frequency ' ...
                'range. SSBlockPattern must be one of ''Case A'' or ' ...
                '''Case B'' or ''Case C'' for FR1.']);
        end
        if ~((length(prm.SSBTransmitted)==4) || ...
             (length(prm.SSBTransmitted)==8))
            error(['SSBTransmitted must be a vector of length 4 or 8', ...
                   'for FR1 frequency range.']);
        end
        if (prm.CenterFreq <= 3e9) && (length(prm.SSBTransmitted)~=4)
            error(['SSBTransmitted must be a vector of length 4 for ' ...
                   'center frequency less than or equal to 3GHz.']);
        end
        if (prm.CenterFreq > 3e9) && (length(prm.SSBTransmitted)~=8)
            error(['SSBTransmitted must be a vector of length 8 for ', ...
                   'center frequency greater than 3GHz and less than ', ...
                   'or equal to 7.125GHz.']);
        end
    else % 'FR2'
        if prm.CenterFreq > 52.6e9 || prm.CenterFreq < 24.25e9
            error(['Specified center frequency is outside the FR2 ', ...
                   'frequency range (24.25 GHz - 52.6 GHz).']);
        end
        if ~(strcmpi(prm.SSBlockPattern,'Case D') || ...
                strcmpi(prm.SSBlockPattern,'Case E'))
            error(['Invalid SSBlockPattern for selected FR2 frequency ' ...
                'range. SSBlockPattern must be either ''Case D'' or ' ...
                '''Case E'' for FR2.']);
        end
        if length(prm.SSBTransmitted)~=64
            error(['SSBTransmitted must be a vector of length 64 for ', ...
                   'FR2 frequency range.']);
        end
    end

    %prm.NumTx = prod(prm.TxArraySize);
    %prm.NumRx = prod(prm.RxArraySize);    
    %if prm.NumTx==1 || prm.NumRx==1
    %   error(['Number of transmit or receive antenna elements must be', ... 
    %          ' greater than 1.']);
    %end
    %prm.IsTxURA = (prm.TxArraySize(1)>1) && (prm.TxArraySize(2)>1);
    %prm.IsRxURA = (prm.RxArraySize(1)>1) && (prm.RxArraySize(2)>1);
    
    if ~( strcmpi(prm.RSRPMode,'SSSonly') || ...
          strcmpi(prm.RSRPMode,'SSSwDMRS') )
        error(['Invalid RSRP measuring mode. Specify either ', ...
               '''SSSonly'' or ''SSSwDMRS'' as the mode.']);
    end

    % Select SCS based on SSBlockPattern
    switch lower(prm.SSBlockPattern) % lower：将字符串转换为小写
        case 'case a'
            scs = 15;
            cbw = 10;
            scsCommon = 15;
        case {'case b', 'case c'}
            scs = 30;
            cbw = 25;
            scsCommon = 30;
        case 'case d'
            scs = 120;
            cbw = 100;
            scsCommon = 120;
        case 'case e'
            scs = 240;
            cbw = 200;
            scsCommon = 120;
    end
    prm.SCS = scs;
    prm.ChannelBandwidth = cbw;
    prm.SubcarrierSpacingCommon = scsCommon;

end

function cfgDL = configureWaveformGenerator(prm,txBurst)
% Configure an nrDLCarrierConfig object to be used by nrWaveformGenerator
% to generate the SS burst waveform.

    cfgDL = nrDLCarrierConfig;
    cfgDL.SCSCarriers{1}.SubcarrierSpacing = prm.SCS;             % 30                 
    if (prm.SCS==240)
        cfgDL.SCSCarriers = [cfgDL.SCSCarriers cfgDL.SCSCarriers];
        cfgDL.SCSCarriers{2}.SubcarrierSpacing = prm.SubcarrierSpacingCommon;
        cfgDL.BandwidthParts{1}.SubcarrierSpacing = prm.SubcarrierSpacingCommon;
    else
        cfgDL.BandwidthParts{1}.SubcarrierSpacing = prm.SCS;     % BWP configuration ????
    end
    cfgDL.PDSCH{1}.Enable = false;
    cfgDL.PDCCH{1}.Enable = false;
    cfgDL.ChannelBandwidth = prm.ChannelBandwidth;               % 25M 
    cfgDL.FrequencyRange = prm.FreqRange;                        % FR1
    %cfgDL.NCellID = prm.NCellID;                                 % 1
    cfgDL.NumSubframes = 5;                                      % 默认是10，现在改成5
    cfgDL.WindowingPercent = 0;                                  % 默认值
    cfgDL.SSBurst = txBurst;                                     % SSB的参数配置
end

function ssbStartSymbols = ssBurstStartSymbols(ssbBlockPattern,Lmax)
% Starting OFDM symbols of SS burst.

    % 'alln' gives the overall set of SS block indices 'n' described in
    % TS 38.213 Section 4.1, from which a subset is used for each Case A-E
    alln = [0; 1; 2; 3; 5; 6; 7; 8; 10; 11; 12; 13; 15; 16; 17; 18];

    cases = {'Case A' 'Case B' 'Case C' 'Case D' 'Case E'};
    m = [14 28 14 28 56];
    i = {[2 8] [4 8 16 20] [2 8] [4 8 16 20] [8 12 16 20 32 36 40 44]};
    nn = [2 1 2 16 8];

    caseIdx = find(strcmpi(ssbBlockPattern,cases));
    if (any(caseIdx==[1 2 3]))
        if (Lmax==4)
            nn = nn(caseIdx);
        elseif (Lmax==8)
            nn = nn(caseIdx) * 2;
        end
    else
        nn = nn(caseIdx);
    end

    n = alln(1:nn);
    ssbStartSymbols = (i{caseIdx} + m(caseIdx)*n).';
    ssbStartSymbols = ssbStartSymbols(:).';

end








