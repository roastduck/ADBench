// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#include "EnzymeBA.h"

constexpr int n_new_cols = BA_NCAMPARAMS + 3 + 1;

// This function must be called before any other function.
void EnzymeBA::prepare(BAInput&& input)
{
    this->input = input;
    result = {
        std::vector<double>(2 * this->input.p),
        std::vector<double>(this->input.p),
        BASparseMat(this->input.n, this->input.m, this->input.p)
    };

    reproj_err_d = std::vector<double>(2 * n_new_cols);
    zach_weight_error_d = std::vector<double>(input.p);
    reproj_err_d_row = std::vector<double>(n_new_cols);
#ifdef OMP
    temp_save = std::vector<std::vector<double>>(input.p, std::vector<double>(30, 0.0));
#endif
}



BAOutput EnzymeBA::output()
{
    return result;
}

extern "C" {
    void ba_objective(
        int n,
        int m,
        int p,
        double const* cams,
        double const* X,
        double const* w,
        int const* obs,
        double const* feats,
        double* reproj_err,
        double* w_err
    );
}

void EnzymeBA::calculate_objective(int times)
{
    for (int i = 0; i < times; i++)
    {
        int camssize = input.cams.size();
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


//#include<chrono>
void EnzymeBA::calculate_jacobian(int times)
{

    //auto start = std::chrono::high_resolution_clock::now();
    for (int i = 0; i < times; i++)
    {
        result.J.clear();
        //auto t1 = std::chrono::high_resolution_clock::now();
        calculate_reproj_error_jacobian_part();
        //auto t2 = std::chrono::high_resolution_clock::now();
        calculate_weight_error_jacobian_part();
        //auto t3 = std::chrono::high_resolution_clock::now();
        //auto duration = std::chrono::duration_cast<std::chrono::microseconds>(t2 - t1);
        //std::cout << "shit: " << ((float)duration.count()) / 1000000.0 << ' ';
        //duration = std::chrono::duration_cast<std::chrono::microseconds>(t3 - t2);
        //std::cout << ((float)duration.count()) / 1000000.0 << '\n';
    }
    //auto end = std::chrono::high_resolution_clock::now();
    //auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    //std::cout << "times = " << times << ", calculate_jacobian = " << ((float)duration.count()) / 1000000.0 << '\n';
}

extern "C" {
    void dcompute_reproj_error(
        const double *cam,
        double *camb,
        const double *X,
        double *Xb,
        const double *w,
        double *wb,
        const double *feat,
        double *err,
        double *errb
    );
}

//#include<iostream>
#ifdef OMP
//#include<omp.h>
#endif
void EnzymeBA::calculate_reproj_error_jacobian_part()
{
    //auto start = std::chrono::high_resolution_clock::now();
    //reproj_err_d容量30，reproj_err_d_row容量15
    //reproj的两个变量在后面都不会再用到了
    #ifndef OMP
    double errb[2];     // stores dY
                        // (i-th element equals to 1.0 for calculating i-th jacobian row)
    #endif
    double err[2];      // stores fictive result
                        // (Tapenade doesn't calculate an original function in reverse mode)

    #ifndef OMP
    double* cam_gradient_part = reproj_err_d_row.data();
    double* x_gradient_part = reproj_err_d_row.data() + BA_NCAMPARAMS;
    double* weight_gradient_part = reproj_err_d_row.data() + BA_NCAMPARAMS + 3;
    #else
    //std::cout << "fuck input p = " << input.p << '\n';
    #pragma omp parallel for
    #endif
    for (int i = 0; i < input.p; i++)
    {
        int camIdx = input.obs[2 * i + 0];
        int ptIdx = input.obs[2 * i + 1];
        #ifdef OMP
        double errb[2];
        #endif

        // calculate first row
        errb[0] = 1.0;
        errb[1] = 0.0;
        #ifdef OMP
        std::vector<double> private_reproj_err_d_row(15, 0.0);
        #else
        for(auto& a : reproj_err_d_row) a = 0.0;
        #endif

        dcompute_reproj_error(
            &input.cams[camIdx * BA_NCAMPARAMS],
            #ifndef OMP
            cam_gradient_part,
            #else
            private_reproj_err_d_row.data(),
            #endif
            &input.X[ptIdx * 3],
            #ifndef OMP
            x_gradient_part,
            #else
            private_reproj_err_d_row.data() + BA_NCAMPARAMS,
            #endif
            &input.w[i],
            #ifndef OMP
            weight_gradient_part,
            #else
            private_reproj_err_d_row.data() + BA_NCAMPARAMS + 3,
            #endif
            &input.feats[i * 2],
            err,
            errb
        );

        // fill first row elements
        for (int j = 0; j < BA_NCAMPARAMS + 3 + 1; j++)
        {
            #ifndef OMP
            reproj_err_d[2 * j] = reproj_err_d_row[j];
            #else
            //reproj_err_d[2 * j] = private_reproj_err_d_row[j];
            temp_save[i][2 * j] = private_reproj_err_d_row[j];
            #endif
        }
        #ifndef OMP
        for(auto& a : reproj_err_d_row) a = 0.0;
        #else
        memset(private_reproj_err_d_row.data(), 0, private_reproj_err_d_row.size() * sizeof(double));
        #endif
        // calculate second row
        errb[0] = 0.0;
        errb[1] = 1.0;
        dcompute_reproj_error(
            &input.cams[camIdx * BA_NCAMPARAMS],
            #ifndef OMP
            cam_gradient_part,
            #else
            private_reproj_err_d_row.data(),
            #endif
            &input.X[ptIdx * 3],
            #ifndef OMP
            x_gradient_part,
            #else
            private_reproj_err_d_row.data() + BA_NCAMPARAMS,
            #endif
            &input.w[i],
            #ifndef OMP
            weight_gradient_part,
            #else
            private_reproj_err_d_row.data() + BA_NCAMPARAMS + 3,
            #endif
            &input.feats[i * 2],
            err,
            errb
        );

        // fill second row elements
        for (int j = 0; j < BA_NCAMPARAMS + 3 + 1; j++)
        {
            #ifndef OMP
            reproj_err_d[2 * j + 1] = reproj_err_d_row[j];
            #else
            //reproj_err_d[2 * j + 1] = private_reproj_err_d_row[j];
            temp_save[i][2 * j + 1] = private_reproj_err_d_row[j];
            #endif
        }
        #ifndef OMP
        result.J.insert_reproj_err_block(i, camIdx, ptIdx, reproj_err_d.data());
        #endif
    }
    #ifdef OMP
    for (int i = 0; i < input.p; i++) {
        int camIdx = input.obs[2 * i + 0];
        int ptIdx = input.obs[2 * i + 1];
        result.J.insert_reproj_err_block(i, camIdx, ptIdx, temp_save[i].data());
    }
    #endif
    //auto end = std::chrono::high_resolution_clock::now();
    //auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    //std::cout << "calculate_reproj_error_jacobian_part = " << ((float)duration.count()) / 1000000.0 << '\n';
}


extern "C" {
    void dcompute_zach_weight_error(
        const double *w,
        double *wb,
        double *err,
        double *errb
    );
}

void EnzymeBA::calculate_weight_error_jacobian_part()
{
    //auto start = std::chrono::high_resolution_clock::now();
    std::vector<double> temp_save(input.p, 0.0);
#ifdef OMP
    /*
    std::cout << "omp_get_max_threads = " << omp_get_max_threads() << '\n';
    */
#endif
    #ifdef OMP
    #pragma omp parallel for
    #endif
    for (int j = 0; j < input.p; j++)
    {
#ifdef OMP
        /*
        if (j > input.p - 10){
            std::cout << "omp_get_num_threads = " << omp_get_num_threads() << ' ';
            std::cout << "omp_get_thread_num = " << omp_get_thread_num() << '\n';
        }
        */
#endif
        // NOTE added set of 0 here
        double wb = 0.0;         // stores calculated derivative

        double err = 0.0;       // stores fictive result
                                // (Tapenade doesn't calculate an original function in reverse mode)

        double errb = 1.0;      // stores dY
                                // (equals to 1.0 for derivative calculation)

        dcompute_zach_weight_error(&input.w[j], &wb, &err, &errb);
        temp_save[j] = wb;
    }
    for(int j = 0; j < input.p; j++){
        result.J.insert_w_err_block(j, temp_save[j]);
    }
    //auto end = std::chrono::high_resolution_clock::now();
    //auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    //std::cout << "calculate_weight_error_jacobian_part = " << ((float)duration.count()) / 1000000.0 << '\n';
}



extern "C" DLL_PUBLIC ITest<BAInput, BAOutput>* get_ba_test()
{
    return new EnzymeBA();
}
