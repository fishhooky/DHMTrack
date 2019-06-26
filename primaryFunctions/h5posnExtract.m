function data = h5posnExtract(filenameIn)
% Convert h5 file into a matlab data array
% Andrew Hook, May 2018
%
% A file to read h5 files that contain (x,y,z) coordinates of multiple
% reconstructed particles, along with the reconstructed volume.
%
% Typically receives an h5 file holography output titled object
%
% Output is an array {nFrames} [nParticles x (x,y,z,vol)] called 'data'.
%
% Required inputs are: filenameIn, which is filepath to h5 file.
%
% Note, this version ignores centroid data and just extracts centre of mass positions.


%% INITIALISE ARRAY AND VARIABLES
info = h5info(filenameIn);
nFrames = size(info.Groups,1);
Lookup(1:nFrames)=0;
for k = 1:nFrames
    Lookup(k) = str2double(info.Groups(k).Name(2:end));
end

%% READ DATA & OUTPUT
for k = min(Lookup):max(Lookup); %H5 data is from 0, MatLab from 1
    try        
        iFrame = find(Lookup==k);
        dataIn = h5read(filenameIn,[info.Groups(iFrame).Name,'/objects']); %Acquire frame data from input file
        dataOut{k-min(Lookup)+1}=dataIn.centerOfMass; %Extract centre of mass data
        dataOut{k-min(Lookup)+1}(4,:)=dataIn.volume; %Extract volume data
        dataOut{k-min(Lookup)+1}=transpose(dataOut{k-min(Lookup)+1}); %Transpose to {nFrames} [nParticles x (x,y,z,vol)]
        clear dataIn
    catch
    end
end

data = dataOut;

