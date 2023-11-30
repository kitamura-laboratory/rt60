% Calculate reverberation time (RT60) from impulse response
clear; close all; clc;

% Set parameters
% impResPath = "./impResponse_short.wav";
impResPath = "./impResponse_long.wav";
bpfFreq = 500; % Center frequency ([Hz]) of band-pass filter (if bpfFreq == 0, filtering will not be applied)
interval = [5, 35]; % Energy interval ([dB]) for linear regression

% Read impulse response
[sig, fs] = audioread(impResPath);

% Calculate reverberation time
calcRevTime(sig, fs, interval, bpfFreq, true);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EOF %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%