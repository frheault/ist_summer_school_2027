#!/usr/bin/env python3
"""
dMRI Summer School - Tutorial 5.4, Track B (called by tutorial_5.4B.sh)
Theme: Structural Connectomics and Graph Theory
Goal: Compute network topology metrics on the structural connectome with NetworkX.
"""

import os
import numpy as np
import networkx as nx

csv_file = "connectome_sift2.csv" if os.path.exists("connectome_sift2.csv") else "connectome.csv"

if not os.path.exists(csv_file):
    print(f"[ERROR] Connectome file '{csv_file}' not found. Run tutorial_5.4B.sh first.")
    exit(1)

print(f"Loading connectome matrix: {csv_file}...")
matrix = np.loadtxt(csv_file, delimiter=",")
print(f"Matrix shape: {matrix.shape[0]} nodes x {matrix.shape[1]} nodes")

# Build weighted NetworkX graph
G = nx.from_numpy_array(matrix)

# Compute core graph metrics (note: nx.global_efficiency uses the binary graph)
density = nx.density(G)
global_eff = nx.global_efficiency(G)
avg_clustering = nx.average_clustering(G, weight="weight")

print("\n--- Structural Connectome Graph Metrics ---")
print(f"  Total Nodes             : {G.number_of_nodes()}")
print(f"  Total Edges             : {G.number_of_edges()}")
print(f"  Graph Density           : {density:.4f}")
print(f"  Global Efficiency (bin) : {global_eff:.4f}")
print(f"  Weighted Avg Clustering : {avg_clustering:.4f}")

# Load node names from MrtrixLUT.txt
lut_file = "template/MrtrixLUT.txt" if os.path.exists("template/MrtrixLUT.txt") else "../template/MrtrixLUT.txt"
lut_names = {}
if os.path.exists(lut_file):
    with open(lut_file, "r") as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 3 and parts[0].isdigit():
                lut_names[int(parts[0]) - 1] = parts[2]

# Print top 5 hub nodes by connection strength (weighted degree)
strengths = dict(G.degree(weight="weight"))
top_hubs = sorted(strengths.items(), key=lambda x: x[1], reverse=True)[:5]

print("\n--- Top 5 Hub Nodes by Strength ---")
for node, str_val in top_hubs:
    label_str = f" ({lut_names[node]})" if node in lut_names else ""
    print(f"  Node {node:02d}{label_str}: Strength = {str_val:.2f}")
