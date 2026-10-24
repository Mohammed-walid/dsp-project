
clear; clc; close all;

fprintf('=== Multi-Band Audio Equalizer System ===\n');

% Audio Input Selection
fileName = input('Enter audio file name (e.g., speech.wav or press Enter for demo synth): ', 's');
fileName = strtrim(fileName); 
if isempty(fileName)
    fileName = 'demo_synth';
end

if strcmp(fileName, 'demo_synth') || ~exist(fileName, 'file')
    if ~strcmp(fileName, 'demo_synth')
        fprintf('File "%s" not found. Generating clean multi-tone voice demo signal...\n', fileName);
    end
    fs_native = 44100;
    t_demo = 0:1/fs_native:2.5;
    x = 0.4*sin(2*pi*150*t_demo) + 0.3*sin(2*pi*900*t_demo) + ...
        0.2*sin(2*pi*3500*t_demo) + 0.05*randn(size(t_demo));
    x = x(:); 
else
    [x, fs_native] = audioread(fileName);
    if size(x, 2) > 1
        x = mean(x, 2); 
    end
end

filterClassInput = input('Select Core Filter Class (FIR or IIR): ', 's');
filterClass = upper(strtrim(filterClassInput));
if isempty(filterClass) || (~strcmp(filterClass, 'FIR') && ~strcmp(filterClass, 'IIR'))
    filterClass = 'FIR'; 
    fprintf('Invalid or empty input. Defaulting to Core Filter Class: FIR\n');
end

filterOrderInput = input('Enter baseline Filter Order (e.g., FIR=60, IIR=4): ', 's');
cleanedOrderStr = regexprep(filterOrderInput, '[a-zA-Z=\s]', '');
filterOrder = str2double(cleanedOrderStr);

if isempty(cleanedOrderStr) || isnan(filterOrder) || filterOrder <= 0
    if strcmp(filterClass, 'FIR')
        filterOrder = 60;
    else
        filterOrder = 4;
    end
    fprintf('Invalid or empty input. Using optimized default order for %s: %d\n', filterClass, filterOrder);
end

if strcmp(filterClass, 'FIR')
    fprintf('Available windows: 1 = Hamming, 2 = Hanning, 3 = Blackman\n');
    subTypeInput = input('Select Window Subtype (1-3): ', 's');
    subType = str2double(regexprep(subTypeInput, '\D', ''));
    if isnan(subType) || subType < 1 || subType > 3
        subType = 1; 
        fprintf('Invalid input. Defaulting to 1 (Hamming Window).\n');
    end
else
    fprintf('Available designs: 1 = Butterworth, 2 = Chebyshev Type I, 3 = Chebyshev Type II\n');
    subTypeInput = input('Select IIR Subtype (1-3): ', 's');
    subType = str2double(regexprep(subTypeInput, '\D', ''));
    if isnan(subType) || subType < 1 || subType > 3
        subType = 1; 
        fprintf('Invalid input. Defaulting to 1 (Butterworth).\n');
    end
end

fprintf('\nOperational Modes:\n1 = Preset Mode (7 Speech-Optimized Bands)\n2 = Custom Variable Band Mode\n');
modeChoiceInput = input('Select Mode (1 or 2): ', 's');
modeChoice = str2double(regexprep(modeChoiceInput, '\D', ''));
if isnan(modeChoice) || (modeChoice ~= 1 && modeChoice ~= 2)
    modeChoice = 1;
    fprintf('Defaulting to Operational Mode 1 (Preset Speech Bands).\n');
end

if modeChoice == 1
    bands = [0 100; 100 300; 300 800; 800 2000; 2000 5000; 5000 10000; 10000 20000];
else
    nBandsInput = input('Enter number of discrete bands (5 to 10): ', 's');
    nBands = str2double(regexprep(nBandsInput, '\D', ''));
    if isnan(nBands) || nBands < 5 || nBands > 10
        nBands = 5;
        fprintf('Out of limits. Setting to default: 5 bands.\n');
    end
    
    fprintf('Enter frequency edges array starting at 0 and ending at 20000.\n');
    edgesInput = input('Example Format [0 200 700 2500 7500 20000]: ', 's');
    edges = str2num(edgesInput); 
    if isempty(edges) || length(edges) ~= (nBands + 1)
        fprintf('Invalid array footprint. Automatically generating %d uniform bands...\n', nBands);
        edges = linspace(0, 20000, nBands + 1);
    end
    bands = [edges(1:end-1)' edges(2:end)'];
end

num_of_bands = size(bands, 1);
gainsDb = zeros(num_of_bands, 1);

fprintf('\n--- Assign Decibel Matrix Gains (-20dB to +20dB) ---\n');
for idx = 1:num_of_bands
    gainValInput = input(sprintf('  Band %d (%g Hz - %g Hz) Gain [dB]: ', idx, bands(idx,1), bands(idx,2)), 's');
    cleanedGain = str2double(regexprep(gainValInput, '[^\d\.-]', '')); 
    if isnan(cleanedGain)
        cleanedGain = 0; 
        fprintf('    No gain parsed. Set to neutral 0 dB.\n');
    end
    gainsDb(idx) = cleanedGain;
end

fprintf('\nOutput Sample Rate Modifiers:\n1 = Native Rate\n2 = Half-Sample Rate\n4 = Quad-Sample Rate\n');
rateChoiceInput = input('Select Rate Modifier (1, 2, or 4): ', 's');
rateChoice = str2double(regexprep(rateChoiceInput, '\D', ''));
if isnan(rateChoice) || (rateChoice ~= 1 && rateChoice ~= 2 && rateChoice ~= 4)
    rateChoice = 1;
    fprintf('Defaulting to 1 (Native Target Rate).\n');
end

band_signals = zeros(length(x), num_of_bands);

for i = 1:num_of_bands
    f1 = bands(i, 1);
    f2 = bands(i, 2);
    
    if strcmp(filterClass, 'FIR')
        [b, a] = compute_equalizer_filter_fir(subType, filterOrder, fs_native, f1, f2);
        band_signals(:, i) = filtfilt(b, a, x);
    else
        [sos, g] = compute_equalizer_filter_iir(subType, filterOrder, fs_native, f1, f2);
        band_signals(:, i) = filtfilt(sos, g, x);
    end
    
    ampLinear = 10^(gainsDb(i) / 20);
    band_signals(:, i) = band_signals(:, i) * ampLinear;
    
    fig_title = sprintf('Band %d Vector Analysis Profile (%g-%g Hz)', i, f1, f2);
    figure('Name', fig_title, 'NumberTitle', 'off');
    
    if strcmp(filterClass, 'FIR')
        subplot(2,2,1); freqz(b, a, 1024, fs_native); title('Frequency Transfer Profile');
        subplot(2,2,2); impz(b, a, [], fs_native); title('Impulse Trajectory');
        subplot(2,2,3); stepz(b, a, [], fs_native); title('Step Tracking');
        subplot(2,2,4); zplane(b, a); title('Pole-Zero Space Projection');
    else
        subplot(2,2,1); freqz(sos, 1024, fs_native); title('Frequency Transfer Profile');
        subplot(2,2,2); impz(sos, [], fs_native); title('Impulse Trajectory');
        subplot(2,2,3); stepz(sos, [], fs_native); title('Step Tracking');
        subplot(2,2,4); zplane(sos); title('Pole-Zero Space Projection');
    end
end

y_native = sum(band_signals, 2);

% Normalize the combined output to prevent digital clipping
if max(abs(y_native)) > 0
    y_native = (y_native / max(abs(y_native))) * 0.9;
end

if rateChoice == 2
    y_final = resample(y_native, 1, 2);
    fs_final = fs_native / 2;
elseif rateChoice == 4
    y_final = resample(y_native, 4, 1);
    fs_final = fs_native * 4;
else
    y_final = y_native;
    fs_final = fs_native;
end

t_in = (0:length(x)-1) / fs_native;
t_out = (0:length(y_final)-1) / fs_final;

figure('Name', 'System Time Domain Profiling', 'NumberTitle', 'off');
subplot(2,1,1); plot(t_in, x, 'Color', [0.3 0.3 0.3]); title('Original Input Audio Waveform'); xlabel('Time (s)'); ylabel('Amplitude'); grid on;
subplot(2,1,2); plot(t_out, y_final, 'b'); title('Processed Equalized Output Audio Waveform'); xlabel('Time (s)'); ylabel('Amplitude'); grid on;

figure('Name', 'Advanced Frequency Domain Profiling', 'NumberTitle', 'off');
subplot(2,1,1);
[p_in, f_in] = pwelch(x, 512, 256, 1024, fs_native);
[p_out, f_out] = pwelch(y_final, 512, 256, 1024, fs_final);
plot(f_in, 10*log10(p_in), 'r', 'LineWidth', 1); hold on;
plot(f_out, 10*log10(p_out), 'b', 'LineWidth', 1.2);
title('Power Spectral Density (PSD) Comparison'); xlabel('Frequency (Hz)'); ylabel('Power/Frequency (dB/Hz)'); legend('Input Data', 'Equalized Output'); grid on;

subplot(2,1,2);
spectrogram(y_final, 256, 128, 256, fs_final, 'yaxis');
title('Short-Time Fourier Transform (STFT) Spectrogram of Equalizer Output');

%% 6) Audio Playback & File Export Execution
audiowrite('equalized_podcast_output.wav', y_final, fs_final);
fprintf('\nProcess complete. Track exported successfully as "equalized_podcast_output.wav".\n');
fprintf('Playing processed output at %g Hz...\n', fs_final);
sound(y_final, fs_final);


function [b, a] = compute_equalizer_filter_fir(sub, N, fs, f1, f2)
    nyq = fs / 2;
    a = 1;
    if f2 >= nyq, f2 = nyq - 10; end
    if f1 <= 0,   f1 = 5;       end
    w1 = f1 / nyq; w2 = f2 / nyq;
    
    switch sub
        case 1, win = hamming(N + 1);
        case 2, win = hann(N + 1);
        case 3, win = blackman(N + 1);
        otherwise, win = hamming(N + 1);
    end
    
    if f1 <= 10
        b = fir1(N, w2, 'low', win);
    elseif f2 >= (nyq - 20)
        b = fir1(N, w1, 'high', win);
    else
        b = fir1(N, [w1 w2], 'bandpass', win);
    end
end

function [sos, g] = compute_equalizer_filter_iir(sub, N, fs, f1, f2)
    nyq = fs / 2;
    if f2 >= nyq, f2 = nyq - 10; end
    if f1 <= 0,   f1 = 5;       end
    w1 = f1 / nyq; w2 = f2 / nyq;
    
    switch sub
        case 1 % Butterworth
            if f1 <= 10
                [z, p, k] = butter(N, w2, 'low');
            elseif f2 >= (nyq - 20)
                [z, p, k] = butter(N, w1, 'high');
            else
                [z, p, k] = butter(N, [w1 w2], 'bandpass');
            end
        case 2 % Chebyshev Type I
            if f1 <= 10
                [z, p, k] = cheby1(N, 1, w2, 'low');
            elseif f2 >= (nyq - 20)
                [z, p, k] = cheby1(N, 1, w1, 'high');
            else
                [z, p, k] = cheby1(N, 1, [w1 w2], 'bandpass');
            end
        case 3 % Chebyshev Type II
            if f1 <= 10
                [z, p, k] = cheby2(N, 40, w2, 'low');
            elseif f2 >= (nyq - 20)
                [z, p, k] = cheby2(N, 40, w1, 'high');
            else
                [z, p, k] = cheby2(N, 40, [w1 w2], 'bandpass');
            end
    end
    [sos, g] = zp2sos(z, p, k); % Safe conversion mapping matrix
end