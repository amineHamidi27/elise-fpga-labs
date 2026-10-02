clc;clear;
pkg load signal;

fs = 125/8;          % MHz
fc = 0.5;            % MHz
b = fir1(4, fc/(fs/2), 'low');
freqz(b,1,1024,fs);  % plot in Hzs
[H,f] = freqz(b,1,2048,fs);
mag_dB = 20*log10(abs(H));
idx = find(mag_dB <= -6, 1);
f_cutoff = f(idx);
printf("−6 dB cutoff ≈ %.3f MHz\n", f_cutoff);

%
