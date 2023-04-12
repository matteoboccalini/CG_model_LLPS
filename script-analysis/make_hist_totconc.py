from numpy import histogram, mean, std, sum
import argparse
import matplotlib.pyplot as plt
import seaborn as sns

sns_fnt = {'xtick.labelsize':20, 'ytick.labelsize':20, 'axes.labelsize':24, 'axes.titlesize':20, 'figure.dpi':300, 'grid.linestyle':'-', 'lines.linewidth':3, 'lines.markersize':7, 'legend.fontsize':15, 'savefig.bbox': 'tight'}
sns.set_theme(rc=sns_fnt, style='whitegrid')

####### PARSER #######

parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter, epilog=" ")

parser.add_argument('-temp', dest='temp', required=True, type=int, help='temperature of the simulation [K]')
parser.add_argument('-nbins', dest='nbins', default=50, type=int)
parser.add_argument('-side', dest='side', default=[50 50 500], nargs='+', type=int, help='Length of sides of the box [x, y, z].')
parser.add_argument('-nb', dest='nb', default=2000, type=int, help='Number of particles to which density is related.')

args = parser.parse_args()
temp = args.temp
nbins = args.nbins
side = args.side
nb = args.nb

volume = side[0] * side[1] * side[2]
tot_conc = nb / volume

print('Volume is %snm^3 \n Total concentration is %snm^3' %(volume, tot_conc))

####### RESRAP #######

# TO BE ADJUSTED:
# Histograms bins are set using Freedman Diaconis estimator,
# https://numpy.org/doc/stable/reference/generated/numpy.histogram_bin_edges.html#numpy.histogram_bin_edges
# which is said to be good for large datasets and robust to outliers

# CONSTANTS
nslices = 5
min_bins, max_bins = 0, 0.05


density, hist_density = [], []
liq_density, gas_density = [], []


for slice in range(nslices):
    filein = 'densities-slice%s.dat' %(slice)

    density_slice, hist_density_slice = [], []
    dens_gas, weigth_gas = [], []
    dens_liq, weigth_liq = [], []

    with open(filein, 'r') as fi:
        for row in fi:
            density_slice.append(float(row.split()[0]))
    density.append(density_slice)

    hist_density_slice, bin_edges = histogram(density, bins=nbins, density=True)
    hist_density.append(hist_density_slice)
    for be, hd in zip(bin_edges[:-1], hist_density_slice):
        if (be > 2 * tot_conc):
            dens_liq.append(be)
            weigth_liq.append(hd)
        elif be <= tot_conc:
            dens_gas.append(be)
            weigth_gas.append(hd)

    num_liq = sum([ c * f for c, f in zip(dens_liq, weigth_liq)])
    den_liq = sum(weigth_liq)
    num_gas = sum([ c * f for c, f in zip(dens_gas, weigth_gas)])
    den_gas = sum(weigth_gas)
    liq_density.append(num_liq/den_liq)
    gas_density.append(num_gas/den_gas)

hist_average = mean(hist_density, axis=0)
hist_error = std(hist_density, axis=0)

# write a file with the average PDF over all slices and its standard deviation

with open('histogram-density.dat', 'w') as fo:
    for be, ha, he in zip(bin_edges[:-1], hist_average, hist_error):
        fo.write('{:<12}{:<12}{:<12}\n'.format( format(be,'.4E'), format(ha,'.4E'), format(2 * he,'.4E')))


liq_mean, liq_err = mean(liq_density), std(liq_density)
gas_mean, gas_err = mean(gas_density), std(gas_density)

# write a file that contains:
#1 temperature
#2 average of gas concentration
#3 error of gas concentration
#4 average of concensate concentration
#5 error of condensate concentration

with open('../temp-gas-liq.dat', 'a') as fo:
    fo.write('{:<10}{:<16}{:<16}{:<16}{:<16}\n'.format(temp, format(gas_mean,'.4E'), format(gas_err,'.4E'), format(liq_mean,'.4E'), format(liq_err,'.4E')))


# plot the average PDF over all slices and its standard deviation

fig, ax = plt.subplots(1,1,figsize=(1,1))

ax.set_xlabel(r'[B]')
ax.set_ylabel(r'PDF')

ax.plot(bin_edges[:-1], hist_average, linewidth=3, marker=' ', color='firebrick', zorder=2)
ax.fill_between(bin_edges[:-1], hist_average - hist_error, hist_average + hist_error, alpha = 0.4, color='gray', zorder=1)

fig.savefig('histogram-density.png')

