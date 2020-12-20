# Experiments for VLDB 2021 paper

This repository contains all material used for the experiments of the following paper and is designed to enable anyone to reproduce them:

S. Irimescu, C. Berker Cikis, I. Müller, G. Fourny, G. Alonso. "Rumble: Data Independence for Large Messy Data Sets." In: PVLDB 14(4), 2020. DOI: [10.14778/3436905.3436910](https://doi.org/10.14778/3436905.3436910).

## Structure of the repository

Each system used in the comparison has its own directory, all with the same structure: a subfolder with `singlecore` experiments and one with `cluster` experiments.

```
rumble/
    cluster/
        queries/
           ...
        deploy.sh
        upload.sh
        run.sh
        terminate.sh
    singlecore/
        queries/
           ...
        deploy.sh
        ...
    run_experiments.sh
zorba/
    ...
```

## Running experiments

The flow for running the experiments is roughly the following:

1. Configure the scripts, your local machine, and some cloud resources.
   * In particular, this includes the capitalized constants in the first few lines of the scripts, setting up the [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html) such that has permissions and uses the correct region with additional flags, and creating some buckets and instance profiles.
1. Generate the data (see below).
1. Deploy the resources for the singlecore and/or cluster experiment of one system using the corresponding `deploy.sh`.
1. Do one of the following:
   * Modifiy `run_experiments.sh` to run the desired subset of the configurations. Run `run_experiments.sh`.
   * Manually run the desired queries:
      1. Run `echo "$filelist" | upload.sh` to upload the files stored in `$filelist`.
      1. Run `cat queries/some-query.jq` | run.sh` to run an individual query.
1. Terminate the resources by running the corresponding `terminate.sh`.
1. Run `make -f path/to/common/make.mk -C results/results_date-of-experiment/` to parse the log files and produce `result.jsonl` with the statistics of all runs.

## Generate data sets

### Github

We use a "prefix" of a sample for the single-core experiments and a "prefix" of the full data set for the cluster experiments. To download the sample or the full data set, use `datasets/github/download-{sample,full}.sh`.

### Weather

We use the scripts of the original authors to [download](https://github.com/apache/vxquery/blob/master/vxquery-benchmark/src/main/resources/noaa-ghcn-daily/scripts/) the data set and convert it to XML. Then we use `datasets/vxquery-weather/convert.sh` (which is based on a [query by the original authors](https://github.com/apache/vxquery/blob/master/vxquery-benchmark/src/main/resources/noaa-ghcn-daily/queries_json/q08_xml_to_json.xq)) to convert it to JSON.

### Common

The `extract_prefix.sh` and `extract_prefix_s3.sh` scripts help in producing a sub set of each data set and uploading it to S3.
