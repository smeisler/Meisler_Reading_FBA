import sys
import argparse
import glob
import shutil
from os.path import exists

# Get arguments from CLI
parser = argparse.ArgumentParser(description='Convert ModelArray H5 outputs to MIF format.')
parser.add_argument('path', metavar='BIDS_root', type=str, nargs='+', help='Full path to BIDS datanase directory')
args = parser.parse_args()
bids_root = args.path[0]
sys.path.insert(0,bids_root+'/code/fba/ConFixel/confixel/')

from fixels import *    # h5_to_mifs
# collect FD mifs to get example header
path_to_fds = bids_root+'/derivatives/fba/template/fixel_stats/fd/'
all_fd_mifs = glob.glob(path_to_fds+'*_fd.mif')
example_mif = all_fd_mifs[0]
h5_files = glob.glob(bids_root+'/derivatives/fba/template/modelarray_outputs/*.h5')
analysis_name = "result_gam"

for h5_file in h5_files:
	print(h5_file)
	fixel_output_dir = h5_file.replace('fixels','mifs').replace('.h5','')
	if exists(fixel_output_dir+'/index.mif'):
		print('Already converted (clear directory if you want to reconvert)')
	else:
		h5_to_mifs(example_mif, h5_file, analysis_name, fixel_output_dir)
		shutil.copyfile(path_to_fds+'directions.mif',fixel_output_dir+'/directions.mif')
		shutil.copyfile(path_to_fds+'index.mif',fixel_output_dir+'/index.mif')
