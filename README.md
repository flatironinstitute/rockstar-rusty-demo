# rockstar-rusty-demo

An example setup of Rockstar on Flatiron's rusty cluster.

## Usage
1. Set the variables in `rockstar.template.cfg` according to your simulation.  See https://bitbucket.org/gfcstanford/rockstar/src/main/README.md for documentation. Note that the `RUSTY_` variables in this file are set in `job.sbatch`.
1. Set the `#SBATCH` variables `job.sbatch`, and the other parameters at the top of that file.
1. Submit the job with `sbatch job.sbatch`.

## Advice
1. Request enough nodes for 60 bytes / particle.  E.g. a 4096^3 simulation should use at least five 1 TB nodes, or maybe something more like eight nodes to allow for surprises.
1. Leave a few cores free per node (e.g. `--ntasks-per-node=60` on a 64-core node)
1. `NUM_READERS_PER_NODE=16` is probably a good value for reader disk IO, although it's possible that the subsequent network would benefit from more/fewer readers. But this is usually a small part of the Rockstar runtime.
1. There's no point in using MPI with Rockstar! It's not an MPI code. Instead, it opens direct TCP connections between processes. This is why we use `srun --mpi=none`, and set the interface with `PARALLEL_IO_SERVER_INTERFACE = "ib0"` (otherwise it uses Ethernet by default).
1. With more than a few hundred client processes, you may start to see `Connection timed out` messages. Usually Rockstar will recover from those and continue, but if you see more than a few such messages, you may need to scale down a bit.

## Performance
On the icelake nodes, a relatively unclustered 4096^3 snapshot takes about 15 minutes on 12 nodes.
