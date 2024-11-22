# How to install dependencies
pip install -r requirements.txt

<br>

# How to run

Make sure to set up the environment variables in the .env file.
Refer to the .env.example file to see which variables need to be defined.

<br>

### Example 1: Importing snomed-ct-description from local file
```
python main.py --context=snomed-ct --doc_type=snomed-ct-description --source_type=local --has_header=true --delimiter="\t" --file_path=sct2_Description_Full_GermanyEdition_20240515.txt
```

<br>

### Example 2: Importing snomed-ct-description from bucket
Make sure you place the bucket json credentials in the root of the project.
In the file path, for instance, Germany Edition 20240515 represents the release version, and full indicates the file type (full, snapshot, delta).    
```
python main.py --context=snomed-ct --doc_type=snomed-ct-description --source_type=bucket --has_header=true --delimiter="\t" --file_path=app_config/snomedct/GermanyEdition_20240515/full/sct2_Description_Full_GermanyEdition_20240515.txt
```

<br>

## Example 3: Importing icd-10-gm-code from local file
```
python main.py --context=icd-10-gm --doc_type=icd-10-gm-code --source_type=local --has_header=false --delimiter=";" --file_path=icd10gm2025syst_kodes.txt
```

<br>

## Example 4: Importing icd-10-gm-code from bucket
Make sure you place the bucket json credentials in the root of the project.
```
python main.py --context=icd-10-gm --doc_type=icd-10-gm-code --source_type=bucket --has_header=false --delimiter=";" --file_path=app_config/icd/2025/latest/icd10gm2025syst_kodes.txt
```

<br>

# Data Appearance Post-Import

The value of the context argument will be assigned to the context attribute of the Meilisearch `terminologies` document.

The value of the doc_type argument will be used as the prefix for the id attribute of the Meilisearch `terminologies` document.

![image](https://github.com/user-attachments/assets/e28d4762-5e00-4b0d-890e-2f35b3576796)

![image](https://github.com/user-attachments/assets/2ba6d9ab-aef7-4d8b-8ecc-e81cf006a263)
