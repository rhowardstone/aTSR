# Phase 2, Experiment 3: Bioinformatics Repositories

## Overview

Tested six prompt variants on domain-specific bioinformatics repositories to evaluate generalization beyond general-purpose Python code.

## Repositories

1. **dnaapler** - DNA sequence reorientation (gbouras13/dnaapler)
   - Baseline coverage: 25%
   - Domain: Microbial genomics
2. **fastqe** - FASTQ quality visualization with emoji (fastqe/fastqe)
   - Baseline coverage: 42%
   - Domain: NGS sequencing QC
3. **pyfaidx** - FASTA file indexing (mdshw5/pyfaidx)
   - Baseline coverage: 66%
   - Domain: Genomics, sequence analysis

## Prompt Variants

Same six variants as Experiments 1-2 (V1-V6).

## Key Findings

- **Higher failure rates** (20-40%) compared to general-purpose repositories
- **V4 (+Mutations)** showed *negative* coverage efficiency on fastqe
- Domain-specific knowledge gaps led to test failures
- Complex dependencies on biological file formats (FASTA, FASTQ)

## Domain Challenges

- Specialized algorithms (sequence alignment, reorientation)
- Data file parsing (FASTA, FASTQ, VCF formats)
- NGS (Next-Generation Sequencing) workflows
- Microbial sequence analysis edge cases

## Files

- `metrics.json` - Complete metrics for all variant×repo combinations
- `figures/` - Visualizations (same structure as Experiments 1-2)
