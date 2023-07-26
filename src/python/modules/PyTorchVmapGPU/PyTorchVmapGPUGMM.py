# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import numpy as np
import torch

from modules.PyTorchVmap.utils import to_torch_tensors, torch_jacobian
from shared.ITest import ITest
from shared.GMMData import GMMInput, GMMOutput
from modules.PyTorchVmap.gmm_objective import gmm_objective


# If using torch.compile, some cases will crash
#gmm_objective_compiled = torch.compile(gmm_objective)
gmm_objective_compiled = gmm_objective

#gmm_jacobian_compiled = torch.compile(lambda inputs, params: torch_jacobian(gmm_objective, inputs, params))
# jacobian can't be compiled: RuntimeError: Cannot access data pointer of Tensor that doesn't have storage
gmm_jacobian_compiled = lambda inputs, params: torch_jacobian(gmm_objective, inputs, params)

class PyTorchVmapGPUGMM(ITest):
    '''Test class for GMM differentiation by PyTorchGPU.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.inputs = to_torch_tensors(
            (input.alphas, input.means, input.icf),
            grad_req = True,
            device = 'cuda'
        )

        self.params = to_torch_tensors(
            (input.x, input.wishart.gamma, input.wishart.m),
            device = 'cuda'
        )

        self.objective = torch.zeros(1, device = 'cuda')
        self.gradient = torch.empty(0, device = 'cuda')

    def output(self):
        '''Returns calculation result.'''

        return GMMOutput(self.objective.item(), self.gradient.detach().cpu().numpy())

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for i in range(times):
            self.objective = gmm_objective_compiled(*self.inputs, *self.params)
        torch.cuda.synchronize()

    def calculate_jacobian(self, times):
        '''Calculates objective function jacobian many times.'''

        for i in range(times):
            self.objective, self.gradient = gmm_jacobian_compiled(
                self.inputs,
                self.params
            )
        torch.cuda.synchronize()
