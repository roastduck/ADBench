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
float tdiff(struct timeval *start, struct timeval *end) {
  return (end->tv_sec-start->tv_sec) + 1e-6*(end->tv_usec-start->tv_usec);
}

using namespace std;
using json = nlohmann::json;

struct GMMInput {
    int d, k, n;
    std::vector<double> alphas, means, icf, x;
    Wishart wishart;
};

struct GMMOutput {
    double objective;
    std::vector<double> gradient;
};

struct GMMParameters {
    bool replicate_point;
};

extern "C" {
    void dgmm_objective(int d, int k, int n, const double *alphas, double *
            alphasb, const double *means, double *meansb, const double *icf,
            double *icfb, const double *x, Wishart wishart, double *err, double *
            errb);

    void gmm_objective_b(int d, int k, int n, const double *alphas, double *
        alphasb, const double *means, double *meansb, const double *icf,
        double *icfb, const double *x, Wishart wishart, double *err, double *
        errb);

    void adept_dgmm_objective(int d, int k, int n, const double *alphas, double *
        alphasb, const double *means, double *meansb, const double *icf,
        double *icfb, const double *x, Wishart wishart, double *err, double *
        errb);
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

typedef void(*deriv_t)(int d, int k, int n, const double *alphas, double *alphasb, const double *means, double *meansb, const double *icf,
            double *icfb, const double *x, Wishart wishart, double *err, double *errb);

template<deriv_t deriv>
void calculate_jacobian(struct GMMInput &input, struct GMMOutput &result)
{
    double* alphas_gradient_part = result.gradient.data();
    double* means_gradient_part = result.gradient.data() + input.alphas.size();
    double* icf_gradient_part =
        result.gradient.data() +
        input.alphas.size() +
        input.means.size();

    double tmp = 0.0;       // stores fictive result
                            // (Tapenade doesn't calculate an original function in reverse mode)

    double errb = 1.0;      // stores dY
                            // (equals to 1.0 for gradient calculation)

    deriv(
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



int main(const int argc, const char* argv[]) {
    printf("starting main\n");

    const auto replicate_point = (argc > 9 && string(argv[9]) == "-rep");
    const GMMParameters params = { replicate_point };

    std::vector<std::string> paths ;//= { "10k/gmm_d20_K200.txt" };

    #ifndef RUN_LARGE_POINT
    getTests(paths, "../../../data/gmm/1k", "1k/");
    getTests(paths, "../../../data/gmm/10k", "10k/");
    #else
      paths  = { "10k/gmm_d20_K200.txt" };

    #endif

    #ifdef OMP
     #ifdef OBJECTIVE
         std::ofstream jsonfile("results_objective_omp.json", std::ofstream::trunc);
     #else
        std::ofstream jsonfile("results_omp.json", std::ofstream::trunc);
    #endif

    #else
        #ifdef OBJECTIVE
         std::ofstream jsonfile("results_objective_serial.json", std::ofstream::trunc);
        #else
        std::ofstream jsonfile("results_serial.json", std::ofstream::trunc);
        #endif
    #endif


    json test_results;

    for (auto path : paths) {


    	if (path == "10k/gmm_d128_K200.txt" || path == "10k/gmm_d128_K100.txt" || path == "10k/gmm_d64_K200.txt" || path == "10k/gmm_d128_K50.txt" || path == "10k/gmm_d64_K100.txt") continue;

        printf("starting path %s\n", path.c_str());
      json test_suite;
      test_suite["name"] = path;

    // {

    // struct GMMInput input;
    // read_gmm_instance("data/" + path, &input.d, &input.k, &input.n,
    //     input.alphas, input.means, input.icf, input.x, input.wishart, params.replicate_point);

    // int Jcols = (input.k * (input.d + 1) * (input.d + 2)) / 2;

    // struct GMMOutput result = { 0, std::vector<double>(Jcols) };

    // {
    //   struct timeval start, end;
    //   gettimeofday(&start, NULL);
    //   calculate_jacobian<gmm_objective_b>(input, result);
    //   gettimeofday(&end, NULL);
    //   printf("Tapenade combined %0.6f\n", tdiff(&start, &end));
    //   json tapenade;
    //   tapenade["name"] = "Tapenade combined";
    //   tapenade["runtime"] = tdiff(&start, &end);
    //   for (unsigned i = result.gradient.size() - 5;
    //        i < result.gradient.size(); i++) {
    //     printf("%f ", result.gradient[i]);
    //     tapenade["result"].push_back(result.gradient[i]);
    //   }
    //   test_suite["tools"].push_back(tapenade);
    //   printf("\n");
    // }

    // }

    // {

    // struct GMMInput input;
    // read_gmm_instance("data/" + path, &input.d, &input.k, &input.n,
    //     input.alphas, input.means, input.icf, input.x, input.wishart, params.replicate_point);

    // int Jcols = (input.k * (input.d + 1) * (input.d + 2)) / 2;

    // struct GMMOutput result = { 0, std::vector<double>(Jcols) };

    // try {
    //   struct timeval start, end;
    //   gettimeofday(&start, NULL);
    //   calculate_jacobian<adept_dgmm_objective>(input, result);
    //   gettimeofday(&end, NULL);
    //   printf("Adept combined %0.6f\n", tdiff(&start, &end));
    //   json adept;
    //   adept["name"] = "Adept combined";
    //   adept["runtime"] = tdiff(&start, &end);
    //   for (unsigned i = result.gradient.size() - 5;
    //        i < result.gradient.size(); i++) {
    //     printf("%f ", result.gradient[i]);
    //     adept["result"].push_back(result.gradient[i]);
    //   }
    //   printf("\n");
    //   test_suite["tools"].push_back(adept);
    // } catch(std::bad_alloc) {
    //    printf("Adept combined 88888888 ooms\n");
    // }

    // }
    const int ntimes = 100;
    {

    struct GMMInput input1[ntimes];
    struct GMMOutput result1[ntimes];
    //预热，不算时间
    for(int i = 0; i < ntimes; i++){
        //struct BAInput start_input;
        read_gmm_instance("../../../data/gmm/" + path, &input1[i].d, &input1[i].k, &input1[i].n, input1[i].alphas, input1[i].means, input1[i].icf, input1[i].x, input1[i].wishart, params.replicate_point);
        int Jcols = (input1[i].k * (input1[i].d + 1) * (input1[i].d + 2)) / 2;
        result1[i] = GMMOutput{ 0, std::vector<double>(Jcols) };
    }





    struct GMMInput input;
    read_gmm_instance("../../../data/gmm/" + path, &input.d, &input.k, &input.n,
        input.alphas, input.means, input.icf, input.x, input.wishart, params.replicate_point);

    int Jcols = (input.k * (input.d + 1) * (input.d + 2)) / 2;

    {
        struct GMMInput input1warm[1];
        struct GMMOutput result1warpup[1];
        result1warpup[0] = GMMOutput{ 0, std::vector<double>(Jcols) };
        read_gmm_instance("../../../data/gmm/" + path, &input1warm[0].d, &input1warm[0].k, &input1warm[0].n,
        input1warm[0].alphas, input1warm[0].means, input1warm[0].icf, input1warm[0].x, input1warm[0].wishart,
        params.replicate_point);
        for (int i = 0; i < 3; ++i){
        #ifdef OBJECTIVE
            call_gmm_objective(
                input1warm[0].d,
                input1warm[0].k,
                input1warm[0].n,
                input1warm[0].alphas.data(),
                input1warm[0].means.data(),
                input1warm[0].icf.data(),
                input1warm[0].x.data(),
                input1warm[0].wishart,
                &result1warpup[0].objective);
            #else
            calculate_jacobian<dgmm_objective>(input1warm[0], result1warpup[0]);
        #endif
        }

    }
    struct GMMOutput result = { 0, std::vector<double>(Jcols) };

    {
      struct timeval start, end;
      int cnt = 0;
      float alltime = 0.0;

      for(int i = 0; i < ntimes; i++){
        auto start = std::chrono::high_resolution_clock::now();
        #ifdef OBJECTIVE
         call_gmm_objective(
            input1[i].d,
            input1[i].k,
            input1[i].n,
            input1[i].alphas.data(),
            input1[i].means.data(),
            input1[i].icf.data(),
            input1[i].x.data(),
            input1[i].wishart,
             &result1[i].objective);
        #else
        calculate_jacobian<dgmm_objective>(input1[i], result1[i]);
        #endif
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
        //std::cout << duration.count() << std::endl;
        alltime +=  ((float)duration.count()) / 1000000.0;
        cnt++;
        if (alltime > 100)
            break;
      }

        call_gmm_objective(
        input.d,
        input.k,
        input.n,
        input.alphas.data(),
        input.means.data(),
        input.icf.data(),
        input.x.data(),
        input.wishart,
            &result.objective);
        calculate_jacobian<dgmm_objective>(input, result);



      json enzyme;
      enzyme["name"] = "Enzyme combined";

      enzyme["runtime"] =  alltime / ((float)cnt);


      enzyme["obejective"].push_back(result.objective);
      for (unsigned i = 0;
           i < result.gradient.size(); i++) {
        //printf("%f ", result.gradient[i]);
        //enzyme["result"].push_back(result.gradient[i]);
      }
      printf("\n");
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
