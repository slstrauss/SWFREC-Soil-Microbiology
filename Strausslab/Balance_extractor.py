#!/usr/bin/env python3

#Import packages
import os
import numpy as np
import pandas as pd
from skbio import TreeNode
from tqdm import tqdm
import qiime2
from q2_types.tree import Hierarchy
from q2_types.feature_table import FeatureTable, Composition
from q2_types.feature_data import FeatureData, Taxonomy
from qiime2.plugin import (Int, Metadata)
from q2_gneiss.plugin_setup import plugin
from gneiss.plot._heatmap import heatmap
from gneiss.util import (match, match_tips, NUMERATOR, DENOMINATOR)
from gneiss.plot._decompose import proportion_plot
from gneiss.util import NUMERATOR, DENOMINATOR

#Import Files
table_art = qiime2.Artifact.load(os.path.join(os.getcwd(),'merged','models','gneiss','filtered-table.qza'))
table = table_art.view(pd.DataFrame)

balance_art = qiime2.Artifact.load(os.path.join(os.getcwd(),'merged','models','gneiss','balances.qza'))
balances = balance_art.view(pd.DataFrame)

tree_art = qiime2.Artifact.load(os.path.join(os.getcwd(),'merged','models','gneiss','hierarchy.qza'))
tree = tree_art.view(TreeNode)

taxa_art = qiime2.Artifact.load(os.path.join(os.getcwd(),'merged','features/taxonomy.qza'))
taxa = taxa_art.view(pd.DataFrame)

metadata = pd.read_table(os.path.join(os.getcwd(),'mappings_LDA.txt'), index_col=0)

viz = qiime2.Visualization.load(os.path.join(os.getcwd(),'merged','models','gneiss','regression_summary.qzv'))
viz.export_data(os.path.join(os.getcwd(),'merged','models','gneiss','ols_summary_dir'))
adj_pvals = pd.read_csv(os.path.join(os.getcwd(),'merged','models','gneiss','ols_summary_dir','fdr-corrected-pvalues.csv'), index_col=0)

#Define taxa and vars
taxadf = pd.DataFrame(taxa.Taxon.apply(lambda x: x.split(';')).values.tolist(),
                    columns=['kingdom', 'phylum', 'class', 'order', 
                             'family', 'genus', 'species'],
                    index=taxa.index)

n_features = 10
fname = 'feature'

#Normalize table and filter adjusted p-values
ptable = table.apply(lambda x: 100*x / x.sum(), axis=1)

cp = adj_pvals.reset_index()
cp = cp.rename(columns={'index': 'balance'})

OLS_df =  pd.melt(cp, id_vars='balance', var_name='Covariate',
                  value_name='Corrected_Pvalue')
OLS_df = OLS_df[(OLS_df['Corrected_Pvalue']<0.1) & (OLS_df['Covariate'] != 'Intercept')]

#Accessory Functions
def num_clade(i):
    return tree.find(i)[NUMERATOR]

def denom_clade(i):
    return tree.find(i)[DENOMINATOR]


#Create the exported dataframe
vardata = pd.DataFrame()
masterDF = pd.DataFrame()

for i in tqdm(range(len(OLS_df))):
    category = OLS_df.iloc[i]['Covariate']
    a = num_clade(OLS_df.iloc[i]['balance'])
    num_features = taxadf.loc[a.parent.subset()]
    num_df = ptable[num_features.index]
    num_data_ = pd.merge(metadata, num_df,
                         left_index=True, right_index=True)
    num_data = pd.melt(num_data_, id_vars=[category],
                       value_vars=list(num_df.columns),
                       value_name='proportion', var_name=fname)
    num_data['part'] = 'numerator'
    num_data2 = pd.merge(num_data, num_features, how='outer',
                         left_on=['feature'], right_index=True)

    b = denom_clade(OLS_df.iloc[i]['balance'])
    denom_features = taxadf.loc[b.parent.subset()]
    denom_df = ptable[denom_features.index]
    denom_data_ = pd.merge(metadata, denom_df,
                           left_index=True, right_index=True)
    denom_data = pd.melt(denom_data_, id_vars=[category],
                         value_vars=list(denom_df.columns),
                         value_name='proportion', var_name=fname)
    denom_data['part'] = 'denominator'
    denom_data2 = pd.merge(denom_data, denom_features, how='outer',
                        left_on=['feature'], right_index=True)
    data0 = pd.concat((num_data2, denom_data2))
    data0['balance']=OLS_df.iloc[i]['balance']
    data0['category']= category
    masterDF = masterDF.append(data0, ignore_index=True)

masterDF.to_csv(os.path.join(os.getcwd(),'merged','models','gneiss','ols_summary_dir','extracted_balances.csv'))
