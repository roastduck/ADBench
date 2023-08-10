

#pragma once

#include "../../json.hpp"
#include "../mshared/defs.h"
#include <vector>
#include <string>
#include <iostream>
#include <fstream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include "omp.h"
#include <chrono>


float tdiff(struct timeval *start, struct timeval *end) {
  return (end->tv_sec-start->tv_sec) + 1e-6*(end->tv_usec-start->tv_usec);
}

using namespace std;
using json = nlohmann::json;

struct BAInput {
    int n = 0, m = 0, p = 0;
    std::vector<double> cams, X, w, feats;
    std::vector<int> obs;
};

// rows is nrows+1 vector containing
// indices to cols and vals.
// rows[i] ... rows[i+1]-1 are elements of i-th row
// i.e. cols[row[i]] is the column of the first
// element in the row. Similarly for values.
class BASparseMat
{
public:
    int n, m, p; // number of cams, points and observations
    int nrows, ncols;
    std::vector<int> rows;
    std::vector<int> cols;
    std::vector<double> vals;

    BASparseMat();
    BASparseMat(int n_, int m_, int p_);

    void insert_reproj_err_block(int obsIdx,
        int camIdx, int ptIdx, const double* const J);

    void insert_w_err_block(int wIdx, double w_d);

    void clear();
};

BASparseMat::BASparseMat() {}

BASparseMat::BASparseMat(int n_, int m_, int p_) : n(n_), m(m_), p(p_)
{
    nrows = 2 * p + p;
    ncols = BA_NCAMPARAMS * n + 3 * m + p;
    rows.reserve(nrows + 1);
    int nnonzero = (BA_NCAMPARAMS + 3 + 1) * 2 * p + p;
    cols.reserve(nnonzero);
    vals.reserve(nnonzero);
    rows.push_back(0);
}

void BASparseMat::insert_reproj_err_block(int obsIdx,
    int camIdx, int ptIdx, const double* const J)
{
    int n_new_cols = BA_NCAMPARAMS + 3 + 1;
    rows.push_back(rows.back() + n_new_cols);
    rows.push_back(rows.back() + n_new_cols);

    for (int i_row = 0; i_row < 2; i_row++)
    {
        for (int i = 0; i < BA_NCAMPARAMS; i++)
        {
            cols.push_back(BA_NCAMPARAMS * camIdx + i);
            vals.push_back(J[2 * i + i_row]);
        }
        int col_offset = BA_NCAMPARAMS * n;
        int val_offset = BA_NCAMPARAMS * 2;
        for (int i = 0; i < 3; i++)
        {
            cols.push_back(col_offset + 3 * ptIdx + i);
            vals.push_back(J[val_offset + 2 * i + i_row]);
        }
        col_offset += 3 * m;
        val_offset += 3 * 2;
        cols.push_back(col_offset + obsIdx);
        vals.push_back(J[val_offset + i_row]);
    }
}

void BASparseMat::insert_w_err_block(int wIdx, double w_d)
{
    rows.push_back(rows.back() + 1);
    cols.push_back(BA_NCAMPARAMS * n + 3 * m + wIdx);
    vals.push_back(w_d);
}

void BASparseMat::clear()
{
    rows.clear();
    cols.clear();
    vals.clear();
    rows.reserve(nrows + 1);
    int nnonzero = (BA_NCAMPARAMS + 3 + 1) * 2 * p + p;
    cols.reserve(nnonzero);
    vals.reserve(nnonzero);
    rows.push_back(0);
}

struct BAOutput {
    std::vector<double> reproj_err;
    std::vector<double> w_err;
    BASparseMat J;
};

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

    void dcompute_reproj_error(
        double const* cam,
        double * dcam,
        double const* X,
        double * dX,
        double const* w,
        double * wb,
        double const* feat,
        double *err,
        double *derr
    );

    void dcompute_zach_weight_error(double const* w, double* dw, double* err, double* derr);

    void compute_reproj_error_b(
        double const* cam,
        double * dcam,
        double const* X,
        double * dX,
        double const* w,
        double * wb,
        double const* feat,
        double *err,
        double *derr
    );

    void compute_zach_weight_error_b(double const* w, double* dw, double* err, double* derr);

    void adept_compute_reproj_error(
        double const* cam,
        double * dcam,
        double const* X,
        double * dX,
        double const* w,
        double * wb,
        double const* feat,
        double *err,
        double *derr
    );

    void adept_compute_zach_weight_error(double const* w, double* dw, double* err, double* derr);
}

void read_ba_instance(const string& fn,
    int& n, int& m, int& p,
    vector<double>& cams,
    vector<double>& X,
    vector<double>& w,
    vector<int>& obs,
    vector<double>& feats)
{
    FILE* fid = fopen(fn.c_str(), "r");
    if (!fid) {
        printf("could not open file: %s\n", fn.c_str());
        exit(1);
    }
    std::cout << "read_ba_instance: opened " << fn << std::endl;

    fscanf(fid, "%i %i %i", &n, &m, &p);
    int nCamParams = 11;

    cams.resize(nCamParams * n);
    X.resize(3 * m);
    w.resize(p);
    obs.resize(2 * p);
    feats.resize(2 * p);

    for (int j = 0; j < nCamParams; j++)
        fscanf(fid, "%lf", &cams[j]);
    for (int i = 1; i < n; i++)
        memcpy(&cams[i * nCamParams], &cams[0], nCamParams * sizeof(double));

    for (int j = 0; j < 3; j++)
        fscanf(fid, "%lf", &X[j]);
    for (int i = 1; i < m; i++)
        memcpy(&X[i * 3], &X[0], 3 * sizeof(double));

    fscanf(fid, "%lf", &w[0]);
    for (int i = 1; i < p; i++)
        w[i] = w[0];

    int camIdx = 0;
    int ptIdx = 0;
    for (int i = 0; i < p; i++)
    {
        obs[i * 2 + 0] = (camIdx++ % n);
        obs[i * 2 + 1] = (ptIdx++ % m);
    }

    fscanf(fid, "%lf %lf", &feats[0], &feats[1]);
    for (int i = 1; i < p; i++)
    {
        feats[i * 2 + 0] = feats[0];
        feats[i * 2 + 1] = feats[1];
    }

    fclose(fid);
}

typedef void(*deriv_reproj_t)(double const*, double *, double const*, double*, double const*, double*, double const*, double *, double *);

template<deriv_reproj_t deriv_reproj>
void calculate_reproj_error_jacobian_part(struct BAInput &input, struct BAOutput &result, std::vector<double> &reproj_err_d, std::vector<double> &reproj_err_d_row)
{
    //reproj_err_d容量30，reproj_err_d_row容量15
    //reproj的两个变量在后面都不会再用到了
    #ifndef OMP
    double errb[2];     // stores dY
                        // (i-th element equals to 1.0 for calculating i-th jacobian row)
    #endif
    //auto start = std::chrono::high_resolution_clock::now();
    double err[2];      // stores fictive result
                        // (Tapenade doesn't calculate an original function in reverse mode)
    #ifndef OMP
    double* cam_gradient_part = reproj_err_d_row.data();
    double* x_gradient_part = reproj_err_d_row.data() + BA_NCAMPARAMS;
    double* weight_gradient_part = reproj_err_d_row.data() + BA_NCAMPARAMS + 3;
    #else
    std::vector<std::vector<double>> temp_save(input.p, std::vector<double>(30, 0.0));
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

        deriv_reproj(
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
        deriv_reproj(
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
        #ifndef INSERT
        result.J.insert_reproj_err_block(i, camIdx, ptIdx, reproj_err_d.data());
        #endif
    }
    #ifdef INSERT
    for (int i = 0; i < input.p; i++) {
        int camIdx = input.obs[2 * i + 0];
        int ptIdx = input.obs[2 * i + 1];
        result.J.insert_reproj_err_block(i, camIdx, ptIdx, temp_save[i].data());
    }
    #endif
    //auto end = std::chrono::high_resolution_clock::now();
    //auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
    //std::cout << "Elapsed time: " << duration.count() << " milliseconds" << std::endl;
}



typedef void(*deriv_weight_t)(double const* w, double* dw, double* err, double* derr);

template<deriv_weight_t deriv_weight>
void calculate_weight_error_jacobian_part(struct BAInput &input, struct BAOutput &result, std::vector<double> &reproj_err_d, std::vector<double> &reproj_err_d_row)
{
    //auto start = std::chrono::high_resolution_clock::now();
    #ifdef OMP
    std::vector<double> temp_save(input.p, 0.0);
    #pragma omp parallel for
    #endif
    for (int j = 0; j < input.p; j++)
    {
        // NOTE added set of 0 here
        double wb = 0.0;         // stores calculated derivative

        double err = 0.0;       // stores fictive result
                                // (Tapenade doesn't calculate an original function in reverse mode)

        double errb = 1.0;      // stores dY
                                // (equals to 1.0 for derivative calculation)

        deriv_weight(&input.w[j], &wb, &err, &errb);
        #ifndef INSERT
        result.J.insert_w_err_block(j, wb);
        #else
        temp_save[j] = wb;
        #endif
    }
    #ifdef INSERT
    for(int j = 0; j < input.p; j++){
        result.J.insert_w_err_block(j, temp_save[j]);
    }
    #endif
    //auto end = std::chrono::high_resolution_clock::now();
    //auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);
    //std::cout << "Elapsed time2: " << duration.count() << " milliseconds" << std::endl;
}


template<deriv_reproj_t deriv_reproj, deriv_weight_t deriv_weight>
void calculate_jacobian(struct BAInput &input, struct BAOutput &result)
{
    auto reproj_err_d = std::vector<double>(2 * (BA_NCAMPARAMS + 3 + 1)); // 30
    auto reproj_err_d_row = std::vector<double>(BA_NCAMPARAMS + 3 + 1); // 15

    calculate_reproj_error_jacobian_part<deriv_reproj>(input, result, reproj_err_d, reproj_err_d_row);
    calculate_weight_error_jacobian_part<deriv_weight>(input, result, reproj_err_d, reproj_err_d_row);
}

int main(const int argc, const char* argv[]) {

    std::string path = std::string(argv[1]);

    std::cout << path << std::endl;
    //exit(0);
    // std::vector<std::string> paths = {
    //       "ba2_n21_m11315_p36455.txt",
    //       "ba3_n161_m48126_p182072.txt",
    //       "ba1_n49_m7776_p31843.txt",
    //       "ba4_n372_m47423_p204472.txt",
    //       "ba5_n257_m65132_p225911.txt",
    // };

    // std::vector<std::string> paths = {
    //     "ba13_n245_m198739_p1091386.txt"
    // };

     std::vector<std::string> paths = {path } ;

    #ifdef OMP
        std::string outputfile = "output/" +path + "_results_omp.json";
     #ifdef OBJECTIVE
          outputfile = "output/objective_" + path + "_results_omp.json";
    #endif

    #else
        std::string outputfile = "output/" + path + "_results_serial.json";
    #endif



    std::ofstream jsonfile(outputfile.c_str(), std::ofstream::trunc);

    json test_results;

    for (auto path : paths) {
      json test_suite;
      test_suite["name"] = path;

    int ntimes = 3;
    {


    struct BAInput*   input1 = new   struct BAInput  [ ntimes];
    struct BAOutput* result1=  new   struct BAOutput  [ ntimes];;

    //预热，不算时间
    for(int i = 0; i < ntimes; i++){

        //struct BAInput start_input;
        read_ba_instance("../../../data/ba/" + path, input1[i].n, input1[i].m, input1[i].p, input1[i].cams, input1[i].X, input1[i].w, input1[i].obs, input1[i].feats);
        result1[i] = BAOutput{
            std::vector<double>(2 * input1[i].p),
            std::vector<double>(input1[i].p),
            BASparseMat(input1[i].n, input1[i].m, input1[i].p)
        };
        //calculate_jacobian<dcompute_reproj_error, dcompute_zach_weight_error>(start_input, start_result);
    }

    #ifdef OBJECTIVE
        ba_objective(
            input1[0].n,
            input1[0].m,
            input1[0].p,
            input1[0].cams.data(),
            input1[0].X.data(),
            input1[0].w.data(),
            input1[0].obs.data(),
            input1[0].feats.data(),
            result1[0].reproj_err.data(),
            result1[0].w_err.data()
        );
    #else
        calculate_jacobian<dcompute_reproj_error, dcompute_zach_weight_error>(input1[0], result1[0]);
    #endif


    struct BAInput input;
    read_ba_instance("../../../data/ba/" + path, input.n, input.m, input.p, input.cams, input.X, input.w, input.obs, input.feats);

    struct BAOutput result = {
        std::vector<double>(2 * input.p),
        std::vector<double>(input.p),
        BASparseMat(input.n, input.m, input.p)
    };


    {
      struct timeval start, end;

      int i;
      for(i = 0; i < 3; i++){

    #ifdef OBJECTIVE
        ba_objective(
            input1[i].n,
            input1[i].m,
            input1[i].p,
            input1[i].cams.data(),
            input1[i].X.data(),
            input1[i].w.data(),
            input1[i].obs.data(),
            input1[i].feats.data(),
            result1[i].reproj_err.data(),
            result1[i].w_err.data()
        );
    #else
        calculate_jacobian<dcompute_reproj_error, dcompute_zach_weight_error>(input1[i], result1[i]);
    #endif
      }

      double totaltime = 0.0;
      for(i = 0; i < ntimes; i++){
        gettimeofday(&start, NULL);
    #ifdef OBJECTIVE
        ba_objective(
            input1[i].n,
            input1[i].m,
            input1[i].p,
            input1[i].cams.data(),
            input1[i].X.data(),
            input1[i].w.data(),
            input1[i].obs.data(),
            input1[i].feats.data(),
            result1[i].reproj_err.data(),
            result1[i].w_err.data()
        );
    #else
        calculate_jacobian<dcompute_reproj_error, dcompute_zach_weight_error>(input1[i], result1[i]);
    #endif
        gettimeofday(&end, NULL);
        totaltime += tdiff(&start, &end);
        if (totaltime > 60)
            break;
      }
    #ifdef OBJECTIVE
        ba_objective(
            input1[i].n,
            input1[i].m,
            input1[i].p,
            input1[i].cams.data(),
            input1[i].X.data(),
            input1[i].w.data(),
            input1[i].obs.data(),
            input1[i].feats.data(),
            result1[i].reproj_err.data(),
            result1[i].w_err.data()
        );
    #else
        calculate_jacobian<dcompute_reproj_error, dcompute_zach_weight_error>(input1[i], result1[i]);
    #endif



      json enzyme;
      enzyme["name"] = "Enzyme combined";
      enzyme["p"] = input.p;
      enzyme["runtime"] = totaltime / ((double)i);
      //enzyme["runtime"] = (double)duration.count() / 10000.0;
      #ifdef INSERT
      for(unsigned i=0; i<result.J.vals.size(); i++) {
        if (i<5)
            printf("%f ", result.J.vals[i]);
        enzyme["result"].push_back(result.J.vals[i]);
      }
      #endif
      //printf("\n");
      test_suite["tools"].push_back(enzyme);
    }

    }
    test_suite["llvm-version"] = __clang_version__;
    test_suite["mode"] = "ReverseMode";
    test_suite["batch-size"] = 1;
    test_results.push_back(test_suite);
   }
   jsonfile << std::setw(4) << test_results;
}

