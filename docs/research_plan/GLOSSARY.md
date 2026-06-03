# Glossary

Definitions for terms used in this research campaign. Read this before working on any experiment to prevent terminology drift.

---

## GPU Architecture

**CUDA core:** A standard GPU processing unit capable of integer and floating-point scalar operations. Executes one floating-point multiply-add per cycle at single precision. Older and less capable per-cycle than Tensor Cores for matrix operations.

**Tensor Core:** A specialized matrix-multiply-accumulate unit present in NVIDIA Ampere (A100), Volta (V100), and newer GPUs. Performs a 4×4 or 16×16 matrix fragment multiply-accumulate in a single clock cycle, providing 8× to 16× throughput over CUDA cores for eligible GEMM operations. Tensor Core utilization requires specific matrix dimension alignment (multiples of 8 or 16 depending on precision).

**GEMM (General Matrix Multiply):** The operation `C = α·A·B + β·C` where A, B, C are matrices. The dominant compute primitive in deep learning. Characterized by three dimensions (M rows of A, N columns of B, K inner dimension).

**SGEMM:** Single-precision GEMM. The `S` prefix denotes float32.

**Waves/SM (full_waves):** A metric reported by Nsight Compute. One "wave" is a complete set of thread blocks filling all Streaming Multiprocessors (SMs) on the GPU simultaneously. `full_waves=0.617` means the kernel launch produces 0.617 full waves — each SM processes less than one complete wave of work over the kernel's lifetime. This indicates spatial underutilization per launch. It does not directly measure throughput loss; that depends also on kernel duration and memory access patterns.

**Occupancy:** The ratio of active warps per SM to the maximum possible active warps. Affected by register usage, shared memory usage, and thread block size. Low occupancy can limit throughput if the kernel is latency-bound.

**Launch count:** The number of times a specific CUDA kernel is dispatched to the GPU. A high launch count with small per-launch work suggests fragmented computation.

---

## Profiling Tools

**Nsight Systems (nsys):** NVIDIA's system-level GPU profiler. Captures a timeline of CPU and GPU activity including CUDA kernel launches, NVTX ranges, API calls, and memory transfers. Produces `.nsys-rep` trace files. Used to identify hotspot kernels by time share and launch count across a full execution trace.

**Nsight Compute (ncu):** NVIDIA's kernel-level GPU profiler. Replays individual kernel launches to collect hardware performance counters. Produces `.ncu-rep` report files or structured section data. Provides detailed metrics: occupancy, wave counts, scheduler statistics, memory throughput, compute throughput. More expensive than nsys (each kernel is replayed multiple times).

**NVTX (NVIDIA Tools Extension):** A C/Python API for inserting named annotation ranges into GPU traces. In Griffin, NVTX labels like `gfm.train_epoch` and `gfm.eval_task` mark model-level execution boundaries, allowing profilers to attribute kernel time to model phases.

---

## Optimization Concepts

**Packing (same-weight packing):** Combining multiple GEMM operations that share the same weight matrix but differ in input data into a single larger GEMM. For example, if 10 different table features are multiplied by the same projection matrix, they can be stacked into a single (10×F) input matrix and processed in one call. This is the primary candidate optimization strategy.

**Batching (BMM / grouped GEMM):** Using batched matrix multiplication (`torch.bmm`) or a grouped GEMM primitive to dispatch a collection of independent GEMMs in a single GPU call, even when the weight matrices differ across instances. Reduces kernel launch overhead and may improve GPU utilization.

**Padding:** Adding zeros to matrix dimensions to align them to tile boundaries (e.g., multiples of 128 or 16). Padding alone does not reduce launch count; it can improve per-launch efficiency for small matrices but wastes compute on the zero elements.

**Grouped GEMM:** A single GPU kernel that executes a list of independent GEMMs with potentially different shapes. Available in libraries such as CUTLASS or via `torch._grouped_mm`. A promising candidate when same-weight packing is not applicable.

**Schema-aware tensorization:** The general strategy of restructuring Griffin's computation to express operations across multiple schema elements (tables, relations, features) as a single tensor operation rather than a loop of separate operations. The goal is to reduce launch count while preserving semantic equivalence.

**Semantic equivalence:** Two implementations are semantically equivalent if they produce numerically identical outputs (within floating-point tolerance) for the same inputs. Any optimization must preserve semantic equivalence to be valid.

**Same-weight packing:** See Packing above. Emphasizes the case where the same learned weight matrix is reused across multiple independent inputs, enabling concatenation.

---

## Measurement Concepts

**Shape census:** A systematic measurement of the actual matrix dimensions (M, N, K) produced at identified call sites during a representative Griffin forward pass. Required input to EXP03 packing microbenchmark.

**Waves/SM:** See above under GPU Architecture.

**Occupancy:** See above under GPU Architecture.

**Launch count:** See above under GPU Architecture.
