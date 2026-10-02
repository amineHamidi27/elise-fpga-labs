% Spectrum of the DDS output for W below and above 2^(N-1)
% Shows aliasing: W and 2^N - W give the same spectral line
N = 10; WIDTH = 14; fclk = 125e6; M = 2^N; L = 4096;
lut = round(((sin(2*pi*(0:M-1)/M) + 1) / 2) * (2^WIDTH - 1));
f = (0:L-1) * fclk / L;
Ws = [100 924; 412 612];            % each row: W < 512 and its alias 1024 - W

figure('visible', 'off', 'position', [0 0 1100 650]);
for r = 1:2
  for c = 1:2
    W = Ws(r, c);
    phase = mod((0:L-1) * W, M);    % phase accumulator modulo 2^N
    y = lut(phase + 1) - mean(lut); % DDS output without DC
    Y = abs(fft(y .* hanning(L)')) / L;
    subplot(2, 2, (r-1)*2 + c);
    plot(f/1e6, 20*log10(Y/max(Y) + 1e-12)); hold on;
    line([fclk/2 fclk/2]/1e6, [-120 5], 'color', [0.85 0 0], 'linestyle', '--', 'linewidth', 1.5);
    text(fclk/2/1e6 + 1.5, -10, 'f_{clk}/2', 'color', [0.85 0 0]);
    [~, i] = max(Y(1:L/2));
    title(sprintf('W = %d : f_{out} = %.2f MHz, line at %.2f MHz', ...
                  W, fclk*W/M/1e6, f(i)/1e6));
    xlim([0 125]); ylim([-120 5]); grid on;
    xlabel('f (MHz)'); ylabel('|X(f)| (dB)');
  end
end
print('-dpng', '-r120', '../rapport/figures/spectre.png');
