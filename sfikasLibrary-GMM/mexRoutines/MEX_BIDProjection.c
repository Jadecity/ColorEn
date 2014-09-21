/*
 * BIDProjection(vector, number of elements in vector)
 * Projects input vector onto constraint plane defined by
 * 1. sum(vector) = 1
 * 2. Each variate of 'vector' >= 0
 *
 * vector must 1xK sized, the second argument must be equal to K.
 *
 * G.Sfikas 22 Mar 2008
 * based on code by K.Blekas
 */

#define SQR(x) ((x)*(x))

#include "mex.h"
#include <stdlib.h>
#include <math.h>

#define MAXK 100
double K;

void BIDProjection(double *result, double *x);
void findMaximum(double *maxValue, int *index, double x[]);

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
    double *x;
    double *result;
    double *sizeX;
    int i;

	/*/ Input*/
	x = mxGetPr(prhs[0]);
    sizeX = mxGetPr(prhs[1]);
    if(x == NULL || sizeX == NULL) {
        printf("BIDProjection: Syntax is MEX_BIDProjection(vector, number of elements in vector)\n");
        printf("BIDProjection: Example: MEX_BIDProjection([1 1.5 -2.1], 3)\n");
    }
    K = *sizeX;
   	/*/ Output*/
	plhs[0] = mxCreateDoubleMatrix(1, K, mxREAL);
	result = mxGetPr(plhs[0]);
	BIDProjection(result, x);
}


void BIDProjection(double *result, double *x)
{
    int i;
    double mes;
    double zet[MAXK];
    double Eta[MAXK];
    double VertDist[MAXK];
    double nzi[MAXK];
    double maxV; int vtx;
    int notfound;
    int c;
    double normX;
    int NOO;
    double sumTzi;
    double tzi[MAXK];
    double Tempzet[MAXK];
    double ggM; int ggExcl;
    double sumAbsX;
    
    /* Check if vector has too large variates */
    findMaximum(&ggM, &ggExcl, x);
    for(sumAbsX = 0,i = 0; i < K; i++)
        sumAbsX += fabs(x[i]);
    if(ggM > 0 && sumAbsX - ggM < 1e-5) {
        for(i = 0; i < K; i++)
            result[i] = 0;
        result[ggExcl] = 1;
        return;
    }
    /**/
    for(mes = 0,i = 0; i < K; i++)
        mes += x[i];
    for(NOO = 0,i = 0; i < K; i++) {
        zet[i] = x[i] + (1 - mes)/K;
        if(zet[i] < 0 || zet[i] > 1)
            NOO++;
    }   
    if(NOO < 1) { /* if(NOO == 0) en fait..Blekas l'ecrit comme ca */
        for(i = 0; i < K; i++)
            result[i] = zet[i];
        return;
    }
    /*********** La piece apres "else" ***************/
    for(i = 0; i < K; i++)
        Eta[i] = 1;
    notfound = 1;
    
    for(normX = 0, i = 0; i < K; i++)
        normX += SQR(x[i]);
    for(i = 0; i < K; i++)
        VertDist[i] = 1 + normX - 2*x[i];
    c = 2;
    for(i = 0; i < K; i++)
        nzi[i] = x[i];
    while(notfound > 0) {
        findMaximum(&maxV, &vtx, VertDist);
        VertDist[vtx] = -1.0;
        Eta[vtx] = 0;
        for(sumTzi = 0, i = 0; i < K; i++) {
            tzi[i] = Eta[i]*nzi[i];
            sumTzi += tzi[i];
        }
        if(K - c + 1 <= 0) {
            printf("MEX_BIDProjection: Hey..this message shouldnt show up!\n");
            return;
        }
        for(i = 0; i < K; i++)
            Tempzet[i] = tzi[i] + (1 - sumTzi)/(K - c + 1);
        for(i = 0; i < K; i++)
            Tempzet[i] = Tempzet[i] * Eta[i];

        for(NOO = 0,i = 0; i < K; i++)
            if(Tempzet[i] < 0 || Tempzet[i] > 1)
                NOO++;
        if(NOO < 1) {
            for(i = 0; i < K; i++)
                result[i] = Tempzet[i];
            notfound = 0;
        }
        c++;
    }
    return;
}

void findMaximum(double *maxValue, int *index, double x[]) {
    int i;
    
    *maxValue = x[0]; *index = 0;
    for(i = 0; i < K; i++)
        if(x[i] > *maxValue) {
            *maxValue = x[i];
            *index = i;
        }
    return;
}
