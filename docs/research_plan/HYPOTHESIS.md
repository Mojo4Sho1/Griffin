# Research Hypothesis

---

## What This Project Is NOT

Do not frame this project as:

> "Griffin bypasses Tensor Cores because its matrix dimensions are odd."

This framing is incomplete. Current NCU evidence shows low wave occupancy and low scheduler eligibility for the dominant GEMM kernel, but it does not directly confirm or deny Tensor Core utilization. Odd dimensions may contribute, but they are not the primary story.

---

## Current Working Hypothesis

Griffin's relational database structure appears to fragment dense computation into many small GPU kernel launches. Each individual launch is likely too small to fill the GPU well (Waves/SM ≈ 0.617 for the dominant GEMM hotspot). The fragmentation plausibly arises because relational schemas create variable-length, irregular table/feature/relation structures — different tables have different numbers of columns, different entities have different numbers of neighbors, different schema graphs have different connectivity — and Griffin's current implementation iterates over these heterogeneous structures, issuing one or more dense operations per structural element rather than combining equivalent operations across elements.

A schema-aware packing, batching, or tensorization strategy may combine equivalent relational dense operations into fewer, larger, more hardware-efficient operations. If such a strategy preserves Griffin's model semantics (same numerical outputs), it could improve GPU utilization without changing model behavior.

---

## Why This Matters for Relational GFMs

Graph foundation models over relational databases face a structural challenge that pure vision or language models do not: the compute graph is determined by the database schema, which is heterogeneous and variable. A customer table and an order table have different numbers of columns; a product may have 3 related items while another has 300. This schema heterogeneity naturally leads to variable-shape tensor operations, and if those operations are issued individually, the resulting GPU launch pattern can be highly fragmented.

If the fragmentation hypothesis is correct, it suggests that a class of relational GFMs — not just Griffin — may benefit from schema-aware computation batching as a systems optimization. The insight would generalize beyond this specific model.

---

## What Would Support the Hypothesis

- EXP01: Source localization showing that the fragmented GEMM launches originate from per-table or per-relation iteration loops in Griffin's model code.
- EXP02: Shape census showing that the observed matrix dimensions are small (e.g., consistent with the 32×32 tile of the dominant GEMM kernel) and highly variable across launches.
- EXP03: Microbenchmark showing that packing EXP02-shaped GEMMs into fewer larger operations reduces per-element compute time and improves Waves/SM.
- EXP04: A schema-aware packing prototype in Griffin that reduces the per-slice launch count for hotspot_1 while producing numerically equivalent outputs.

---

## What Would Falsify or Weaken the Hypothesis

- EXP01 showing that the launches originate from a single large batched operation that is already efficient, not from iteration over schema elements.
- EXP02 showing that the matrix dimensions are large and uniform, not small and heterogeneous.
- EXP03 showing that packing at EXP02 shapes provides no throughput advantage (e.g., because the operations are already memory-bound and packing does not change memory access patterns).
- EXP04 showing that a packing implementation changes model outputs, indicating that the operations are not semantically equivalent across schema elements.

---

## Terminology

**Packing (same-weight packing):** Combining multiple GEMM operations that share the same weight matrix but operate on different input batches into a single larger GEMM. This is the primary candidate strategy.

**Batching (BMM / grouped GEMM):** Using batched matrix multiplication or a grouped GEMM primitive to issue a single GPU operation for a collection of independent GEMMs that may have different weight matrices. This is the secondary candidate strategy.

**Padding:** Adding zeros to matrices to make their dimensions multiples of tile sizes (e.g., 128 or 256). Padding alone does not reduce launch count; it may improve per-launch efficiency but is not the primary idea here.

**Schema-aware tensorization:** The general strategy of restructuring Griffin's computation graph so that operations over multiple schema elements (tables, relations, features) are expressed as a single tensor operation rather than a loop of individual operations.

**Semantic equivalence:** Two implementations are semantically equivalent if they produce bit-identical (or within floating-point tolerance) outputs for the same inputs. Any optimization must preserve semantic equivalence to be valid.

**Grouped GEMM:** A single GPU primitive that executes a list of independent GEMMs with potentially different shapes in a single kernel launch. Available via `torch._grouped_mm` or similar interfaces.

**Shape census:** A measurement of the actual matrix dimensions (M, N, K) produced at identified call sites during a representative forward pass.
