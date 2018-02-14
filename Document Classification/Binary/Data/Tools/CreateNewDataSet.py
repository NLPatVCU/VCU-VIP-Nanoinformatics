import pandas as pd
import numpy as np
import re

PMC_NONNANO_abstracts = pd.read_json("../JSON/Non-Nano.json")
PMC_NONNANO_abstracts['is_nano'] = "No"
PMC_abstracts = pd.read_json("../JSON/Nano.json")
PMC_abstracts['is_nano'] = 'Yes'
DOI_abstracts = pd.read_json("../JSON/DOIData.json")
DOI_abstracts['is_nano'] = 'Yes'
DOI_abstracts['abstract'] = DOI_abstracts['abstract'].apply(lambda x: re.sub("\n", "", x))  # Remove new lines
abstracts = pd.concat([PMC_abstracts, DOI_abstracts, PMC_NONNANO_abstracts], ignore_index=True)  # Combine data
abstracts = abstracts[abstracts.abstract != "No Abstract Provided"]  # Remove papers with no abstract
abstracts = abstracts[abstracts.abstract.str.strip() != ""]  # Remove papers with empty abstracts
abstracts = abstracts.reindex(np.random.permutation(abstracts.index))
abstracts.to_json("../Datasets/abstracts.json", orient="records")