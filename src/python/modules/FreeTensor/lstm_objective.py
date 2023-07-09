import freetensor as ft


# The LSTM model
@ft.inline
def lstm(weight, bias, hidden, cell, _input):
    # NOTE this line came from: gates = hcat(input,hidden) * weight .+ bias
    hsize = hidden.shape(0)
    forget = ft.sigmoid(_input * weight[0:hsize] + bias[0:hsize])
    ingate = ft.sigmoid(hidden * weight[hsize:2 * hsize] +
                        bias[hsize:2 * hsize])
    outgate = ft.sigmoid(_input * weight[2 * hsize:3 * hsize] +
                         bias[2 * hsize:3 * hsize])
    change = ft.tanh(hidden * weight[3 * hsize:] + bias[3 * hsize:])
    cell = cell * forget + ingate * change
    hidden = outgate * ft.tanh(cell)
    return (hidden, cell)


# Predict output given an input
@ft.inline
def predict(w, w2, s, x):
    # create new temp x
    x = x * w2[0]
    for i in range(0, s.shape(0), 2):
        (s[i], s[i + 1]) = lstm(w[i], w[i + 1], s[i], s[i + 1], x)
        x[...] = s[i]
    return x * w2[1] + w2[2]


# Get the average loss for the LSTM across a sequence of inputs
@ft.inline
def lstm_objective_inline(main_params, extra_params, state, sequence):
    total = ft.var(0., 'float64')
    internal_state = ft.empty(state.shape(), 'float64')
    internal_state[...] = state
    for t in range(0, sequence.shape(0) - 1):
        ypred = predict(main_params, extra_params, internal_state, sequence[t])
        ynorm = ypred - ft.ln(2 + ft.reduce_sum(ft.exp(ypred), keepdims=False))
        ygold = sequence[t + 1]
        total[...] += ft.reduce_sum(ygold * ynorm, keepdims=False)
    return ft.var(-total / ((sequence.shape(0) - 1) * sequence.shape(1)), 'float64')
