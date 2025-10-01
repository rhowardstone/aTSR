#!/usr/bin/env python3
"""
Beautiful multi-panel visualization for aTSR benchmark results.
Compares model performance, strategies, and efficiency metrics.
"""

import json
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import numpy as np
from pathlib import Path
import seaborn as sns

# Set style for beautiful plots
plt.style.use('seaborn-v0_8-darkgrid')
sns.set_palette("husl")

def load_data(json_path):
    """Load and parse the benchmark JSON data."""
    with open(json_path, 'r') as f:
        data = json.load(f)
    
    # Extract configurations
    configs = []
    for bench in data['benchmarks']:
        for config in bench['configurations']:
            configs.append(config)
    
    return configs

def create_visualization(json_path, output_path=None):
    """Create comprehensive visualization of benchmark results."""
    
    # Load data
    configs = load_data(json_path)
    
    # Define consistent colors
    colors = {
        'sonnet-4-5-refine': '#FF6B6B',  # Coral red
        'sonnet-4-5-base': '#FFB6B6',     # Light coral
        'opus-4-1-refine': '#4ECDC4',     # Teal
        'opus-4-1-base': '#95E1D3'        # Light teal
    }
    
    # Repository order and labels
    repos = ['schedule', 'mistune', 'click']
    repo_labels = ['Schedule\n(~400 LOC)', 'Mistune\n(~2600 LOC)', 'Click\n(~8000 LOC)']
    
    # Create figure with subplots
    fig = plt.figure(figsize=(18, 12))
    fig.suptitle('Test Suite Refinement Benchmark Results', fontsize=20, fontweight='bold', y=0.98)
    
    # Define grid
    gs = fig.add_gridspec(3, 3, hspace=0.3, wspace=0.25)
    
    # 1. Coverage Comparison (Top Left)
    ax1 = fig.add_subplot(gs[0, 0])
    coverage_data = {repo: {} for repo in repos}
    for config in configs:
        key = f"{config['model']}-{config['strategy']}"
        coverage_data[config['repository']][key] = config['coverage']
    
    x = np.arange(len(repos))
    width = 0.18
    
    for i, (model_strat, color) in enumerate(colors.items()):
        values = [coverage_data[repo].get(model_strat, 0) for repo in repos]
        ax1.bar(x + (i-1.5)*width, values, width, label=model_strat.replace('-', ' ').title(), 
                color=color, alpha=0.9, edgecolor='black', linewidth=0.5)
    
    ax1.set_ylabel('Coverage (%)', fontweight='bold')
    ax1.set_title('Test Coverage Achievement', fontweight='bold', pad=10)
    ax1.set_xticks(x)
    ax1.set_xticklabels(repo_labels)
    ax1.set_ylim([50, 100])
    ax1.legend(loc='lower right', fontsize=8, framealpha=0.9)
    ax1.grid(True, alpha=0.3)
    
    # Add baseline line
    ax1.axhline(y=80, color='green', linestyle='--', alpha=0.5, label='Target (80%)')
    
    # 2. Pass Rate Comparison (Top Middle)
    ax2 = fig.add_subplot(gs[0, 1])
    pass_data = {repo: {} for repo in repos}
    for config in configs:
        key = f"{config['model']}-{config['strategy']}"
        pass_data[config['repository']][key] = config['pass_rate']
    
    for i, (model_strat, color) in enumerate(colors.items()):
        values = [pass_data[repo].get(model_strat, 0) for repo in repos]
        ax2.bar(x + (i-1.5)*width, values, width, label=model_strat.replace('-', ' ').title(), 
                color=color, alpha=0.9, edgecolor='black', linewidth=0.5)
    
    ax2.set_ylabel('Pass Rate (%)', fontweight='bold')
    ax2.set_title('Test Suite Quality (Pass Rate)', fontweight='bold', pad=10)
    ax2.set_xticks(x)
    ax2.set_xticklabels(repo_labels)
    ax2.set_ylim([60, 105])
    ax2.grid(True, alpha=0.3)
    
    # 3. Tests Added (Top Right)
    ax3 = fig.add_subplot(gs[0, 2])
    tests_data = {repo: {} for repo in repos}
    for config in configs:
        key = f"{config['model']}-{config['strategy']}"
        tests_data[config['repository']][key] = config['tests_added']
    
    for i, (model_strat, color) in enumerate(colors.items()):
        values = [tests_data[repo].get(model_strat, 0) for repo in repos]
        ax3.bar(x + (i-1.5)*width, values, width, label=model_strat.replace('-', ' ').title(), 
                color=color, alpha=0.9, edgecolor='black', linewidth=0.5)
    
    ax3.set_ylabel('Tests Added', fontweight='bold')
    ax3.set_title('Test Generation Volume', fontweight='bold', pad=10)
    ax3.set_xticks(x)
    ax3.set_xticklabels(repo_labels)
    ax3.grid(True, alpha=0.3)
    
    # 4. Token Efficiency (Middle Left) - Tests per Million Tokens
    ax4 = fig.add_subplot(gs[1, 0])
    efficiency_data = []
    labels = []
    colors_list = []
    
    for repo in repos:
        for model in ['sonnet-4-5', 'opus-4-1']:
            for strategy in ['refine', 'base']:
                config = next((c for c in configs if c['repository'] == repo 
                              and c['model'] == model and c['strategy'] == strategy), None)
                if config:
                    efficiency = (config['tests_added'] / (config['tokens'] / 1_000_000))
                    efficiency_data.append(efficiency)
                    labels.append(f"{repo[:4]}\n{model.split('-')[0]}-{strategy[:3]}")
                    colors_list.append(colors[f"{model}-{strategy}"])
    
    bars = ax4.bar(range(len(efficiency_data)), efficiency_data, color=colors_list, 
                   alpha=0.9, edgecolor='black', linewidth=0.5)
    ax4.set_ylabel('Tests per Million Tokens', fontweight='bold')
    ax4.set_title('Token Efficiency', fontweight='bold', pad=10)
    ax4.set_xticks(range(len(labels)))
    ax4.set_xticklabels(labels, rotation=45, ha='right', fontsize=7)
    ax4.grid(True, alpha=0.3)
    
    # 5. Coverage vs Tokens Scatter (Middle Center)
    ax5 = fig.add_subplot(gs[1, 1])
    
    for config in configs:
        model_strat = f"{config['model']}-{config['strategy']}"
        marker = 'o' if 'refine' in model_strat else 's'
        size = 100 + config['tests_added'] * 0.3  # Size based on tests added
        
        ax5.scatter(config['tokens']/1_000_000, config['coverage'], 
                   color=colors[model_strat], s=size, alpha=0.7, 
                   edgecolor='black', linewidth=1, marker=marker,
                   label=f"{config['repository']}-{model_strat}")
    
    ax5.set_xlabel('Tokens Used (Millions)', fontweight='bold')
    ax5.set_ylabel('Coverage Achieved (%)', fontweight='bold')
    ax5.set_title('Coverage vs Token Cost\n(bubble size = tests added)', fontweight='bold', pad=10)
    ax5.grid(True, alpha=0.3)
    
    # Add efficiency frontier
    ax5.axhline(y=80, color='green', linestyle='--', alpha=0.3, label='Target Coverage')
    
    # 6. Strategy Comparison Radar (Middle Right)
    ax6 = fig.add_subplot(gs[1, 2], projection='polar')
    
    # Metrics for radar chart
    categories = ['Coverage', 'Pass Rate', 'Tests/Token', 'Total Tests']
    N = len(categories)
    
    # Calculate averages for each strategy
    strategies = {'refine': [], 'base': []}
    for strategy in strategies.keys():
        strategy_configs = [c for c in configs if c['strategy'] == strategy]
        
        # Normalize metrics to 0-100 scale
        avg_coverage = np.mean([c['coverage'] for c in strategy_configs])
        avg_pass_rate = np.mean([c['pass_rate'] for c in strategy_configs])
        avg_tests = np.mean([c['tests_added'] for c in strategy_configs])
        avg_efficiency = np.mean([c['tests_added']/(c['tokens']/1_000_000) for c in strategy_configs])
        
        # Normalize to 0-100
        strategies[strategy] = [
            avg_coverage,
            avg_pass_rate,
            avg_efficiency / 100 * 100,  # Scale efficiency
            avg_tests / 4  # Scale tests
        ]
    
    # Plot radar chart
    angles = [n / float(N) * 2 * np.pi for n in range(N)]
    angles += angles[:1]
    
    ax6.set_theta_offset(np.pi / 2)
    ax6.set_theta_direction(-1)
    
    for strategy, values in strategies.items():
        values += values[:1]  # Complete the circle
        color = '#FF6B6B' if strategy == 'refine' else '#4ECDC4'
        ax6.plot(angles, values, 'o-', linewidth=2, label=strategy.title(), color=color, alpha=0.7)
        ax6.fill(angles, values, alpha=0.25, color=color)
    
    ax6.set_xticks(angles[:-1])
    ax6.set_xticklabels(categories, fontsize=9)
    ax6.set_ylim(0, 100)
    ax6.set_title('Strategy Performance Profile', fontweight='bold', pad=20)
    ax6.legend(loc='upper right', bbox_to_anchor=(1.3, 1.1))
    ax6.grid(True)
    
    # 7. Model Comparison (Bottom Left)
    ax7 = fig.add_subplot(gs[2, 0:2])
    
    # Grouped comparison by model
    models = ['sonnet-4-5', 'opus-4-1']
    metrics = ['Avg Coverage', 'Avg Pass Rate', 'Avg Tests Added', 'Avg Tokens (M)']
    
    model_data = {}
    for model in models:
        model_configs = [c for c in configs if c['model'] == model]
        model_data[model] = [
            np.mean([c['coverage'] for c in model_configs]),
            np.mean([c['pass_rate'] for c in model_configs]),
            np.mean([c['tests_added'] for c in model_configs]) / 3,  # Scale down
            np.mean([c['tokens'] for c in model_configs]) / 1_000_000 * 10  # Scale for visibility
        ]
    
    x = np.arange(len(metrics))
    width = 0.35
    
    for i, model in enumerate(models):
        offset = -width/2 if i == 0 else width/2
        color = '#FF6B6B' if 'sonnet' in model else '#4ECDC4'
        ax7.bar(x + offset, model_data[model], width, label=model.replace('-', ' ').title(),
               color=color, alpha=0.9, edgecolor='black', linewidth=0.5)
    
    ax7.set_xlabel('Metrics', fontweight='bold')
    ax7.set_ylabel('Normalized Value', fontweight='bold')
    ax7.set_title('Model Performance Comparison', fontweight='bold', pad=10)
    ax7.set_xticks(x)
    ax7.set_xticklabels(metrics)
    ax7.legend()
    ax7.grid(True, alpha=0.3)
    
    # 8. Summary Statistics (Bottom Right)
    ax8 = fig.add_subplot(gs[2, 2])
    ax8.axis('off')
    
    # Calculate summary statistics
    total_tokens = sum(c['tokens'] for c in configs) / 1_000_000
    avg_coverage = np.mean([c['coverage'] for c in configs])
    avg_pass_rate = np.mean([c['pass_rate'] for c in configs])
    total_tests = sum(c['tests_added'] for c in configs)
    
    refine_configs = [c for c in configs if c['strategy'] == 'refine']
    base_configs = [c for c in configs if c['strategy'] == 'base']
    
    refine_avg_cov = np.mean([c['coverage'] for c in refine_configs])
    base_avg_cov = np.mean([c['coverage'] for c in base_configs])
    
    summary_text = f"""
    📊 SUMMARY STATISTICS
    
    Total Tokens Used: {total_tokens:.1f}M
    Total Tests Added: {total_tests:,}
    
    Average Coverage: {avg_coverage:.1f}%
    Average Pass Rate: {avg_pass_rate:.1f}%
    
    🔄 Strategy Comparison:
    Refine Avg Coverage: {refine_avg_cov:.1f}%
    Base Avg Coverage: {base_avg_cov:.1f}%
    Difference: {refine_avg_cov - base_avg_cov:+.1f}%
    
    🏆 Best Performers:
    Highest Coverage: {max(configs, key=lambda x: x['coverage'])['repository']} 
                     ({max(c['coverage'] for c in configs)}%)
    Most Efficient: {min(configs, key=lambda x: x['tokens']/x['tests_added'])['repository']}
                   ({min(c['tokens']/c['tests_added'] for c in configs):.0f} tokens/test)
    """
    
    ax8.text(0.1, 0.5, summary_text, fontsize=11, verticalalignment='center',
            bbox=dict(boxstyle='round', facecolor='wheat', alpha=0.5))
    
    # Adjust layout
    plt.tight_layout()
    
    # Save or show
    if output_path:
        plt.savefig(output_path, dpi=300, bbox_inches='tight')
        print(f"Visualization saved to {output_path}")
    else:
        plt.show()
    
    return fig

if __name__ == "__main__":
    import sys
    
    if len(sys.argv) < 2:
        print("Usage: python visualize_benchmark.py <json_path> [output_path]")
        sys.exit(1)
    
    json_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else None
    
    create_visualization(json_path, output_path)