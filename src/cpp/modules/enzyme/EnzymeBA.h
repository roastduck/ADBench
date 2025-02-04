// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

// EnzymeBA.h - Contains declarations of BA tester functions
#pragma once

#include "../../shared/ITest.h"
#include "../../shared/BAData.h"
#include "../../shared/defs.h"

#include <stdlib.h>
#include <float.h>
#include <string>
#include <string.h>
#include <vector>

class EnzymeBA : public ITest<BAInput, BAOutput>
{
private:
    BAInput input;
    BAOutput result;
    std::vector<double> state;

    // buffer for reprojection error jacobian part holding (column-major)
    std::vector<double> reproj_err_d, zach_weight_error_d;

    // buffer for reprojection error jacobian block row holding
    std::vector<double> reproj_err_d_row;
#ifdef OMP
    std::vector<std::vector<double>> temp_save;
#endif

public:
    // This function must be called before any other function.
    virtual void prepare(BAInput&& input) override;

    virtual void calculate_objective(int times) override;
    virtual void calculate_jacobian(int times) override;
    virtual BAOutput output() override;

    ~EnzymeBA() {}

private:
    void calculate_weight_error_jacobian_part();
    void calculate_reproj_error_jacobian_part();
};
