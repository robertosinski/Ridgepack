function [EPSILON,PHI,ALPHAHAT,VR,HK,HS,LK,LS,epmesh,phmesh,vr,...
           epsplitmesh,phsplitmesh,d1,d2]=ridgepack_trajectory(hf,hfs,res)

% ridgepack_trajectory - Calculate state-space trajectory of a ridge 
%
% function [EPSILON,PHI,ALPHAHAT,VR,HK,HS,LK,LS,epmesh,phmesh,vr,...
%            epsplitmesh,phsplitmesh,d1,d2]=ridgepack_trajectory(hf,hfs,res)
%
% This calculates the zeta-hat trajectory on VR leafs of the alpha-hat
% plane of an individual ridge with potential energy density.
%
% INPUT:
%
% hf  - parent ice thickness (m)
% hfs - thickness of snow on parent ice (m)
% res - resolution of the strain and porosity grid (optional)
%       with typical values between 0.01 and 0.001.
%
%
% OUTPUT:
%
% EPSILON     - ridge strain along zeta-hat trajectory (dimensionless)
% PHI         - ridge porosity along zeta-hat trajectory (dimensionless)
% ALPHAHAT    - ridge alpha-hat along zeta-hat trajectory (degrees)
% VR          - potential energy density along zeta-hat trajectory (J m^-2)
% HK          - draft of a keel (m)
% HS          - height of a sail (m)
% LK          - cross-sectional width of a keel (m)
% LS          - cross-sectional width of a sail (m)
% epmesh      - ridge strain on standard epsilon mesh (dimensionless)
% phmesh      - porosity on standard phi mesh (dimensionless)
% vr          - potential energy density on (epmesh,phmesh) grid (J m^-2)
% epsplitmesh - ridge strain on split epsilon mesh (dimensionless)
% phsplitmesh - porosity on split phi mesh (dimensionless)
% d1          - dilation field on (epsplitmesh,phsplitmesh)
%               [epsilon-component](J m^-2)
% d2          - dilation field on (epsplitmesh,phsplitmesh)
%               [phi-component](J m^-2)
%
% Ridgepack Version 1.0.
% Andrew Roberts, Naval Postgraduate School, March 2018 (afrobert@nps.edu)
% Reviewed by Samy Kamal, Naval Postgraduate School, May 2018

global debug;
if debug; disp(['Entering ',mfilename,'...']); end

% error check
if nargin<2
 error('incorrect number of inputs')
elseif length(hf)>1 | length(hfs)>1
 error('length of hf or hfs is greater than 1')
end

if nargin<3
 res=0.005;
elseif res>0.01
 error('Resolution is incorretly set')
end

% initialize grids, using split grids to calculate dilation
[hincr,eincr,hgrid,epsilongrid,phigrid,epsilonsplit,phisplit,ghphi]=...
   ridgepack_gridinit(res);

% prepare mesh and split mesh
[epmesh,phmesh]=meshgrid(epsilongrid,phigrid);
[epsplitmesh,phsplitmesh]=meshgrid(epsilonsplit,phisplit);

% get potential energy density for given ice thickness 
[vr]=ridgepack_energetics(hf,hfs,epmesh,phmesh);

% calculate dilation field
dVdep=(vr(:,2:end)-vr(:,1:end-1))./(epmesh(:,2:end)-epmesh(:,1:end-1));
dVdph=(vr(2:end,:)-vr(1:end-1,:))./(phmesh(2:end,:)-phmesh(1:end-1,:));
d1=(dVdep(1:end-1,:)+dVdep(2:end,:))/2;
d2=(dVdph(:,1:end-1)+dVdph(:,2:end))/2;

% initialize arrays
EPSILON=epsilonsplit;
PHI=zeros(size(EPSILON));

% integrate streamline from initial conditions
jdx=1;
PHI(1)=phisplit(jdx); % initial condition
for i=2:length(EPSILON)
 PHI(i)=PHI(i-1)-(d2(jdx,i)./d1(jdx,i)).*eincr;
 jdx=find(min(abs(PHI(i)-phisplit(:)))==abs(PHI(i)-phisplit(:)));
 if jdx>size(d2,1) | jdx>size(d1,1)
  error('Max phi exceeded')
 end
end

% determine entire state space 
[VR,ALPHAHAT,HK,HS,LK,LS]=ridgepack_energetics(hf,hfs,EPSILON,PHI);

if debug; disp(['...Leaving ',mfilename]); end

