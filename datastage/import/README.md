# mcix datastage import GitHub action

This action invokes the [mcix datastage import](https://nextgen.mettleci.io/mettleci-cli/datastage-namespace/#import) command.

## Inputs

* api-key (Required)

CP4D/CP4DaaS API key

* *url (Required)

Base url of CP4D/CP4DaaS

* user (Required)

CP4D/CP4DaaS username

* assets (Required)

Path to DataStage export zip file or directory

* project (Required when -project-id not specified)

Name of target project

* project-id (Required when -project not specified)

Id of target project

## Outputs

## `output`

The console output of the mcix asset-analysis test command.

## Example usage

```
- name: mcix asset-analysis test action
  uses: actions/mcix-asset-analysis-test
  with:
    rules: '/app/rules'
    path: '/app/datastage'
    report: '/app/asset_analysis_report.xml'
    test-suite: 'mcix tests'
```
