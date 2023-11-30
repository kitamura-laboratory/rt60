function [rt60] = calcRevTime(impRes, sampFreq, regIntvl, analyFreq, isPlot)
% Calculate reverberation time (RT60) from impulse response
%
% [Syntax]
%       [rt60] = calcRevTime(impRes,sampFreq,regIntvl,analyFreq)
%
% [Inputs]
%       impRes: input impulse response waveform (sigLen x 1)
%     sampFreq: sampling frequency (positive scalr)
%     regIntvl: Energy interval ([dB]) for linear regression (nonnegative 1 x 2 vector, default: [5, 35])
%    analyFreq: Center frequency ([Hz]) of band-pass filter (nonnegative scalar, if analyFreq = 0, filtering will not be applied, default: 500)
%       isPlot: Plot reverberation curve and regression function or not (true/false, default: true)
%
% [Outputs]
%         rt60: estimated reverberation time [s] (scalar)
%

% Check arguments and set default values
arguments
    impRes (:,1) {mustBeNumeric}
    sampFreq (1,1) {mustBePositive}
    regIntvl (1,2) {mustBeNonnegative} = [5, 35]
    analyFreq (1,1) {mustBeNonnegative} = 500
    isPlot (1,1) = true
end
sigLen = size(impRes, 1);

% Apply band-pass filter (4th-order Butterworth filter)
if analyFreq > 0
    nyquistFreq = sampFreq/2; % [Hz]
    lowCutFreq = analyFreq/sqrt(2); % [Hz]
    highCutFreq = analyFreq*sqrt(2); % [Hz]
    [z, p, k] = butter(2, [lowCutFreq, highCutFreq]/nyquistFreq, "bandpass"); % 4th-order Butterworth filter
    sos = zp2sos(z, p, k); % Convert zero points, poles, and gains to state-space representation
    if isPlot
        fvtool(sos); % Show filter characteristics
    end
    impRes = sosfilt(sos, impRes); % Apply filtering and overwrite
end

% Calculate Schroeder integral
powImpRes = impRes.^2; % Power (energy) of impulse response
revCurve = sum(powImpRes) - cumsum(powImpRes); % Schroeder integral
revCurve = revCurve./max(revCurve); % Normalization
logRevCurve = 10*log10(max(revCurve, eps)); % Convert to dB

% Estimate linear regression function
timeAx = linspace(0, sigLen/sampFreq, sigLen);
indIntvl = find(logRevCurve <= -1*regIntvl(1) & logRevCurve >= -1*regIntvl(2));
indStart = indIntvl(1); % index of -1*regIntvl(1) dB
indEnd = indIntvl(end); % index of -1*regIntvl(2) dB
coef = polyfit(timeAx(indStart:indEnd), logRevCurve(indStart:indEnd, :), 1); % linear regression
a = coef(1); % gradient
b = coef(2); % intercept

% Calculate reverberation time (RT60)
beginPnt = (-regIntvl(1) - b) / a; % - regIntvl(1) = a * beginPnt + b
endPnt = (-60 - regIntvl(1) - b)/a; % -60 - regIntvl(1) = a * endPnt + b
rt60 = endPnt - beginPnt;

% Plot reverberation curve
if isPlot
    figure("Position", [100, 100, 800, 400]);
    plot(timeAx, logRevCurve, "LineWidth", 2.5); grid on;
    set(gca, "FontSize", 11, "FontName", "Arial");
    xlim([0, sigLen/sampFreq]); ylim([-120, 0]);
    xlabel("Time [s]"); ylabel("Reverberation energy [dB]");
    hold on;
    plot(timeAx, a*timeAx + b, "LineWidth", 1);
    yline(-regIntvl(1), '-r', {'Reg begin point'}, "LabelHorizontalAlignment", "left", "LabelVerticalAlignment", "bottom", "FontSize", 11);
    yline(-regIntvl(2), '-r', {'Reg end point'}, "LabelHorizontalAlignment", "left", "LabelVerticalAlignment", "bottom", "FontSize", 11);
    xline(beginPnt, '-r', {'RT60 begin point'}, "LabelVerticalAlignment", "bottom", "FontSize", 11);
    xline(endPnt, '-r', {'RT60 end point'}, "LabelVerticalAlignment", "bottom", "FontSize", 11);
    legend(["Reverberation curve", sprintf("Linear regression in [%d, %d] dB", -1*regIntvl(1), -1*regIntvl(2))]);
    fprintf("Reverberation time (RT60) is %.3f [ms].\n", rt60*1000);
    hold off;
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% EOF %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%