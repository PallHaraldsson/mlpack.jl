export lsh

using mlpack.util.cli

import mlpack_jll
const lshLibrary = mlpack_jll.libmlpack_julia_lsh

# Call the C binding of the mlpack lsh binding.
function lsh_mlpackMain()
  success = ccall((:lsh, lshLibrary), Bool, ())
  if !success
    # Throw an exception---false means there was a C++ exception.
    throw(ErrorException("mlpack binding error; see output"))
  end
end

" Internal module to hold utility functions. "
module lsh_internal
  import ..lshLibrary

" Get the value of a model pointer parameter of type LSHSearch."
function CLIGetParamLSHSearchPtr(paramName::String)
  return ccall((:CLI_GetParamLSHSearchPtr, lshLibrary), Ptr{Nothing}, (Cstring,), paramName)
end

" Set the value of a model pointer parameter of type LSHSearch."
function CLISetParamLSHSearchPtr(paramName::String, ptr::Ptr{Nothing})
  ccall((:CLI_SetParamLSHSearchPtr, lshLibrary), Nothing, (Cstring, Ptr{Nothing}), paramName, ptr)
end

end # module

"""
    lsh(; [bucket_size, hash_width, input_model, k, num_probes, projections, query, reference, second_hash_size, seed, tables, true_neighbors, verbose])

This program will calculate the k approximate-nearest-neighbors of a set of
points using locality-sensitive hashing. You may specify a separate set of
reference points and query points, or just a reference set which will be used as
both the reference and query set. 

For example, the following will return 5 neighbors from the data for each point
in `input` and store the distances in `distances` and the neighbors in
`neighbors`:

julia> using CSV
julia> input = CSV.read("input.csv")
julia> distances, neighbors, _ = lsh(k=5, reference=input)

The output is organized such that row i and column j in the neighbors output
corresponds to the index of the point in the reference set which is the j'th
nearest neighbor from the point in the query set with index i.  Row j and column
i in the distances output file corresponds to the distance between those two
points.

Because this is approximate-nearest-neighbors search, results may be different
from run to run.  Thus, the `seed` parameter can be specified to set the random
seed.

This program also has many other parameters to control its functionality; see
the parameter-specific documentation for more information.

# Arguments

 - `bucket_size::Int`: The size of a bucket in the second level hash. 
      Default value `500`.
      
 - `hash_width::Float64`: The hash width for the first-level hashing in
      the LSH preprocessing. By default, the LSH class automatically estimates a
      hash width for its use.  Default value `0`.
      
 - `input_model::unknown_`: Input LSH model.
 - `k::Int`: Number of nearest neighbors to find.  Default value `0`.

 - `num_probes::Int`: Number of additional probes for multiprobe LSH; if
      0, traditional LSH is used.  Default value `0`.
      
 - `projections::Int`: The number of hash functions for each table 
      Default value `10`.
      
 - `query::Array{Float64, 2}`: Matrix containing query points (optional).
 - `reference::Array{Float64, 2}`: Matrix containing the reference
      dataset.
 - `second_hash_size::Int`: The size of the second level hash table. 
      Default value `99901`.
      
 - `seed::Int`: Random seed.  If 0, 'std::time(NULL)' is used.  Default
      value `0`.
      
 - `tables::Int`: The number of hash tables to be used.  Default value
      `30`.
      
 - `true_neighbors::Array{Int64, 2}`: Matrix of true neighbors to compute
      recall with (the recall is printed when -v is specified).
 - `verbose::Bool`: Display informational messages and the full list of
      parameters and timers at the end of execution.  Default value `false`.
      

# Return values

 - `distances::Array{Float64, 2}`: Matrix to output distances into.
 - `neighbors::Array{Int64, 2}`: Matrix to output neighbors into.
 - `output_model::unknown_`: Output for trained LSH model.

"""
function lsh(;
             bucket_size::Union{Int, Missing} = missing,
             hash_width::Union{Float64, Missing} = missing,
             input_model::Union{Ptr{Nothing}, Missing} = missing,
             k::Union{Int, Missing} = missing,
             num_probes::Union{Int, Missing} = missing,
             projections::Union{Int, Missing} = missing,
             query = missing,
             reference = missing,
             second_hash_size::Union{Int, Missing} = missing,
             seed::Union{Int, Missing} = missing,
             tables::Union{Int, Missing} = missing,
             true_neighbors = missing,
             verbose::Union{Bool, Missing} = missing,
             points_are_rows::Bool = true)
  # Force the symbols to load.
  ccall((:loadSymbols, lshLibrary), Nothing, ());

  CLIRestoreSettings("K-Approximate-Nearest-Neighbor Search with LSH")

  # Process each input argument before calling mlpackMain().
  if !ismissing(bucket_size)
    CLISetParam("bucket_size", convert(Int, bucket_size))
  end
  if !ismissing(hash_width)
    CLISetParam("hash_width", convert(Float64, hash_width))
  end
  if !ismissing(input_model)
    lsh_internal.CLISetParamLSHSearchPtr("input_model", convert(Ptr{Nothing}, input_model))
  end
  if !ismissing(k)
    CLISetParam("k", convert(Int, k))
  end
  if !ismissing(num_probes)
    CLISetParam("num_probes", convert(Int, num_probes))
  end
  if !ismissing(projections)
    CLISetParam("projections", convert(Int, projections))
  end
  if !ismissing(query)
    CLISetParamMat("query", query, points_are_rows)
  end
  if !ismissing(reference)
    CLISetParamMat("reference", reference, points_are_rows)
  end
  if !ismissing(second_hash_size)
    CLISetParam("second_hash_size", convert(Int, second_hash_size))
  end
  if !ismissing(seed)
    CLISetParam("seed", convert(Int, seed))
  end
  if !ismissing(tables)
    CLISetParam("tables", convert(Int, tables))
  end
  if !ismissing(true_neighbors)
    CLISetParamUMat("true_neighbors", true_neighbors, points_are_rows)
  end
  if verbose !== nothing && verbose === true
    CLIEnableVerbose()
  else
    CLIDisableVerbose()
  end

  CLISetPassed("distances")
  CLISetPassed("neighbors")
  CLISetPassed("output_model")
  # Call the program.
  lsh_mlpackMain()

  return CLIGetParamMat("distances", points_are_rows),
         CLIGetParamUMat("neighbors", points_are_rows),
         lsh_internal.CLIGetParamLSHSearchPtr("output_model")
end
