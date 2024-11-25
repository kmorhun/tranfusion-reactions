# USE AS REFERENCE FOR FUTURE PYTHON WORK. THIS WILL LIKELY NOT RUN AS IS
# Questions
"""
1. What tables and features differentiate blood-transfusion-related and non-blood-transfusion-related admittances?
2. How many hospital admittances in MIMIC-III are for blood transfusions?
3. Break down these stats by race, by gender, by other demographics
4. How common is it for a blood transfusion to be cut short?
5. What's the average/most extreme body temp difference between the start of transfusion end of transfusion? After 2 hrs? After 4? 8? 24?
6. Characterise the clinicians notes for admittances that were for blood transfusions.
"""
import os
import pandas as pd
from dotenv import load_dotenv
from google.cloud import bigquery
import matplotlib.pyplot as plt
import numpy as np
pd.set_option('display.max_rows', 100)    # Show all rows

load_dotenv()
query_path = os.environ.get('BASE_QUERY_PATH')
client = bigquery.Client(os.environ.get('BIGQUERY_PROJECT_NAME'))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
with open(f"{query_path}/scratch.sql", 'r') as file:
    query = file.read()

results = client.query(query).to_dataframe()
results

"""
## Question 1: What tables and features differentiate blood-transfusion-related and non-blood-transfusion-related admittances?
Potentially relevant tables:
* INPUTEVENTS_CV, INPUTEVENTS_MV, OUTPUTEVENTS: https://mimic.mit.edu/docs/iii/about/io/ 
* chartevents, datetimeevents, procedureevents_mv, services

NB: Timeshifting - https://mimic.mit.edu/docs/iii/about/time/#date-shifting
* Time of day, Day of week, and season(winter, spring, summer, fall) preserved
* year, exact day of month, patient overlap in ICU not preserved

NB: MIMIC Schema - https://mit-lcp.github.io/mimic-schema-spy/index.html 

"""

# get the types of items that can be administered to a patient
with open(f"{query_path}/types_of_items_cv.sql", 'r') as file:
    query_cv = file.read()
with open(f"{query_path}/types_of_items_mv.sql", 'r') as file:
    query_mv = file.read()

results_cv = client.query(query_cv).to_dataframe()
print(results_cv)
results_mv = client.query(query_mv).to_dataframe()
results_mv

#found category 'Blood Products/Colloids', ONLY IN MV
with open(f"{query_path}/all_blood_products_mv.sql", 'r') as file:
    query = file.read()

results = client.query(query).to_dataframe()
results

# as per our esteemed clinician's advice, we will use the following blood products:
chosen_blood_products_mv = (225168, 225170, 225171, 227070, 227071, 227072, 220970, 227532, 226367, 226368, 226369, 226371)
chosen_blood_products_cv = (30179, 30001, 30004, 30005, 30180)
# https://mimic.mit.edu/docs/iii/tables/inputevents_mv/ 

with open(f"{query_path}/all_blood_inputs_mv.sql", 'r') as file:
    query = file.read()

all_results = client.query(query).to_dataframe()
all_results

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
"""
sanity check: 
amountuoms are all the same
totalamountuoms are all the same
rates are reasonable
counts of status descriptions
types of cancelreasons
amounts are greater than 0
durations are reasonable
where does totalamount not match amount?
"""
print(all_results.amountuom.value_counts(dropna=False))
print()
print(all_results.totalamountuom.value_counts(dropna=False))
print()
print(all_results.statusdescription.value_counts(dropna=False))
print()
print(all_results.cancelreason.value_counts(dropna=False))
print()
print(all_results.rate.value_counts(dropna=False))
print()


#what entry has ul?
uLentries = all_results[all_results.amountuom == 'uL']
print(uLentries)
print()

print("min amount", min(all_results.amount), 'max amount', max(all_results.amount))
print("min duration", min(all_results.duration_minutes), 'max duration', max(all_results.duration_minutes))

#amounts are not greater than 0 generally speaking!
print(f"{np.size(all_results[all_results.amount < 0])} amounts < 0mL")
print(f"{np.size(all_results[all_results.amount > 1000])} amounts > 1000mL")
print(f"{np.size(all_results[all_results.amount > 2000])} amounts > 2000mL")
print(f"{np.size(all_results[all_results.amount > 10000])} amounts > 10000mL")
print(f"{np.size(all_results[all_results.amount > 20000])} amounts > 20000mL")
print(f"{np.size(all_results[all_results.amount > 50000])} amounts > 50000mL")

# plt.hist(all_results.amount, bins=[0, 0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, max(all_results.amount)])
# plt.hist(all_results.amount, bins=[0, 0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, max(all_results.amount)], density=True)
plt.hist(all_results.amount, bins=50, log=True)
plt.title("Distribution of amounts given to patients, log scale")
plt.ylabel("log(counts)")
plt.xlabel("mL")
plt.show()

plt.hist(all_results[all_results.amount < 1000].amount, bins=50, log=True)
plt.title("Distribution of amounts given to patients, limited to <1000mL")
plt.ylabel("log(counts)")
plt.xlabel("mL")
plt.show()

plt.violinplot(all_results[all_results.amount < 2000].amount)
plt.title("Distribution of amounts given to patients, limited to <2000mL")
plt.ylabel("mL")
plt.show()
plt.violinplot(all_results[all_results.amount > 2000].amount)
plt.title("Distribution of amounts given to patients, limited to >2000mL")
plt.ylabel("mL")
plt.show()

all_results[all_results.amount > 50000]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
plt.pie(all_results.statusdescription.value_counts(), labels=all_results.statusdescription.value_counts().index)

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
rounded_amounts = np.round(all_results.amount, decimals=2)
rounded_amounts.value_counts().reset_index()[:15]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print(f"{np.size(all_results[all_results.duration_minutes < 0])} durations < 0 min")
print(f"{np.size(all_results[all_results.duration_minutes > 500])} durations > 500 min")
print(f"{np.size(all_results[all_results.duration_minutes > 5000])} durations > 5000 min")

print(all_results.duration_minutes.value_counts(normalize=True)[:15])


plt.hist(all_results.duration_minutes, bins=50, log=True)
plt.title("Distribution of durations of blood inputs, log scale")
plt.ylabel("log(counts)")
plt.xlabel("minutes")
plt.show()

plt.hist(all_results[all_results.duration_minutes < 300].duration_minutes, bins=50, log=True)
plt.title("Distribution of durations of blood inputs, limited to <300 mins")
plt.ylabel("log(counts)")
plt.xlabel("minutes")
plt.show()

plt.hist(all_results[all_results.duration_minutes < 100].duration_minutes, bins=50, log=True)
plt.title("Distribution of durations of blood inputs, limited to <100 mins")
plt.ylabel("log(counts)")
plt.xlabel("minutes")
plt.show()

plt.violinplot(all_results[all_results.duration_minutes < 500].duration_minutes)
plt.title("Distribution of durations of blood inputs, limited to <500 mins")
plt.ylabel("minutes")
plt.show()
# plt.violinplot(all_results[all_results.amount > 2000].amount)
# plt.title("Distribution of amounts given to patients, limited to >2000mL")
# plt.ylabel("mL")
# plt.show()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# are durations properly correlated with amounts?
fig = plt.figure()
ax = plt.gca()
ax.scatter(all_results.duration_minutes, all_results.amount, c=(0.1, 0.2, 0.5, 0.05))
plt.axvline(x=1, color='red', linestyle='--', label='1 minute')
# plt.axvline(x=30, color='green', linestyle='--', label='30 minutes')
plt.axvline(x=60, color='blue', linestyle='--', label='60 minutes')
plt.axvline(x=15, color='purple', linestyle='--', label='120 minutes')
plt.axhline(y=350, color='purple', linestyle='--', label='350 mL')
plt.axhline(y=100, color='green', linestyle='--', label='100 mL')
ax.set_title('Transfusion duration vs Amount administered')
ax.set_xlabel('Duration (minutes)')
ax.set_ylabel('Amount administered (mL)')
ax.set_yscale('log')
ax.set_xscale('log')
ax.legend()
plt.show()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# another view of the above scatterplot;
no_neg = all_results[(all_results.duration_minutes>0) & (all_results.amount>0)]
log_mins = np.log(no_neg.duration_minutes)
log_amounts = np.log(no_neg.amount)
hist, xedges, yedges = np.histogram2d(log_mins, log_amounts, bins=100)
plt.imshow(hist.T, origin='lower', extent=[xedges[0], xedges[-1], yedges[0], yedges[-1]], cmap='viridis')
plt.colorbar(label='Count')
plt.title('Transfusion duration vs Amount administered')
plt.xlabel('duration (log(minutes)')
plt.ylabel('Y-axis')

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# based on https://github.com/MIT-LCP/mimic-code/issues/14, negative amounts might be associated with cancelled orders
with open(f"{query_path}/completed_blood_inputs.sql", 'r') as file:
    completed_query = file.read()

completed_results = client.query(completed_query).to_dataframe()
completed_results

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print(completed_results.amountuom.value_counts())
print()
print(completed_results.totalamountuom.value_counts())
print()
print(completed_results.statusdescription.value_counts())
print()
print(completed_results.cancelreason.value_counts())
print()

#what entry has ul?
uLentries = completed_results[completed_results.amountuom == 'uL']
print(uLentries)
print()

print("min amount", min(completed_results.amount), 'max amount', max(completed_results.amount))
print("min duration", min(completed_results.duration_minutes), 'max duration', max(completed_results.duration_minutes))

print(f"{np.size(completed_results[completed_results.amount < 0])} amounts < 0mL")
print(f"{np.size(completed_results[completed_results.amount > 1000])} amounts > 1000mL")
print(f"{np.size(completed_results[completed_results.amount > 2000])} amounts > 2000mL")
print(f"{np.size(completed_results[completed_results.amount > 10000])} amounts > 10000mL")
print(f"{np.size(completed_results[completed_results.amount > 20000])} amounts > 20000mL")
print(f"{np.size(completed_results[completed_results.amount > 50000])} amounts > 50000mL")
# plt.hist(completed_results.amount, bins=[0, 0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, max(completed_results.amount)])
# plt.hist(completed_results.amount, bins=[0, 0, 100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, max(completed_results.amount)], density=True)
plt.hist(completed_results.amount, bins=50, log=True)
plt.title("Distribution of amounts given to patients, log scale")
plt.ylabel('log(counts)')
plt.xlabel("mL")
plt.show()
plt.violinplot(completed_results[completed_results.amount < 5000].amount)
plt.title("Distribution of amounts given to patients, limited to <2000mL")
plt.ylabel("mL")
plt.show()
plt.violinplot(completed_results[completed_results.amount > 5000].amount)
plt.title("Distribution of amounts given to patients, limited to >2000mL")
plt.ylabel("mL")
plt.show()

completed_results[completed_results.amount > 50000]

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
completed_rounded_amounts = np.round(completed_results.amount, decimals=2)
completed_rounded_amounts.value_counts().reset_index()[:15]


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print(f"{np.size(completed_results[completed_results.duration_minutes < 0])} durations < 0 min")
print(f"{np.size(completed_results[completed_results.duration_minutes > 500])} durations > 500 min")
print(f"{np.size(completed_results[completed_results.duration_minutes > 5000])} durations > 5000 min")

print(completed_results.duration_minutes.value_counts(normalize=True)[:15])

plt.hist(completed_results.duration_minutes, bins=50, log=True)
plt.title("Distribution of durations of blood inputs, log scale")
plt.xlabel("minutes")
plt.show()

plt.hist(completed_results[completed_results.duration_minutes < 300].duration_minutes, bins=50, log=True)
plt.title("Distribution of durations of blood inputs, limited to <300 mins")
plt.xlabel("minutes")
plt.show()

plt.hist(completed_results[completed_results.duration_minutes < 100].duration_minutes, bins=50, log=True)
plt.title("Distribution of durations of blood inputs, limited to <100 mins")
plt.xlabel("minutes")
plt.show()

plt.violinplot(completed_results[completed_results.duration_minutes < 500].duration_minutes)
plt.title("Distribution of durations of blood inputs, limited to <500 mins")
plt.ylabel("minutes")
plt.show()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# are durations properly correlated with amounts?
fig = plt.figure()
ax = plt.gca()
ax.scatter(completed_results.duration_minutes, completed_results.amount, c=(0.1, 0.2, 0.5, 0.05))
plt.axvline(x=1, color='red', linestyle='--', label='1 minute')
# plt.axvline(x=30, color='green', linestyle='--', label='30 minutes')
plt.axvline(x=60, color='blue', linestyle='--', label='60 minutes')
# plt.axvline(x=120, color='purple', linestyle='--', label='120 minutes')
plt.axhline(y=350, color='purple', linestyle='--', label='350 mL')
ax.set_xlabel('Duration (minutes)')
ax.set_ylabel('Amount administered (mL)')
ax.set_yscale('log')
ax.set_xscale('log')
ax.legend()
plt.show()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
with open(f"{query_path}/blood_input_amounts_by_item.sql", 'r') as file:
    amounts_by_item_query = file.read()

amounts_by_item_results = client.query(amounts_by_item_query).to_dataframe()
amounts_by_item_results

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
with open(f"{query_path}/completed_blood_input_amounts_by_item.sql", 'r') as file:
    completed_amounts_by_item_query = file.read()

completed_amounts_by_item_results = client.query(completed_amounts_by_item_query).to_dataframe()
completed_amounts_by_item_results

"""
# Exploring CV Inputs 
"""

with open(f"{query_path}/rbc_inputs_cv.sql", 'r') as file:
    cv_inputs_query = file.read()

cv_inputs_results = client.query(cv_inputs_query).to_dataframe()
cv_inputs_results
print(cv_inputs_results.rate.value_counts(dropna=False))
print(cv_inputs_results.rateuom.value_counts(dropna=False))
print(cv_inputs_results.label.value_counts(dropna=False))
print(cv_inputs_results.amountuom.value_counts(dropna=False))

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
plt.hist(cv_inputs_results.amount, bins=50, log=True)
plt.title("RBC input amounts from cv, log scale")
plt.xlabel("ml")
plt.ylabel("log(count)")
plt.show()

plt.hist(cv_inputs_results[cv_inputs_results.amount < 2500].amount, bins=50, log=True)
plt.title("RBC input amounts from cv, log scale (limited to <2500 ml)")
plt.xlabel("ml")
plt.ylabel("log(count)")

cv_amounts_rounded = np.round(cv_inputs_results.amount, decimals=2)
cv_amounts_rounded.value_counts().reset_index()[:15]

# WHy are there so many "None"s for amountuom?
cv_inputs_results[cv_inputs_results.amountuom != "ml"]


"""
# Just RBC Transfusions    
"""

with open(f"{query_path}/rbc_inputs.sql", 'r') as file:
    rbc_transfusion_query = file.read()

rbc_transfusion_results_mv = client.query(rbc_transfusion_query).to_dataframe()
rbc_transfusion_results_mv
rbc_transfusion_results_mv.label.value_counts()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
PRBC = rbc_transfusion_results_mv[rbc_transfusion_results_mv.itemid == 225168]
OR_PRBC = rbc_transfusion_results_mv[rbc_transfusion_results_mv.itemid == 226368]
PACU_PRBC = rbc_transfusion_results_mv[rbc_transfusion_results_mv.itemid == 227070]

#OR and PACU PRBCs are all duration 1 minute?
print(OR_PRBC.duration_minutes.value_counts())
print(PACU_PRBC.duration_minutes.value_counts())

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# are durations properly correlated with amounts?
fig = plt.figure()
ax = plt.gca()

#color by the three item ids
# ax.scatter(PRBC.duration_minutes, PRBC.amount, c=(0.1, 0.2, 0.5, 0.05))
ax.scatter(OR_PRBC.duration_minutes, OR_PRBC.amount, c=(0.5, 0.1, 0.2, 0.05))
ax.scatter(PACU_PRBC.duration_minutes, PACU_PRBC.amount, c=(0.2, 0.5, 0.1, 0.05))
plt.axvline(x=1, color='red', linestyle='--', label='1 minute')
# plt.axvline(x=30, color='green', linestyle='--', label='30 minutes')
plt.axvline(x=60, color='blue', linestyle='--', label='60 minutes')
plt.axvline(x=240, color='purple', linestyle='--', label='240 minutes')
plt.axhline(y=350, color='purple', linestyle='--', label='350 mL')
ax.set_xlabel('Duration (minutes)')
ax.set_ylabel('Amount administered (mL)')
ax.set_yscale('log')
ax.set_xscale('log')
ax.set_title('Metavision Packed RBC transfusion events by duration and volume')
ax.legend()
plt.show()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
print(f"removing {np.sum(rbc_transfusion_results_mv["cancelreason"] != 0)} entries for being cancelled")
completed_rbc_transfusion_results_mv = rbc_transfusion_results_mv[rbc_transfusion_results_mv["cancelreason"] == 0]
completed_rbc_transfusion_results_mv

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
completed_PRBC = completed_rbc_transfusion_results_mv[completed_rbc_transfusion_results_mv.itemid == 225168]
completed_OR_PRBC = completed_rbc_transfusion_results_mv[completed_rbc_transfusion_results_mv.itemid == 226368]
completed_PACU_PRBC = completed_rbc_transfusion_results_mv[completed_rbc_transfusion_results_mv.itemid == 227070]

#OR and PACU PRBCs are all duration 1 minute?
print(completed_OR_PRBC.duration_minutes.value_counts())
print(completed_PACU_PRBC.duration_minutes.value_counts())

# of the 1 minute PRBC transfusions, what are their volumes?
completed_OR_PRBC_1min = completed_OR_PRBC[completed_OR_PRBC.duration_minutes == 1]
plt.hist(completed_OR_PRBC_1min.amount, bins=50, log=True)
plt.xlabel("volume (ml)")
plt.ylabel("log(count)")
plt.title("Metavision OR PRBC volumes for 1-minute duration transfusions")
plt.show()

plt.hist(completed_OR_PRBC_1min[completed_OR_PRBC_1min.amount < 1500].amount, bins=50, log=True)
plt.xlabel("volume (ml)")
plt.ylabel("log(count)")
plt.title("Metavision OR PRBC volumes for 1-minute duration transfusions (amount < 1500 ml)")
plt.show()

completed_PACU_PRBC_1min = completed_PACU_PRBC[completed_PACU_PRBC.duration_minutes == 1]
plt.hist(completed_PACU_PRBC_1min.amount, bins=50, log=True)
plt.xlabel("volume (ml)")
plt.ylabel("log(count)")
plt.title("Metavision PACU PRBC volumes for 1-minute duration transfusions")
plt.show()

plt.hist(completed_PACU_PRBC_1min[completed_PACU_PRBC_1min.amount < 1500].amount, bins=50, log=True)
plt.xlabel("volume (ml)")
plt.ylabel("log(count)")
plt.title("Metavision PACU PRBC volumes for 1-minute duration transfusions (amount < 1500 ml)")
plt.show()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# are durations properly correlated with amounts?
fig = plt.figure()
ax = plt.gca()

#if you comment and uncomment different combinations of the scatter plots below
# you will see that OR_PRBC and PACU_PRBC are exclusively 1min duration inputs
ax.scatter(completed_PRBC.duration_minutes, completed_PRBC.amount, c=(0.1, 0.2, 0.5, 0.05))
ax.scatter(completed_OR_PRBC.duration_minutes, completed_OR_PRBC.amount, c=(0.5, 0.1, 0.2, 0.05))
ax.scatter(completed_PACU_PRBC.duration_minutes, completed_PACU_PRBC.amount, c=(0.2, 0.5, 0.1, 0.05))
plt.axvline(x=1, color='red', linestyle='--', label='1 minute')
# plt.axvline(x=30, color='green', linestyle='--', label='30 minutes')
plt.axvline(x=60, color='blue', linestyle='--', label='60 minutes')
plt.axvline(x=240, color='purple', linestyle='--', label='240 minutes')
plt.axhline(y=350, color='purple', linestyle='--', label='350 mL')
ax.set_xlabel('Duration (minutes)')
ax.set_ylabel('Amount administered (mL)')
ax.set_yscale('log')
ax.set_xscale('log')
ax.set_title('Metavision Packed RBC transfusion events by duration and volume')
ax.legend()
plt.show()

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
completed_PRBC.describe()
completed_OR_PRBC.describe()
#NOTE that the rates are all NaN! and end/start are 1 minute apart
completed_PACU_PRBC.describe()
#NOTE that the rates are all NaN! and end/start are 1 minute apart

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

plt.hist(completed_PRBC.rate, bins=50, log=True)
plt.xlabel("ml/min")
plt.ylabel("log(count)")
plt.title("Distribution of recorded rate of completed PRBC transfusions, log count ")

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
with open(f"{query_path}/FFP_blood_inputs.sql", 'r') as file:
    FFP_transfusion_query = file.read()

FFP_inputs_mv = client.query(FFP_transfusion_query).to_dataframe()
FFP_inputs_mv

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
with open(f"{query_path}/platelets_blood_inputs.sql", 'r') as file:
    platelets_transfusion_query = file.read()

platelets_inputs_mv = client.query(platelets_transfusion_query).to_dataframe()
platelets_inputs_mv

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
with open(f"{query_path}/rbc_inputs.sql", 'r') as file:
    PRBC_transfusion_query = file.read()

PRBC_inputs_mv = client.query(PRBC_transfusion_query).to_dataframe()
PRBC_inputs_mv

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

def plot_transfusiontype(cat, name, i):

    # are durations properly correlated with amounts?
    fig = plt.figure()
    ax = plt.gca()



    #OR and PACU PRBCs are all duration 1 minute?
    print("Counts")
    print(len(cat))
    #if you comment and uncomment different combinations of the scatter plots below
    # you will see that OR_= and PACU_ are exclusively 1min duration inputs
    ax.scatter(cat.duration_minutes, cat.amount, c=(0.1, 0.2, 0.5, 0.05), label=name)
    plt.axvline(x=1, color='red', linestyle='--', label='1 minute')
    # plt.axvline(x=30, color='green', linestyle='--', label='30 minutes')
    plt.axvline(x=60, color='blue', linestyle='--', label='60 minutes')
    plt.axvline(x=240, color='purple', linestyle='--', label='240 minutes')
    plt.axhline(y=350, color='purple', linestyle='--', label='350 mL')
    ax.set_xlabel('Duration (minutes)')
    ax.set_ylabel('Amount administered (mL)')
    ax.set_yscale('log')
    ax.set_xscale('log')
    ax.set_title("Metavision "+name+" transfusion events, cancelreason="+str(i))
    ax.legend()
    plt.legend()
    plt.show()

for i in range(3):
    print("Examining Cancel Reason "+str(i))

    FFP_c = FFP_inputs_mv[FFP_inputs_mv.cancelreason == i]
    platelets_c = platelets_inputs_mv[platelets_inputs_mv.cancelreason == i]
    PRBC_c = PRBC_inputs_mv[PRBC_inputs_mv.cancelreason == i]

    FFP = FFP_c[FFP_c.itemid == 220970]
    OR_FFP = FFP_c[FFP_c.itemid == 226367]
    PACU_FFP = FFP_c[FFP_c.itemid == 227072]

    PRBCs = PRBC_c[PRBC_c.itemid == 225168]

    plat = platelets_c[platelets_c.itemid == 225170]
    OR_plat = platelets_c[platelets_c.itemid == 226369]
    PACU_plat = platelets_c[platelets_c.itemid == 227071]

    plot_transfusiontype(FFP, "FFP", i)
    plot_transfusiontype(plat, "Platelets", i)
    plot_transfusiontype(PRBCs, "PRBCs", i)


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
for i in range(3):
    print("Examining Cancel Reason "+str(i))

    FFP_c = FFP_inputs_mv[FFP_inputs_mv.cancelreason == i]
    platelets_c = platelets_inputs_mv[platelets_inputs_mv.cancelreason == i]
    PRBC_c = PRBC_inputs_mv[PRBC_inputs_mv.cancelreason == i]

    FFP = FFP_c[FFP_c.itemid == 220970]
    platelet = platelets_c[platelets_c.itemid == 225170]
    PRBCs = PRBC_c[PRBC_c.itemid == 225168]
    
    #plot_transfusiontype(FFP, OR_FFP, PACU_FFP, "FFP", i)
    #plot_transfusiontype(plat, OR_plat, PACU_plat, "Platelets", i)
    # are durations properly correlated with amounts?
    fig = plt.figure()
    ax = plt.gca()

    #if you comment and uncomment different combinations of the scatter plots below
    # you will see that OR_= and PACU_ are exclusively 1min duration inputs
    ax.scatter(platelet.duration_minutes, platelet.amount, c=(0.1, 0.2, 0.5, 0.05), label="platelet")
    ax.scatter(FFP.duration_minutes, FFP.amount, c=(0.5, 0.1, 0.2, 0.05),label="FFP")
    ax.scatter(PRBCs.duration_minutes, PRBCs.amount, c=(0.2, 0.5, 0.1, 0.05), label="PRBC")
    plt.axvline(x=1, color='red', linestyle='--', label='1 minute')
    # plt.axvline(x=30, color='green', linestyle='--', label='30 minutes')
    plt.axvline(x=60, color='blue', linestyle='--', label='60 minutes')
    plt.axvline(x=240, color='purple', linestyle='--', label='240 minutes')
    plt.axhline(y=350, color='purple', linestyle='--', label='350 mL')
    ax.set_xlabel('Duration (minutes)')
    ax.set_ylabel('Amount administered (mL)')
    ax.set_yscale('log')
    ax.set_xscale('log')
    ax.set_title("Metavision transfusion events, cancelreason="+str(i))
    ax.legend()
    plt.legend()
    plt.show()





