# Copyright (c) Microsoft Corporation.
# Licensed under the MIT license.

import numpy as np
import torch

from modules.PyTorch.utils import to_torch_tensors, torch_jacobian
from shared.ITest import ITest
from shared.LSTMData import LSTMInput, LSTMOutput
from modules.PyTorch.lstm_objective import lstm_objective



class PyTorchGPULSTM(ITest):
    '''Test class for LSTM diferentiation by PyTorchGPU.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.inputs = to_torch_tensors(
            (input.main_params, input.extra_params),
            grad_req = True,
            device = 'cuda'
        )

        self.params = to_torch_tensors((input.state, input.sequence), device = 'cuda')
        self.gradient = torch.empty(0, device = 'cuda')
        self.objective = torch.zeros(1, device = 'cuda')

    def output(self):
        '''Returns calculation result.'''

        return LSTMOutput(self.objective.item(), self.gradient.detach().cpu().numpy())

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for i in range(times):
            self.objective = lstm_objective(*self.inputs, *self.params)
        torch.cuda.synchronize()

    def calculate_jacobian(self, times):
        ''' Calculates objective function jacobian many times.'''

        for i in range(times):
            self.objective, self.gradient = torch_jacobian(
                lstm_objective,
                self.inputs,
                self.params
            )
        torch.cuda.synchronize()
