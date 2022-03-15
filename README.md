# API

Lines of interest:
  1) Matlab
     #53 to #57 //
        % define the device (either Arduino or Seeeduino) serial communication
        % Timeout is defined so that it wait untils the mentioned time to
        % read from serial port 
        device = serialport('COM10',9600,"Timeout",30);
        flush(device);
      
     #84 to #88
        flush(device);
        % reads the gait cycle number as a char value
        m_char = readline(device);
        % converts to double
        mm = str2double(m_char);
        
     #186 to #189
            % converts double to string 
            Td = num2str(Td_int);
            % writes string to serial port
            writeline(device,Td);
