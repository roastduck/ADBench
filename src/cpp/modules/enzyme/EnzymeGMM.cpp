// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include "EnzymeGMM.h"

// This function must be called before any other function.
void EnzymeGMM::prepare(GMMInput&& input)
{
    this->input = input;
    int Jcols = (this->input.k * (this->input.d + 1) * (this->input.d + 2)) / 2;
    result = { 0, std::vector<double>(Jcols) };
}



GMMOutput EnzymeGMM::output()
{
    return result;
}

extern "C" {
    void dgmm_objective(
        int d,
        int k,
        int n,
        const double *alphas,
        double *alphasb,
        const double *means,
        double *meansb,
        const double *icf,
        double *icfb,
        const double *x,
        Wishart wishart,
        double *err,
        double *errb
    );

    void call_gmm_objective(
        int d,
        int k,
        int n,
        double const* __restrict alphas,
        double const* __restrict means,
        double const* __restrict icf,
        double const* __restrict x,
        Wishart wishart,
        double* __restrict err
    );
}


void EnzymeGMM::calculate_objective(int times)
{
    for (int i = 0; i < times; i++)
    {
        call_gmm_objective(
            input.d,
            input.k,
            input.n,
            input.alphas.data(),
            input.means.data(),
            input.icf.data(),
            input.x.data(),
            input.wishart,
            &result.objective
        );
    }
}



void EnzymeGMM::calculate_jacobian(int times)
{
    double* alphas_gradient_part = result.gradient.data();
    double* means_gradient_part = result.gradient.data() + input.alphas.size();
    double* icf_gradient_part =
        result.gradient.data() +
        input.alphas.size() +
        input.means.size();

    for (int i = 0; i < times; i++)
    {
        std::fill(result.gradient.begin(), result.gradient.end(), 0);
        double tmp = 0.0;       // stores fictive result
                                // (Enzyme doesn't calculate an original function in reverse mode)

        double errb = 1.0;      // stores dY
                                // (equals to 1.0 for gradient calculation)

        dgmm_objective(
            input.d,
            input.k,
            input.n,
            input.alphas.data(),
            alphas_gradient_part,
            input.means.data(),
            means_gradient_part,
            input.icf.data(),
            icf_gradient_part,
            input.x.data(),
            input.wishart,
            &tmp,
            &errb
        );
    }
}



extern "C" DLL_PUBLIC ITest<GMMInput, GMMOutput>* get_gmm_test()
{
    return new EnzymeGMM();
}
