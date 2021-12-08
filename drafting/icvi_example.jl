
# ## Plotting

# Now we can plot the criterion values over time to see how the clustering process and ICVI evaluation evolve over time.
# Every ICVI behaves differently, so feel free to experiment with different ICVIs to see their trend lines in cases like that in this notebook.

## Plot the ICVIs over time
# p = scatter(collect(1:n_samples), criterion_values, title="CH ICVI on DDVFA Streaming Clustering of Iris Data")
# plot(p, legend = false, xtickfontsize=6, xguidefontsize=8, titlefont=font(8))
# title!("CH ICVI on DDVFA Streaming Clustering of Iris Data")
# xlabel!("Sample Index")
# ylabel!("Criterion Value")
# xlims!(1, n_samples)
# ylims!(0, Inf)
# try
#     display(p)
# catch
# end