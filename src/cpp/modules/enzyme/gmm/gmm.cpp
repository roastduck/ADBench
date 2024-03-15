// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

/*
 *   File "gmm_b_tapenade_generated.c" is generated by Tapenade 3.14 (r7259)
 * from this file. To reproduce such a generation you can use Tapenade CLI (can
 * be downloaded from http://www-sop.inria.fr/tropics/tapenade/downloading.html)
 *
 *   Firstly, add a type declaration of Wishart to the content of this file
 * (Tapenade can't process a file with unknown types). You can both take this
 * declaration from the file "<repo root>/src/cpp/shared/defs.h" or copypaste
 * the following lines removing asterisks:
 *
 *   typedef struct
 *   {
 *       double gamma;
 *       int m;
 *   } Wishart;
 *
 *   After Tapenade CLI installing use the next command to generate a file:
 *
 *      tapenade -b -o gmm_tapenade -head "gmm_objective(err)/(alphas means
 * icf)" gmm.c
 *
 *   This will produce a file "gmm_tapenade_b.c" which content will be the same
 * as the content of "gmm_b_tapenade_generated.c", except one-line header and a
 * Wishart typedef (which should be removed). Moreover a log-file
 * "gmm_tapenade_b.msg" will be produced.
 *
 *   NOTE: the code in "gmm_b_tapenade_generated.c" is wrong and won't work.
 *         REPAIRED SOURCE IS STORED IN THE FILE "gmm_b.c".
 *         You can either use diff tool or read "gmm_b.c" header to figure out
 * what changes was performed to fix the code.
 *
 *   NOTE: you can also use Tapenade web server
 * (http://tapenade.inria.fr:8080/tapenade/index.jsp) for generating but result
 * can be slightly different.
 */

#include <math.h>
#include <string.h>
#include <stdlib.h>
#include "../../../shared/defs.h"

#define MAX_THREAD_NUM 256
extern "C" {

/* ==================================================================== */
/*                                UTILS                                 */
/* ==================================================================== */

// This throws error on n<1
double arr_max(int n, double const* x) {
    int i;
    double m = x[0];
    for (i = 1; i < n; i++) {
        if (m < x[i]) {
            m = x[i];
        }
    }

    return m;
}

// sum of component squares
double sqnorm(int n, double const* x) {
    int i;
    double res = x[0] * x[0];
    for (i = 1; i < n; i++) {
        res += x[i] * x[i];
    }

    return res;
}

// out = a - b
void subtract(int d, double const* x, double const* y, double* out) {
    int id;
    for (id = 0; id < d; id++) {
        out[id] = x[id] - y[id];
    }
}

double log_sum_exp(int n, double const* x) {
    int i;
    double mx = arr_max(n, x);
    double semx = 0.0;
    for (i = 0; i < n; i++) {
        semx += exp(x[i] - mx);
    }

    return log(semx) + mx;
}

__attribute__((const)) double log_gamma_distrib(double a, double p) {
    int j;
    double out = 0.25 * p * (p - 1) * log(PI);
    for (j = 1; j <= p; j++) {
        out += lgamma(a + 0.5 * (1 - j));
    }

    return out;
}

/* ======================================================================== */
/*                                MAIN LOGIC                                */
/* ======================================================================== */

double log_wishart_prior(int p, int k, Wishart wishart, double const* sum_qs,
                         double const* Qdiags, double const* icf) {
    int ik;
    int n = p + wishart.m + 1;
    int icf_sz = p * (p + 1) / 2;

    double C = n * p * (log(wishart.gamma) - 0.5 * log(2)) -
               log_gamma_distrib(0.5 * n, p);

    double out = 0;
    double* temp_k = new double[k];
    for (ik = 0; ik < k; ik++) {
        double frobenius = sqnorm(p, &Qdiags[ik * p]) +
                           sqnorm(icf_sz - p, &icf[ik * icf_sz + p]);
        temp_k[ik] = 0.5 * wishart.gamma * wishart.gamma *
                     (frobenius)-wishart.m * sum_qs[ik];
        // out += 0.5 * wishart.gamma * wishart.gamma * (frobenius) - wishart.m
        // * sum_qs[ik];
    }

    for (ik = 0; ik < k; ik++) {
        out += temp_k[ik];
    }
    delete[] temp_k;
    return out - k * C;
}

void preprocess_qs(int d, int k, double const* icf, double* sum_qs,
                   double* Qdiags) {
    int ik, id;
    int icf_sz = d * (d + 1) / 2;
    for (ik = 0; ik < k; ik++) {
        sum_qs[ik] = 0.;
        for (id = 0; id < d; id++) {
            double q = icf[ik * icf_sz + id];
            sum_qs[ik] = sum_qs[ik] + q;
            Qdiags[ik * d + id] = exp(q);
        }
    }
}

void Qtimesx(int d, double const* Qdiag,
             double const* ltri,  // strictly lower triangular part
             double const* x, double* out) {
    int i, j;
    for (i = 0; i < d; i++) {
        out[i] = Qdiag[i] * x[i];
    }

    // caching lparams as scev doesn't replicate index calculation
    //  todo note changing to strengthened form
    // int Lparamsidx = 0;
    for (i = 0; i < d; i++) {
        int Lparamsidx = i * (2 * d - i - 1) / 2;
        for (j = i + 1; j < d; j++) {
            // and this x
            out[j] = out[j] + ltri[Lparamsidx] * x[i];
            Lparamsidx++;
        }
    }
}


void gmm_objective(int d, int k, int n, double const* __restrict alphas,
                   double const* __restrict means, double const* __restrict icf,
                   double const* __restrict x, Wishart wishart,
                   double* __restrict err, double* __restrict xcentered,
                   double* __restrict Qxcentered, double* __restrict main_term,
                   double* __restrict Qdiags, double* __restrict sum_qs,
                   double* __restrict temp_save) {
#define int int64_t
    const double CONSTANT = -n * d * 0.5 * log(2 * PI);
    int icf_sz = d * (d + 1) / 2;
    preprocess_qs(d, k, icf, &sum_qs[0], &Qdiags[0]);

    double slse = 0.;
#ifdef OMP
#pragma omp parallel for
#endif
    for (int ix = 0; ix < n; ix++) {
        int dd = d;
        for (int ik = 0; ik < k; ik++) {
#ifndef OMP
            // 只会更改xcentered和qxcentered，且不会读xcentered和qxcentered
            subtract(dd, &x[ix * dd], &means[ik * dd], &xcentered[0]);
            Qtimesx(dd, &Qdiags[ik * dd], &icf[ik * icf_sz + dd], &xcentered[0],
                    &Qxcentered[0]);
            // two caches for qxcentered at idx 0 and at arbitrary index
            main_term[ik] =
                alphas[ik] + sum_qs[ik] - 0.5 * sqnorm(d, &Qxcentered[0]);
#else
            subtract(dd, &x[ix * dd], &means[ik * dd], &xcentered[ix * d + 0]);
            Qtimesx(dd, &Qdiags[ik * dd], &icf[ik * icf_sz + dd],
                    &xcentered[ix * d + 0], &Qxcentered[ix * d + 0]);
            // two caches for qxcentered at idx 0 and at arbitrary index
            main_term[ix * k + ik] = alphas[ik] + sum_qs[ik] -
                                     0.5 * sqnorm(d, &Qxcentered[ix * d + 0]);
#endif
        }

// storing cmp for max of main_term
// 2 x (0 and arbitrary) storing sub to exp
// storing sum for use in log
#ifdef OMP
        temp_save[ix] += log_sum_exp(k, &main_term[ix * k + 0]);
#else
        slse = slse + log_sum_exp(k, &main_term[0]);
#endif
    }
#ifdef OMP
    for (int ix = 0; ix < n; ix++) {
        slse += temp_save[ix];
    }
#endif

    // storing cmp of alphas
    double lse_alphas = log_sum_exp(k, alphas);

    *err = CONSTANT + slse - n * lse_alphas +
           log_wishart_prior(d, k, wishart, &sum_qs[0], &Qdiags[0], icf);

#undef int
}

void call_gmm_objective(int d, int k, int n, double const* __restrict alphas,
                        double const* __restrict means,
                        double const* __restrict icf,
                        double const* __restrict x, Wishart wishart,
                        double* __restrict err) {
    double* xcentered = (double*)calloc(n * d, sizeof(double));
    double* Qxcentered = (double*)calloc(n * d, sizeof(double));
    double* main_term = (double*)calloc(n * k, sizeof(double));
    double* Qdiags = (double*)calloc(d * k, sizeof(double));
    double* sum_qs = (double*)calloc(k, sizeof(double));
    double* temp_save = (double*)calloc(n, sizeof(double));
    gmm_objective(d, k, n, alphas, means, icf, x, wishart, err, xcentered,
                  Qxcentered, main_term, Qdiags, sum_qs, temp_save);
    free(xcentered);
    free(Qxcentered);
    free(main_term);
    free(Qdiags);
    free(sum_qs);
    free(temp_save);
}

extern int enzyme_const;
extern int enzyme_dup;
extern int enzyme_dupnoneed;
void __enzyme_autodiff(...) noexcept;

// *      tapenade -b -o gmm_tapenade -head "gmm_objective(err)/(alphas means
// icf)" gmm.c
void dgmm_objective(int d, int k, int n, const double* alphas, double* alphasb,
                    const double* means, double* meansb, const double* icf,
                    double* icfb, const double* x, Wishart wishart, double* err,
                    double* errb) {
    double* xcentered = (double*)calloc(n * d, sizeof(double));
    double* Qxcentered = (double*)calloc(n * d, sizeof(double));
    double* main_term = (double*)calloc(n * k, sizeof(double));
    double* xcenteredb = (double*)calloc(n * d, sizeof(double));
    double* Qxcenteredb = (double*)calloc(n * d, sizeof(double));
    double* main_termb = (double*)calloc(n * k, sizeof(double));
    double* Qdiags = (double*)calloc(d * k, sizeof(double));
    double* sum_qs = (double*)calloc(k, sizeof(double));
    double* temp_save = (double*)calloc(n, sizeof(double));
    double* Qdiagsb = (double*)calloc(d * k, sizeof(double));
    double* sum_qsb = (double*)calloc(k, sizeof(double));
    double* temp_saveb = (double*)calloc(n, sizeof(double));
    __enzyme_autodiff(gmm_objective, enzyme_const, d, enzyme_const, k,
                      enzyme_const, n, enzyme_dup, alphas, alphasb, enzyme_dup,
                      means, meansb, enzyme_dup, icf, icfb, enzyme_const, x,
                      enzyme_const, wishart, enzyme_dupnoneed, err, errb,
                      enzyme_dup, xcentered, xcenteredb, enzyme_dup, Qxcentered,
                      Qxcenteredb, enzyme_dup, main_term, main_termb,
                      enzyme_dup, Qdiags, Qdiagsb, enzyme_dup, sum_qs, sum_qsb,
                      enzyme_dup, temp_save, temp_saveb);
    // gmm_objective(d, k, n, alphas, means, icf, x, wishart, err);
    free(xcentered);
    free(Qxcentered);
    free(main_term);
    free(xcenteredb);
    free(Qxcenteredb);
    free(main_termb);
    free(Qdiags);
    free(Qdiagsb);
    free(sum_qs);
    free(sum_qsb);
    free(temp_save);
    free(temp_saveb);
}
}

