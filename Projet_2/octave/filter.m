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

% Conversion des coefficients en entiers sur 8 bits ()
nbits = 8;
k     = floor(-log2(max(b)));       % nb de fois qu'on peut doubler max(b) en restant < 1
nF    = nbits + k;                  % ici 8 + 1 = 9
b_int = round(b * 2^nF);            % 18 123 230 123 18
printf("nF = %d, scale = %d\n", nF, 2^nF);
printf("b_int = "); printf("%d ", b_int); printf("\n");
printf("sum(b_int) = %d\n", sum(b_int));   % 512 = 2^nF -> gain 1
print('-dpng', '-r150', '../rapport/figures/bode_lowpass.png');

