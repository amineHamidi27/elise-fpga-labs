N = 10;
WIDTH = 14;
points = 2^N;

x = 2*pi*(0:points-1)/points;
raw_sine = round(((sin(x) + 1) / 2) * (2^WIDTH - 1));

fid = fopen('sine_lut_vhdl.txt', 'w');
for i = 1:(points - 1)
    fprintf(fid, '        %d,\n', raw_sine(i));
end
fprintf(fid, '        %d\n', raw_sine(points));
fclose(fid);