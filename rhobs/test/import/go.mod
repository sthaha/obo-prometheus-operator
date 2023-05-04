module github.com/rhobs/obo-prometheus-operator/rhobs/test/import

go 1.20

require (
	github.com/rhobs/obo-prometheus-operator v0.64.0-rhobs2
	github.com/rhobs/obo-prometheus-operator/pkg/apis/monitoring v0.64.0-rhobs2
	github.com/rhobs/obo-prometheus-operator/pkg/client v0.64.0-rhobs1
)

replace (
	github.com/rhobs/obo-prometheus-operator => ../../..
	github.com/rhobs/obo-prometheus-operator/pkg/client => ../../../pkg/client
	github.com/rhobs/obo-prometheus-operator/pks/apis/monitoring => ../../../pkg/apis/monitoring/
)
