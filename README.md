# Riverside County Address Scraping

## Preface

This entire project might have been unnecessary, since I just found the data I needed on the website for [Riverside County Open Data](https://data.countyofriverside.us/RIVCOconnect-Broadband/County-of-Riverside-General-Parcel-Locations-with-/kxn5-8er5).

## Stage 1

The first goal of this project is to scrape a list of addresses off of the [Riverside County Assessor's Website](https://rivcoview.rivcoacr.org/).
To start the scraping script in the background, run the following command.

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
