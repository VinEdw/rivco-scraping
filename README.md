# Riverside County Address Scraping

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
