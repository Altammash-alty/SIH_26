% STARTUP - Adds all modular project directories to MATLAB path
rootPath = fileparts(mfilename('fullpath'));
addpath(rootPath);
addpath(fullfile(rootPath, 'pipeline'));
addpath(fullfile(rootPath, 'models'));
addpath(fullfile(rootPath, 'validation'));
addpath(fullfile(rootPath, 'param_search'));
addpath(fullfile(rootPath, 'results'));
