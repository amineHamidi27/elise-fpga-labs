clc;clear;
pkg load signal;

fs = 125/8;          % MHz
f1 = 2;  f2 = 2.5;
b  = fir1(30, [f1 f2]/(fs/2), 'bandpass');
freqz(b,1,1024,fs);  % plot in Hzs
print('-dpng', '-r150', '../rapport/figures/bode_bandpass.png');
[H,f] = freqz(b,1,20000,fs);
mag_dB = 20*log10(abs(H));
in = find(mag_dB >= -6);
printf("-6 dB band: %.3f - %.3f MHz\n", f(in(1)), f(in(end)));

printf("%.6f, ", b(1:end-1)); printf("%.6f\n", b(end));




