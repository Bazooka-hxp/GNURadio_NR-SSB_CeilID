function [strTxWaveform] = python_SSB_SignalCreate()
%% ---------------------------生成 SSB 信号----------------------------- %%
% 基本参数配置
prm.NCellID = 1000;                            % Cell ID
prm.FreqRange = 'FR1';                        % Frequency range: 'FR1' or 'FR2'
prm.CenterFreq = 5.5e9;                       % Hz 载频
prm.SSBlockPattern = 'Case B';                % Case A/B/C/D/E
prm.SSBTransmitted = [ones(1,8) zeros(1,0)];  % 4/8 or 64 in length
prm.RSRPMode = 'SSSwDMRS';                    % {'SSSwDMRS', 'SSSonly'}
prm.TxArraySize = [4 2];                      % Transmit array size, [rows cols]
prm.RxArraySize = [2 1];                      % Receive array size, [rows cols]

% 验证参数是否符合通信协议规定、根据基本参数填充其他必要参数
prm = validateParams(prm);
% 检查内容：根据频段检查中心频率、模式、L、SSSonly/SSSwDMRS、scs、cbw、scsCommon
% 返回内容：收发天线数、URA/ULA逻辑值


% SSB参数配置
txBurst = nrWavegenSSBurstConfig;                % 官方配置函数
txBurst.Power = 30;
txBurst.BlockPattern = prm.SSBlockPattern;       % 'Case B'
txBurst.TransmittedBlocks = prm.SSBTransmitted;  %  L = 8
txBurst.Period = 20;                             %  发送周期
txBurst.SubcarrierSpacingCommon = prm.SubcarrierSpacingCommon;    % SIB1的SCS（即scsCommon）

% 为符合 nrWaveformGenerator 函数规范，对上述参数进行整合，同时配置 nrDLCarrierConfig
cfgDL = configureWaveformGenerator(prm,txBurst);

% 配置OFDM基本参数，包含：NFFT点数、采样率、CP长度、窗等
ofdmInfo = nrOFDMInfo(cfgDL.SCSCarriers{1}.NSizeGrid,prm.SCS);     % 官方配置函数

% 生成SSB波形
burstWaveform = nrWaveformGenerator(cfgDL);

% 展示SSB频谱图
% figure;
% nfft = ofdmInfo.Nfft;
% spectrogram(burstWaveform,ones(nfft,1),0,nfft,'centered',ofdmInfo.SampleRate,'yaxis','MinThreshold',-130);
% title('Spectrogram of SS burst waveform')

%% ------------------------- 生成特定索引SSB ---------------------------- %%
% 根据简化版方案，会提前计算出AP应该发送什么SSB，所以下面将 burstWaveform 中对应
% SSB部分提取出来，扩展到发送天线数
% Get the set of OFDM symbols occupied by each SSB
numBlocks = length(txBurst.TransmittedBlocks);
burstStartSymbols = ssBurstStartSymbols(txBurst.BlockPattern,numBlocks);
burstStartSymbols_1 = burstStartSymbols(txBurst.TransmittedBlocks==1);
burstOccupiedSymbols = burstStartSymbols_1.' + (1:4);

% Apply steering per OFDM symbol for each SSB
gridSymLengths = repmat(ofdmInfo.SymbolLengths,1,cfgDL.NumSubframes);

% ssb索引值[1,8]，分别对应SSB0~SSB7
ssb = 1;  

% Extract SSB waveform from burst
blockSymbols = burstOccupiedSymbols(ssb,:);
startSSBInd = sum(gridSymLengths(1:blockSymbols(1)-1))+1;    % 起始点
endSSBInd = sum(gridSymLengths(1:blockSymbols(4)));          % 结束点
ssbWaveform = burstWaveform(startSSBInd:endSSBInd,1);

% 发送序列只保留对应SSB序列
[row,column] = size(burstWaveform);
strTxWaveform = zeros(row,column);
strTxWaveform(startSSBInd:endSSBInd,:) = ssbWaveform;
strTxWaveform = strTxWaveform';

% 下面之所以省略是因为实验使用的USRP单天线发送，故发送ssbWaveform即可
%  repeat burst over numTx to prepare for steering
%txWave = repmat(strTxWaveform,1,prm.NumTx);



end



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

    prm.NumTx = prod(prm.TxArraySize);
    prm.NumRx = prod(prm.RxArraySize);    
    if prm.NumTx==1 || prm.NumRx==1
        error(['Number of transmit or receive antenna elements must be', ... 
               ' greater than 1.']);
    end
    prm.IsTxURA = (prm.TxArraySize(1)>1) && (prm.TxArraySize(2)>1);
    prm.IsRxURA = (prm.RxArraySize(1)>1) && (prm.RxArraySize(2)>1);
    
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
    cfgDL.NCellID = prm.NCellID;                                 % 1
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
