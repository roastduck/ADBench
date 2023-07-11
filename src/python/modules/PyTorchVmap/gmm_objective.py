# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import math
import torch


def log_gamma_distrib(a, p):
    return torch.special.multigammaln(a, p)


def log_wishart_prior(p, wishart_gamma, wishart_m, sum_qs, Qdiags, icf):
    n = p + wishart_m + 1
    k = icf.shape[0]

    out = torch.sum(
        0.5 * wishart_gamma**2 *
        (torch.sum(Qdiags**2, dim=1) + torch.sum(icf[:, p:]**2, dim=1)) -
        wishart_m * sum_qs)

    C = n * p * (math.log(wishart_gamma / math.sqrt(2)))
    return out - k * (C - log_gamma_distrib(0.5 * n, p))


def constructL(d, icf: torch.Tensor):
    i, j = torch.triu_indices(d, d, 1, device=icf.device)
    result = torch.zeros((icf.shape[0], d, d),
                         dtype=icf.dtype,
                         device=icf.device)
    result[:, j, i] = icf[:, d:]
    return result


def Qtimesx(Qdiag, L, x):

    f = torch.einsum('ijk,mik->mij', L, x)
    return Qdiag * x + f


def gmm_objective(alphas, means, icf, x, wishart_gamma, wishart_m):
    n = x.shape[0]
    d = x.shape[1]

    Qdiags = torch.exp(icf[:, :d])
    sum_qs = torch.sum(icf[:, :d], 1)
    Ls = constructL(d, icf)

    xcentered = x.unsqueeze(1) - means
    Lxcentered = Qtimesx(Qdiags, Ls, xcentered)
    sqsum_Lxcentered = torch.sum(Lxcentered**2, 2)
    inner_term = alphas + sum_qs - 0.5 * sqsum_Lxcentered
    lse = torch.logsumexp(inner_term, dim=1)
    slse = torch.sum(lse)

    CONSTANT = -n * d * 0.5 * math.log(2 * math.pi)
    return CONSTANT + slse - n * torch.logsumexp(alphas, dim=0) \
        + log_wishart_prior(d, wishart_gamma, wishart_m, sum_qs, Qdiags, icf)
