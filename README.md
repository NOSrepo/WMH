# NOS WMH

This repository hosts the code for the extraction of White Matter Hyperintensities from FLAIR MRI images using a diverse set of algorithms.

A tarball of all employed singularity containers (18GB) can be downloaded from the following location: https://g-24ef4c.98c54.8443.data.globus.org/NOS_WMHcontainers.tar.gz

The main script NOS_WMHsegment.sh performs White Matter Hyperintensities (WMH) segmentation from FLAIR images.
Author: Norman Scheel, scheelno@msu.edu, Department of Radiology, Michigan State University, East Lansing, MI, USA (12/18/2024)

Usage:
  ./NOS_WMHsegment.sh [options]

Options:
  -inT1 <path>         Path to the input T1-weighted image.
  -inFLAIR <path>      Path to the input FLAIR image.
  -outFolder <path>    Path to the output folder where results will be saved.
  -threads <number>    Number of threads to use for processing.
  -doLPA               Perform LPA segmentation.
  -doPGS               Perform PGS segmentation.
  -doSYSU              Perform SYSU media 2 segmentation.
  -doFMRIB             Perform FMRIB truenet segmentation.
  -doUCD               Perform UC Davis segmentation.
  -doLSTAI             Perform LSTAI segmentation.
  -doWMHsynthseg       Perform WMHsynthseg segmentation.
  -doALL               Perform all segmentations.

Example:
  ./NOS_WMHsegment.sh -inT1 /path/to/t1.nii -inFLAIR /path/to/flair.nii -outFolder /path/to/output -threads 4 -doLPA -doPGS

Note:
  Ensure that the input images are in NIfTI format and the paths are correctly specified.
  The output folder should be empty or non-existent before running the script.
  The script requires Singularity, to run PGS, SYSU media 2, FMRIB-TrUENet-2, LST-AI, and the UC Davis WMHkit.
  The script requires FreeSurfer >= 7.4.1, to run synthetic T1 based image registration.
  The script requires MATLAB with SPM12 and LST to run LPA.
  The script requires FSL, AFNI, ANTs, for preprocessing and postprocessing.
  The script also requires the Singularity containers to be available in the specified location (please adjust the containerlocation variable below).
  A tarball of all containers (18GB) can be downloaded from the following location: https://g-24ef4c.98c54.8443.data.globus.org/NOS_WMHcontainers.tar.gz
  The script will create a folder structure in the output folder and save the results in the appropriate folders.
  The script will also create symbolic links to the input images in the output folder if they are not already there.
  The script will perform the specified segmentations and save the results in the output folder.
  The script will calculate the volume of FLAIR hyperintensities and save it as ml in a text file in the output folder.

Please give credit to the authors by citing the following papers:
  Scheel & Hubert, et al. in preparation: Assessment of MRI T2 FLAIR White Matter Hyperintensity Segmentation Algorithms for Volumetric Analysis in Clinical Trials
  LPA............: Schmidt P, Gaser C, Arsic M, et al. An automated tool for detection of FLAIR-hyperintense white-matter lesions in Multiple Sclerosis. NeuroImage. 2012;59(4):3774-3783. doi:10.1016/j.neuroimage.2011.11.032
	LST-AI.........: Wiltgen T, McGinnis J, Schlaeger S, et al. LST-AI: A deep learning ensemble for accurate MS lesion segmentation. NeuroImage Clin. 2024;42:103611. doi:10.1016/j.nicl.2024.103611
	UCD-WMHkit.....: DeCarli C, Fletcher E, Ramey V, Harvey D, Jagust WJ. Anatomical mapping of white matter hyperintensities (WMH): Exploring the relationships between periventricular WMH, deep WMH, and total WMH burden. Stroke. 2005;36(1):50-55. doi:10.1161/01.STR.0000150668.58689.f2
	WMHsynthseg....: Laso P, Cerri S, Sorby-Adams A, et al. Quantifying white matter hyperintensity and brain volumes in heterogeneous clinical and low-field portable MRI. Published online February 15, 2024. doi:10.48550/arXiv.2312.05119
	PGS............: Park G, Hong J, Duffy BA, Lee JM, Kim H. White matter hyperintensities segmentation using the ensemble U-Net with multi-scale highlighting foregrounds. NeuroImage. 2021;237:118140. doi:10.1016/j.neuroimage.2021.118140
	Sysu-Media-2...: Li H, Menze B. Robust White Matter Hyperintensities Segmentation by Deep Stack Networks and Ensemble Learning. Technical University of Munich; 2021. https://wmh.isi.uu.nl/wp-content/uploads/2018/08/sysu_media_2.pdf
	FMRIB-TrUENet-2: Sundaresan V, Zamboni G, Rothwell PM, Jenkinson M, Griffanti L. Triplanar ensemble U-Net model for white matter hyperintensities segmentation on MR images. Med Image Anal. 2021;73:102184. doi:10.1016/j.media.2021.102184

