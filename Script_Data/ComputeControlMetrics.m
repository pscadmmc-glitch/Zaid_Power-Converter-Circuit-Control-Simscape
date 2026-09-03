function metrics = ComputeControlMetrics(outData, disturbanceTime)
%COMPUTECONTROLMETRICS Extract transient-performance metrics from a run.
%
%   metrics = ComputeControlMetrics(outData, disturbanceTime) returns a
%   struct of scalar indicators used to compare the PI and STSMC inner
%   current loops on identical scenarios.
%
% Fields:
%   Pss, Qss        steady-state active / reactive power (pu)
%   Overshoot       peak overshoot of P after the disturbance (%)
%   SettlingTime    time to stay inside a 2% band around Pss (s)
%   IAE, ITAE       integral error indices on P tracking
%   PeakCurrent     maximum current magnitude sqrt(Id^2+Iq^2) (pu)
%   VoltageDip      largest drop of Vd below its pre-disturbance value (pu)
%   FreqDeviation   largest excursion of the GFM frequency from 50 Hz (Hz)
%   CurrentTHD      total harmonic distortion of phase-a current (%)
%   Outcome         pass/fail verdict reported by the model post-processing

log = outData.LogsoutGridFormingConverter;

[t,   P]    = getSignal(log, 'Pmeas');
[~,   Q]    = getSignal(log, 'Qmeas');
[tr,  Pref] = getSignal(log, 'Pref');
[~,   Vgd]  = getSignal(log, 'Vgd');
[tf,  freq] = getSignal(log, 'Freq');
[~,   Igd]  = getSignal(log, 'Igd');
[~,   Igq]  = getSignal(log, 'Igq');

metrics = struct();

% ---- Steady state -----------------------------------------------------
metrics.Pss = P(end);
metrics.Qss = Q(end);

% ---- Post-disturbance transient on active power -----------------------
idx = t >= disturbanceTime;
if nnz(idx) < 3
    idx = true(size(t));
end
tPost = t(idx);
pPost = P(idx);
pFinal = pPost(end);

span = max(abs(pFinal), 1e-3);
metrics.Overshoot = (max(abs(pPost)) - abs(pFinal))/span*100;

band = 0.02*span;
outside = find(abs(pPost - pFinal) > band, 1, 'last');
if isempty(outside)
    metrics.SettlingTime = 0;
else
    metrics.SettlingTime = tPost(min(outside+1, numel(tPost))) - disturbanceTime;
end

% ---- Tracking error indices ------------------------------------------
PrefOnP = interp1(tr, Pref, t, 'previous', 'extrap');
err = abs(P - PrefOnP);
metrics.IAE  = trapz(t, err);
metrics.ITAE = trapz(t, t(:).*err(:));

% ---- Current, voltage, frequency stress -------------------------------
Is = sqrt(Igd.^2 + Igq.^2);
metrics.PeakCurrent = max(Is);

preIdx = t < disturbanceTime;
if nnz(preIdx) > 0
    vPre = Vgd(find(preIdx, 1, 'last'));
else
    vPre = Vgd(1);
end
metrics.VoltageDip = max(0, vPre - min(Vgd));

metrics.FreqDeviation = max(abs(freq - 50));

% ---- Current distortion ----------------------------------------------
metrics.CurrentTHD = estimateTHD(log, tf);

% ---- Verdict ----------------------------------------------------------
metrics.Outcome = FindTestOutCome(P, Vgd, freq);
end

% =======================================================================
function [t, y] = getSignal(log, name)
% Fetch a logged signal as column vectors, tolerating missing entries.
element = log.get(name);
if isempty(element)
    t = [0; 1];
    y = [0; 0];
    return
end
t = element.Values.Time(:);
y = reshape(element.Values.Data, 1, []).';
end

% =======================================================================
function thd = estimateTHD(log, tFallback)
% THD of phase-a output current over the last 5 fundamental periods.
element = log.get('Iabc');
if isempty(element)
    thd = NaN;
    return
end
t = element.Values.Time(:);
data = reshape(element.Values.Data, 3, []);
ia = data(1,:).';

f0 = 50;                      % Hz
window = 5/f0;                % s
mask = t >= (t(end) - window);
if nnz(mask) < 32
    thd = NaN;
    return
end

tw = t(mask);
iw = ia(mask);

% Resample uniformly - the variable-step solver output is not equispaced.
n  = 2^12;
tu = linspace(tw(1), tw(end), n).';
iu = interp1(tw, iw, tu, 'linear');
iu = iu - mean(iu);

% Hann window written out so the metric does not need Signal Processing Toolbox.
w = 0.5*(1 - cos(2*pi*(0:n-1).'/(n-1)));

spectrum = abs(fft(iu.*w));
spectrum = spectrum(1:floor(n/2));

df = 1/(tu(end) - tu(1));
kFund = round(f0/df) + 1;
if kFund < 2 || kFund > numel(spectrum)
    thd = NaN;
    return
end

% Sum the harmonic bins up to the 40th, skipping the fundamental lobe.
fundamental = max(spectrum(max(kFund-1,1):min(kFund+1,end)));
harmonics = 0;
for h = 2:40
    k = round(h*f0/df) + 1;
    if k+1 > numel(spectrum), break; end
    harmonics = harmonics + max(spectrum(k-1:k+1))^2;
end

if fundamental <= 0
    thd = NaN;
else
    thd = sqrt(harmonics)/fundamental*100;
end
end
