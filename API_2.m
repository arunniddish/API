device = serialport('COM6',9600,"Timeout",30);
flush(device);

write(device,'define A 2 3 5 9 end',"string"); % Define the gait 
check = "Defined";
i = 1;  % Logical true to enter while loop
while(i)
    data_recieve = strtrim(readline(device))
    if(strcmp(check,data_recieve) == 1)
        write(device,'start A 10',"string");
        i = 0; % Logical false to exit while loop
    end
end
    