% Seismology Toolbox - fk
% Version 0.6.0-r140 Dhaulagiri 27-May-2010
%
% Frequency-Wavenumber analysis functions
%CHKFKARFSTRUCT - Validate if a struct is as defined by FKARF
%CHKFKSTRUCT    - Validate if a struct is as defined by FKMAP/VOLUME/4D
%FK4D           - Returns a 4D map of energy in frequency-wavenumber-time space
%FKARF          - Returns the fk array response function for a seismic array
%FKDBINFO       - Returns the min/median/max dB for a FK struct
%FKFREQSLIDE    - Slides through a fk volume plotting each frequency
%FKMAP          - Returns a 2D map of energy in frequency-wavenumber space
%FKTIMESLIDE    - Slides through a sequence of fk maps plotting each one
%FKVOL2MAP      - Converts a fk volume to a fk map
%FKVOLUME       - Returns a 3D map of energy in frequency-wavenumber space
%FKXCVOLUME     - Returns energy map in frequency-wavenumber space for xc data
%KXY2SLOWBAZ    - Converts wavenumbers in x & y to slowness and back-azimuth
%PLOTFKARF      - Plots an fk array response function
%PLOTFKMAP      - Plots the frequency-wavenumber output from FKMAP
%SLOWBAZ2KXY    - Converts slowness and back-azimuth to wavenumbers in x & y
%SNYQUIST       - Returns the nyquist slowness for an array
%UPDATEFKMAP    - Quickly updates an existing fk plot with a new map

