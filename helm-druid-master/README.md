# helm-druid

A helm chart for druid

### Setup

**You can skip this section if the zookeeper chart is already tracked in charts/**

Make sure you have your helm repos set up for stable and incubating

```
helm dep update
```

Zookeeper is a dependency here so the above command will download zookeeper chart

### Installation (Local)

This chart comes with multiple values files

- values.yaml -> derby
- values-postgres.yaml -> postgres

Which one you would like to use is up to you.

```
helm install druid ./
OR
helm install -f values-local-postgres.yaml druid ./
```