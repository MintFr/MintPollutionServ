# MintPollutionServ

This repository aims to import the data from our pollution model and upload data in our databases in order to use them during our itinerary calculations.

# Process of upload

## 1 - Exposition data
The data we get from the pollution model is a csv file, with different columns. The three first are coordinates x, y and z and the other ones are the concentrations of the different polluting particles we are studying.

## 2 - Import data in our databases
The first step of our data integration is to upload the data from the csv file in our databases. To do so, we create a table, called pollution, in which we store the data.

## 3 - Simplify data
The next step is to simplify data, because we have too much precision. Indeed, we use the OpenStreetMap open data for our geographic database, and the table we use to calculate itineraries (called ways) is based on edges. The output of the model gives us too much data per edge, whereas we only need a unique value per type of particles. Therefore, we created a new table called buffer_ways, which creates a 5 meter buffer on all edges. Then, we get all pollution data intersecting each buffer, and calculate the average concentration for each particle. In this way, we end up with only one value for. each edge, which is representative because it is the average concentration of all points close to the edge.

## 4 - Create concentration index for each edge
Then, we need to create a concentration index, gathering all the polluting particles we took into account. In our case, it is NO2, PM10 and PM2.5 (PM stands for "Particle Matter"). Thus, we used a conversion array found on website of air quality organizations (from Bretagne and Centre regions), and we converted our concentrations with this array.

![arrayConversion](Conversion from concentration into indexes)

The concentration index we used is the sum of the different indexes of particles.

## 5 - Final index by edge
The last step to create our indexes is to take into account the geometry and especially the distance of the edge we consider. Indeed, the index of an edge of 600 meters should be different of an edge of 30 meters, even if the concentration are equivalents.
Therefore, we chose this formula to get our final indexes : 

$$ i_{final} = i_{concentration} \times \dfrac {1}{2} $$
