// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#ifdef __cplusplus
extern "C" {
#endif

#include <math.h>
#include <stdlib.h>

#include "defs.h"

// GMM function differentiated in reverse mode by Tapenade.
void gmm_objective_b(int* d, int* k, int* n, double const* alphas,
                     double* alphasb, double const* means, double* meansb,
                     double const* icf, double* icfb, double const* x,
                     Wishart* wishart, double* err, double* errb);
void gmm_objective_b_c(int d, int k, int n, const double *alphas, double *
        alphasb, const double *means, double *meansb, const double *icf, 
        double *icfb, const double *x, Wishart wishart, double *err, double *
        errb) ;
#ifdef __cplusplus
}
#endif
