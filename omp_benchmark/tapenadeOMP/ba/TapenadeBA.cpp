// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include "TapenadeBA.h"

constexpr int n_new_cols = BA_NCAMPARAMS + 3 + 1;

// This function must be called before any other function.
void TapenadeBA::prepare(BAInput&& input)
{
    this->input = input;
    result = {
        std::vector<double>(2 * this->input.p),
        std::vector<double>(this->input.p),
        BASparseMat(this->input.n, this->input.m, this->input.p)
    };

    reproj_err_d = std::vector<double>(2 * n_new_cols * input.p);
    zach_weight_error_d = std::vector<double>(input.p);
    reproj_err_d_row = std::vector<double>(n_new_cols * input.p);
}



BAOutput TapenadeBA::output()
{
    for (int i = 0; i < input.p; ++i) {
        int camIdx = input.obs[2 * i + 0];
        int ptIdx = input.obs[2 * i + 1];
        result.J.insert_reproj_err_block(i, camIdx, ptIdx, reproj_err_d.data() + i * 2 * n_new_cols);
    }
    for (int i = 0; i < input.p; ++i) {
        result.J.insert_w_err_block(i, zach_weight_error_d[i]);
    }
    return result;
}


extern "C"  void ba_objectivefortran(
    int *n,
    int *m,
    int *p,
    int *camssize,
    double const* cams,
    double const* X,
    double const* w,
    int const* obs,
    double const* feats,
    double* reproj_err,
    double* w_err
);
void TapenadeBA::calculate_objective(int times)
{
    for (int i = 0; i < times; i++)
    {
        int camssize = input.cams.size();
        // ba_objectivefortran(
        //     &input.n,
        //     &input.m,
        //     &input.p,
        //     &camssize,
        //     input.cams.data(),
        //     input.X.data(),
        //     input.w.data(),
        //     input.obs.data(),
        //     input.feats.data(),
        //     result.reproj_err.data(),
        //     result.w_err.data()
        // );
        //printf("compute time\n");
        ba_objective(
            input.n,
            input.m,
            input.p,
            input.cams.data(),
            input.X.data(),
            input.w.data(),
            input.obs.data(),
            input.feats.data(),
            result.reproj_err.data(),
            result.w_err.data()
        );
    }
}



void TapenadeBA::calculate_jacobian(int times)
{

    for (int i = 0; i < times; i++)
    {
        result.J.clear();
        calculate_reproj_error_jacobian_part();
        calculate_weight_error_jacobian_part();
    }
}


extern "C"   void compute_reproj_error_b(const double *cam, double *camb, const double *X, 
        double *Xb, const double *w, double *wb, const double *feat, double *
        err, double *errb);
void TapenadeBA::calculate_reproj_error_jacobian_part()
{

#ifdef OMP

#endif


    double* cam_gradient_part = reproj_err_d_row.data();
    double* x_gradient_part = reproj_err_d_row.data() + BA_NCAMPARAMS;
    double* weight_gradient_part = reproj_err_d_row.data() + BA_NCAMPARAMS + 3;

#ifdef OMP
    #pragma omp parallel for 
#endif
    for (int i = 0; i < input.p; i++)
    {
#ifdef OMP
    cam_gradient_part = reproj_err_d_row.data() + i * (BA_NCAMPARAMS + 3);
    x_gradient_part = cam_gradient_part + BA_NCAMPARAMS;
    weight_gradient_part = cam_gradient_part + BA_NCAMPARAMS + 3;    
#endif

        double errb[2];     // stores dY
                            // (i-th element equals to 1.0 for calculating i-th jacobian row)

        double err[2];      // stores fictive result
                            // (Tapenade doesn't calculate an original function in reverse mode)
        int camIdx = input.obs[2 * i + 0];
        int ptIdx = input.obs[2 * i + 1];

        // calculate first row
        errb[0] = 1.0;
        errb[1] = 0.0;
        compute_reproj_error_b(
            &input.cams[camIdx * BA_NCAMPARAMS],
            cam_gradient_part,
            &input.X[ptIdx * 3],
            x_gradient_part,
            &input.w[i],
            weight_gradient_part,
            &input.feats[i * 2],
            err,
            errb
        );

        // fill first row elements
        for (int j = 0; j < n_new_cols; j++)
        {
            reproj_err_d[i * n_new_cols * 2 + 2 * j] = reproj_err_d_row[j];
        }

        // calculate second row
        errb[0] = 0.0;
        errb[1] = 1.0;
        compute_reproj_error_b(
            &input.cams[camIdx * BA_NCAMPARAMS],
            cam_gradient_part,
            &input.X[ptIdx * 3],
            x_gradient_part,
            &input.w[i],
            weight_gradient_part,
            &input.feats[i * 2],
            err,
            errb
        );

        // fill second row elements
        for (int j = 0; j < n_new_cols; j++)
        {
            reproj_err_d[i * n_new_cols * 2 + 2 * j + 1] = reproj_err_d_row[j];
        }
    }
}


extern "C" void compute_zach_weight_error_b(const double *w, double *wb, double *err, 
        double *errb);

#include<omp.h>
void TapenadeBA::calculate_weight_error_jacobian_part()
{

#ifdef OMP
    #pragma omp parallel for 
#endif
    for (int j = 0; j < input.p; j++)
    {
        //int id = omp_get_thread_num();
        //printf("id=%d\n",id);
        double err = 0.0;       // stores fictive result
                                // (Tapenade doesn't calculate an original function in reverse mode)

        double errb = 1.0;      // stores dY
                                // (equals to 1.0 for derivative calculation)

        compute_zach_weight_error_b(&input.w[j], &zach_weight_error_d[j], &err, &errb);
    }
}



extern "C" DLL_PUBLIC ITest<BAInput, BAOutput>* get_ba_test()
{
    return new TapenadeBA();
}