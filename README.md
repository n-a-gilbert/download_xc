# Information and code to download recordings to prepare for birding trips

I've found that the best way to learn calls (apart from actually getting out and birding) is to listen to recordings over and over and over again. Training the neural net, if you will. Well, that is annoying and laborious to do manually on eBird or Merlin. Therefore it is desirable to assemble a playlist that can be listened to (and re-listened to) while doing other tasks like driving, cooking, etc., to learn bird calls. But. Downloading lots of Xeno-Canto recordings is a huge pain in the ass. Huge shoutout to Marcelo Araya-Salas and Grace Smith-Vidaurre for their excellent [warbleR](https://marce10.github.io/warbleR/) package which allows for automated download of XC recordings.

## Step 1. Get species list and frequencies for focal regions or hotspots from eBird. 

For this example, I want to download recordings for reguarly reported species from Kaeng Krachan National Park in Thailand. To get barcharts, navigate: eBird home > Explore > Barcharts. You can specify a region (state, county, province) OR hotspots within a region. I specified the 20 or so hotspots within and near Kaeng Krachan National Park. Once the barcharts load, there is a link ("Download Histogram Data") to download a .txt file with data from the barchart: 

![image](https://github.com/user-attachments/assets/8b358c75-0744-41c8-93c9-ea142abc4975)

## Step 2. Format the .txt file.

The text file has some weird/unforunate formatting. There is a bunch of white space at the top, and then sample size information at the top. Delete the white space and the sample size information so the first data recorded is the name of the first species (here, Lesser Whistling Duck). 

![image](https://github.com/user-attachments/assets/e61c94fa-9d9e-42be-8100-406ad9ff2e48)

## Step 3. Wrangle the text file to clean up scientific names and get reporting frequencies. 

The script [download_xc_recordings.R](./code/download_xc_recordings.R) first does some wrangling on the eBird text file to clean up the scientific names. You may also want to filter down the species list to omit species that are rare or only occur in the focal region seasonally. Since I'm going to Thailand in the winter, I filtered down to species that occur in the winter months and am retaining species that are recorded on at least 1% of checklists.

## Step 4. Query Xento-Canto metadata and specify what types of recordings you want to download. 

The R package [warbleR](https://marce10.github.io/warbleR/) makes it easy to query the Xeno-Canto database. The script [download_xc_recordings.R](./code/download_xc_recordings.R) first queries the database for all recordings of the species of interest. I then do some wrangling on the metadata file because I want to download a variety of call types (I simplify the vocalization type column into "song", "call", "song & call", and "other"), of the best quality possible, and ideally want recordings that are not too long (I used 90 seconds as my cutoff). This produces a table I call "download_these", which contains a column of the recording ID and common name and call type to name the downloaded files. There are lots of other possible options for filtering - for example, if you want recordings that only come from the specific region you are studying for, you could create a simple features bounding box around the region and retain only recordings that come from that area (most recordings have lat/longs included in the metadata). 

## Step 5. Download the recordings. 

The last step in [download_xc_recordings.R](./code/download_xc_recordings.R) is looping through the download_these table and downloading each file.

## Step 6. Transfer recordings to mobile device.

Once the recordings downloaded, I was able to easily transfer them onto my phone via a USB cable. 

## Step 7. Play recordings using Spotify or Foldplay apps.

It is possible to play local files with Spotify (you have to change app settings to allow access to local files). **However, Spotify has the irksome feature of not recognizing folder structure.** So, if you download recordings for multiple hotspots or regions, and want to have them stashed in separate playlists for studying, your SOL with Spotify. An alternative option I found is the [Foldplay app](https://play.google.com/store/apps/details?id=net.pnhdroid.foldplay&hl=en_US&pli=1), which respects folder structure and has the same playlist features as Spotify (shuffle, etc.)
