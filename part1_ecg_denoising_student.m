
clear; clc; close all;

%% 1) Problem Definition and Specifications
fs = 360;       
nyq = fs / 2;   

%% 2) Load Authentic MIT-BIH Data (Record 100)
fprintf('Loading MIT-BIH Record 100...\n');
if exist('100.dat', 'file')
    fid = fopen('100.dat', 'r');
    bytes = fread(fid, [3, 3600], 'uint8')'; % Read 3600 samples (10 seconds)
    fclose(fid);
    
    M1 = bytes(:, 1);
    M2 = bytes(:, 2);
    M3 = bytes(:, 3);
    
    % Extract Signal 1 (Lead I)
    ecg_clean = bitand(M2, 15) * 256 + M1;
    ecg_clean(ecg_clean > 2047) = ecg_clean(ecg_clean > 2047) - 4096; 
    ecg_clean = (ecg_clean - 1024) / 200; 
    ecg_clean = ecg_clean';
else
    error('Error: "100.dat" not found in current directory.');
end

t = (0:length(ecg_clean)-1) / fs;

baseline_wander = 0.4 * sin(2 * pi * 0.3 * t);               
powerline_noise = 0.15 * sin(2 * pi * 50 * t);               
muscle_noise    = 0.08 * randn(size(t));                     
ecg_noisy = ecg_clean + baseline_wander + powerline_noise + muscle_noise;


[b_hp, a_hp] = butter(2, 0.5/nyq, 'high');


f0 = 50;                     
w0 = 2 * pi * f0 / fs;       
r = 0.99;                    

b_notch = [1, -2*cos(w0), 1];
a_notch = [1, -2*r*cos(w0), r^2];

b0 = (1 - 2*r*cos(w0) + r^2) / (2 - 2*cos(w0));
b_notch = b_notch * b0;


fc_lp = 100;
order_lp = 50;
b_lp = fir1(order_lp, fc_lp/nyq, 'low', hamming(order_lp + 1));
a_lp = 1;

fprintf('\n--- Filter Coefficients ---\n');
disp('1. High-pass (Butterworth) B & A:'); disp(b_hp); disp(a_hp);
disp('2. Analytical Notch B & A:'); disp(b_notch); disp(a_notch);
disp('3. Low-pass (FIR Hamming) B:'); disp(b_lp);


ecg_hp     = filtfilt(b_hp, a_hp, ecg_noisy);
ecg_notch  = filtfilt(b_notch, a_notch, ecg_hp);
ecg_denoised  = filtfilt(b_lp, a_lp, ecg_notch);

noise_removed = ecg_noisy - ecg_denoised;
snr_initial = 10 * log10(var(ecg_clean) / var(ecg_noisy - ecg_clean));
snr_final   = 10 * log10(var(ecg_clean) / var(ecg_denoised - ecg_clean));
snr_imp     = snr_final - snr_initial;

fprintf('\n--- Performance Metric Summary ---\n');
fprintf('Initial SNR: %.2f dB\n', snr_initial);
fprintf('Denoised SNR: %.2f dB\n', snr_final);
fprintf('Total SNR Improvement: %.2f dB\n', snr_imp);


% --- Figure 1: Time-Domain Waveform Cascaded Analysis ---
figure('Name', 'Time-Domain Analysis Flow', 'NumberTitle', 'off');
subplot(4,1,1); plot(t, ecg_noisy, 'r'); title('Corrupted Original ECG Input'); ylabel('Amp (mV)'); grid on;
subplot(4,1,2); plot(t, ecg_hp, 'g'); title('Stage 1: After Baseline Wander Removal (HPF)'); ylabel('Amp (mV)'); grid on;
subplot(4,1,3); plot(t, ecg_notch, 'm'); title('Stage 2: After Powerline Cancellation (Notch)'); ylabel('Amp (mV)'); grid on;
subplot(4,1,4); plot(t, ecg_denoised, 'b'); title('Stage 3: Final Denoised Output (FIR LPF)'); ylabel('Amp (mV)'); xlabel('Time (s)'); grid on;

% --- Figure 2: Before & After Comparison ---
figure('Name', 'Before vs After Comparison', 'NumberTitle', 'off');
plot(t, ecg_noisy, 'r', 'LineWidth', 0.8); hold on;
plot(t, ecg_denoised, 'k', 'LineWidth', 1.2);
legend('Noisy Input Signal', 'Clean Denoised Output Signal');
title('ECG Signal Optimization Comparison'); xlabel('Time (s)'); ylabel('Amplitude (mV)'); grid on;

% --- Figure 3: Advanced Spectral Validation (PSD & Spectrogram) ---
figure('Name', 'Spectral Diagnostics', 'NumberTitle', 'off');

subplot(2,1,1);
[pxx_noisy, f_noisy] = pwelch(ecg_noisy, 256, 128, 512, fs);
[pxx_clean, f_clean] = pwelch(ecg_denoised, 256, 128, 512, fs);
plot(f_noisy, 10*log10(pxx_noisy), 'r', 'LineWidth', 1); hold on;
plot(f_clean, 10*log10(pxx_clean), 'b', 'LineWidth', 1.2);
title('Power Spectral Density (PSD) - Welch Estimation');
xlabel('Frequency (Hz)'); ylabel('Power/Frequency (dB/Hz)'); legend('Noisy Input', 'Denoised'); grid on;

% Spectrogram (STFT) Analysis of Denoised Output
subplot(2,1,2);
spectrogram(ecg_denoised, 128, 120, 128, fs, 'yaxis');
title('Short-Time Fourier Transform (STFT) Spectrogram of Cleaned ECG');

% --- Figures 4-6: Complete Technical Filter System Profiles ---
% Profile High Pass
figure('Name', 'HPF Characteristics', 'NumberTitle', 'off');
subplot(2,2,1); freqz(b_hp, a_hp, 512, fs); title('Magnitude/Phase Response');
subplot(2,2,2); impz(b_hp, a_hp, 50, fs); title('Impulse Response');
subplot(2,2,3); stepz(b_hp, a_hp, 50, fs); title('Step Response');
subplot(2,2,4); zplane(b_hp, a_hp); title('Pole-Zero Constellation Map');

% Profile Notch
figure('Name', 'Notch Filter Characteristics', 'NumberTitle', 'off');
subplot(2,2,1); freqz(b_notch, a_notch, 512, fs); title('Magnitude/Phase Response');
subplot(2,2,2); impz(b_notch, a_notch, 50, fs); title('Impulse Response');
subplot(2,2,3); stepz(b_notch, a_notch, 50, fs); title('Step Response');
subplot(2,2,4); zplane(b_notch, a_notch); title('Pole-Zero Constellation Map');

% Profile Low Pass FIR
figure('Name', 'LPF FIR Characteristics', 'NumberTitle', 'off');
subplot(2,2,1); freqz(b_lp, a_lp, 512, fs); title('Magnitude/Phase Response');
subplot(2,2,2); impz(b_lp, a_lp, 50, fs); title('Impulse Response');
subplot(2,2,3); stepz(b_lp, a_lp, 50, fs); title('Step Response');
subplot(2,2,4); zplane(b_lp, a_lp); title('Pole-Zero Constellation Map');