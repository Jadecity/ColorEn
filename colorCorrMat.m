function CM = colorCorrMat( data )
%colorCorrMat calculates the color correlation matrix of fourcorners of a window
%    Note: this function surppose data is 1d vector form
dnum = length(data)/3;

%get corrlation coefficients 
colorcorr = corr( reshape(data, 3,4) );

%reshape upper triangle matrix to a row vector
CM = colorcorr(logical(triu(ones(dnum,dnum), 1)));

end