# RHOBS Scripts

This directory hosts scripts that helps with creation of forked Prometheus
Operator with only the api-group changed to `monitoring.rhobs`

How to use this branch

```
git fetch upstream
git push downstream v0.59.1:refs/heads/rhobs-rel-0.59.1-rhobs1
```

### Prepare release

```
git co -b pr-for-release
git reset --hard v0.59.1
git merge --squash --allow-unrelated-histories rhobs-scripts
git commit -m "git: merge rhobs-scripts"
./rhobs/rhobs/make-release-commit.sh

git push -u my-fork HEAD

```
Create pull request and ensure that the title says
`chore(release): v0.59.1-rhobs`

### Automatic release once the PR merges

Check .github/workflows/rhobs-release.yaml
