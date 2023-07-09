import numpy as np
import freetensor as ft

from modules.FreeTensor.utils import to_ft_tensor, to_ft_tensors, ft_jacobian
from shared.ITest import ITest
from shared.LSTMData import LSTMInput, LSTMOutput
from modules.FreeTensor.lstm_objective import lstm_objective_inline


class FreeTensorGPULSTM(ITest):
    '''Test class for LSTM diferentiation.'''

    def prepare(self, input):
        '''Prepares calculating. This function must be run before
        any others.'''

        self.device = ft.GPU()
        with self.device:
            self.inputs = to_ft_tensors(
                (input.main_params, input.extra_params))
            self.params = to_ft_tensors((input.state, input.sequence))
            self.gradient = to_ft_tensor(np.empty(0))
            self.objective = to_ft_tensor(np.zeros(1))

            self.n_layers = input.main_params.shape[0] // 2
            self.n_hidden = input.main_params.shape[1] // 4
            self.seq_len = input.sequence.shape[0]

            assert input.main_params.shape == (2 * self.n_layers,
                                               4 * self.n_hidden)
            assert input.extra_params.shape == (3, self.n_hidden)
            assert input.state.shape == (2 * self.n_layers, self.n_hidden)
            assert input.sequence.shape == (self.seq_len, self.n_hidden)

            @ft.transform
            def lstm_objective(main_params, extra_params, state, sequence,
                               n_layers: ft.JIT[int], n_hidden: ft.JIT[int],
                               seq_len: ft.JIT[int]):
                main_params: ft.Var[(2 * n_layers, 4 * n_hidden), 'float64']
                extra_params: ft.Var[(3, n_hidden), 'float64']
                state: ft.Var[(2 * n_layers, n_hidden), 'float64']
                sequence: ft.Var[(seq_len, n_hidden), 'float64']
                return lstm_objective_inline(main_params, extra_params, state,
                                             sequence)

            def schedule(s, target):
                s.auto_use_lib(target)
                s.auto_fission_fuse(target)
                s.auto_reorder(target)
                s.auto_parallelize(target)
                s.auto_set_mem_type(target)
                s.auto_unroll(target)

            self.comp_objective = ft.optimize(
                lstm_objective,
                schedule_callback=lambda s: schedule(s, self.device))
            self.comp_jacobian = ft_jacobian(
                lstm_objective,
                len(self.inputs),
                schedule_callback=lambda s: schedule(s, self.device))

    def output(self):
        '''Returns calculation result.'''

        return LSTMOutput(self.objective.numpy().item(), self.gradient.numpy())

    def calculate_objective(self, times):
        '''Calculates objective function many times.'''

        for i in range(times):
            self.objective = self.comp_objective(*self.inputs, *self.params,
                                                 self.n_layers, self.n_hidden,
                                                 self.seq_len)
        self.device.sync()

    def calculate_jacobian(self, times):
        ''' Calculates objective function jacobian many times.'''

        for i in range(times):
            self.objective, self.gradient = self.comp_jacobian(
                self.inputs,
                self.params + (self.n_layers, self.n_hidden, self.seq_len))
        self.device.sync()
