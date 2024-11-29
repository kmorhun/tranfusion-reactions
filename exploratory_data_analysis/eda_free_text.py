# USE AS REFERENCE FOR FUTURE PYTHON WORK. THIS WILL LIKELY NOT RUN AS IS
"""
## Questions
1. How many free texts are associated with the patients with inputs of potential blood transfusion reaction products? Those later identified without transfusion reaction could serve as negative label 
2. What are potential key words to look for transfusion reaction? Is there a feasible rule-based apporoach? In what kinds of notes (physicians? nurses?)
3. How does the notes compare to Kat's methods? 
"""

import os
import pandas as pd
import numpy as np
from dotenv import load_dotenv
from google.cloud import bigquery
import matplotlib.pyplot as plt
pd.set_option('display.max_rows', 100)    # Show all rows



load_dotenv()
query_path = os.environ.get('BASE_QUERY_PATH')
client = bigquery.Client(os.environ.get('BIGQUERY_PROJECT_NAME'))

# Look at example free-text notes from noteevents 
with open(f"{query_path}/free_text_examples.sql", 'r') as file:
    query_fte = file.read()

results_fte = client.query(query_fte).to_dataframe()
print(results_fte)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Look at transfusion input from Kat and Quinn
# as per our esteemed clinician's advice, we will use the following blood products:
chosen_blood_products_mv = (225168, 225170, 225171, 227070, 227071, 227072, 220970, 227532, 226367, 226368, 226369, 226371)
chosen_blood_products_cv = (30179, 30001, 30004, 30005, 30180)
# https://mimic.mit.edu/docs/iii/tables/inputevents_mv/ 

with open(f"{query_path}/all_blood_inputs.sql", 'r') as file:
    query = file.read()

completed_results = client.query(query).to_dataframe()
completed_results

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Note entries with matched subject_id from all_blood_inputs, documented on the same or next day of input 
# with open(f"{query_path}/blood_notes.sql", 'r') as file: # Caution: run time = 11 min, 479399 rows
with open(f"{query_path}/blood_notes_1d.sql", 'r') as file: # Caution: run time = 8 min, 309714 rows   
    query_blood_notes = file.read()

blood_notes = client.query(query_blood_notes).to_dataframe()
blood_notes

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Count note category
note_type_count = blood_notes["CATEGORY"].value_counts()
plt.figure(figsize=(20, 10))
plt.bar(note_type_count.index, note_type_count.values)
plt.xlabel("Note Category")
plt.ylabel("Counts")
plt.title("Counts of Each Category in Blood Notes")
plt.xticks(rotation=45)
plt.show()`

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Use regex to find 'transfusion reaction'
TR_idx = blood_notes['TEXT'].str.contains('transfusion reaction', regex=True, case=False)
TR_notes = blood_notes[TR_idx]
TR_notes

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Who document transfusion reaction? 
TR_note_counts = TR_notes["CATEGORY"].value_counts()
TR_note_counts

plt.figure(figsize=(20,10))
plt.bar(TR_note_counts.index, TR_note_counts.values)
plt.xlabel("Note Category")
plt.ylabel("Count")
plt.title("Count of documented transfusion reaction notes by category")
plt.show()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Count the percentage of transfusion reaction in blood notes
TR_note_df = pd.DataFrame({'Category': TR_note_counts.index, 'count_TR': TR_note_counts.values})
note_type_df = pd.DataFrame({'Category': note_type_count.index, 'count_blood': note_type_count.values})
TR_note_type_df = TR_note_df.merge(note_type_df, on='Category', how='left')
TR_note_type_df['Percentage'] = TR_note_type_df['count_TR']/TR_note_type_df['count_blood']
TR_note_type_df

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fig, ax1 = plt.subplots(figsize=(12, 8))

# Set the width of the bars
bar_width = 0.4

# Set the x locations for the bars
x1 = np.arange(len(TR_note_counts))  # X positions for the count bars
x2 = x1 + bar_width  # X positions for the percentage bars

# First bar graph (Count)
ax1.bar(x1, TR_note_counts.values, width=bar_width, color='b', alpha=0.6, label='Count')
ax1.set_xlabel("Note Category")
ax1.set_ylabel("Count of Transfusion Reaction", color='b')
ax1.tick_params(axis='y', labelcolor='b')
ax1.set_title("Count of Documented Transfusion Reaction Notes by Category")
ax1.set_xticks(x1 + bar_width / 2)  # Centering the x-ticks between the two sets of bars
ax1.set_xticklabels(TR_note_counts.index)

# Create a second y-axis for the second bar graph (Percentage)
ax2 = ax1.twinx()
ax2.bar(x2, TR_note_type_df['Percentage'], width=bar_width, color='r', alpha=0.6, label='Percentage')
ax2.set_ylabel("Percentage of Transfusion Reaction", color='r')
ax2.tick_params(axis='y', labelcolor='r')

# Show the plot
plt.tight_layout()
plt.show()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
fig, ax1 = plt.subplots(figsize=(12, 8))

# Set the width of the bars
bar_width = 0.4

# Set the x locations for the bars
x1 = np.arange(len(TR_note_counts))  # X positions for the count bars
x2 = x1 + bar_width  # X positions for the percentage bars

# First bar graph (Count)
ax1.bar(x1, TR_note_counts.values, width=bar_width, color='b', alpha=0.6, label='Count')
ax1.set_xlabel("Note Category")
ax1.set_ylabel("Count of Transfusion Reaction", color='b')
ax1.tick_params(axis='y', labelcolor='b')
ax1.set_title("Count of Documented Transfusion Reaction Notes by Category")
ax1.set_xticks(x1 + bar_width / 2)  # Centering the x-ticks between the two sets of bars
ax1.set_xticklabels(TR_note_counts.index)

# Create a second y-axis for the second bar graph (Percentage)
ax2 = ax1.twinx()
ax2.bar(x2, TR_note_type_df['Percentage'], width=bar_width, color='r', alpha=0.6, label='Percentage')
ax2.set_ylabel("Percentage of Transfusion Reaction", color='r')
ax2.tick_params(axis='y', labelcolor='r')

# Show the plot
plt.tight_layout()
plt.show()