function u = StokesDcloseeval(x, s, sigma, side,CDLP)
% STOKESDCLOSEEVAL - evaluate Stokes DLP potential on global quadr curve
%
% u = StokesDevalclose(x,s,tau,side) returns potentials at targets x due to
%  double-layer potential with density sigma living on curve s.
%  The DLP is broken down into 5 Laplace DLP-like (2 are Cauchy) potential
%  calls, each of which are evaluated with the globally-compensated scheme.
%  "side" controls whether targets are inside (default) or outside.
%  (A mixture isn't allowed).
%
% Inputs:
% x = M-by-1 list of targets in complex plane
% s = curve struct containing N-by-1 vector s.x of source nodes (as complex
%     numbers), and all other fields in s which are generated by quadr(), and
%     s.a one interior point far from bdry (mean(s.x) used if not provided).
% sigma = double-layer density values (N-by-1) at nodes, in complex notation:
%     real, imag contains the 1,2 vector components.
% side = 'i','e' (default) to indicate targets are all interior or exterior
%     to the curve.
%
% Outputs:
% u = velocity values at targets x (M-by-1): real, imag contains 1,2 components
%
% needs: lapDevalclose.m, quadr.m
%
% Also see: QUADR, testStokesSDevalclose.m
%
% (c) Bowei Wu, Sept 2014. Tweaks by Barnett 10/8/14

if nargin<4, side = 'e'; end        % default

% find I_1:
% Bowei's version with "illegal" complex tau, with interp to fine nodes
beta = 2.2;  % >=1: how many times more dense to make fine nodes, for I_1
N = ceil(beta*numel(s.x)/2)*2;  % nearest even # fine nodes
sf.x = fftinterp(s.x,N); sf = quadr(sf); % build fine nodes
sigf = fftinterp(sigma,N);     % fine Stokes density
tauf = sigf./sf.nx.*real(sf.nx);  % feed complex tau to Laplace close eval
if nargin==5
    I1x1 = lapDevalclose(x, sf, tauf, side,CDLP{1});
else
    I1x1 = lapDevalclose(x, sf, tauf, side);
end
tauf = sigf./sf.nx.*imag(sf.nx);
if nargin==5
    I1x2 = lapDevalclose(x, sf, tauf, side,CDLP{1});
else
    I1x2 = lapDevalclose(x, sf, tauf, side);
end
I1 = I1x1+1i*I1x2;

% find I_2
tau = real(s.x.*conj(sigma));
if nargin==5
    [~, I2x1, I2x2] = lapDevalclose(x, s, tau, side,CDLP{2});
else
    [~, I2x1, I2x2] = lapDevalclose(x, s, tau, side);
end
I2 = I2x1+1i*I2x2;

% find I_3
tau = real(sigma);
if nargin==5
    [~, I3x1, I3x2] = lapDevalclose(x, s, tau, side,CDLP{2});
else
    [~, I3x1, I3x2] = lapDevalclose(x, s, tau, side);
end
I3 = real(x).*(I3x1(:)+1i*I3x2(:));

% find I_4
tau = imag(sigma);
if nargin==5
    [~, I4x1, I4x2] = lapDevalclose(x, s, tau, side,CDLP{2});
else
    [~, I4x1, I4x2] = lapDevalclose(x, s, tau, side);
end
I4 = imag(x).*(I4x1(:)+1i*I4x2(:));

u = I1(:)+I2(:)-I3(:)-I4(:);

% test which is causing slow convergence at nearby pt (side='e', vary N):
% jj= find(abs(x - (0.7-0.9i))<1e-12); I1(jj), I2(jj), I3(jj)+I4(jj)
% ans: it's I1, of course. (Alex)

% keyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end main %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function testfftinterp
n = 50;
N = 100;
x = 2*pi*(0:n-1)/n;
f = @(x) exp(sin(x));
g = fftinterp(f(x),N);
ge = f(2*pi*(0:N-1)/N);
% g ./ ge
norm(g - ge)

function g = fftinterp(f,N)
% FFTINTERP - resample periodically sampled function onto finer grid
%
% g = fftinterp(f,N)
% inputs:  f - (row or column) vector length n of samples
%          N - desired output number of samples, must be >= n
% outputs: g - vector length N of interpolant, (row or col as f was)
% Note on phasing: the output and input grid first entry align.
% Barnett 9/5/14.  To do: downsample case N<n
n = numel(f);
if N==n, g = f; return; end
if mod(N,2)~=0 || mod(n,2)~=0, warning('N and n must be even'); end
F = fft(f(:).');    % row vector
g = ifft([F(1:n/2) F(n/2+1)/2 zeros(1,N-n-1) F(n/2+1)/2 F(n/2+2:end)]);
g = g*(N/n);   % factor from the ifft
if size(f,1)>size(f,2), g = g(:); end % make col vector
