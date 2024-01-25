// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

#pragma once

#include <vector>

#include "../../shared/GMMData.h"
#include "../../shared/ITest.h"

class EnzymeGMM : public ITest<GMMInput, GMMOutput> {
   private:
    GMMInput input, input_t;
    GMMOutput result;
    std::vector<double> state;

   public:
    // This function must be called before any other function.
    virtual void prepare(GMMInput&& input) override;

    virtual void calculate_objective(int times) override;
    virtual void calculate_jacobian(int times) override;
    virtual GMMOutput output() override;

    ~EnzymeGMM() {}
};

