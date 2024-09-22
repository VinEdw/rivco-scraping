# Riverside County Address Scraping

## Goal

The goal of this project was to acquire a list of addresses with coordinates, then assign those addresses to territories.
The territories are identified by a letter and a number, and their boundaries are defined by lists of coordinates that form a polygon.

## Stage 1: Scraping

The first stage of this project was to scrape a list of addresses off of the [Riverside County Assessor's Website](https://rivcoview.rivcoacr.org/).
Each parcel is given a 9 digit PIN/APN.
A certain POST request can be made with that APN to the site, retrieving a JSON string describing the parcel.
In addition, a certain GET request can be made with a partial APN to the site, retrieving a list of up to 50 valid APNs that include the partial APN as a substring.
Thus, the scraping script was designed to use an 8 digit partial APN to get a list of valid APNs via the GET request, returning a maximum of 20 APNs.
Then, POST requests were made to get additional information about the parcels at those valid APNs.
The data retrieved was put into an [SQLite](https://www.sqlite.org/) database named `rivco.db`.
This process was repeated for sequential 8 digit whole numbers.

The next step would have been to find a pattern in the valid APNs.
That way, those 8 digit whole numbers could be chosen in a smarter way to avoid requesting information about invalid APNs.
Initially, I thought the first 3 digits were the book number, the next 3 were the page number of that book, and the last 3 were the lot number on that page.
But, I had trouble finding evidence in the data to support that pattern.
After doing more research, I realized that this entire stage might have been unnecessary.

I had already started scraping when I found a spreadsheet containing a superset of the addresses I needed.
It was on the website for [Riverside County Open Data](https://data.countyofriverside.us/RIVCOconnect-Broadband/County-of-Riverside-General-Parcel-Locations-with-/kxn5-8er5).
If I had found this earlier, I would have written a script to extract the latitude and longitude values into their own columns, then moved on to Stage 2.
Ultimately, to save development time I created a temporary, modified version the scraping script to directly target some of the APNs in this spreadsheet.

To start the original scraping script in the background, run the following command.

```bash
nohup python -u scrape.py > log.txt &
```

Note the PID so that you can kill the process later.
Or, search for the PID later with this command.

```bash
ps -ef | grep 'python -u scrape.py'
```

To kill the process, use the following command (substituting in your own `PID`).

```bash
kill PID
```

## Stage 2: Point in Polygon

The second stage of this project was to assign addresses to territories.
The territories are identified by a letter and a number, and their boundaries are defined by lists of coordinates that form a polygon.
This info was put in a CSV file named `territories.csv`.
Determining whether an address is found within a territory is analogous to finding whether a point is inside a polygon, barring edge cases where latitude and longitude wrap around.
Thus, I used a [ray casting algorithm](https://en.wikipedia.org/wiki/Point_in_polygon#Ray_casting_algorithm) to determine whether my points (addresses) fell within polygons (territory boundaries).

A script was written to operate on a CSV export of the database named `rivco.csv`.
Its output was sent to a new spreadsheet file named `assigned-addresses.csv`, where the addresses were assigned to their proper territories if possible.
A `makefile` was written to create both CSV files.
To build those files, you run the `make` command.
