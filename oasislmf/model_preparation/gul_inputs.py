# -*- coding: utf-8 -*-

from __future__ import absolute_import
from __future__ import division
from __future__ import print_function
from __future__ import unicode_literals

from builtins import open as io_open
from builtins import str

from future import standard_library
standard_library.install_aliases()

__all__ = [
    'get_gul_input_items',
    'write_coverages_file',
    'write_gulsummaryxref_file',
    'write_gul_input_files',
    'write_items_file',
    'write_complex_items_file'
]

import os
import multiprocessing
import sys

from collections import OrderedDict
from itertools import (
    chain,
    product,
)
from future.utils import (
    viewitems,
    viewkeys,
    viewvalues,
)

import pandas as pd

from ..utils.concurrency import (
    multithread,
    Task,
)
from ..utils.data import (
    get_dataframe,
    merge_dataframes,
)
from ..utils.defaults import get_default_exposure_profile
from ..utils.exceptions import OasisException
from ..utils.log import oasis_log
from ..utils.metadata import COVERAGE_TYPES
from ..utils.path import as_path
from .il_inputs import (
    get_sub_layer_calcrule_ids,
    unified_fm_profile_by_level_and_term_group,
    unified_fm_terms_by_level_and_term_group,
    unified_id_terms,
)


@oasis_log
def get_gul_input_items(
    exposure_fp,
    keys_fp,
    exposure_profile=get_default_exposure_profile()
):
    """
    Generates and returns a Pandas dataframe of GUL input items.

    :param exposure_fp: OED source exposure file
    :type exposure_df: pandas.DataFrame

    :param keys_df: Keys data generated by a model lookup or some other source
    :type keys_df: pandas.DataFrame

    :param exposure_profile: OED source exposure profile
    :type exposure_profile: dict
    """
    exppf = exposure_profile
    ufp = unified_fm_profile_by_level_and_term_group(profiles=(exppf,))

    if not ufp:
        raise OasisException(
            'Source exposure profile is possibly missing FM term information: '
            'FM term definitions for TIV, limit, deductible, attachment and/or share.'
        )

    id_terms = unified_id_terms(unified_profile_by_level_and_term_group=ufp)
    loc_id = id_terms['locid']
    acc_id = id_terms['accid']
    portfolio_num = id_terms['portid']

    exposure_df = get_dataframe(
        src_fp=exposure_fp,
        col_dtypes={loc_id: 'str', acc_id: 'str', portfolio_num: 'str'},
        required_cols=(loc_id, acc_id, portfolio_num,),
        empty_data_error_msg='No data found in the source exposure (loc.) file'
    )

    keys_df = get_dataframe(
        src_fp=keys_fp,
        col_dtypes={'locid': 'str'},
        empty_data_error_msg='No keys found in the keys file'
    )

    tiv_terms = OrderedDict({v['tiv']['CoverageTypeID']:v['tiv']['ProfileElementName'].lower() for k, v in viewitems(ufp[1])})

    cov_level = COVERAGE_TYPES['buildings']['id']
    cov_fm_terms = unified_fm_terms_by_level_and_term_group(unified_profile_by_level_and_term_group=ufp)[cov_level]

    try:
        gul_inputs_df = merge_dataframes(exposure_df, keys_df, left_on=loc_id, right_on='locid', how='outer')
        gul_inputs_df = gul_inputs_df[(gul_inputs_df[[v for v in viewvalues(tiv_terms)]] != 0).any(axis=1)]
        gul_inputs_df['group_id'] = [
            gidx + 1 for gidx, (_, group) in enumerate(
                gul_inputs_df.groupby(by=[loc_id])) for _, (gidx, _) in enumerate(product([gidx], group[loc_id].tolist())
            )
        ]

        gul_inputs_df.rename(
            columns={
                'perilid': 'peril_id',
                'coveragetypeid': 'coverage_type_id',
                'areaperilid': 'areaperil_id',
                'vulnerabilityid': 'vulnerability_id'
            },
            inplace=True
        )

        gul_inputs_df['model_data'] = gul_inputs_df.get('modeldata')
        if gul_inputs_df['model_data'].any():
            gul_inputs_df['areaperil_id'] = gul_inputs_df['vulnerability_id'] = -1

        def get_bi_coverage(row):
            return row['coverage_type_id'] == COVERAGE_TYPES['bi']['id']

        gul_inputs_df['is_bi_coverage'] = gul_inputs_df.apply(get_bi_coverage, axis=1)

        def get_tiv(row):
            return row.get(tiv_terms[row['coverage_type_id']]) or 0.0

        gul_inputs_df['tiv'] = gul_inputs_df.apply(get_tiv, axis=1)

        def get_term_val(row, term=None):
            val = row.get(cov_fm_terms[row['coverage_type_id']][term]) or 0.0
            if term in ('deductible', 'limit',) and val < 1:
                val *= row['tiv']
            return val

        gul_inputs_df['deductible'] = gul_inputs_df.apply(get_term_val, axis=1, term='deductible')
        gul_inputs_df['deductible_min'] = gul_inputs_df.apply(get_term_val, axis=1, term='deductiblemin')
        gul_inputs_df['deductible_max'] = gul_inputs_df.apply(get_term_val, axis=1, term='deductiblemax')
        gul_inputs_df['limit'] = gul_inputs_df.apply(get_term_val, axis=1, term='limit')

        item_ids = range(1, len(gul_inputs_df) + 1)
        gul_inputs_df = gul_inputs_df.assign(
            item_id=item_ids,
            coverage_id=item_ids,
            calcrule_id=-1,
            agg_id=item_ids,
            summary_id=1,
            summaryset_id=1
        )
    except (AttributeError, KeyError, IndexError, TypeError, ValueError) as e:
        raise OasisException(e)

    return gul_inputs_df, exposure_df


def write_complex_items_file(gul_inputs_df, complex_items_fp):
    """
    Writes an items file.
    """
    try:
        gul_inputs_df.to_csv(
            columns=['item_id', 'coverage_id', 'model_data', 'group_id'],
            path_or_buf=complex_items_fp,
            encoding='utf-8',
            chunksize=1000,
            index=False
        )
    except (IOError, OSError) as e:
        raise OasisException(e)


def write_items_file(gul_inputs_df, items_fp):
    """
    Writes an items file.
    """
    try:
        gul_inputs_df.to_csv(
            columns=['item_id', 'coverage_id', 'areaperil_id', 'vulnerability_id', 'group_id'],
            path_or_buf=items_fp,
            encoding='utf-8',
            chunksize=1000,
            index=False
        )
    except (IOError, OSError) as e:
        raise OasisException(e)

    return items_fp


def write_coverages_file(gul_inputs_df, coverages_fp):
    """
    Writes a coverages file.
    """
    try:
        gul_inputs_df.to_csv(
            columns=['coverage_id', 'tiv'],
            path_or_buf=coverages_fp,
            encoding='utf-8',
            chunksize=1000,
            index=False
        )
    except (IOError, OSError) as e:
        raise OasisException(e)

    return coverages_fp


def write_gulsummaryxref_file(gul_inputs_df, gulsummaryxref_fp):
    """
    Writes a gulsummaryxref file.
    """
    try:
        gul_inputs_df.to_csv(
            columns=['coverage_id', 'summary_id', 'summaryset_id'],
            path_or_buf=gulsummaryxref_fp,
            encoding='utf-8',
            chunksize=1000,
            index=False
        )
    except (IOError, OSError) as e:
        raise OasisException(e)

    return gulsummaryxref_fp


@oasis_log
def write_gul_input_files(
    exposure_fp,
    keys_fp,
    target_dir,
    exposure_profile=get_default_exposure_profile(),
    oasis_files_prefixes={
        'items': 'items',
        'complex_items': 'complex_items',
        'coverages': 'coverages',
        'gulsummaryxref': 'gulsummaryxref'
    },
    write_inputs_table_to_file=False
):
    """
    Writes the standard Oasis GUL input files, namely::

        items.csv
        coverages.csv
        gulsummaryxref.csv

    with the addition of a complex items file in case of a complex/custom model
    """
    # Clean the target directory path
    target_dir = as_path(target_dir, 'Target IL input files directory', is_dir=True, preexists=False)

    gul_inputs_df, exposure_df = get_gul_input_items(exposure_fp, keys_fp, exposure_profile=exposure_profile)

    if write_inputs_table_to_file:
        gul_inputs_df.to_csv(path_or_buf=os.path.join(target_dir, 'gul_inputs.csv'), index=False, encoding='utf-8', chunksize=1000)

    if not gul_inputs_df['model_data'].any():
        gul_inputs_df.drop(['model_data'], axis=1, inplace=True)
        if oasis_files_prefixes.get('complex_items'):
            oasis_files_prefixes.pop('complex_items')

    gul_input_files = {
        k: os.path.join(target_dir, '{}.csv'.format(oasis_files_prefixes[k])) 
        for k in oasis_files_prefixes
    }

    this_module = sys.modules[__name__]
    for k, v in viewitems(gul_input_files):
        getattr(this_module, 'write_{}_file'.format(k))(gul_inputs_df, v)

    return gul_input_files, gul_inputs_df, exposure_df
