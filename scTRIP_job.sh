#!/bin/bash
#
#SBATCH --ntasks=64
#SBATCH --nodes=1
#SBATCH --time=2-00:00
#SBATCH --mem-per-cpu=4G
#SBATCH --partition=highmem
#SBATCH --mail-type=ALL

cd $SLURM_SUBMIT_DIR 
#cd /fast/groups/ag_sanders/scratch/bendy_tmp/ # path to directory containing cloned repository
echo $(pwd)

# test working directory is set correctly
[ ! $(ls | grep 'Snakefile' | wc -l) -ge 1 ] && { echo "ERROR: a Snakefile could not be found in $(pwd), make sure you are cd'ing into the cloned repo dir" ; exit ; }

# correct sample names
for sample in $(ls bam) ; do
        for mydir in all selected ; do
                if [[ "$(ls bam/${sample}/${mydir})" == *sorted* ]] ; then
                        echo "correcting file names in bam/${sample}/${mydir}"
                        for myfile in $(ls bam/$sample/$mydir);  do
                                (
                                        newname=$(echo $myfile | sed 's/sorted/sort/g')
                                        mv bam/$sample/$mydir/$myfile bam/$sample/$mydir/$newname
                                ) &
                                if [[ $(jobs -r -p | wc -l) -ge $(nproc) ]]; # allows nproc number of jobs to be executed in parallel
                                then
                                        wait -n # if there are $(nproc) jobs running wait here for space to start next job
                                fi
                        done
                        wait # wait for all jobs in the above loop to be done
                fi
        done
done

singularity exec --bind /fast docker://smei/mosaicatcher-pipeline-rpe1-chr3 snakemake \
    -j $(nproc) \
    --configfile Snake.config-singularity.BIH.json \
    -F
