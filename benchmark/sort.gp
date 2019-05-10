set title 'Sort benchmark'
set xlabel 'Elements'
set ylabel 'Seconds'
set key autotitle columnheader noenhanced

set xtics format '%.1s%c'
set lmargin 10
set rmargin 10
set grid

set style line 1 linecolor rgb 'red' linetype 1 linewidth 1.5 pointtype 6 pointsize 1
set style line 2 linecolor rgb 'green' linetype 1 linewidth 1.5 pointtype 6 pointsize 1
set style line 3 linecolor rgb 'blue' linetype 1 linewidth 1.5 pointtype 6 pointsize 1

set terminal png size 1280,960
set output 'sort.png'

plot for [i=2:4] 'sort.dat' using 1:i with linespoints linestyle i-1, \
	for [i=2:4] '' using 1:i:(sprintf('%.2fs', column(i))) with labels offset 2.5,0.5 notitle

set terminal wxt persist

replot
