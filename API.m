device = serialport('COM6',9600,"Timeout",30);
flush(device);
pause(4);
A = [2;3;5;9]
write(device,'define',"string");
pause(4);
write(device,'4',"string");
pause(3);
for i = 1:size(A,1)
write(device,A(i),"int8");
pause(4);
end
pause(2);
write(device,'start',"string");
pause(2)
inp = 'A7';
writeline(device,inp);
while(str2double(readline(device)) == 0)
end
write(device,'start',"string");
pause(4)
inp = 'A7';
writeline(device,inp);
