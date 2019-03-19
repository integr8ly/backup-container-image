# Adding backup CronJobs to Integreatly

Documentation for adding a new backup CronJob to an Integreatly instance.

## Adding a new type of backup

Currently, we have a [backup image](https://github.com/integr8ly/backup-container-image)
that can perform generic backups for a number of components such as `MySQL`,
`Redis` and `Postgres`. If there is a new component type that needs to be
backed-up, it should be added to this image by adding a new script into
[`image/tools/lib/component/`](https://github.com/integr8ly/backup-container-image/tree/master/image/tools/lib/component).

The name of the script is important, as it will be referenced in the
[CronJob spec](https://github.com/integr8ly/backup-container-image/blob/master/templates/openshift/backup-cronjob-template.yaml#L35)
to define what type of backup should be performed in the Job.

For a detailed description of how the default backup CronJob template is used,
[see the documentation](https://github.com/integr8ly/backup-container-image/tree/master/templates/openshift).

## Adding a new backup CronJob

Adding a new backup CronJob can be done either in the Integreatly installation
Ansible scripts or in the Operators for a service.

### Installer

When adding a CronJob through the installer, a `backup.yml` task file should be
added to the component. This `backup.yml` file should follow the same pattern
as other existing components e.g. [3scale](https://github.com/integr8ly/installation/blob/master/roles/3scale/tasks/backup.yml)
with any shared logic being kept in the [Backup Role](https://github.com/integr8ly/installation/tree/master/roles/backup).

### Operator

When adding a CronJob through an operator, it can follow the pattern from the
[Keycloak Operator](https://github.com/integr8ly/keycloak-operator/blob/cf1bcad27ca0a36a4e3ecb8f70f801d19a416839/pkg/keycloak/phaseHandler.go#L219).

### Monitoring

In order for the CronJob and the Jobs that it creates to be monitored correctly
a number of steps must be done:
- The CronJob and the Job it creates must have a label `monitoring-key: middleware`.
This allows us to filter out any CronJobs that aren't related to Integreatly.
- The Job that the CronJob creates must also have a label `cronjob-name: <cronjob>`,
where `<cronjob>` is the `name` of the parent CronJob. This allows us to link
Jobs to their CronJobs.
- The CronJob must be added to the `backup_expected_cronjobs` var in the `backup`
role of the installer, regardless of where the CronJob is created.
