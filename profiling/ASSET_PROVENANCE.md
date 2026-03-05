# Asset Provenance Manifest

This document records source-of-truth provenance for realistic-scale asset readiness.

## Acquisition Session
- initial_probe_utc: `2026-03-05T20:00:53Z`
- verification_utc: `2026-03-05T21:19:32Z`
- acquisition_mode: `manual_user_download` (user executed `hf download ... --revision <sha> --local-dir ...` from repo root)
- auth_mode_observed: anonymous CLI cache metadata present; explicit token usage not required for completed user download.
- tooling:
  - `huggingface-cli`: available (`huggingface_hub` CLI)
  - `git-lfs`: `3.0.2`
  - `sha256sum`: available

## Canonical Upstream Sources

### Dataset: `yamboo/Griffin_datasets_joint_v65`
- source_url: `https://huggingface.co/datasets/yamboo/Griffin_datasets_joint_v65`
- repo_type: `dataset`
- pinned_revision_sha: `e0c54ceada75317b06f11f8dcda7aa8304fbb593`
- local_path: `datasets/joint-v65`
- local_state: `production_equivalent_verified`
- local_summary:
  - size: `91G`
  - files_total: `4009`
  - files_non_cache: `1336`
  - required_files_present:
    - `metanode.yaml`: yes
    - `metaadj.yaml`: yes
    - `metatask.yaml`: yes
- metadata_evidence:
  - `datasets/joint-v65/.cache/huggingface/download/README.md.metadata` first line = `e0c54ceada75317b06f11f8dcda7aa8304fbb593`
- critical_hashes:
  - `README.md`: `e663ae993bf05331bcf7ca7d8027d6efd9d5d26d52753abc6da148512c56f987`
  - `metanode.yaml`: `88de8767bacbb16295d9242d85b5e861b1e61d087404d895e160967bbbfcd3f7`
  - `metaadj.yaml`: `1caa1217bc802019e7786cc8d7cfc7b6f74594181826c3fe7ad7f64b4dd00e88`
  - `metatask.yaml`: `6b8c03874444173325e19e3a7da966a6523687daaa363ac844fed96db15540db`

### Dataset: `yamboo/Griffin_datasets_single_pretrain_v3`
- source_url: `https://huggingface.co/datasets/yamboo/Griffin_datasets_single_pretrain_v3`
- repo_type: `dataset`
- pinned_revision_sha: `dbb31254586361eaf271db0d1d9bfed6292b820d`
- local_path: `datasets/single-pretrain-v3-hf`
- local_state: `production_equivalent_verified`
- local_summary:
  - size: `6.4G`
  - files_total: `4573`
  - files_non_cache: `1528`
  - required_files_present:
    - `metanode.yaml`: yes
    - `metaadj.yaml`: yes
    - `metatask.yaml`: yes
    - `featnameemb.pt`: yes
    - `edgenameemb.pt`: yes
    - `tasknameemb.pt`: yes
- metadata_evidence:
  - `datasets/single-pretrain-v3-hf/.cache/huggingface/download/README.md.metadata` first line = `dbb31254586361eaf271db0d1d9bfed6292b820d`
- critical_hashes:
  - `README.md`: `ee257e8ac6016f8cc5bbf2062166572e278d7408f73faf53e2d0700df383d42a`
  - `metanode.yaml`: `4403da9cac69634426ae73a20b44f7d645ebd460fa027c6b4ba43dc2e5666ee9`
  - `metaadj.yaml`: `6837404b2096c1a6d41a5baeacdf29c20bd019f9b8a35c4654826ec2d636d2a9`
  - `metatask.yaml`: `805a9406f32a261ae61b38a4fbc3f2159123d814f50f5dd9d7bd39692c303121`
  - `tasknameemb.pt`: `9c14c40fb695beb59019afe27c4e94057a65222983eb13eec2181732ed361393`

### Model: `yamboo/Griffin_models`
- source_url: `https://huggingface.co/yamboo/Griffin_models`
- repo_type: `model`
- pinned_revision_sha: `bd8c5be5130f34e7faa31099d0bd81d95d0aa995`
- local_path: `checkpoints/`
- local_state: `production_equivalent_verified`
- local_summary:
  - required_files_present:
    - `checkpoints/single-completion/config.json`: yes
    - `checkpoints/single-completion/model.safetensors`: yes
    - `checkpoints/single-sft/config.json`: yes
    - `checkpoints/single-sft/model.safetensors`: yes
- metadata_evidence:
  - `checkpoints/.cache/huggingface/download/single-completion/model.safetensors.metadata` first line = `bd8c5be5130f34e7faa31099d0bd81d95d0aa995`
  - `checkpoints/.cache/huggingface/download/single-sft/model.safetensors.metadata` first line = `bd8c5be5130f34e7faa31099d0bd81d95d0aa995`
- critical_hashes:
  - `checkpoints/single-completion/config.json`: `91c9c30c27988e73651b74adcbdc8c28fcf2cdceba703e5d7d5a15a50ec97bb4`
  - `checkpoints/single-completion/model.safetensors`: `aa93815aee4bde59576de34eb8b32f358cbec4fd9a281c781263bcf5dc73fd6c`
  - `checkpoints/single-sft/config.json`: `91c9c30c27988e73651b74adcbdc8c28fcf2cdceba703e5d7d5a15a50ec97bb4`
  - `checkpoints/single-sft/model.safetensors`: `9cd195f6e963fdffc1d4bdb34ba0f78af56aa83f753348f6a0f5a69cf46c323d`

## Local Staged-Run Checkpoints (Historical)
- `checkpoints/single-completion/best_checkpoint/model.safetensors`
  - sha256: `f6651709297916c9b2708c411607e31e197bcfa864ee087803d72ceafc5aebc5`
- `checkpoints/single-sft/best_checkpoint/model.safetensors`
  - sha256: `7e8b3199d7693d0db76beb47eb15480f4762996870f8eb920f00469e12e42158`

## Readiness Decision
- realistic_scale_assets_ready: `true`
- blocker_class: `none`
- decision: `TR-B1 asset provenance gate satisfied; realistic-scale baseline-validation execution may proceed.`
