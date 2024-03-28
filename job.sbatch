#!/bin/bash
#SBATCH --ntasks-per-node=60
#SBATCH -N 12
#SBATCH -p scc
#SBATCH -t 0-2
#SBATCH -C ib-icelake  # or ib-rome

### Begin user config section ###

INBASE="/mnt/home/usteinwandel/ceph/dm_sims/doug/run_4096_G4/output/"
OUTBASE="$HOME/ceph/rockstar_out"
STARTING_SNAP=2
NUM_SNAPS=5
NUM_BLOCKS=1024  # number of files per snapshot

# This is a good default, but make sure NUM_READERS <= NUM_BLOCKS
NUM_READERS_PER_NODE=32
NUM_READERS=$((NUM_READERS_PER_NODE * SLURM_NNODES))

# For rockstar in modules:
#ml rockstar
#rockstar=rockstar

# For gadget4 rockstar:
ml hdf5
rockstar=/mnt/home/drennehan/local/bin/rockstar_dm_only_gadget4

### End user config section ###

mkdir -p $OUTBASE

rm -f $OUTBASE/auto-rockstar.cfg

sed \
    -e "s,RUSTY_NUM_WRITERS,$SLURM_NTASKS,g" \
    -e "s,RUSTY_NUM_READERS,$NUM_READERS,g" \
    -e "s,RUSTY_INBASE,$INBASE,g" \
    -e "s,RUSTY_OUTBASE,$OUTBASE,g" \
    -e "s,RUSTY_NUM_SNAPS,$NUM_SNAPS,g" \
    -e "s,RUSTY_STARTING_SNAP,$STARTING_SNAP,g" \
    -e "s,RUSTY_NUM_BLOCKS,$NUM_BLOCKS,g" \
    rockstar.template.cfg > $OUTBASE/rockstar_input.cfg

$rockstar -c $OUTBASE/rockstar_input.cfg &

# wait for auto-rockstar.cfg to be created
while [ ! -f $OUTBASE/auto-rockstar.cfg ]; do sleep 1; done

# Start NUM_READERS readers and NUM_WRITERS writers.
# Note that Rockstar is designed so that the readers and writers
# mostly aren't doing work at the same time, so it's okay to
# use --overlap to have them share CPUs.

srun -n $NUM_READERS --ntasks-per-node=$NUM_READERS_PER_NODE --mpi=none --overlap $rockstar -c $OUTBASE/auto-rockstar.cfg  &  # start readers
sleep 5
srun --mpi=none --overlap $rockstar -c $OUTBASE/auto-rockstar.cfg &  # start writers

wait
