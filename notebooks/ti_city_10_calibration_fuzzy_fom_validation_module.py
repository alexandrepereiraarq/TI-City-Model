"""
ti_city_08_fuzzy_fom_validation_module.py
=========================================
Validation module for the TI-City / TA City agent-based urban growth model.
Computes the strict Figure of Merit (FoM) and the fuzzy (soft) FoM between
simulated new-urban cells and observed new-urban cells, on the model's own
150 m AOI reference grid.

Designed to plug directly into the existing workflow (all keyword arguments
declared explicitly at call time):
    from ti_city_08_fuzzy_fom_validation_module import *

    # references pre-loaded as numpy arrays (ASCII/TIFF, 150 m AOI grid):
    new_cells_observed = observed_new_from_rasters(
        urban_late = urban_late_raster,
        urban_early = urban_early_raster)

    # model runs (results_dict) and baselines (baseline_dict) are loaded and
    # evaluated SEPARATELY, then normalised:
    fom_table = evaluate_scenario_fom(
        results_dict = results_dict,
        obs_new = new_cells_observed,
        initial_urban = urban_early_raster > 0,
        start_year = calibration_years[0],   # 2000 for JAK calibration ticks
        per_tick = 'final',
        variant = 'hits_only',
        case_city = case_city,
        cell_km = 0.150,
        silent = False)

    baseline_fom_table = evaluate_scenario_fom(
        results_dict = baseline_dict,
        obs_new = new_cells_observed,
        initial_urban = urban_early_raster > 0,
        start_year = calibration_years[0],
        per_tick = 'final',
        variant = 'hits_only',
        case_city = case_city,
        cell_km = 0.150,
        silent = False)

    fom_table = normalize_against_baselines(
        fom_table = fom_table,
        baseline_fom_table = baseline_fom_table)

    results_table = append_validation_to_results_table(
        results_table = results_table,
        fom_table = fom_table)

Agent-class convention (from agent_class_dict):
    0 = na (not urban / background)
    1 = deprived, 2 = low, 3 = mid, 4 = high   -> new-urban agents
    5 = urban_first_year (initial urban mask, e.g. urban 2000 for JAK)

Definitions
-----------
Strict FoM (Pontius et al. 2008, Ecol. Modelling 219:460-467):
    H  = |sim ∩ obs|                      hits
    M  = |obs \\ sim|                      misses
    FA = |sim \\ obs|                      false alarms
    FoM = H / (H + M + FA)

Fuzzy FoM with neighbourhood tolerance t (in cells; 1 cell = 150 m):
    H_f  = |obs ∩ dilate(sim, t)|          observed cells within t cells of a simulated cell
    M_f  = |obs| - H_f                     observed cells not near any simulated cell
    FA_f = |sim \\ dilate(obs, t)|         simulated cells not near any observed cell
    FoM_f = H_f / (H_f + M_f + FA_f)
Dilation uses a square (Chebyshev) structuring element of side 2t+1, clipped
at the grid edges. t = 0 recovers the strict FoM exactly. This is the fuzzy map
comparison tradition of Hagen (2003) and Hagen-Zanker (2006, J. Geographical
Systems 8:145-160).

Variant 'hits_only' reproduces the earlier quick-check soft-FoM (45.2% at
t = 3 for the JAK 093 run): fuzzy hits and fuzzy misses, strict false alarms.
    FoM_h = H_f / (H_f + M_f + FA_strict) = H_f / (n_obs + FA_strict)
Use it only for continuity with earlier reported numbers; 'full' is the
recommended default (it is symmetric and degrades gracefully to the strict
FoM on both sides of the comparison).

Interpretation of the tolerance sweep (FoM at t = 0,1,2,3,5):
    * steep rise then plateau  -> errors are small spatial offsets (near-misses)
    * flat curve               -> errors are structural misallocation
"""

import numpy as np
import pandas as pd
from scipy import ndimage
import natsort

# ----------------------------------------------------------------------
# Conventions
# ----------------------------------------------------------------------
NEW_URBAN_CLASSES = (1, 2, 3, 4)   # deprived, low, mid, high
FIRST_YEAR_CLASS = 5              # urban at simulation start (e.g. urban 2000)

DEFAULT_TOLERANCES = (0, 1, 2, 3, 5)   # cells; 0 = strict FoM


# ----------------------------------------------------------------------
# Mask extraction from TI-City output arrays
# ----------------------------------------------------------------------
def extract_new_urban(raster):
    """Boolean mask of new-urban agent cells (classes 1-4) from one output array."""
    arr = np.asarray(raster)
    return (arr >= min(NEW_URBAN_CLASSES)) & (arr <= max(NEW_URBAN_CLASSES))


def extract_first_year_urban(raster):
    """Boolean mask of the initial urban footprint (class 5) from one output array."""
    return np.asarray(raster) == FIRST_YEAR_CLASS


def restrict_mask(mask, initial_urban=None, valid_mask=None):
    """Remove cells that must not participate in validation:
    cells already urban at simulation start, and cells outside the AOI/nodata."""
    out = np.asarray(mask, dtype=bool).copy()
    if initial_urban is not None:
        out &= ~np.asarray(initial_urban, dtype=bool)
    if valid_mask is not None:
        out &= np.asarray(valid_mask, dtype=bool)
    return out


# ----------------------------------------------------------------------
# Observed new-urban masks
# ----------------------------------------------------------------------
def load_observed_new_urban_csv(csv_path, n_rows, n_cols, skiprows=1):
    """Load an observed new-urban 0/1 CSV written row-major (like the project's
    JAK_new_urban_cells_2000_2025 file: one header line, then n_rows lines of
    n_cols values). Returns a boolean array shaped (n_rows, n_cols).
    For JAK: n_rows=680, n_cols=772 -> the 150 m AOI reference grid."""
    arr = np.loadtxt(csv_path, delimiter=',', skiprows=skiprows)
    if arr.shape != (n_rows, n_cols):
        raise ValueError(
            f'Observed CSV reshapes to {arr.shape}, expected {(n_rows, n_cols)}. '
            'Check grid dimensions before comparing.')
    return arr.astype(bool)


def load_observed_new_urban_raster(raster_path, initial_urban_raster_path=None):
    """Load an observed new-urban raster (1 = new urban), optionally subtracting
    an initial-urban raster so that only genuinely new cells remain.
    Both rasters must already be on the AOI reference grid."""
    import rasterio
    with rasterio.open(raster_path, 'r') as src:
        obs = src.read(1)
    obs_new = np.asarray(obs) > 0
    if initial_urban_raster_path is not None:
        with rasterio.open(initial_urban_raster_path, 'r') as src:
            init = src.read(1)
        obs_new &= ~np.asarray(init > 0)
    return obs_new


def observed_new_from_rasters(urban_late, urban_early, valid_mask=None):
    """Observed new-urban raster from the two pre-loaded reference rasters
    (numpy arrays already in the workflow):
        obs_new = observed_new_from_rasters(urban_late_raster, urban_early_raster)
        initial_urban = urban_early_raster > 0
    Returns an int array with 0 = not new-urban, 1 = new-urban
    (raster-friendly; matches the 0/1 convention of the ASCII/TIFF layers).
    All downstream functions accept either 0/1 arrays or boolean masks.
    Both inputs must be on the AOI reference grid; cells > 0 count as urban.
    CAUTION: if the rasters carry a nodata value that is > 0 (e.g. 255 or
    -9999 read as positive), pass valid_mask (AOI/nodata mask) as well, or
    nodata cells will be counted as urban."""
    late = np.asarray(urban_late) > 0
    early = np.asarray(urban_early) > 0
    if late.shape != early.shape:
        raise ValueError(f'Shape mismatch: urban_late {late.shape} vs '
                         f'urban_early {early.shape}')
    obs_new = late & ~early
    if valid_mask is not None:
        obs_new &= np.asarray(valid_mask, dtype=bool)
    return obs_new.astype(np.uint8)   # 0 = False, 1 = True


def derive_initial_urban_from_first_tick(results_dict, scenario=None):
    """Class-5 mask from a scenario's tick-0 (or first available tick) array."""
    scenario = scenario if scenario is not None else list(results_dict.keys())[0]
    first_key = natsort.natsorted(results_dict[scenario].keys())[0]
    return extract_first_year_urban(results_dict[scenario][first_key])


# ----------------------------------------------------------------------
# Core metrics
# ----------------------------------------------------------------------
def dilate_mask(mask, tolerance):
    """Square (Chebyshev) dilation by `tolerance` cells, clipped at grid edges.
    tolerance <= 0 returns the mask unchanged."""
    if tolerance <= 0:
        return np.asarray(mask, dtype=bool)
    struct = np.ones((2 * tolerance + 1, 2 * tolerance + 1), dtype=bool)
    return ndimage.binary_dilation(np.asarray(mask, dtype=bool), structure=struct)


def fom_from_masks(sim_new, obs_new, tolerance=0, variant='full'):
    """Strict or fuzzy FoM between two boolean new-urban masks.

    tolerance : neighbourhood in cells (0 -> strict FoM)
    variant   : 'full'       -> fuzzy hits AND fuzzy false alarms (recommended)
                'hits_only'  -> fuzzy hits and fuzzy misses, strict false
                alarms (legacy quick-check; reproduces the 45.2% at t = 3)
    Returns dict with H, M, FA, FoM, HitRate (= H / n_obs, fuzzy sensitivity).
    """
    sim = np.asarray(sim_new, dtype=bool)
    obs = np.asarray(obs_new, dtype=bool)
    if sim.shape != obs.shape:
        raise ValueError(f'Shape mismatch: sim {sim.shape} vs obs {obs.shape}')

    sim_d = dilate_mask(sim, tolerance)
    H_f = int(np.sum(obs & sim_d))          # hits (fuzzy)
    M_f = int(np.sum(obs)) - H_f            # misses (fuzzy)

    if tolerance > 0 and variant == 'full':
        obs_d = dilate_mask(obs, tolerance)
        FA_f = int(np.sum(sim & ~obs_d))    # false alarms (fuzzy)
    else:
        FA_f = int(np.sum(sim & ~obs))      # false alarms (strict)

    n_obs = int(np.sum(obs))
    denom = H_f + M_f + FA_f
    return {
        'tolerance': tolerance,
        'Hits': H_f,
        'Misses': M_f,
        'FalseAlarms': FA_f,
        'FoM': (H_f / denom) if denom else np.nan,
        'HitRate': (H_f / n_obs) if n_obs else np.nan,
    }


def fom_tolerance_sweep(sim_new, obs_new, tolerances=DEFAULT_TOLERANCES, variant='full'):
    """FoM at several tolerances. Returns a dict {tolerance: FoM}."""
    return {t: fom_from_masks(sim_new, obs_new, tolerance=t, variant=variant)['FoM']
            for t in tolerances}


# ----------------------------------------------------------------------
# Baselines (null models) & normalisation
# ----------------------------------------------------------------------
# Two kinds of baselines can be used, and both should:
#   1. ABM-generated baseline scenarios (recommended): the random-allocation,
#      road-bound and edge-growth runs produced with the model itself
#      (weight 10 for a single parameter, every agent class). They share the
#      grid, the demand/quantity, the output format and the stochastic
#      machinery with the real runs -> score them with evaluate_scenario_fom
#      like any other scenario in results_dict, then normalise with
#      normalize_against_baselines().
#   2. Statistical random allocation (null_fom_baseline below): a cheap
#      chance floor for sanity checks; keep it, but the ABM baselines are
#      the anchors that matter.
# Caveat: all baselines must be run with the SAME demand (frozen quantity)
# as the calibration runs, otherwise their FoM is not comparable.
def null_fom_baseline(obs_new, eligible_mask, n_seeds=5,
                      tolerances=DEFAULT_TOLERANCES, variant='full', seed=42):
    """Random-allocation null model: scatter n_obs cells uniformly over the
    eligible cells and compute the FoM sweep. Returns a one-row DataFrame with
    the mean over `n_seeds` draws, to normalise the real scores against."""
    obs = np.asarray(obs_new, dtype=bool)
    elig = np.asarray(eligible_mask, dtype=bool)
    n_obs = int(np.sum(obs))
    flat_idx = np.flatnonzero(elig.ravel())
    rng = np.random.default_rng(seed)
    sweeps = []
    for _ in range(n_seeds):
        pick = rng.choice(flat_idx, size=n_obs, replace=False)
        sim = np.zeros_like(elig).ravel()
        sim[pick] = True
        sim = sim.reshape(elig.shape)
        sweeps.append(fom_tolerance_sweep(sim, obs, tolerances=tolerances, variant=variant))
    row = {'Scenario': 'NULL_random', 'N_sim': n_obs, 'N_obs': n_obs}
    for t in tolerances:
        row[f'FoM_t{t}'] = float(np.mean([s[t] for s in sweeps]))
    return pd.DataFrame([row])


def normalize_against_baselines(fom_table, baseline_fom_table,
                                metric_cols=None, perfect=1.0,
                                group_col='Tick', per_baseline=True):
    """Normalise the FoM columns of the model scenarios against ALL baselines.

    Two kinds of output columns are added (both per tick when a Tick column
    is present in both tables):

    1. '<col>_skill'            vs the STRONGEST baseline for that metric
                                skill = (model - best_baseline) / (perfect - best_baseline)
                                This is the single anchor for the objective
                                function: the binding constraint is the best
                                cheap explanation, not the average one.
    2. '<col>_vs_<baseline>'   one column PER baseline scenario
                                Same formula, against that baseline alone.
                                Diagnostic: read these to see WHICH mechanism
                                the model does or does not beat (random =
                                chance floor, edge = organic expansion null,
                                roadbound = infrastructure null).

    fom_table          : evaluate_scenario_fom(results_dict, ...)  -> model runs
    baseline_fom_table : evaluate_scenario_fom(baseline_dict, ...)  -> baselines
                         (all baselines are compared; set per_baseline=False
                         to emit only the overall _skill columns)
    perfect            : value of a perfect model (1.0 for FoM-like metrics).
    group_col          : column aligning model rows to baseline rows
                         ('Tick'; falls back to the global best if absent).

    A model row only earns skill above 0 where it beats every single-factor
    explanation (random / road-bound / edge-growth). This is the multi-pattern
    filter of pattern-oriented modeling: matching one statistic that a
    single-parameter baseline already matches is not evidence of skill.
    Baselines are the anchors: never normalise them against themselves.
    If baseline_fom_table contains several seed runs per baseline, pass the
    per-seed rows directly - max over all rows of a baseline is used
    (strictest choice); pre-aggregate to means first if you prefer
    'beats the average'.
    Returns a copy of fom_table with the added skill columns.
    """
    out = fom_table.copy()
    base = baseline_fom_table.copy()
    if metric_cols is None:
        metric_cols = ([c for c in out.columns if c.startswith('FuzzyFoM')]
                       + (['FoM'] if 'FoM' in out.columns else []))
    if 'Scenario' not in base.columns:
        raise ValueError('baseline_fom_table must be the output of '
                         'evaluate_scenario_fom(baseline_dict, ...)')
    use_group = bool(group_col) and group_col in out.columns and group_col in base.columns

    def _best(sub, col):
        """Max of col over the baseline rows, aligned to model rows."""
        if use_group:
            return out[group_col].map(sub.groupby(group_col)[col].max())
        return sub[col].max()

    for col in metric_cols:
        if col not in out.columns or col not in base.columns:
            continue
        if per_baseline:
            for scen in base['Scenario'].unique():
                sub = base.loc[base['Scenario'] == scen]
                bpr = _best(sub, col)
                out[f'{col}_vs_{scen}'] = (out[col] - bpr) / (perfect - bpr)
        best_per_row = _best(base, col)
        out[f'{col}_skill'] = (out[col] - best_per_row) / (perfect - best_per_row)
    return out


def evaluate_all_fom(results_dict, baseline_dict, obs_new,
                     initial_urban=None, valid_mask=None,
                     tolerances=DEFAULT_TOLERANCES, variant='full',
                     per_tick='all', start_year=None, case_city='JAK',
                     silent=False, normalize=True, perfect=1.0):
    """One-call evaluation for the split workflow:
    model scenarios from results_dict, baselines from baseline_dict.
    Returns (fom_table, baseline_fom_table, fom_table_normalized) when
    normalize=True, else (fom_table, baseline_fom_table)."""
    fom_table = evaluate_scenario_fom(
        results_dict, obs_new, initial_urban=initial_urban,
        valid_mask=valid_mask, tolerances=tolerances, variant=variant,
        per_tick=per_tick, start_year=start_year, case_city=case_city,
        silent=silent)
    baseline_fom = evaluate_scenario_fom(
        baseline_dict, obs_new, initial_urban=initial_urban,
        valid_mask=valid_mask, tolerances=tolerances, variant=variant,
        per_tick=per_tick, start_year=start_year, case_city=case_city,
        silent=silent)
    if normalize:
        fom_table = normalize_against_baselines(
            fom_table, baseline_fom, perfect=perfect)
        return fom_table, baseline_fom, fom_table
    return fom_table, baseline_fom


# ----------------------------------------------------------------------
# Scenario-level evaluation (plugs into load_ascii_files output)
# ----------------------------------------------------------------------
def evaluate_scenario_fom(results_dict, obs_new, initial_urban=None,
                          valid_mask=None, tolerances=DEFAULT_TOLERANCES,
                          variant='full', per_tick='all', start_year=None,
                          case_city='JAK', cell_km=0.150, silent=False):
    """Evaluate every scenario (and tick) in results_dict against the observed
    new-urban mask.

    Parameters
    ----------
    results_dict  : {scenario: {tick_key: np.ndarray}} from load_ascii_files()
    obs_new       : boolean (rows x cols) observed new-urban mask, same grid
    initial_urban : boolean mask of urban at start (class 5 of tick 0 is used
                    when None). Sim and obs hits are ignored on these cells.
    valid_mask    : boolean AOI mask; None = all cells valid.
    per_tick      : 'all' -> one row per tick; 'final' -> last tick only.
    start_year    : year of tick 0 (e.g. 2000 for the JAK calibration run);
                    None -> use the tick number as the Year column.
    Returns a long DataFrame, one row per scenario x tick, with strict FoM,
    quantity agreement, and the fuzzy FoM / HitRate at every tolerance.
    """
    obs_all = np.asarray(obs_new, dtype=bool)
    if initial_urban is None:
        initial_urban = derive_initial_urban_from_first_tick(results_dict)
    obs = restrict_mask(obs_all, initial_urban=initial_urban, valid_mask=valid_mask)
    n_obs = int(np.sum(obs))
    if not silent:
        print(f'Evaluating against {n_obs:,} observed new-urban cells '
              f'(excl. {case_city} initial urban & invalid cells).')

    rows = []
    for scenario, series in results_dict.items():
        sorted_keys = natsort.natsorted(series.keys())
        keys = sorted_keys if per_tick == 'all' else sorted_keys[-1:]
        for key in keys:
            raster = series[key]
            if raster.shape != obs.shape:
                raise ValueError(
                    f'Scenario {scenario} tick {key}: raster {raster.shape} does not '
                    f'match the observed grid {obs.shape}. Check the AOI reference raster.')
            sim = restrict_mask(extract_new_urban(raster),
                               initial_urban=initial_urban, valid_mask=valid_mask)
            row = {'Scenario': scenario, 'Tick': key}
            row['Year'] = (start_year + int(key)) if start_year is not None else int(key)
            row['N_sim'] = int(np.sum(sim))
            row['N_obs'] = n_obs
            row['QuantityRatio'] = row['N_sim'] / n_obs if n_obs else np.nan
            strict = fom_from_masks(sim, obs, tolerance=0)
            row['Hits'], row['Misses'], row['FalseAlarms'] = (
                strict['Hits'], strict['Misses'], strict['FalseAlarms'])
            row['FoM'] = strict['FoM']
            row['HitRate'] = strict['HitRate']
            row['SimArea_km2'] = np.round(row['N_sim'] * cell_km * cell_km, 2)
            for t in tolerances:
                if t == 0:
                    continue
                m = fom_from_masks(sim, obs, tolerance=t, variant=variant)
                row[f'FuzzyFoM_t{t}'] = m['FoM']
                row[f'FuzzyHitRate_t{t}'] = m['HitRate']
            rows.append(row)
            if not silent:
                print(f'  {scenario} t{key}: N_sim={row["N_sim"]:,} '
                      f'FoM={row["FoM"]:.3f} '
                      + ' '.join(f'fFoM_t{t}={row[f"FuzzyFoM_t{t}"]:.3f}'
                                 for t in tolerances if t > 0))
    return pd.DataFrame(rows)


# ----------------------------------------------------------------------
# Merge with the existing results table
# ----------------------------------------------------------------------
def append_validation_to_results_table(results_table, fom_table,
                                       export_results_table=False,
                                       export_path=None, case_city='JAK'):
    """Left-join the FoM columns onto compile_scenarios_table()'s output.
    Join keys: Scenario + Year. The Tick column is dropped (results_table
    carries Year already). Optionally export to Excel like the workflow does."""
    fom_cols = fom_table.drop(columns=['Tick'])
    merged = results_table.merge(fom_cols, on=['Scenario', 'Year'], how='left')
    if export_results_table and export_path is not None:
        out = export_path / f'{case_city}_urban_exposed_areas_analysis_with_FoM.xlsx'
        merged.to_excel(out, index_label='ID')
        print(f'Validation-augmented results table exported to {out}')
    return merged


# ----------------------------------------------------------------------
# Self-test on synthetic data (no files needed):
# python ti_city_08_fuzzy_fom_validation_module.py
# ----------------------------------------------------------------------
if __name__ == '__main__':
    h, w = 60, 60
    rng = np.random.default_rng(0)
    # observed: a 10x10 blob
    obs = np.zeros((h, w), dtype=bool)
    obs[20:30, 20:30] = True
    # perfect simulation
    sim_perfect = obs.copy()
    # offset simulation: same blob shifted 2 cells (a pure near-miss case)
    sim_offset = np.zeros((h, w), dtype=bool)
    sim_offset[22:32, 22:32] = True
    # structural mismatch: blob placed far away
    sim_far = np.zeros((h, w), dtype=bool)
    sim_far[45:55, 45:55] = True

    for name, sim in [('perfect', sim_perfect), ('offset2', sim_offset), ('far', sim_far)]:
        sweep = fom_tolerance_sweep(sim, obs, tolerances=DEFAULT_TOLERANCES)
        print(name, {f't{t}': round(v, 3) for t, v in sweep.items()})

    assert fom_from_masks(sim_perfect, obs)['FoM'] == 1.0
    assert fom_from_masks(sim_offset, obs, tolerance=2)['FoM'] == 1.0      # near-miss forgiven
    assert fom_from_masks(sim_far, obs, tolerance=2)['FoM'] < 0.01       # structural mismatch stays flat
    print('Self-test passed: tolerance sweep separates offsets from misallocation.')