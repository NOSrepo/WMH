#!/bin/bash
# This script performs White Matter Hyperintensities (WMH) segmentation from FLAIR images.
# Author: Norman Scheel, scheelno@msu.edu, Department of Radiology, Michigan State University, East Lansing, MI, USA (12/18/2024)
#
# Usage:
#   ./NOS_WMHsegment.sh [options]
#
# Options:
#   -inT1 <path>         Path to the input T1-weighted image.
#   -inFLAIR <path>      Path to the input FLAIR image.
#   -outFolder <path>    Path to the output folder where results will be saved.
#   -threads <number>    Number of threads to use for processing.
#   -doLPA               Perform LPA segmentation.
#   -doPGS               Perform PGS segmentation.
#   -doSYSU              Perform SYSU media 2 segmentation.
#   -doFMRIB             Perform FMRIB truenet segmentation.
#   -doUCD               Perform UC Davis segmentation.
#   -doLSTAI             Perform LSTAI segmentation.
#   -doWMHsynthseg       Perform WMHsynthseg segmentation.
#   -doALL               Perform all segmentations.
#
# Example:
#   ./NOS_WMHsegment.sh -inT1 /path/to/t1.nii -inFLAIR /path/to/flair.nii -outFolder /path/to/output -threads 4 -doLPA -doPGS
#
# Note:
#   Ensure that the input images are in NIfTI format and the paths are correctly specified.
#   The output folder should be empty or non-existent before running the script.
#   The script requires Singularity, to run PGS, SYSU media 2, FMRIB-TrUENet-2, LST-AI, and the UC Davis WMHkit.
#   The script requires FreeSurfer >= 7.4.1, to run synthetic T1 based image registration.
#   The script requires MATLAB with SPM12 and LST to run LPA.
#   The script requires FSL, AFNI, ANTs, for preprocessing and postprocessing.
#   The script also requires the Singularity containers to be available in the specified location (please adjust the containerlocation variable below).
#   Containers can be downloaded from the following location: https://g-24ef4c.98c54.8443.data.globus.org/NOS_WMHcontainers.tar.gz
#   The script will create a folder structure in the output folder and save the results in the appropriate folders.
#   The script will also create symbolic links to the input images in the output folder if they are not already there.
#   The script will perform the specified segmentations and save the results in the output folder.
#   The script will calculate the volume of FLAIR hyperintensities and save it as ml in a text file in the output folder.
#
# Please give credit to the authors by citing the following papers:
#   Scheel & Hubert, et al. in preparation: Assessment of MRI T2 FLAIR White Matter Hyperintensity Segmentation Algorithms for Volumetric Analysis in Clinical Trials
#   LPA............: Schmidt P, Gaser C, Arsic M, et al. An automated tool for detection of FLAIR-hyperintense white-matter lesions in Multiple Sclerosis. NeuroImage. 2012;59(4):3774-3783. doi:10.1016/j.neuroimage.2011.11.032
#	LST-AI.........: Wiltgen T, McGinnis J, Schlaeger S, et al. LST-AI: A deep learning ensemble for accurate MS lesion segmentation. NeuroImage Clin. 2024;42:103611. doi:10.1016/j.nicl.2024.103611
#	UCD-WMHkit.....: DeCarli C, Fletcher E, Ramey V, Harvey D, Jagust WJ. Anatomical mapping of white matter hyperintensities (WMH): Exploring the relationships between periventricular WMH, deep WMH, and total WMH burden. Stroke. 2005;36(1):50-55. doi:10.1161/01.STR.0000150668.58689.f2
#	WMHsynthseg....: Laso P, Cerri S, Sorby-Adams A, et al. Quantifying white matter hyperintensity and brain volumes in heterogeneous clinical and low-field portable MRI. Published online February 15, 2024. doi:10.48550/arXiv.2312.05119
#	PGS............: Park G, Hong J, Duffy BA, Lee JM, Kim H. White matter hyperintensities segmentation using the ensemble U-Net with multi-scale highlighting foregrounds. NeuroImage. 2021;237:118140. doi:10.1016/j.neuroimage.2021.118140
#	Sysu-Media-2...: Li H, Menze B. Robust White Matter Hyperintensities Segmentation by Deep Stack Networks and Ensemble Learning. Technical University of Munich; 2021. https://wmh.isi.uu.nl/wp-content/uploads/2018/08/sysu_media_2.pdf
#	FMRIB-TrUENet-2: Sundaresan V, Zamboni G, Rothwell PM, Jenkinson M, Griffanti L. Triplanar ensemble U-Net model for white matter hyperintensities segmentation on MR images. Med Image Anal. 2021;73:102184. doi:10.1016/j.media.2021.102184


# Set default value for container location and FreeSurfer directories
containerlocation='/var/lib/singularity'
FSdir='/usr/local/freesurfer/current';   
FSdir_dev='/usr/local/freesurfer/7-dev'; # only needed for WMHsynthseg

# Parse input arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -inT1) inT1="$2"; shift ;;
        -inFLAIR) inFLAIR="$2"; shift ;;
        -outFolder) outputfolder="$2"; shift ;;
        -threads) threads="$2"; shift ;;
        -doLPA) doLPA=true ;;
        -doPGS) doPGS=true ;;
        -doSYSU) doSYSU=true ;;
        -doFMRIB) doFMRIB=true ;;
        -doUCD) doUCD=true ;;
        -doLSTAI) doLSTAI=true ;;
        -doWMHsynthseg) doWMHsynthseg=true ;;
        -doALL) doLPA=true; doPGS=true; doSYSU=true; doFMRIB=true; doUCD=true; doLSTAI=true; doWMHsynthseg=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Check if required arguments are set
if [[ -z "$inT1" || -z "$inFLAIR" || -z "$outputfolder" || -z "$threads" || (-z "$doLPA" && -z "$doPGS" && -z "$doSYSU" && -z "$doFMRIB" && -z "$doUCD" && -z "$doLSTAI" && -z "$doWMHsynthseg") ]]; then
    echo "Usage: ./NOS_WMHsegment.sh -inT1 <path> -inFLAIR <path> -outFolder <path> -threads <number> [-doLPA] [-doPGS] [-doSYSU] [-doFMRIB] [-doUCD] [-doLSTAI] [-doWMHsynthseg] [-doALL]"
    exit 1
fi

# Check if inFLAIR is a full path
if [[ ! $inFLAIR == /* ]]; then
    # Check if the file exists in the current path
    if [[ -f "./$inFLAIR" ]]; then
        # Replace inFLAIR with the full path
        inFLAIR="$(pwd)/$inFLAIR"
    else
        echo "Error: FLAIR image file not found."
        exit 1
    fi
fi

# Check if inT1 is a full path
if [[ ! $inT1 == /* ]]; then
    # Check if the file exists in the current path
    if [[ -f "./$inT1" ]]; then
        # Replace inT1 with the full path
        inT1="$(pwd)/$inT1"
    else
        echo "Error: T1 image file not found."
        exit 1
    fi
fi

# Check if outputfolder is a full path
if [[ ! $outputfolder == /* ]]; then
    # Prepend the current path to outputfolder
    outputfolder="$(pwd)/$outputfolder"
fi


# print configuration
echo "Running NOS WMH segmentation script with the following configuration:"
echo "T1 Image: $inT1"
echo "FLAIR Image: $inFLAIR"
echo "Output Folder: $outputfolder"
echo "Threads: $threads"
echo "LPA: ${doLPA:-false}"
echo "PGS: ${doPGS:-false}"
echo "SYSU: ${doSYSU:-false}"
echo "FMRIB: ${doFMRIB:-false}"
echo "UCD: ${doUCD:-false}"
echo "LSTAI: ${doLSTAI:-false}"
echo "WMHsynthseg: ${doWMHsynthseg:-false}"

# Set environment variable for number of threads
export OMP_NUM_THREADS="$threads"

# Preprocessing
# create folder structure
folder_proc="${outputfolder}/proc"
folder_orig="${folder_proc}/orig"
folder_pre="${folder_proc}/pre"
folder_seg="${folder_proc}/seg"

if [ ! -f "$folder_pre/FLAIR.nii.gz" ]; then
   
    mkdir -p "$folder_proc"
    mkdir -p "$folder_orig"
    mkdir -p "$folder_pre"
    mkdir -p "$folder_seg"

    # Link FLAIR and T1 to outputfolder if not already there as input
    cd "$outputfolder"
    if [[ "$(dirname "$inFLAIR")" != "$outputfolder" ]]; then
        ln -s "$(realpath --relative-to="$outputfolder" "$inFLAIR")" "$(basename "$inFLAIR")"
    fi
    if [[ "$(dirname "$inT1")" != "$outputfolder" ]]; then
        ln -s "$(realpath --relative-to="$outputfolder" "$inT1")" "$(basename "$inT1")"
    fi

    # Preprocess T1 and FLAIR images
    cd "$folder_orig"

    # Check if T1 and FLAIR images are oblique and repair if necessary
    # still needs to be tested
    T1info=$(3dinfo "$inT1")
    if [[ "$T1info" == *"Data Axes Tilt:  Oblique"* ]]; then
        echo "T1 Oblique! repairing!"
        3dresample -orient LPI -input "$inT1" -prefix 3DT1.nii.gz
        3drefit -deoblique 3DT1.nii.gz
    else
        3dresample -orient LPI -input "$inT1" -prefix 3DT1.nii.gz
    fi
    FLAIRinfo=$(3dinfo "$inFLAIR")
    if [[ "$FLAIRinfo" == *"Data Axes Tilt:  Oblique"* ]]; then
        echo "FLAIR Oblique! repairing!"
        3dresample -orient RPI -input "$inFLAIR" -prefix FLAIR.nii.gz
        3drefit -deoblique FLAIR.nii.gz
    else
        3dresample -orient RPI -input "$inFLAIR" -prefix FLAIR.nii.gz
    fi

    # Resample T1 to match FLAIR orientation and voxel size
    info=$(3dinfo FLAIR.nii.gz)

    # get orientation from FLAIR
    orient=$(echo "$info" | grep -oP '(?<=-orient ).+?(?=\s)')

    # Find every word before "voxels" in $info
    dimensions=$(echo "$info" | grep -oP '\b\w+(?=\svoxels)')

    # Get the first line in $dimensions
    x=$(echo "$dimensions" | head -n 1)

    # Get the second row in $dimensions
    y=$(echo "$dimensions" | sed -n '2p')

    # Get the third row in $dimensions
    z=$(echo "$dimensions" | sed -n '3p')

    # Find every word between -step- and mm in $info
    voxeldims=$(echo "$info" | grep -oP '(?<=-step- ).+?(?= mm)')

    # Get the first line in $dimensions
    dx=$(echo "$voxeldims" | head -n 1)

    # Get the second row in $dimensions
    dy=$(echo "$voxeldims" | sed -n '2p')

    # Get the third row in $dimensions
    dz=$(echo "$voxeldims" | sed -n '3p')

    3dresample -input 3DT1.nii.gz -orient "$orient" -dxyz "$dx" "$dy" "$dz" -prefix T1.nii.gz

    # Perform N4 bias field correction on T1 and FLAIR images
    N4BiasFieldCorrection -i 3DT1.nii.gz -o 3DT1_N4.nii.gz
    N4BiasFieldCorrection -i FLAIR.nii.gz -o FLAIR_N4.nii.gz

    # Align T1 to FLAIR via synthetic T1
    echo "   ==> Aligning T1 to FLAIR via synthetic T1 ..."
    input="FLAIR_N4.nii.gz"
    T1ref="3DT1_N4.nii.gz"
    omat="FLAIR_to_T1.mat"
    output="FLAIR_to_T1.nii.gz"
    dof=6
    idx=$(echo "$input" | grep -b -o ".nii" | grep -o "^[0-9]*")
    mri_synthsr --i "$input" --o "${input:0:idx}_synthT1.nii" --cpu --threads "$threads"
    3drefit -space ORIG "${input:0:idx}_synthT1.nii"
    flirt -in "${input:0:idx}_synthT1.nii" -ref "$T1ref" -dof "$dof" -omat "$omat"
    flirt -in "$input" -ref "$T1ref" -out "$output" -init "$omat" -applyxfm
    convert_xfm -omat "inverse_$omat" -inverse "$omat"
    flirt -in "3DT1_N4.nii.gz" -ref "FLAIR_N4_synthT1.nii" -out 3DT1_to_FLAIR.nii.gz -init inverse_FLAIR_to_T1.mat -applyxfm
    flirt -in "3DT1_N4.nii.gz" -ref "FLAIR_N4.nii.gz" -out T1_to_FLAIR.nii.gz -init inverse_FLAIR_to_T1.mat -applyxfm

    # Move preprocessed files to the appropriate folders
    mv "FLAIR_N4.nii.gz" "$folder_pre/FLAIR.nii.gz"
    mv 3DT1_to_FLAIR.nii.gz "$folder_pre/3DT1.nii.gz"
    mv T1_to_FLAIR.nii.gz "$folder_pre/T1.nii.gz"
    mv "FLAIR_N4_synthT1.nii" "$outputfolder/FLAIR_synthT1.nii"
    mv FLAIR_to_T1.mat "$outputfolder/reg_FLAIR_to_3DT1.txt"
    mv inverse_FLAIR_to_T1.mat reg_3DT1_to_FLAIR.txt
    rm -f *N4* FLAIR_to_T1.nii.gz

    cd "$outputfolder"
    ln -s "$(realpath --relative-to="$outputfolder" "${folder_pre}/3DT1.nii.gz")" T1Volume_aligned.nii.gz
    ln -s "$(realpath --relative-to="$outputfolder" "${folder_pre}/FLAIR.nii.gz")" FLAIR_preprocessed.nii.gz


else
    echo "   ==> found existing files, skipping preprocessing, delete if errors occur ..."
fi

if [ "$doLPA" = true ]; then
    echo "Running LPA ..."
    start_time=$(date +%s)

    # Set output folder for LPA segmentation
    folder_out="${folder_seg}/LPA"
    if [ -d "$folder_out" ]; then
        echo "   ==> found existing LPA segmentation folder, deleting and starting over ..."
        rm -rf "$folder_out"
    fi
    mkdir -p "$folder_out"
    cd "$folder_out"

    # Create symbolic links to the preprocessed FLAIR and T1 images
    cp "${folder_pre}/FLAIR.nii.gz" "$folder_out/FLAIR.nii.gz"
    cp "${folder_pre}/3DT1.nii.gz" "$folder_out/3DT1.nii.gz"
    cp "${folder_pre}/T1.nii.gz" "$folder_out/T1.nii.gz"

    # Unzip the FLAIR image
    gunzip FLAIR.nii.gz

    # Run the LPA segmentation using MATLAB
    matlab -nodisplay -r "try; \
        disp('Running LPA ...'); \
        folder_out = '$folder_out'; \
        matlabbatch{1}.spm.tools.LST.lpa.data_F2 = {'FLAIR.nii,1'}; \
        matlabbatch{1}.spm.tools.LST.lpa.html_report = 1; \
        spm('defaults', 'FMRI'); \
        spm_jobman('run', matlabbatch); \
        LPA_output = fileread('report_LST_lpa_mFLAIR.html'); \
        expr = '[^\\n]*[^\\n]*'; \
        LPA_output = regexp(LPA_output,expr,'match'); \
        for line = 1:size(LPA_output,2), \
            if contains(char(LPA_output(line)),'<td>Lesion volume</td>'), \
                volumeline = char(LPA_output(line+1)); \
                sep1 = strfind(volumeline,'>'); \
                sep2 = strfind(volumeline,'ml'); \
                HyperIntensityVolume = str2double(volumeline(sep1(1)+1:sep2(1)-1)); \
            end; \
        end; \
        dlmwrite('WMHvolumeLPA.txt', HyperIntensityVolume, 'delimiter', '\\t', 'precision', '%.6f'); \
        catch ME; disp(getReport(ME)); exit(1); end; exit(0);"

        rm -f FLAIR.nii
        rm -f mFLAIR.nii
        3drefit -space ORIG ples_lpa_mFLAIR.nii

        3dcalc -a ples_lpa_mFLAIR.nii -expr 'step(a-0.5)' -prefix ples_lpa_mFLAIR_bin.nii

        microliters=$(fslstats ples_lpa_mFLAIR_bin.nii -V)
        mcl=$(echo "$microliters" | cut -d' ' -f1)
        WMHvolume=$(echo "scale=6; $mcl / 1000" | bc)
        printf "%0.6f\n" "$WMHvolume" > WMHvolume.txt

        cd "$outputfolder"
        ln -s "$(realpath --relative-to="$outputfolder" "${folder_out}/ples_lpa_mFLAIR.nii")" WMH_LPA.nii

    end_time=$(date +%s)
    elapsed_time=$(( (end_time - start_time) / 60 ))
    printf "WMH Volume: %0.6f ml\n" "$WMHvolume" > WMH_LPA.txt
    echo "Processing time: $elapsed_time minutes" >> WMH_LPA.txt
    echo "   ==> LPA took $elapsed_time minutes."

fi

if [ "$doLSTAI" = true ]; then
    echo "Running LST-AI ..."
    start_time=$(date +%s)

    # Set output folder for LST-AI segmentation
    folder_out="${folder_seg}/LST-AI"
    if [ -d "$folder_out" ]; then
        echo "   ==> found existing LST-AI segmentation folder, deleting and starting over ..."
        rm -rf "$folder_out"
    fi
    mkdir -p "$folder_out"
    cd "$folder_out"

    # Define input, output, and temporary directories for LST-AI
    lst_in="$folder_pre"
    lst_out="${folder_out}/Result"
    lst_tmp="${folder_out}/tmp"
    mkdir -p "$lst_out"
    mkdir -p "$lst_tmp"

    # Run the LST-AI segmentation using Singularity container
    echo "   ==> running singularity container ..."
    singularity exec --nv -e \
        -B "$lst_in":/custom_apps/lst_input:ro \
        -B "$lst_out":/custom_apps/lst_output \
        -B "$lst_tmp":/custom_apps/lst_temp \
        "$containerlocation/LST-AI.sif" \
        lst --device cpu --t1 /custom_apps/lst_input/3DT1.nii.gz --flair /custom_apps/lst_input/FLAIR.nii.gz --output /custom_apps/lst_output --temp /custom_apps/lst_temp

    # Calculate the volume of FLAIR hyperintensities
    cd "$lst_out"
    gunzip space-flair_seg-lst.nii.gz
    3dcalc -a space-flair_seg-lst.nii -expr 'step(a-0.5)' -prefix space-flair_seg-lst_bin.nii
    # Calculate the volume of FLAIR hyperintensities
    microliters=$(fslstats space-flair_seg-lst_bin.nii -V)
    mcl=$(echo "$microliters" | cut -d' ' -f1)
    WMHvolume=$(echo "scale=6; $mcl / 1000" | bc)
    printf "%0.6f\n" "$WMHvolume" > WMHvolume.txt
    echo "   ==> Volume of FLAIR hyperintensities: $WMHvolume ml"

    # Create a symbolic link to the result image in the output folder
    cd "$outputfolder"
    ln -s "$(realpath --relative-to="$outputfolder" "${lst_out}/space-flair_seg-lst.nii")" WMH_LST-AI.nii

    # Calculate and display the elapsed time
    end_time=$(date +%s)
    elapsed_time=$(( (end_time - start_time) / 60 ))
    printf "WMH Volume: %0.6f ml\n" "$WMHvolume" > WMH_LST-AI.txt
    echo "Processing time: $elapsed_time minutes" >> WMH_LST-AI.txt
    echo "   ==> LST-AI took $elapsed_time minutes."
fi


if [ "$doPGS" = true ]; then
    echo "Running PGS ..."
    start_time=$(date +%s)

    # Set output folder for PGS segmentation
    folder_out="${folder_seg}/PGS"
    if [ -d "$folder_out" ]; then
        echo "   ==> found existing PGS segmentation folder, deleting and starting over ..."
        rm -rf "$folder_out"
    fi
    mkdir -p "$folder_out"
    cd "$folder_out"

    # Run the PGS segmentation using Singularity container
    echo "   ==> running singularity container ..."
    singularity exec -e \
        -B "$folder_orig":/input/orig:ro \
        -B "$folder_pre":/input/pre:ro \
        -B "$folder_out":/output \
        "$containerlocation/pgs_latest.sif" \
        sh /WMHs_segmentation_PGS.sh T1.nii.gz FLAIR.nii.gz result.nii.gz

    # Fix the result image
    3dcopy result.nii.gz result_fixed.nii
    fslcpgeom "${folder_pre}/FLAIR.nii.gz" result_fixed.nii -d

    # Calculate the volume of FLAIR hyperintensities
    microliters=$(fslstats result_fixed.nii -V)
    mcl=$(echo "$microliters" | cut -d' ' -f1)
    WMHvolume=$(echo "scale=6; $mcl / 1000" | bc)
    printf "%0.6f\n" "$WMHvolume" > WMHvolume.txt
    echo "   ==> Volume of FLAIR hyperintensities: $WMHvolume ml"

    # Create a symbolic link to the result image in the output folder
    cd "$outputfolder"
    ln -s "$(realpath --relative-to="$outputfolder" "${folder_out}/result_fixed.nii")" WMH_PGS.nii

    # Calculate and display the elapsed time
    end_time=$(date +%s)
    elapsed_time=$(( (end_time - start_time) / 60 ))
    printf "WMH Volume: %0.6f ml\n" "$WMHvolume" > WMH_PGS.txt
    echo "Processing time: $elapsed_time minutes" >> WMH_PGS.txt
    echo "   ==> PGS took $elapsed_time minutes."
fi


if [ "$doSYSU" = true ]; then
    echo "Running sysu_media_2 ..."
    start_time=$(date +%s)

    # Set output folder for sysu_media_2 segmentation
    folder_out="${folder_seg}/sysu_media_2"
    if [ -d "$folder_out" ]; then
        echo "   ==> found existing sysu_media_2 segmentation folder, deleting and starting over ..."
        rm -rf "$folder_out"
    fi
    mkdir -p "$folder_out"
    cd "$folder_out"

    # Run the sysu_media_2 segmentation using Singularity container
    echo "   ==> running singularity container ..."
    singularity exec -e \
        -B "$folder_orig":/input/orig:ro \
        -B "$folder_pre":/input/pre:ro \
        -B "$folder_out":/output \
        "$containerlocation/sysu_media_2_latest.sif" \
        python /wmhseg_example/example.py

    # Unzip the result image
    gunzip result.nii.gz

    # Set everything that is smaller than 1 in result.nii to 0, excluding 1
    3dcalc -a result.nii -expr 'step(a-0.9999)' -prefix result_fixed.nii

    fslcpgeom "${folder_pre}/FLAIR.nii.gz" result_fixed.nii.gz -d

    # Calculate the volume of FLAIR hyperintensities
    microliters=$(fslstats result_fixed.nii -V)
    mcl=$(echo "$microliters" | cut -d' ' -f1)
    WMHvolume=$(echo "scale=6; $mcl / 1000" | bc)
    printf "%0.6f\n" "$WMHvolume" > WMHvolume.txt
    echo "   ==> Volume of FLAIR hyperintensities: $WMHvolume ml"

    # Create a symbolic link to the result image in the output folder
    cd "$outputfolder"
    ln -s "$(realpath --relative-to="$outputfolder" "${folder_out}/result_fixed.nii")" WMH_sysu_media_2.nii

    # Calculate and display the elapsed time
    end_time=$(date +%s)
    elapsed_time=$(( (end_time - start_time) / 60 ))
    printf "WMH Volume: %0.6f ml\n" "$WMHvolume" > WMH_sysu_media_2.txt
    echo "Processing time: $elapsed_time minutes" >> WMH_sysu_media_2.txt
    echo "   ==> sysu_media_2 took $elapsed_time minutes."
fi

if [ "$doFMRIB" = true ]; then
    echo "Running fmrib-truenet_2 ..."
    start_time=$(date +%s)

    # Set output folder for fmrib-truenet_2 segmentation
    folder_out="${folder_seg}/fmrib-truenet_2"
    if [ -d "$folder_out" ]; then
        echo "   ==> found existing fmrib-truenet_2 segmentation folder, deleting and starting over ..."
        rm -rf "$folder_out"
    fi
    mkdir -p "$folder_out"
    cd "$folder_out"

    # Run the fmrib-truenet_2 segmentation using Singularity container
    echo "   ==> running singularity container ..."
    singularity exec -e \
        -B "$folder_orig":/input/orig:ro \
        -B "$folder_pre":/input/pre:ro \
        -B "$folder_out":/output \
        "$containerlocation/fmrib-truenet_2_latest.sif" \
        python /wmhseg_example/example.py

    # Fix the result image
    fslswapdim result.nii.gz -x -y z result_flipped.nii.gz
    fslcpgeom "${folder_pre}/FLAIR.nii.gz" result_flipped.nii.gz -d
    mv result_flipped.nii.gz result_fixed.nii.gz
    gunzip result_fixed.nii.gz

    # Calculate the volume of FLAIR hyperintensities
    microliters=$(fslstats result_fixed.nii -V)
    mcl=$(echo "$microliters" | cut -d' ' -f1)
    WMHvolume=$(echo "scale=6; $mcl / 1000" | bc)
    printf "%0.6f\n" "$WMHvolume" > WMHvolume.txt
    echo "   ==> Volume of FLAIR hyperintensities: $WMHvolume ml"

    # Create a symbolic link to the result image in the output folder
    cd "$outputfolder"
    ln -s "$(realpath --relative-to="$outputfolder" "${folder_out}/result_fixed.nii")" WMH_fmrib-truenet_2.nii

    # Calculate and display the elapsed time
    end_time=$(date +%s)
    elapsed_time=$(( (end_time - start_time) / 60 ))
    printf "WMH Volume: %0.6f ml\n" "$WMHvolume" > WMH_fmrib-truenet_2.txt
    echo "Processing time: $elapsed_time minutes" >> WMH_fmrib-truenet_2.txt
    echo "   ==> fmrib-truenet_2 took $elapsed_time minutes."
fi

if [ "$doUCD" = true ]; then
    echo "Running UC Davis WMHkit ..."
    start_time=$(date +%s)

    folder_out="${folder_seg}/UCD"
    if [ -d "$folder_out" ]; then
        echo "   ==> found existing UCD segmentation folder, deleting and starting over ..."
        rm -rf "$folder_out"
    fi
    mkdir -p "$folder_out"
    cd "$folder_out"

    # UCD preproc
    3dcopy "${folder_orig}/3DT1.nii.gz" 3DT1.nii
    3dcopy "${folder_pre}/FLAIR.nii.gz" FLAIR.nii

    echo "   ==> running brain extraction ..."
    bet 3DT1 3DT1_bet -R -m -f 0.3
    gunzip 3DT1_bet_mask.nii.gz 3DT1_bet.nii.gz

    run_singularity="singularity exec -e \
        -B $(pwd):$(pwd) \
        $containerlocation/UCDWMH/UCD_WMHkit.sif \
        /opt/UCDWMHSegmentation-1.3/ucd_wmh_segmentation/ucd_wmh_segmentation.py \
        3DT1.nii 3DT1_bet_mask.nii FLAIR.nii --delete-temporary"

    echo "   ==> running singularity container ..."
    output=$(eval "$run_singularity")

    # delete intermediates
    rm -rf 3DT1_orig_WMHProcess
    rm -f 3DT1.nii 3DT1_bet.nii 3DT1_bet_mask.nii FLAIR.nii


    3dcalc -a FLAIR_WMH_Native.nii -expr 'step(a-0.5)' -prefix FLAIR_WMH_Native_bin.nii

    microliters=$(fslstats FLAIR_WMH_Native_bin.nii -V)
    mcl=$(echo "$microliters" | cut -d' ' -f1)
    WMHvolume=$(echo "scale=6; $mcl / 1000" | bc)
    printf "%0.6f\n" "$WMHvolume" > WMHvolume.txt
    echo "   ==> Volume of FLAIR hyperintensities: $WMHvolume ml"

    cd "$outputfolder"
    ln -s "$(realpath --relative-to="$outputfolder" "${folder_out}/FLAIR_WMH_Native.nii")" WMH_UCD.nii

    end_time=$(date +%s)
    elapsed_time=$(( (end_time - start_time) / 60 ))
    printf "WMH Volume: %0.6f ml\n" "$WMHvolume" > WMH_UCDkit.txt
    echo "Processing time: $elapsed_time minutes" >> WMH_UCDkit.txt
    echo "$output" >> WMH_UCDkit.txt
    echo "   ==> UC Davis WMHkit took $elapsed_time minutes."
fi


if [ "$doWMHsynthseg" = true ]; then
    echo "Running WMHsynthseg ..."
    start_time=$(date +%s)

    # Set output folder for WMHsynthseg segmentation
    folder_out="${folder_seg}/WMHsynthseg"
    if [ -d "$folder_out" ]; then
        echo "   ==> found existing WMHsynthseg segmentation folder, deleting and starting over ..."
        rm -rf "$folder_out"
    fi
    mkdir -p "$folder_out"
    cd "$folder_out"

    # switch to dev version of FreeSurfer
    export FREESURFER_HOME=$FSdir_dev
    export MNI_DIR="$FSdir_dev/mni"
    export PATH="${PATH//$FSdir/$FSdir_dev}"
    source $FREESURFER_HOME/SetUpFreeSurfer.sh

    # Run the WMHsynthseg segmentation
    echo "   ==> running WMHsynthseg ..."
    mri_WMHsynthseg --i "${folder_pre}/FLAIR.nii.gz" \
                    --o Result.nii.gz \
                    --csv_vols Result.csv \
                    --threads "$threads" \
                    --crop --save_lesion_probabilities
                    
    # switch back to current version of FreeSurfer
    export FREESURFER_HOME=$FSdir
    export MNI_DIR="$FSdir/mni"
    export PATH="${PATH//$FSdir_dev/$FSdir}" 
    source $FREESURFER_HOME/SetUpFreeSurfer.sh

    # Refit the result images to the original space
    3drefit -space ORIG Result.nii.gz
    3drefit -space ORIG Result.lesion_probs.nii.gz

    # Create a binary mask of the WMH segmentation
    3dcalc -a Result.nii.gz -expr 'equals(a,77)' -prefix Result_binary.nii

    # Calculate the volume of FLAIR hyperintensities
    microliters=$(fslstats Result_binary.nii -V)
    mcl=$(echo "$microliters" | cut -d' ' -f1)
    WMHvolume=$(echo "scale=6; $mcl / 1000" | bc)
    printf "%0.6f\n" "$WMHvolume" > WMHvolume.txt
    echo "   ==> Volume of FLAIR hyperintensities: $WMHvolume ml"


    # Create a symbolic link to the result image in the output folder
    cd "$outputfolder"
    ln -s "$(realpath --relative-to="$outputfolder" "${folder_out}/Result_binary.nii")" WMH_WMHsynthseg.nii

    # Calculate and display the elapsed time
    end_time=$(date +%s)
    elapsed_time=$(( (end_time - start_time) / 60 ))
    printf "WMH Volume: %0.6f ml\n" "$WMHvolume" > WMH_WMHsynthseg.txt
    echo "Processing time: $elapsed_time minutes" >> WMH_WMHsynthseg.txt
    echo "   ==> WMHsynthseg took $elapsed_time minutes."
fi
