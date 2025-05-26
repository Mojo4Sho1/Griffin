import os
import numpy as np
import pandas as pd

from pathlib import Path
import argparse
import shutil
import yaml
import torch

parser = argparse.ArgumentParser()
parser.add_argument('data_dir_1', type=str, default='data/')
parser.add_argument('data_dir_2', type=str, default='data/')
parser.add_argument('output_dir', type=str, default='data/')
args = parser.parse_args()

data_dir_1 = Path(args.data_dir_1)
data_dir_2 = Path(args.data_dir_2)
output_dir = Path(args.output_dir)
output_dir.mkdir(parents=True, exist_ok=False)

# copy all files under edge/, node/, and task/ of data_dir_1 and data_dir_2 to output_dir
for dir in ['edge', 'node', 'task']:
    for src in data_dir_1.glob(f'{dir}/*'):
        dst = output_dir / dir / src.name
        if src.is_dir():
            shutil.copytree(src, dst, dirs_exist_ok=True)
        else:
            shutil.copy2(src, dst)
            
    for src in data_dir_2.glob(f'{dir}/*'):
        dst = output_dir / dir / src.name
        if src.is_dir():
            shutil.copytree(src, dst, dirs_exist_ok=True)
        else:
            shutil.copy2(src, dst)

# read and concatenate metaadj.yaml, metanode.yaml, and metatask.yaml of data_dir_1 and data_dir_2 to output_dir
for file in ['metaadj.yaml', 'metanode.yaml', 'metatask.yaml']:
    with open(data_dir_1 / file, 'r') as f:
        data_1 = yaml.load(f, Loader=yaml.FullLoader)
    with open(data_dir_2 / file, 'r') as f:
        data_2 = yaml.load(f, Loader=yaml.FullLoader)
    data = {**data_1, **data_2}
    with open(output_dir / file, 'w') as f:
        yaml.dump(data, f)

# read dict from edgenameemb.pt, featnameemb.pt, and tasknameemb.pt of data_dir_1 and data_dir_2 to output_dir
for file in ['edgenameemb.pt', 'featnameemb.pt', 'tasknameemb.pt']:
    data_1 = torch.load(data_dir_1 / file)
    data_2 = torch.load(data_dir_2 / file)
    # if have the same key, check if the value is the same
    for key in data_1.keys():
        if key in data_2:
            assert torch.allclose(data_1[key], data_2[key]), f"Key {key} has different values in data_dir_1 and data_dir_2"
    data = {**data_1, **data_2}
    print(data.keys())
    torch.save(data, output_dir / file)

