#!/usr/bin/env python
import argparse
import os
import os.path as op
from collections import defaultdict
import nibabel as nb
import pandas as pd
import numpy as np
from collections import defaultdict
from tqdm import tqdm
import h5py



def flattened_image(scalar_image, scalar_mask, group_mask_matrix):
    scalar_mask_img = nb.load(scalar_mask)
    scalar_mask_matrix = scalar_mask_img.get_fdata() > 0
    
    scalar_img = nb.load(scalar_image)
    scalar_matrix = scalar_img.get_fdata()

    scalar_matrix[np.logical_not(scalar_mask_matrix)] = np.nan
    return scalar_matrix[group_mask_matrix].squeeze()     # .shape = (#voxels,)  # squeeze() is to remove the 2nd dimension which is not necessary
    

def back_to_3d(group_mask_file, results_array, out_file):
    """ Save a volume file for one statistical metric
    """
    group_mask_img = nb.load(group_mask_file)
    group_mask_matrix = group_mask_img.get_fdata() > 0

    output = np.zeros(group_mask_matrix.shape)
    output[group_mask_matrix] = results_array
    output_img = nb.Nifti1Image(output, affine=group_mask_img.affine,
                                header=group_mask_img.header)
    output_img.to_filename(out_file)


def h5_to_volumes(h5_file, analysis_name, group_mask_file, output_extension, volume_output_dir):
    """ Convert stat results in .h5 file to a list of volume (.nii or .nii.gz) files
    """

    # group-level mask:
    group_mask_img = nb.load(group_mask_file)
    group_mask_matrix = group_mask_img.get_fdata() > 0

    # results in .h5 file:
    h5_data = h5py.File(h5_file, "r")
    results_matrix = h5_data['results/' + analysis_name + '/results_matrix']
    names_data = results_matrix.attrs['colnames']  # NOTE: results_matrix: need to be transposed...
    # print(results_matrix.shape)   

    try:
        results_names = names_data.tolist()
    except Exception:
        print("Unable to read column names, using 'componentNNN' instead")
        results_names = ['component%03d' % (n + 1) for n in
                         range(results_matrix.shape[0])]

    # # Make output directory if it does not exist  # has been done in h5_to_volumes_wrapper()
    # if op.isdir(volume_output_dir) == False:
    #     os.mkdir(volume_output_dir)

    # for loop: save stat metric results one by one:
    for result_col, result_name in enumerate(results_names):
        valid_result_name = result_name.replace(" ", "_").replace("/", "_")

        out_file = op.join(volume_output_dir, analysis_name + "_" + valid_result_name + output_extension)
        output = np.zeros(group_mask_matrix.shape)
        output[group_mask_matrix] = results_matrix[result_col, :]
        output_img = nb.Nifti1Image(output, affine=group_mask_img.affine,
                                    header=group_mask_img.header)
        output_img.to_filename(out_file)


def h5_to_volumes_wrapper():
    parser = get_h5_to_volume_parser()
    args = parser.parse_args()

    volume_output_dir = op.join(args.relative_root, args.output_dir)  # absolute path for output dir
    
    if op.exists(volume_output_dir):
        print("WARNING: Output directory exists")
    os.makedirs(volume_output_dir, exist_ok=True)

    # any files to copy?

    # other arguments:
    group_mask_file = op.join(args.relative_root, args.group_mask_file)
    h5_input = op.join(args.relative_root, args.input_hdf5)
    analysis_name = args.analysis_name
    output_extension = args.output_ext

    # call function:
    h5_to_volumes(h5_input, analysis_name, group_mask_file, output_extension, volume_output_dir)


def write_hdf5(group_mask_file, cohort_file, 
               output_h5='voxeldb.h5',
               relative_root='/'):
    """
    Load all volume data.
    Parameters
    -----------
    group_mask_file: str
        path to a Nifti1 binary group mask file
    cohort_file: str
        path to a csv with demographic info and paths to data
    output_h5: str
        path to a new .h5 file to be written
    relative_root: str
        path to which group_mask_file and cohort_file (and its contents) are relative
    """
    # gather cohort data
    cohort_df = pd.read_csv(op.join(relative_root, cohort_file))

    # Load the group mask image to define the rows of the matrix
    group_mask_img = nb.load(op.join(relative_root, group_mask_file))
    group_mask_matrix = group_mask_img.get_fdata() > 0     # get_fdata(): get matrix data in float format
    voxel_coords = np.column_stack(np.nonzero(group_mask_img.get_fdata()))  # np.nonzero() returns the coords of nonzero elements; then np.column_stack() stack them together as an (#voxels, 3) array

    # voxel_table: records the coordinations of the nonzero voxels; coord starts from 0 (because using python)
    voxel_table = pd.DataFrame(
        dict(
            voxel_id=np.arange(voxel_coords.shape[0]),
            i=voxel_coords[:, 0],
            j=voxel_coords[:, 1],
            k=voxel_coords[:, 2]))


    # upload each cohort's data
    scalars = defaultdict(list)
    sources_lists = defaultdict(list)
    print("Extracting NIfTI data...")
    for ix, row in tqdm(cohort_df.iterrows(), total=cohort_df.shape[0]):   # ix: index of row (start from 0); row: one row of data
        scalar_file = op.join(relative_root, row['source_file'])
        scalar_mask_file = op.join(relative_root, row['source_mask_file'])
        scalar_data = flattened_image(scalar_file, scalar_mask_file, group_mask_matrix)
        scalars[row['scalar_name']].append(scalar_data)   # append to specific scalar_name
        sources_lists[row['scalar_name']].append(row['source_file'])  # append source mif filename to specific scalar_name

    # Write the output
    output_file = op.join(relative_root, output_h5)
    f = h5py.File(output_file, "w")
    
    voxelsh5 = f.create_dataset(name="voxels", data=voxel_table.to_numpy().T)
    voxelsh5.attrs['column_names'] = list(voxel_table.columns)
    
    for scalar_name in scalars.keys():  # in the cohort.csv, two or more scalars in one sheet is allowed, and they can be separated to different scalar group.
        one_scalar_h5 = f.create_dataset('scalars/{}/values'.format(scalar_name),
                         data=np.row_stack(scalars[scalar_name]))
        one_scalar_h5.attrs['column_names'] = list(sources_lists[scalar_name])  # column names: list of source .mif filenames
    f.close()
    return int(not op.exists(output_file))

def get_h5_to_volume_parser():
    parser = argparse.ArgumentParser(
        description="Convert statistical results from an hdf5 file to a volume data (NIfTI file)")
    parser.add_argument(
        "--group-mask-file", "--group_mask_file",
        help="Path to a group mask file",
        required=True)
    parser.add_argument(
        "--cohort-file", "--cohort_file",
        help="Path to a csv with demographic info and paths to data.",
        required=True)
    parser.add_argument(
        "--relative-root", "--relative_root",
        help="Root to which all paths are relative, i.e. defining the (absolute) path to root directory of group_mask_file, cohort_file, and output_hdf5.",
        type=op.abspath, 
        default="/inputs/")
    parser.add_argument(
        "--analysis-name", "--analysis_name",
        help="Name of the statistical analysis results to be saved.")
    parser.add_argument(
        "--input-hdf5", "--input_hdf5",
        help="Name of HDF5 (.h5) file where results outputs are saved.")
    parser.add_argument(
        "--output-dir", "--output_dir",
        help="A directory where output volume files will be saved. If the directory does not exist, it will be automatically created.")
    parser.add_argument(
        "--output-ext", "--output_ext",
        help="The extension for output volume data. Options are .nii.gz (default) and .nii. Please provide the prefix dot.",
        default=".nii.gz")
    return parser
    

def get_parser():

    parser = argparse.ArgumentParser(
        description="Create a hdf5 file of volume data")
    parser.add_argument(
        "--group-mask-file", "--group_mask_file",
        help="Path to a group mask file",
        required=True)
    parser.add_argument(
        "--cohort-file", "--cohort_file",
        help="Path to a csv with demographic info and paths to data.",
        required=True)
    parser.add_argument(
        "--relative-root", "--relative_root",
        help="Root to which all paths are relative, i.e. defining the (absolute) path to root directory of group_mask_file, cohort_file, and output_hdf5.",
        type=op.abspath, 
        default="/inputs/")
    parser.add_argument(
        "--output-hdf5", "--output_hdf5",
        help="Name of HDF5 (.h5) file where outputs will be saved.", 
        default="fixelarray.h5")
    return parser

def main():
    parser = get_parser()
    args = parser.parse_args()
    status = write_hdf5(group_mask_file=args.group_mask_file, 
                        cohort_file=args.cohort_file, 
                        output_h5=args.output_hdf5,
                        relative_root=args.relative_root)


    return status

if __name__ == "__main__":
#    main()
    h5_to_volumes_wrapper()
