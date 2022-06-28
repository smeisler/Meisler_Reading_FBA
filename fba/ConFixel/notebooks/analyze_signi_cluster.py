'''
This is to get the list of fixel indices of a significant cluster
- Manually defined mask - for a bigger, rough boundary of cluster
    -  load in the voxel mask (.mif)
    -  convert it into fixel mask: with list of fixel indices


After these, will run FixelArray/notebooks/analyze_signi_cluster.R for plotting the results
'''

import argparse
import os
import sys
import nibabel as nb

sys.path.append( os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "confixel"  ))
# abspath is the filename of current file including full folder; dirname is where current file is (full path of directory); another dirname means the folder above it
# then go to confixel folder

from confixel.fixels import *    # h5_to_mifs
# This means: from confixel folder -> fixel.py file


def convert_voxelMask_to_fixelIndex(fn_index_mif, fn_directions_mif, fn_manual_mask):
    '''
    This is to convert a voxel mask to a list of fixel indices.
    '''
    # first, get the projection between fixels and voxels
    fixel_table, voxel_table = gather_fixels(fn_index_mif, fn_directions_mif)
    # print(fixel_table.shape)

    # then, load the manual defined voxel mask:
    _, voxel_mask_3D = mif_to_nifti2(fn_manual_mask)
    dim = voxel_mask_3D.shape
    #print(voxel_mask_3D.shape)  # check if this matches to dimensions in index.mif (via mrinfo)

    # # convert 3D to indices
    # list_tf = voxel_mask_3D.ravel() == 1   # ravel means flattened array | # list of true or false whether == 1
    # voxel_mask_index_list_inAllVoxel = [i for i, x in enumerate(list_tf) if x]  # extract the index of true-s
    # # convert back to 3D to get subscripts:
    # voxel_mask_sub_inAllVoxel = np.array( np.unravel_index(voxel_mask_index_list_inAllVoxel, voxel_mask_3D.shape) )
    # #np.amin(voxel_mask_sub_inAllVoxel, axis=1)
    # #np.amax(voxel_mask_sub_inAllVoxel, axis=1)

    # easier way: 
    voxel_mask_sub_inAllVoxel = np.stack((voxel_mask_3D == 1).nonzero())

    # get the corresponding index list of fixels in those voxels
    # using voxel_table: i.j,k are subscript; voxel_id is the index in fixel analysis
    # note: not all voxels are included in fixel analysis, so cannot directly use numpy's ravel() to convert subscript to index

    voxel_mask_index_list_inFixelAnalysis = []
    for i_voxel in np.arange(voxel_mask_sub_inAllVoxel.shape[1]):   # len(voxel_mask_index_list_inAllVoxel)
        i = voxel_mask_sub_inAllVoxel[0,i_voxel]  # dim[0] - 1 - 
        j = voxel_mask_sub_inAllVoxel[1,i_voxel]    # dim[1] - 1 - 
        k = voxel_mask_sub_inAllVoxel[2,i_voxel]  # dim[2] - 1 - 

        voxel_id = voxel_table.loc[(voxel_table["i"] == i) & \
            (voxel_table["j"] == j) & \
            (voxel_table["k"] == k)]["voxel_id"]
        #print(voxel_id)
        # if len(voxel_id) != 1:   # should only 1 (1-1 mapping) or 0 (no fixel in this voxel) - normal if the ROI covers CSF
        #     print("i_voxel=" + str(i_voxel) + ": length = " + str(len(voxel_id)))
        #     print(voxel_id)
        voxel_mask_index_list_inFixelAnalysis.extend(voxel_id.tolist())
        # it is normal that _inFixelAnalysis's len() is smaller than _inAllVoxel, as some voxels in manually drawn mask do not have fixels

    print("number of voxels in manually drawn mask:")
    print(str(voxel_mask_sub_inAllVoxel.shape[1]))
    print("among them, number of voxels that have fixels:")
    print(str(len(voxel_mask_index_list_inFixelAnalysis)))

    ### get the fixel IDs within manual drawn mask:
    fixel_mask_index_list = fixel_table.loc[fixel_table["voxel_id"].isin(voxel_mask_index_list_inFixelAnalysis)]["fixel_id"]
    print("number of fixels within manually drawn mask:")
    print(str(len(fixel_mask_index_list)))

    ### save:
    fn_manual_mask_fixelIdList = fn_manual_mask.replace(".mif","_fixelIdList.txt")
    if (fn_manual_mask == fn_manual_mask_fixelIdList):
        print("Error: two filenames are the same!")
        raise ValueError()

    textfile = open(fn_manual_mask_fixelIdList, "w")
    for element in fixel_mask_index_list:
        textfile.write(str(element) + "\n")
    textfile.close()

    print()

def save_selectedFixel_mask(fn_selected_txt, example_mif):
    '''
    This is to save the "mask" of selected fixels.
    The saved file is a fixel's scalar file (.mif), 
        where 1 = selected, 0 = unselected
        dimension is # of fixels x 1
    Inputs:
        fn_selected_txt: str
            is the text file containing a list of fixel ids. These fixels are selected and to be included in the mask.
        example_mif: str
            abspath to a scalar mif file. Its header is used as a template
    Output:
        - a .mif file of mask of selected fixels
    '''

    # basic information of this fixel dataset
    fixel_table, voxel_table = gather_fixels(fn_index_mif, fn_directions_mif)
    num_fixel_total = fixel_table.shape[0]

    # load the txt of fixel list:
    with open(fn_selected_txt) as f:
        selected_fixelIds_list = [int(line) for line in f]   # as there is only one value (int) in one line, so no need to line.split()

    f.close()

    # make the fixel mask:
    fixel_mask = np.zeros_like(np.arange(num_fixel_total, dtype=np.int32))  # it's a mask, so int32 is enough
    fixel_mask[selected_fixelIds_list] = 1

    # get an example header:
    nifti2_img, _ = mif_to_nifti2(example_mif)

    # save the fixel mask as .mif file:
    temp_nifti2 = nb.Nifti2Image(fixel_mask.reshape(-1, 1, 1),   # reshape to [# of fixels] x 1 x 1
                                     nifti2_img.affine,
                                     header=nifti2_img.header)
    out_mif = fn_selected_txt.replace("_fixelIdList.txt",
                                    "_fixelMask.mif")
    if out_mif == fn_selected_txt:
        print("out_mif is not correct - same as fn_selected_txt!")
        raise ValueError()

    nifti2_to_mif(temp_nifti2, out_mif)

    print("please visually check in mrview if this matches to what your want!")
    '''
    How to visually check: 
    - load the fixel data into mrview (Fixel Plot)
    - colored by = direction
    - Check if these two images matches: (you may take a screenshot for one of them to compare)
        1. threshold by = "which image you use to threshold with"
            thresholds = "the thresholds you apply"
        2. threshold by = "the fixel mask we just saved.mif"   # e.g. "*__Intersect__*mif"

    '''


if __name__ == '__main__':   # main function
    # ++++++++++++++++++++++ CHANGE BELOW FOR YOUR PURPOSE ++++++++++++++++++++++++++++++++++
    # the .h5 file with results of statistics, saved from R:
    fn_h5_results = "/home/chenying/Desktop/fixel_project/data/data_from_josiane/results/ltn_FDC_n938_wResults_nfixels-0_20220109-183909.h5"
    # manually defined mask - for a bigger, rough boundary of cluster:
    filename_manual_mask = "ROI_x69_sage_p_lt_1e-15.mif"  # this should be a .mif file!

    # for thresholding:
    analysis_name = "gam_allOutputs"
    stat_name_thr = "s_Age.p.value"  # the stat name for thresholding
    flag_compare = "lt"
    thr = 1e-15

    # for saving intersect mask:
    example_mif = "/home/chenying/Desktop/fixel_project/data/data_from_josiane/for_fixelcfestats/fdc_10_smoothed_10fwhm_new/sub-80010.mif"
    # ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    folder_results = fn_h5_results.replace(".h5", "")
    fn_manual_mask = os.path.join(folder_results, filename_manual_mask)

    fn_index_mif = os.path.join(folder_results, "index.mif")
    fn_directions_mif = os.path.join(folder_results, "directions.mif")
    
    # filename for intersect:
    tag_thr = analysis_name + "_" + stat_name_thr + "_" + flag_compare + "_" + str(thr)
    filename_intersect_list = tag_thr + "__Intersect__"
    filename_intersect_list += filename_manual_mask.replace(".mif","_fixelIdList.txt")
    fn_intersect_list = os.path.join(folder_results, filename_intersect_list)

    ### Run
    # convert_voxelMask_to_fixelIndex(fn_index_mif, fn_directions_mif,
    #                                 fn_manual_mask)

    save_selectedFixel_mask(fn_intersect_list, example_mif)

    print()
    