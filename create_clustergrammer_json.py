# make network object and load file
from clustergrammer import Network
net = Network()
net.load_file('mult_view.tsv')




# Z-score normalize the rows
#net.normalize(axis='row', norm_type='zscore', keep_orig=True)





# calculate clustering using default parameters
net.cluster()

# save visualization JSON to file for use by front end
net.write_json_to_file('viz', 'mult_view.json')



#	needs pandas and sklearn as well
#	pip install --user --upgrade clustergrammer pandas sklearn
